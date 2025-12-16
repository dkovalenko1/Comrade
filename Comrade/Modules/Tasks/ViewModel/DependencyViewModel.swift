import Foundation

// Dependency Node Model

struct DependencyNode {
    let task: TaskEntity
    let level: Int
    let isCompleted: Bool
    let isBlocking: Bool  // This task is blocking the main task
    
    var id: UUID? { task.id }
    var name: String { task.name ?? "Untitled" }
    var category: String? { task.category }
    var categoryColorHex: String? { task.categoryColorHex }
}

// DependencyViewModel

final class DependencyViewModel {
    
    // Properties
    
    private let taskService = TaskService.shared
    private let rootTask: TaskEntity
    private var pendingDependencies: [TaskEntity]  // Dependencies not yet saved to CoreData
    
    private(set) var dependencyNodes: [DependencyNode] = []
    private(set) var dependentNodes: [DependencyNode] = []  // Tasks that depend on this task
    
    // Output Closures
    
    var onDataUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    var onDependencyCompleted: ((TaskEntity) -> Void)?
    var onDependenciesChanged: (([TaskEntity]) -> Void)?  // Notify parent about changes
    
    // Computed Properties
    
    var rootTaskName: String {
        rootTask.name ?? "Untitled"
    }
    
    var rootTaskCategory: String? {
        rootTask.category
    }
    
    var rootTaskCategoryColorHex: String? {
        rootTask.categoryColorHex
    }
    
    var canCompleteRootTask: Bool {
        // Check both saved and pending dependencies
        let allDependencies = getAllDependencies()
        return allDependencies.allSatisfy { $0.isCompleted }
    }
    
    var totalDependencies: Int {
        dependencyNodes.count
    }
    
    var completedDependencies: Int {
        dependencyNodes.filter { $0.isCompleted }.count
    }
    
    var blockingDependencies: Int {
        dependencyNodes.filter { $0.isBlocking }.count
    }
    
    var hasDependencies: Bool {
        !dependencyNodes.isEmpty
    }
    
    var hasDependents: Bool {
        !dependentNodes.isEmpty
    }
    
    /// Get current list of dependencies (for syncing back to parent)
    var currentDependencies: [TaskEntity] {
        // Return direct dependencies (level 1) only
        return dependencyNodes.filter { $0.level == 1 }.map { $0.task }
    }
    
    // Init
    
    init(task: TaskEntity, pendingDependencies: [TaskEntity] = []) {
        self.rootTask = task
        self.pendingDependencies = pendingDependencies
        loadDependencies()
    }
    
    // Helper
    
    private func getAllDependencies() -> [TaskEntity] {
        // Combine saved dependencies from CoreData with pending ones
        var allDeps = Set<UUID>()
        var result: [TaskEntity] = []
        
        // Add saved dependencies
        if let savedDeps = rootTask.dependencies as? Set<TaskEntity> {
            for dep in savedDeps {
                if let id = dep.id, !allDeps.contains(id) {
                    allDeps.insert(id)
                    result.append(dep)
                }
            }
        }
        
        // Add pending dependencies
        for dep in pendingDependencies {
            if let id = dep.id, !allDeps.contains(id) {
                allDeps.insert(id)
                result.append(dep)
            }
        }
        
        return result
    }
    
    // Data Loading
    
    func loadDependencies() {
        loadDirectDependencies()
        loadDependentTasks()
        onDataUpdated?()
    }
    
    private func loadDirectDependencies() {
        dependencyNodes = []
        
        let allDependencies = getAllDependencies()
        guard !allDependencies.isEmpty else { return }
        
        // Build dependency tree with levels
        var visited = Set<UUID>()
        buildDependencyTree(from: allDependencies, level: 1, visited: &visited)
        
        // Sort by level, then by completion status
        dependencyNodes.sort { node1, node2 in
            if node1.level != node2.level {
                return node1.level < node2.level
            }
            // Incomplete tasks first within same level
            if node1.isCompleted != node2.isCompleted {
                return !node1.isCompleted
            }
            return node1.name < node2.name
        }
    }
    
    private func buildDependencyTree(from tasks: [TaskEntity], level: Int, visited: inout Set<UUID>) {
        for task in tasks {
            guard let taskId = task.id, !visited.contains(taskId) else { continue }
            visited.insert(taskId)
            
            let isBlocking = !task.isCompleted
            let node = DependencyNode(
                task: task,
                level: level,
                isCompleted: task.isCompleted,
                isBlocking: isBlocking
            )
            dependencyNodes.append(node)
            
            // Recursively add sub-dependencies
            if let subDependencies = task.dependencies as? Set<TaskEntity>, !subDependencies.isEmpty {
                buildDependencyTree(from: Array(subDependencies), level: level + 1, visited: &visited)
            }
        }
    }
    
    private func loadDependentTasks() {
        dependentNodes = []
        
        guard let dependentOn = rootTask.dependentOn as? Set<TaskEntity> else {
            return
        }
        
        for task in dependentOn {
            let node = DependencyNode(
                task: task,
                level: 1,
                isCompleted: task.isCompleted,
                isBlocking: false
            )
            dependentNodes.append(node)
        }
        
        // Sort by name
        dependentNodes.sort { $0.name < $1.name }
    }
    
    // Actions
    
    /// Complete a dependency task
    func completeDependency(at index: Int) {
        guard index < dependencyNodes.count else { return }
        
        let node = dependencyNodes[index]
        guard !node.isCompleted else { return }
        
        // Check if this dependency can be completed (has its own dependencies completed)
        if !taskService.canComplete(task: node.task) {
            let blockers = taskService.getUncompletedDependencies(for: node.task)
            let blockerNames = blockers.compactMap { $0.name }.joined(separator: ", ")
            onError?("Cannot complete '\(node.name)'. It depends on: \(blockerNames)")
            return
        }
        
        guard let taskId = node.task.id else { return }
        
        if taskService.completeTask(id: taskId) {
            onDependencyCompleted?(node.task)
            loadDependencies()
        } else {
            onError?("Failed to complete task")
        }
    }
    
    /// Remove a dependency from root task
    func removeDependency(at index: Int) {
        guard index < dependencyNodes.count else { return }
        
        let node = dependencyNodes[index]
        
        // Only remove direct dependencies (level 1)
        guard node.level == 1 else {
            onError?("Can only remove direct dependencies")
            return
        }
        
        guard let taskId = node.task.id else { return }
        
        // Check if it's a pending dependency
        if let pendingIndex = pendingDependencies.firstIndex(where: { $0.id == taskId }) {
            pendingDependencies.remove(at: pendingIndex)
        } else {
            // It's a saved dependency - remove from CoreData
            taskService.removeDependency(from: rootTask, dependency: node.task)
        }
        
        loadDependencies()
        
        // Notify parent about changes
        onDependenciesChanged?(currentDependencies)
    }
    
    /// Add a new dependency to root task
    func addDependency(_ task: TaskEntity) {
        // Prevent self-dependency
        guard task.id != rootTask.id else {
            onError?("A task cannot depend on itself")
            return
        }
        
        // Check for circular dependency
        if taskService.wouldCreateCircularDependency(task: rootTask, newDependency: task) {
            onError?("Cannot add this dependency - it would create a circular reference")
            return
        }
        
        // Check if already a dependency (saved or pending)
        let allDeps = getAllDependencies()
        if allDeps.contains(where: { $0.id == task.id }) {
            onError?("This task is already a dependency")
            return
        }
        
        // Add to pending dependencies
        pendingDependencies.append(task)
        loadDependencies()
        
        // Notify parent about changes
        onDependenciesChanged?(currentDependencies)
    }
    
    /// Get available tasks that can be added as dependencies
    func getAvailableTasksForDependency() -> [TaskEntity] {
        let allTasks = taskService.getActiveTasks()
        
        // Get current dependency IDs (both saved and pending)
        let allDeps = getAllDependencies()
        let currentDependencyIds = Set(allDeps.compactMap { $0.id })
        
        return allTasks.filter { task in
            // Exclude self
            guard task.id != rootTask.id else { return false }
            
            // Exclude already dependencies
            guard let taskId = task.id, !currentDependencyIds.contains(taskId) else { return false }
            
            // Exclude tasks that would create circular dependency
            if taskService.wouldCreateCircularDependency(task: rootTask, newDependency: task) {
                return false
            }
            
            return true
        }
    }
    
    // Section Data (for UI)
    
    var numberOfSections: Int {
        var count = 0
        if hasDependencies { count += 1 }
        if hasDependents { count += 1 }
        return max(count, 1)  // At least 1 section for empty state
    }
    
    func sectionTitle(for section: Int) -> String {
        if !hasDependencies && !hasDependents {
            return "No Dependencies"
        }
        
        if hasDependencies && section == 0 {
            return "Dependencies (\(completedDependencies)/\(totalDependencies))"
        }
        
        if hasDependents {
            return "Dependent Tasks (\(dependentNodes.count))"
        }
        
        return ""
    }
    
    func numberOfRows(in section: Int) -> Int {
        if !hasDependencies && !hasDependents {
            return 0
        }
        
        if hasDependencies && section == 0 {
            return dependencyNodes.count
        }
        
        if hasDependents {
            return dependentNodes.count
        }
        
        return 0
    }
    
    func node(at section: Int, row: Int) -> DependencyNode? {
        if hasDependencies && section == 0 {
            guard row < dependencyNodes.count else { return nil }
            return dependencyNodes[row]
        }
        
        if hasDependents {
            guard row < dependentNodes.count else { return nil }
            return dependentNodes[row]
        }
        
        return nil
    }
    
    func isDependencySection(_ section: Int) -> Bool {
        return hasDependencies && section == 0
    }
}
