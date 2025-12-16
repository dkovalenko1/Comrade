import Foundation

// Editor Mode

enum TaskEditorMode {
    case create
    case edit(TaskEntity)
}

// Reminder Model

struct ReminderModel {
    let id: UUID
    var isRelative: Bool
    var absoluteDate: Date?
    var relativeMinutes: Int32
    
    init(isRelative: Bool = true, absoluteDate: Date? = nil, relativeMinutes: Int32 = 30) {
        self.id = UUID()
        self.isRelative = isRelative
        self.absoluteDate = absoluteDate
        self.relativeMinutes = relativeMinutes
    }
    
    init(from entity: ReminderEntity) {
        self.id = entity.id ?? UUID()
        self.isRelative = entity.isRelative
        self.absoluteDate = entity.absoluteDate
        self.relativeMinutes = entity.relativeMinutes
    }
    
    var displayText: String {
        if isRelative {
            return formatRelativeTime(minutes: Int(relativeMinutes))
        } else if let date = absoluteDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, HH:mm"
            return formatter.string(from: date)
        }
        return "No reminder"
    }
    
    private func formatRelativeTime(minutes: Int) -> String {
        if minutes == 0 {
            return "At time of event"
        } else if minutes < 60 {
            return "\(minutes) min before"
        } else if minutes < 1440 {
            let hours = minutes / 60
            return "\(hours) hour\(hours == 1 ? "" : "s") before"
        } else {
            let days = minutes / 1440
            return "\(days) day\(days == 1 ? "" : "s") before"
        }
    }
}

// TaskEditorViewModel

final class TaskEditorViewModel {
    
    // Properties
    
    private let taskService: TaskService
    private let notificationService: NotificationService
    private let categoryService: CategoryService
    
    let mode: TaskEditorMode
    private var existingTask: TaskEntity?
    
    // Task Fields
    
    var name: String = ""
    var taskDescription: String = ""
    var category: String = "Personal"
    var categoryColorHex: String = "#007AFF"
    var priority: TaskPriority = .medium
    var deadline: Date?
    var deadlineIsAllDay: Bool = true
    var reminders: [ReminderModel] = []
    var selectedTags: [TagEntity] = []
    var dependencies: [TaskEntity] = []
    
    // Available Options
    
    var availableCategories: [Category] {
        return categoryService.categories
    }
    
    let availableRelativeReminders: [(title: String, minutes: Int32)] = [
        ("At time of event", 0),
        ("5 minutes before", 5),
        ("15 minutes before", 15),
        ("30 minutes before", 30),
        ("1 hour before", 60),
        ("2 hours before", 120),
        ("1 day before", 1440),
        ("2 days before", 2880),
        ("1 week before", 10080)
    ]
    
    // Output Closures
    
    var onValidationError: ((String) -> Void)?
    var onSaveSuccess: ((TaskEntity) -> Void)?
    var onSaveError: ((String) -> Void)?
    
    // Init
    
    init(
        mode: TaskEditorMode,
        prefilledDeadline: Date? = nil,
        taskService: TaskService = .shared,
        notificationService: NotificationService = .shared,
        categoryService: CategoryService = .shared
    ) {
        self.mode = mode
        self.taskService = taskService
        self.notificationService = notificationService
        self.categoryService = categoryService
        
        if case .edit(let task) = mode {
            self.existingTask = task
            loadTaskData(task)
        } else if let date = prefilledDeadline {
            let startOfDay = Calendar.current.startOfDay(for: date)
            self.deadline = startOfDay
            self.deadlineIsAllDay = true
        }
    }
    
    // Load Existing Task
    
    private func loadTaskData(_ task: TaskEntity) {
        name = task.name ?? ""
        taskDescription = task.taskDescription ?? ""
        category = task.category ?? "Personal"
        categoryColorHex = task.categoryColorHex ?? "#007AFF"
        priority = TaskPriority(rawValue: task.priority) ?? .medium
        deadline = task.deadline
        deadlineIsAllDay = task.deadlineIsAllDay
        
        // Load reminders
        if let reminderEntities = task.reminders as? Set<ReminderEntity> {
            reminders = reminderEntities.map { ReminderModel(from: $0) }
        }
        
        // Load tags
        if let tagEntities = task.tags as? Set<TagEntity> {
            selectedTags = Array(tagEntities)
        }
        
        // Load dependencies
        if let dependencyEntities = task.dependencies as? Set<TaskEntity> {
            dependencies = Array(dependencyEntities)
        }
    }
    
    // Validation
    
    func validate() -> Bool {
        // Name is required
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            onValidationError?("Task name is required")
            return false
        }
        
        if trimmedName.count > 200 {
            onValidationError?("Task name is too long (max 200 characters)")
            return false
        }
        
        return true
    }
    
    // Save
    
    func save() {
        guard validate() else { return }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = taskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch mode {
        case .create:
            createTask(name: trimmedName, description: trimmedDescription)
        case .edit:
            updateTask(name: trimmedName, description: trimmedDescription)
        }
    }
    
    private func createTask(name: String, description: String) {
        let task = taskService.createTask(
            name: name,
            taskDescription: description.isEmpty ? nil : description,
            category: category,
            categoryColorHex: categoryColorHex,
            priority: priority,
            deadline: deadline,
            deadlineIsAllDay: deadlineIsAllDay
        )
        
        
        // Add tags
        for tag in selectedTags {
            taskService.addTag(tag, to: task)
        }
        
        // Add dependencies
        for dependency in dependencies {
            taskService.addDependency(to: task, dependency: dependency)
        }
        
        // Create reminders in CoreData and schedule notifications
        saveReminders(for: task)
        
        onSaveSuccess?(task)
    }
    
    private func updateTask(name: String, description: String) {
        guard let task = existingTask else {
            onSaveError?("Task not found")
            return
        }
        
        task.name = name
        task.taskDescription = description.isEmpty ? nil : description
        task.category = category
        task.categoryColorHex = categoryColorHex
        task.priority = priority.rawValue
        task.deadline = deadline
        task.deadlineIsAllDay = deadlineIsAllDay
        
        // Update tags - remove old, add new
        if let existingTags = task.tags as? Set<TagEntity> {
            for tag in existingTags {
                taskService.removeTag(tag, from: task)
            }
        }
        for tag in selectedTags {
            taskService.addTag(tag, to: task)
        }
        
        // Update dependencies - remove old, add new
        if let existingDeps = task.dependencies as? Set<TaskEntity> {
            for dep in existingDeps {
                taskService.removeDependency(from: task, dependency: dep)
            }
        }
        for dependency in dependencies {
            taskService.addDependency(to: task, dependency: dependency)
        }
        
        // Update reminders
        if let taskId = task.id {
            notificationService.cancelReminders(for: taskId)
        }
        if let existingReminders = task.reminders as? Set<ReminderEntity> {
            for reminder in existingReminders {
                taskService.removeReminder(reminder)
            }
        }
        saveReminders(for: task)
        
        taskService.updateTask(task)
        onSaveSuccess?(task)
    }
    
    private func saveReminders(for task: TaskEntity) {
        for reminder in reminders {
            _ = taskService.addReminder(
                to: task,
                isRelative: reminder.isRelative,
                absoluteDate: reminder.absoluteDate,
                relativeMinutes: reminder.relativeMinutes
            )
            
            // Schedule notification
            if reminder.isRelative {
                if let deadline = deadline {
                    let notificationDate = Calendar.current.date(
                        byAdding: .minute,
                        value: -Int(reminder.relativeMinutes),
                        to: deadline
                    )
                    if let date = notificationDate {
                        notificationService.scheduleReminder(for: task, at: date)
                    }
                }
            } else if let absoluteDate = reminder.absoluteDate {
                notificationService.scheduleReminder(for: task, at: absoluteDate)
            }
        }
    }
    
    // Category
    
    func setCategory(_ categoryName: String) {
        if let found = availableCategories.first(where: { $0.name == categoryName }) {
            category = found.name
            categoryColorHex = found.colorHex
        }
    }
    
    func getCategoryIndex() -> Int {
        return availableCategories.firstIndex(where: { $0.name == category }) ?? 0
    }
    
    // Reminders
    
    func addReminder(_ reminder: ReminderModel) {
        reminders.append(reminder)
    }
    
    func removeReminder(at index: Int) {
        guard index < reminders.count else { return }
        reminders.remove(at: index)
    }
    
    func addRelativeReminder(minutes: Int32) {
        let reminder = ReminderModel(isRelative: true, relativeMinutes: minutes)
        reminders.append(reminder)
    }
    
    func addRelativeReminderIfNeeded(minutes: Int32) {
        guard !reminders.contains(where: { $0.isRelative && $0.relativeMinutes == minutes }) else { return }
        reminders.append(ReminderModel(isRelative: true, relativeMinutes: minutes))
    }
    
    func clearReminders() {
        reminders.removeAll()
    }
    
    func addAbsoluteReminder(date: Date) {
        let reminder = ReminderModel(isRelative: false, absoluteDate: date)
        reminders.append(reminder)
    }
    
    // Dependencies
    
    func addDependency(_ task: TaskEntity) {
        guard let existingTask = existingTask else {
            // For new task, just add to list
            if !dependencies.contains(where: { $0.id == task.id }) {
                dependencies.append(task)
            }
            return
        }
        
        // Check for circular dependency
        if taskService.wouldCreateCircularDependency(task: existingTask, newDependency: task) {
            onValidationError?("Cannot add this dependency - it would create a circular reference")
            return
        }
        
        if !dependencies.contains(where: { $0.id == task.id }) {
            dependencies.append(task)
        }
    }
    
    func removeDependency(at index: Int) {
        guard index < dependencies.count else { return }
        dependencies.remove(at: index)
    }
    
    // Tags
    
    func addTag(_ tag: TagEntity) {
        if !selectedTags.contains(where: { $0.id == tag.id }) {
            selectedTags.append(tag)
        }
    }
    
    func removeTag(at index: Int) {
        guard index < selectedTags.count else { return }
        selectedTags.remove(at: index)
    }
    
    // Available Tasks for Dependencies
    
    func getAvailableTasksForDependency() -> [TaskEntity] {
        let allTasks = taskService.getActiveTasks()
        
        // Exclude current task and already selected dependencies
        return allTasks.filter { task in
            // Exclude self
            if let existingTask = existingTask, task.id == existingTask.id {
                return false
            }
            
            // Exclude already selected
            if dependencies.contains(where: { $0.id == task.id }) {
                return false
            }
            
            return true
        }
    }
}
