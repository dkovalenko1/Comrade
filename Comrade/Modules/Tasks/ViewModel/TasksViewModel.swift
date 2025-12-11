//
//  TasksViewModel.swift
//  Comrade
//
//  Created by Savelii Kozlov on 11.12.2025.
//

import Foundation

// Section Type

enum TaskSection: Int, CaseIterable {
    case today = 0
    case personal
    case work
    case studies
    case completed
    
    var title: String {
        switch self {
        case .today: return "Today"
        case .personal: return "Personal"
        case .work: return "Work"
        case .studies: return "Studies"
        case .completed: return "Completed"
        }
    }
    
    var category: String? {
        switch self {
        case .today: return nil
        case .personal: return "Personal"
        case .work: return "Work"
        case .studies: return "Studies"
        case .completed: return nil
        }
    }
}

// TasksViewModel

final class TasksViewModel {
    
    // Properties
    
    private let taskService = TaskService.shared
    
    /// All tasks from database
    private var allTasks: [TaskEntity] = []
    
    /// Tasks grouped by section
    private(set) var sections: [TaskSection: [TaskEntity]] = [:]
    
    /// Expanded state for each section
    private(set) var expandedSections: Set<TaskSection> = [.today, .studies]
    
    /// Current sort type
    var sortType: TaskSortType = .createdAt
    
    /// Current search query
    var searchQuery: String = ""
    
    // Output Closures
    
    var onDataUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    var onTaskCompleted: ((TaskEntity) -> Void)?
    var onTaskCompletionFailed: ((TaskEntity, [TaskEntity]) -> Void)?
    
    // Init
    
    init() {
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Setup
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTaskCreated),
            name: .taskCreated,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTaskUpdated),
            name: .taskUpdated,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTaskDeleted),
            name: .taskDeleted,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTaskCompleted),
            name: .taskCompleted,
            object: nil
        )
    }
    
    // Notification Handlers
    
    @objc private func handleTaskCreated(_ notification: Notification) {
        loadTasks()
    }
    
    @objc private func handleTaskUpdated(_ notification: Notification) {
        loadTasks()
    }
    
    @objc private func handleTaskDeleted(_ notification: Notification) {
        loadTasks()
    }
    
    @objc private func handleTaskCompleted(_ notification: Notification) {
        if let task = notification.userInfo?["task"] as? TaskEntity {
            onTaskCompleted?(task)
        }
        loadTasks()
    }
    
    // Data Loading
    
    /// Loads all tasks and groups them by section
    func loadTasks() {
        if searchQuery.isEmpty {
            allTasks = taskService.getAllTasks()
        } else {
            allTasks = taskService.searchTasks(searchQuery)
        }
        
        groupTasksBySection()
        onDataUpdated?()
    }
    
    /// Groups tasks into sections
    private func groupTasksBySection() {
        // Reset sections
        sections = [:]
        for section in TaskSection.allCases {
            sections[section] = []
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        for task in allTasks {
            // Completed tasks go to completed section
            if task.isCompleted {
                sections[.completed]?.append(task)
                continue
            }
            
            // Check if task is due today
            if let deadline = task.deadline {
                let deadlineDay = calendar.startOfDay(for: deadline)
                if deadlineDay >= today && deadlineDay < tomorrow {
                    sections[.today]?.append(task)
                    continue
                }
            }
            
            // Group by category
            if let category = task.category {
                switch category.lowercased() {
                case "personal":
                    sections[.personal]?.append(task)
                case "work":
                    sections[.work]?.append(task)
                case "studies":
                    sections[.studies]?.append(task)
                default:
                    // Default to personal if unknown category
                    sections[.personal]?.append(task)
                }
            } else {
                // No category - put in personal
                sections[.personal]?.append(task)
            }
        }
        
        // Sort tasks within each section
        for section in TaskSection.allCases {
            sections[section] = sortTasks(sections[section] ?? [])
        }
    }
    
    /// Sorts tasks by current sort type
    private func sortTasks(_ tasks: [TaskEntity]) -> [TaskEntity] {
        return taskService.sortTasks(tasks, by: sortType, ascending: sortType != .priority)
    }
    
    // Section Management
    
    /// Returns tasks for a specific section
    func tasks(for section: TaskSection) -> [TaskEntity] {
        return sections[section] ?? []
    }
    
    /// Returns count of tasks in a section
    func taskCount(for section: TaskSection) -> Int {
        return sections[section]?.count ?? 0
    }
    
    /// Returns task at specific section and row
    func task(at section: Int, row: Int) -> TaskEntity? {
        guard let taskSection = TaskSection(rawValue: section) else { return nil }
        let tasks = self.tasks(for: taskSection)
        guard row < tasks.count else { return nil }
        return tasks[row]
    }
    
    /// Checks if section is expanded
    func isSectionExpanded(_ section: TaskSection) -> Bool {
        return expandedSections.contains(section)
    }
    
    /// Toggles section expanded state
    func toggleSection(_ section: TaskSection) {
        if expandedSections.contains(section) {
            expandedSections.remove(section)
        } else {
            expandedSections.insert(section)
        }
        onDataUpdated?()
    }
    
    /// Expands a section
    func expandSection(_ section: TaskSection) {
        expandedSections.insert(section)
        onDataUpdated?()
    }
    
    /// Collapses a section
    func collapseSection(_ section: TaskSection) {
        expandedSections.remove(section)
        onDataUpdated?()
    }
    
    /// Returns number of rows for a section (0 if collapsed)
    func numberOfRows(in section: TaskSection) -> Int {
        if isSectionExpanded(section) {
            return taskCount(for: section)
        }
        return 0
    }
    
    // Task Actions
    
    /// Toggles task completion status
    func toggleTaskCompletion(at section: Int, row: Int) {
        guard let task = task(at: section, row: row) else { return }
        
        if task.isCompleted {
            // Uncomplete task
            if let taskId = task.id {
                taskService.uncompleteTask(id: taskId)
            }
        } else {
            // Try to complete task
            guard let taskId = task.id else { return }
            
            let success = taskService.completeTask(id: taskId)
            
            if !success {
                // Task has uncompleted dependencies
                let blockers = taskService.getUncompletedDependencies(for: task)
                onTaskCompletionFailed?(task, blockers)
            }
        }
    }
    
    /// Deletes a task
    func deleteTask(at section: Int, row: Int) {
        guard let task = task(at: section, row: row),
              let taskId = task.id else { return }
        
        // Cancel notifications for this task
        NotificationService.shared.cancelReminders(for: taskId)
        
        taskService.deleteTask(id: taskId)
    }
    
    // Search
    
    /// Updates search query and reloads tasks
    func search(_ query: String) {
        searchQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        loadTasks()
    }
    
    /// Clears search and shows all tasks
    func clearSearch() {
        searchQuery = ""
        loadTasks()
    }
    
    // Sorting
    
    /// Changes sort type and reloads
    func sort(by type: TaskSortType) {
        sortType = type
        groupTasksBySection()
        onDataUpdated?()
    }
    
    // Statistics
    
    /// Returns total count of all tasks
    var totalTaskCount: Int {
        return allTasks.count
    }
    
    /// Returns count of active tasks
    var activeTaskCount: Int {
        return allTasks.filter { !$0.isCompleted }.count
    }
    
    /// Returns count of completed tasks
    var completedTaskCount: Int {
        return allTasks.filter { $0.isCompleted }.count
    }
    
    /// Returns count of overdue tasks
    var overdueTaskCount: Int {
        return taskService.getOverdueTaskCount()
    }
}

// - Section Header Data

extension TasksViewModel {
    
    /// Returns data for section header
    func headerData(for section: TaskSection) -> (title: String, count: Int, isExpanded: Bool) {
        return (
            title: section.title,
            count: taskCount(for: section),
            isExpanded: isSectionExpanded(section)
        )
    }
}
