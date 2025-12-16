import Foundation
import CoreData

// Enums

enum TaskPriority: Int16 {
    case low = 0
    case medium = 1
    case high = 2
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

enum TaskSortType {
    case createdAt
    case deadline
    case priority
    case name
}

enum TaskFilterStatus {
    case all
    case active
    case completed
}

// Notification Names

extension Notification.Name {
    static let taskCreated = Notification.Name("taskCreated")
    static let taskUpdated = Notification.Name("taskUpdated")
    static let taskDeleted = Notification.Name("taskDeleted")
    static let taskCompleted = Notification.Name("taskCompleted")
}

// TaskService

final class TaskService {
    
    // Singleton
    
    static let shared = TaskService()
    
    private let coreDataStack: CoreDataStack
    
    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }
    
    // CRUD Operations
    
    /// Creates a new task with the given parameters
    @discardableResult
    func createTask(
        name: String,
        taskDescription: String? = nil,
        category: String? = nil,
        categoryColorHex: String? = nil,
        priority: TaskPriority = .medium,
        deadline: Date? = nil,
        deadlineIsAllDay: Bool = true
    ) -> TaskEntity {
        let task = coreDataStack.create(TaskEntity.self)
        
        task.id = UUID()
        task.name = name
        task.taskDescription = taskDescription
        task.category = category
        task.categoryColorHex = categoryColorHex
        task.priority = priority.rawValue
        task.deadline = deadline
        task.deadlineIsAllDay = deadlineIsAllDay
        task.isCompleted = false
        task.createdAt = Date()
        
        coreDataStack.save { success in
            if success {
                NotificationCenter.default.post(
                    name: .taskCreated,
                    object: nil,
                    userInfo: ["task": task]
                )
                AchievementsService.shared.refreshAllAsync()
            }
        }
        
        return task
    }
    
    /// Updates an existing task
    func updateTask(_ task: TaskEntity) {
        coreDataStack.save { success in
            if success {
                NotificationCenter.default.post(
                    name: .taskUpdated,
                    object: nil,
                    userInfo: ["task": task]
                )
                AchievementsService.shared.refreshAllAsync()
            }
        }
    }
    
    /// Deletes a task by ID
    func deleteTask(id: UUID) {
        guard let task = getTask(id: id) else { return }
        
        // Remove all reminders associated with this task
        if let reminders = task.reminders as? Set<ReminderEntity> {
            reminders.forEach { coreDataStack.context.delete($0) }
        }
        
        coreDataStack.delete(task)
        
        NotificationCenter.default.post(
            name: .taskDeleted,
            object: nil,
            userInfo: ["taskId": id]
        )
        AchievementsService.shared.refreshAllAsync()
    }
    
    /// Deletes a task entity directly
    func deleteTask(_ task: TaskEntity) {
        guard let id = task.id else { return }
        deleteTask(id: id)
    }
    
    // Fetch Operations
    
    /// Gets a single task by ID
    func getTask(id: UUID) -> TaskEntity? {
        let predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return coreDataStack.fetchFirst(TaskEntity.self, predicate: predicate)
    }
    
    /// Gets all tasks
    func getAllTasks() -> [TaskEntity] {
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        return coreDataStack.fetch(TaskEntity.self, sortDescriptors: [sortDescriptor])
    }
    
    /// Gets active (not completed) tasks
    func getActiveTasks() -> [TaskEntity] {
        let predicate = NSPredicate(format: "isCompleted == NO")
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        return coreDataStack.fetch(TaskEntity.self, predicate: predicate, sortDescriptors: [sortDescriptor])
    }
    
    /// Gets completed tasks
    func getCompletedTasks() -> [TaskEntity] {
        let predicate = NSPredicate(format: "isCompleted == YES")
        let sortDescriptor = NSSortDescriptor(key: "completedAt", ascending: false)
        return coreDataStack.fetch(TaskEntity.self, predicate: predicate, sortDescriptors: [sortDescriptor])
    }
    
    /// Gets tasks by category
    func getTasksByCategory(_ category: String) -> [TaskEntity] {
        let predicate = NSPredicate(format: "category == %@", category)
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        return coreDataStack.fetch(TaskEntity.self, predicate: predicate, sortDescriptors: [sortDescriptor])
    }
    
    /// Gets tasks by priority
    func getTasksByPriority(_ priority: TaskPriority) -> [TaskEntity] {
        let predicate = NSPredicate(format: "priority == %d", priority.rawValue)
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        return coreDataStack.fetch(TaskEntity.self, predicate: predicate, sortDescriptors: [sortDescriptor])
    }
    
    /// Gets overdue tasks (deadline passed and not completed)
    func getOverdueTasks() -> [TaskEntity] {
        let predicate = NSPredicate(format: "isCompleted == NO AND deadline != nil AND deadline < %@", Date() as CVarArg)
        let sortDescriptor = NSSortDescriptor(key: "deadline", ascending: true)
        return coreDataStack.fetch(TaskEntity.self, predicate: predicate, sortDescriptors: [sortDescriptor])
    }
    
    /// Gets tasks due today
    func getTasksDueToday() -> [TaskEntity] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = NSPredicate(
            format: "isCompleted == NO AND deadline >= %@ AND deadline < %@",
            startOfDay as CVarArg,
            endOfDay as CVarArg
        )
        let sortDescriptor = NSSortDescriptor(key: "deadline", ascending: true)
        return coreDataStack.fetch(TaskEntity.self, predicate: predicate, sortDescriptors: [sortDescriptor])
    }
    
    /// Gets tasks due this week
    func getTasksDueThisWeek() -> [TaskEntity] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfDay)!
        
        let predicate = NSPredicate(
            format: "isCompleted == NO AND deadline >= %@ AND deadline < %@",
            startOfDay as CVarArg,
            endOfWeek as CVarArg
        )
        let sortDescriptor = NSSortDescriptor(key: "deadline", ascending: true)
        return coreDataStack.fetch(TaskEntity.self, predicate: predicate, sortDescriptors: [sortDescriptor])
    }
    
    // Completion
    
    /// Marks a task as completed
    /// Returns false if task has uncompleted dependencies
    @discardableResult
    func completeTask(id: UUID) -> Bool {
        guard let task = getTask(id: id) else { return false }
        
        // Check dependencies
        if !canComplete(task: task) {
            return false
        }
        
        task.isCompleted = true
        task.completedAt = Date()
        
        coreDataStack.save { success in
            if success {
                NotificationCenter.default.post(
                    name: .taskCompleted,
                    object: nil,
                    userInfo: ["task": task]
                )
                AchievementsService.shared.checkAfterTaskCompletion(task)
            }
        }
        
        return true
    }
    
    /// Marks a task as not completed (returns to active)
    func uncompleteTask(id: UUID) {
        guard let task = getTask(id: id) else { return }
        
        task.isCompleted = false
        task.completedAt = nil
        
        coreDataStack.save { success in
            if success {
                NotificationCenter.default.post(
                    name: .taskUpdated,
                    object: nil,
                    userInfo: ["task": task]
                )
                AchievementsService.shared.refreshAllAsync()
            }
        }
    }
    
    /// Toggles task completion status
    @discardableResult
    func toggleTaskCompletion(id: UUID) -> Bool {
        guard let task = getTask(id: id) else { return false }
        
        if task.isCompleted {
            uncompleteTask(id: id)
            return true
        } else {
            return completeTask(id: id)
        }
    }
    
    // Dependencies
    
    /// Checks if task can be completed (all dependencies are completed)
    func canComplete(task: TaskEntity) -> Bool {
        guard let dependencies = task.dependencies as? Set<TaskEntity> else {
            return true
        }
        
        return dependencies.allSatisfy { $0.isCompleted }
    }
    
    /// Gets uncompleted dependencies for a task
    func getUncompletedDependencies(for task: TaskEntity) -> [TaskEntity] {
        guard let dependencies = task.dependencies as? Set<TaskEntity> else {
            return []
        }
        
        return dependencies.filter { !$0.isCompleted }
    }
    
    /// Adds a dependency to a task
    /// Returns false if it would create a circular dependency
    @discardableResult
    func addDependency(to task: TaskEntity, dependency: TaskEntity) -> Bool {
        // Prevent self-dependency
        guard task.id != dependency.id else { return false }
        
        // Check for circular dependency
        if wouldCreateCircularDependency(task: task, newDependency: dependency) {
            return false
        }
        
        let mutableDependencies = task.mutableSetValue(forKey: "dependencies")
        mutableDependencies.add(dependency)
        
        coreDataStack.save()
        return true
    }
    
    /// Removes a dependency from a task
    func removeDependency(from task: TaskEntity, dependency: TaskEntity) {
        let mutableDependencies = task.mutableSetValue(forKey: "dependencies")
        mutableDependencies.remove(dependency)
        
        coreDataStack.save()
    }
    
    /// Checks if adding a dependency would create a circular reference
    func wouldCreateCircularDependency(task: TaskEntity, newDependency: TaskEntity) -> Bool {
        // If the new dependency depends on the current task (directly or indirectly),
        // adding it would create a cycle
        return isDependentOn(task: newDependency, target: task, visited: Set<UUID>())
    }
    
    /// Recursively checks if a task depends on a target task
    private func isDependentOn(task: TaskEntity, target: TaskEntity, visited: Set<UUID>) -> Bool {
        guard let taskId = task.id, let targetId = target.id else { return false }
        
        if taskId == targetId {
            return true
        }
        
        var visited = visited
        visited.insert(taskId)
        
        guard let dependencies = task.dependencies as? Set<TaskEntity> else {
            return false
        }
        
        for dependency in dependencies {
            guard let depId = dependency.id, !visited.contains(depId) else { continue }
            
            if isDependentOn(task: dependency, target: target, visited: visited) {
                return true
            }
        }
        
        return false
    }
    
    /// Gets the full dependency chain for a task
    func getDependencyChain(for task: TaskEntity) -> [TaskEntity] {
        var chain: [TaskEntity] = []
        var visited = Set<UUID>()
        
        collectDependencies(task: task, chain: &chain, visited: &visited)
        
        return chain
    }
    
    private func collectDependencies(task: TaskEntity, chain: inout [TaskEntity], visited: inout Set<UUID>) {
        guard let taskId = task.id, !visited.contains(taskId) else { return }
        
        visited.insert(taskId)
        
        guard let dependencies = task.dependencies as? Set<TaskEntity> else { return }
        
        for dependency in dependencies {
            chain.append(dependency)
            collectDependencies(task: dependency, chain: &chain, visited: &visited)
        }
    }
    
    // Tags
    
    /// Adds a tag to a task
    func addTag(_ tag: TagEntity, to task: TaskEntity) {
        let mutableTags = task.mutableSetValue(forKey: "tags")
        mutableTags.add(tag)
        coreDataStack.save()
    }
    
    /// Removes a tag from a task
    func removeTag(_ tag: TagEntity, from task: TaskEntity) {
        let mutableTags = task.mutableSetValue(forKey: "tags")
        mutableTags.remove(tag)
        coreDataStack.save()
    }
    
    /// Gets all tasks with a specific tag
    func getTasksWithTag(_ tag: TagEntity) -> [TaskEntity] {
        guard let tasks = tag.tasks as? Set<TaskEntity> else {
            return []
        }
        return Array(tasks)
    }
    
    // Reminders
    
    /// Adds a reminder to a task
    @discardableResult
    func addReminder(
        to task: TaskEntity,
        isRelative: Bool,
        absoluteDate: Date? = nil,
        relativeMinutes: Int32 = 0
    ) -> ReminderEntity {
        let reminder = coreDataStack.create(ReminderEntity.self)
        
        reminder.id = UUID()
        reminder.isRelative = isRelative
        reminder.absoluteDate = absoluteDate
        reminder.relativeMinutes = relativeMinutes
        reminder.task = task
        
        coreDataStack.save()
        
        return reminder
    }
    
    /// Removes a reminder
    func removeReminder(_ reminder: ReminderEntity) {
        coreDataStack.delete(reminder)
    }
    
    /// Gets all reminders for a task
    func getReminders(for task: TaskEntity) -> [ReminderEntity] {
        guard let reminders = task.reminders as? Set<ReminderEntity> else {
            return []
        }
        return Array(reminders).sorted { ($0.absoluteDate ?? Date.distantFuture) < ($1.absoluteDate ?? Date.distantFuture) }
    }
    
    // Sorting & Filtering
    
    /// Sorts tasks by the specified criteria
    func sortTasks(_ tasks: [TaskEntity], by sortType: TaskSortType, ascending: Bool = true) -> [TaskEntity] {
        switch sortType {
        case .createdAt:
            return tasks.sorted {
                let date1 = $0.createdAt ?? Date.distantPast
                let date2 = $1.createdAt ?? Date.distantPast
                return ascending ? date1 < date2 : date1 > date2
            }
        case .deadline:
            return tasks.sorted {
                let date1 = $0.deadline ?? Date.distantFuture
                let date2 = $1.deadline ?? Date.distantFuture
                return ascending ? date1 < date2 : date1 > date2
            }
        case .priority:
            return tasks.sorted {
                return ascending ? $0.priority < $1.priority : $0.priority > $1.priority
            }
        case .name:
            return tasks.sorted {
                let name1 = $0.name ?? ""
                let name2 = $1.name ?? ""
                return ascending ? name1 < name2 : name1 > name2
            }
        }
    }
    
    /// Filters tasks by status, category, and priority
    func filterTasks(
        _ tasks: [TaskEntity],
        status: TaskFilterStatus = .all,
        category: String? = nil,
        priority: TaskPriority? = nil
    ) -> [TaskEntity] {
        var filtered = tasks
        
        // Filter by status
        switch status {
        case .all:
            break
        case .active:
            filtered = filtered.filter { !$0.isCompleted }
        case .completed:
            filtered = filtered.filter { $0.isCompleted }
        }
        
        // Filter by category
        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filter by priority
        if let priority = priority {
            filtered = filtered.filter { $0.priority == priority.rawValue }
        }
        
        return filtered
    }
    
    /// Searches tasks by name or description
    func searchTasks(_ query: String) -> [TaskEntity] {
        guard !query.isEmpty else { return getAllTasks() }
        
        let predicate = NSPredicate(
            format: "name CONTAINS[cd] %@ OR taskDescription CONTAINS[cd] %@",
            query, query
        )
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        return coreDataStack.fetch(TaskEntity.self, predicate: predicate, sortDescriptors: [sortDescriptor])
    }
    
    // Statistics
    
    /// Gets total count of tasks
    func getTotalTaskCount() -> Int {
        return coreDataStack.count(TaskEntity.self)
    }
    
    /// Gets count of completed tasks
    func getCompletedTaskCount() -> Int {
        let predicate = NSPredicate(format: "isCompleted == YES")
        return coreDataStack.count(TaskEntity.self, predicate: predicate)
    }
    
    /// Gets count of active tasks
    func getActiveTaskCount() -> Int {
        let predicate = NSPredicate(format: "isCompleted == NO")
        return coreDataStack.count(TaskEntity.self, predicate: predicate)
    }
    
    /// Gets count of overdue tasks
    func getOverdueTaskCount() -> Int {
        let predicate = NSPredicate(format: "isCompleted == NO AND deadline != nil AND deadline < %@", Date() as CVarArg)
        return coreDataStack.count(TaskEntity.self, predicate: predicate)
    }
}
