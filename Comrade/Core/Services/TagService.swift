import Foundation
import CoreData

final class TagService {
    
    // Singleton
    
    static let shared = TagService()
    
    // Properties
    
    private let coreDataStack = CoreDataStack.shared
    
    // Default Tags
    
    private let defaultTags: [(name: String, colorHex: String)] = [
        ("Urgent", "#FF6B6B"),
        ("Important", "#4ECDC4"),
        ("Meeting", "#45B7D1"),
        ("Review", "#96CEB4"),
        ("Bug", "#FF8C42"),
        ("Feature", "#6C5CE7"),
        ("Personal", "#FDA7DF"),
        ("Research", "#A8E6CF")
    ]
    
    // Init
    
    private init() {
        createDefaultTagsIfNeeded()
    }
    
    // CRUD Operations
    
    /// Fetch all tags
    func fetchAllTags() -> [TagEntity] {
        let request: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            return try coreDataStack.context.fetch(request)
        } catch {
            print("Error fetching tags: \(error)")
            return []
        }
    }
    
    /// Create a new tag
    @discardableResult
    func createTag(name: String, colorHex: String) -> TagEntity? {
        // Check if tag with same name exists
        if tagExists(name: name) {
            print("Tag with name '\(name)' already exists")
            return nil
        }
        
        let tag = TagEntity(context: coreDataStack.context)
        tag.id = UUID()
        tag.name = name
        tag.colorHex = colorHex
        
        coreDataStack.save()
        
        NotificationCenter.default.post(name: .tagCreated, object: tag)
        
        return tag
    }
    
    /// Update existing tag
    func updateTag(_ tag: TagEntity, name: String? = nil, colorHex: String? = nil) {
        if let name = name {
            tag.name = name
        }
        if let colorHex = colorHex {
            tag.colorHex = colorHex
        }
        
        coreDataStack.save()
        
        NotificationCenter.default.post(name: .tagUpdated, object: tag)
    }
    
    /// Delete tag
    func deleteTag(_ tag: TagEntity) {
        coreDataStack.context.delete(tag)
        coreDataStack.save()
        
        NotificationCenter.default.post(name: .tagDeleted, object: nil)
    }
    
    /// Find tag by ID
    func findTag(by id: UUID) -> TagEntity? {
        let request: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            return try coreDataStack.context.fetch(request).first
        } catch {
            print("Error finding tag: \(error)")
            return nil
        }
    }
    
    /// Find tag by name
    func findTag(byName name: String) -> TagEntity? {
        let request: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        request.predicate = NSPredicate(format: "name ==[c] %@", name)
        request.fetchLimit = 1
        
        do {
            return try coreDataStack.context.fetch(request).first
        } catch {
            print("Error finding tag: \(error)")
            return nil
        }
    }
    
    /// Check if tag exists
    func tagExists(name: String) -> Bool {
        return findTag(byName: name) != nil
    }
    
    // Task-Tag Operations
    
    /// Add tag to task
    func addTag(_ tag: TagEntity, to task: TaskEntity) {
        task.addToTags(tag)
        coreDataStack.save()
    }
    
    /// Remove tag from task
    func removeTag(_ tag: TagEntity, from task: TaskEntity) {
        task.removeFromTags(tag)
        coreDataStack.save()
    }
    
    /// Set tags for task (replaces existing)
    func setTags(_ tags: [TagEntity], for task: TaskEntity) {
        // Remove all existing tags
        if let existingTags = task.tags as? Set<TagEntity> {
            for tag in existingTags {
                task.removeFromTags(tag)
            }
        }
        
        // Add new tags
        for tag in tags {
            task.addToTags(tag)
        }
        
        coreDataStack.save()
    }
    
    /// Get tags for task
    func getTags(for task: TaskEntity) -> [TagEntity] {
        guard let tags = task.tags as? Set<TagEntity> else {
            return []
        }
        return Array(tags).sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    
    /// Get tasks with specific tag
    func getTasks(with tag: TagEntity) -> [TaskEntity] {
        guard let tasks = tag.tasks as? Set<TaskEntity> else {
            return []
        }
        return Array(tasks)
    }
    
    // Helpers
    
    /// Create default tags if none exist
    private func createDefaultTagsIfNeeded() {
        let existingTags = fetchAllTags()
        
        if existingTags.isEmpty {
            for tagData in defaultTags {
                let tag = TagEntity(context: coreDataStack.context)
                tag.id = UUID()
                tag.name = tagData.name
                tag.colorHex = tagData.colorHex
            }
            coreDataStack.save()
        }
    }
    
    /// Get random color hex for new tag
    func randomColorHex() -> String {
        let colors = [
            "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4",
            "#FF8C42", "#6C5CE7", "#FDA7DF", "#A8E6CF",
            "#FFE66D", "#95E1D3", "#F38181", "#AA96DA"
        ]
        return colors.randomElement() ?? "#FF6B6B"
    }
}

// Notification Names

extension Notification.Name {
    static let tagCreated = Notification.Name("tagCreated")
    static let tagUpdated = Notification.Name("tagUpdated")
    static let tagDeleted = Notification.Name("tagDeleted")
}
