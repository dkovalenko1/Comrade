import Foundation
import CoreData

// Category Model

struct Category: Codable, Equatable {
    let id: UUID
    var name: String
    var colorHex: String
    var isDefault: Bool
    
    init(id: UUID = UUID(), name: String, colorHex: String, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.isDefault = isDefault
    }
}

// CategoryService

final class CategoryService {
    
    // Singleton
    
    static let shared = CategoryService()
    
    // Properties
    
    private let coreDataStack: CoreDataStack
    private let legacyUserDefaultsKey = "com.comrade.categories"
    private(set) var categories: [Category] = []
    
    // Default Categories
    
    private let defaultCategories: [Category] = [
        Category(name: "Personal", colorHex: "#007AFF", isDefault: true),
        Category(name: "Work", colorHex: "#34C759", isDefault: true),
        Category(name: "Studies", colorHex: "#FF6B6B", isDefault: true)
    ]
    
    // Init
    
    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
        loadCategories()
    }
    
    // Persistence
    
    private func loadCategories() {
        refreshCategories()
        
        // First launch - seed defaults
        if categories.isEmpty {
            if !migrateLegacyCategories() {
                seedDefaultCategories()
            }
        }
    }
    
    private func refreshCategories() {
        let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        let sort = NSSortDescriptor(key: "sortOrder", ascending: true)
        request.sortDescriptors = [sort]
        
        do {
            let entities = try coreDataStack.context.fetch(request)
            categories = entities.map { Category(from: $0) }
        } catch {
            print("Failed to fetch categories: \(error)")
            categories = []
        }
    }
    
    private func seedDefaultCategories() {
        persist(categories: defaultCategories)
    }
    
    private func notifyUpdate() {
        NotificationCenter.default.post(name: .categoriesUpdated, object: nil)
    }
    
    private func saveContextAndRefresh() {
        coreDataStack.save()
        refreshCategories()
        notifyUpdate()
    }
    
    // CRUD Operations
    
    @discardableResult
    func createCategory(name: String, colorHex: String) -> Category {
        let entity = CategoryEntity(context: coreDataStack.context)
        entity.id = UUID()
        entity.name = name
        entity.colorHex = colorHex
        entity.isDefault = false
        entity.sortOrder = Int32(categories.count)
        
        saveContextAndRefresh()
        return categories.last ?? Category(name: name, colorHex: colorHex)
    }
    
    func updateCategory(_ category: Category, name: String, colorHex: String) {
        guard let entity = fetchCategoryEntity(by: category.id) else { return }
        
        entity.name = name
        entity.colorHex = colorHex
        
        saveContextAndRefresh()
    }
    
    func deleteCategory(_ category: Category) {
        // Don't delete default categories
        guard !category.isDefault, let entity = fetchCategoryEntity(by: category.id) else { return }
        
        coreDataStack.context.delete(entity)
        saveContextAndRefresh()
        updateSortOrder()
    }
    
    func deleteCategory(at index: Int) {
        guard index < categories.count else { return }
        deleteCategory(categories[index])
    }
    
    // Query
    
    func getCategory(byName name: String) -> Category? {
        return categories.first { $0.name.lowercased() == name.lowercased() }
    }
    
    func getCategory(byId id: UUID) -> Category? {
        return categories.first { $0.id == id }
    }
    
    func getCategoryColor(forName name: String) -> String {
        return getCategory(byName: name)?.colorHex ?? "#007AFF"
    }
    
    // Reset
    
    func resetToDefaults() {
        let request: NSFetchRequest<NSFetchRequestResult> = CategoryEntity.fetchRequest()
        let batchDelete = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try coreDataStack.context.execute(batchDelete)
        } catch {
            print("Failed to reset categories: \(error)")
        }
        
        seedDefaultCategories()
    }
    
    // Reorder
    
    func moveCategory(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex < categories.count, destinationIndex < categories.count else { return }
        
        let category = categories.remove(at: sourceIndex)
        categories.insert(category, at: destinationIndex)
        
        updateSortOrder()
        notifyUpdate()
    }
    
    private func updateSortOrder() {
        for (index, category) in categories.enumerated() {
            guard let entity = fetchCategoryEntity(by: category.id) else { continue }
            entity.sortOrder = Int32(index)
        }
        coreDataStack.save()
        refreshCategories()
    }
    
    // Helpers
    
    private func migrateLegacyCategories() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: legacyUserDefaultsKey),
              let legacyCategories = try? JSONDecoder().decode([Category].self, from: data),
              !legacyCategories.isEmpty else {
            return false
        }
        
        persist(categories: legacyCategories)
        UserDefaults.standard.removeObject(forKey: legacyUserDefaultsKey)
        return true
    }
    
    private func persist(categories: [Category]) {
        for (index, category) in categories.enumerated() {
            let entity = CategoryEntity(context: coreDataStack.context)
            entity.id = category.id
            entity.name = category.name
            entity.colorHex = category.colorHex
            entity.isDefault = category.isDefault
            entity.sortOrder = Int32(index)
        }
        
        coreDataStack.save()
        refreshCategories()
        notifyUpdate()
    }
    
    private func fetchCategoryEntity(by id: UUID) -> CategoryEntity? {
        let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            return try coreDataStack.context.fetch(request).first
        } catch {
            print("Failed to fetch category: \(error)")
            return nil
        }
    }
}

private extension Category {
    init(from entity: CategoryEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? "Untitled"
        self.colorHex = entity.colorHex ?? "#007AFF"
        self.isDefault = entity.isDefault
    }
}

// Notification Names

extension Notification.Name {
    static let categoriesUpdated = Notification.Name("categoriesUpdated")
}
