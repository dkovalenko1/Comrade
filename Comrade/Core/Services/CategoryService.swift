import Foundation

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
    
    private let userDefaultsKey = "com.comrade.categories"
    private let userDefaults: UserDefaults
    
    private(set) var categories: [Category] = []
    
    // Default Categories
    
    private let defaultCategories: [Category] = [
        Category(name: "Personal", colorHex: "#007AFF", isDefault: true),
        Category(name: "Work", colorHex: "#34C759", isDefault: true),
        Category(name: "Studies", colorHex: "#FF6B6B", isDefault: true)
    ]
    
    // Init
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        loadCategories()
    }
    
    // Persistence
    
    private func loadCategories() {
        if let data = userDefaults.data(forKey: userDefaultsKey),
           let savedCategories = try? JSONDecoder().decode([Category].self, from: data) {
            categories = savedCategories
        } else {
            // First launch - use default categories
            categories = defaultCategories
            saveCategories()
        }
    }
    
    private func saveCategories() {
        if let data = try? JSONEncoder().encode(categories) {
            userDefaults.set(data, forKey: userDefaultsKey)
        }
        
        NotificationCenter.default.post(name: .categoriesUpdated, object: nil)
    }
    
    // CRUD Operations
    
    @discardableResult
    func createCategory(name: String, colorHex: String) -> Category {
        let category = Category(name: name, colorHex: colorHex, isDefault: false)
        categories.append(category)
        saveCategories()
        return category
    }
    
    func updateCategory(_ category: Category, name: String, colorHex: String) {
        guard let index = categories.firstIndex(where: { $0.id == category.id }) else { return }
        
        categories[index].name = name
        categories[index].colorHex = colorHex
        saveCategories()
    }
    
    func deleteCategory(_ category: Category) {
        // Don't delete default categories
        guard !category.isDefault else { return }
        
        categories.removeAll { $0.id == category.id }
        saveCategories()
    }
    
    func deleteCategory(at index: Int) {
        guard index < categories.count else { return }
        let category = categories[index]
        
        // Don't delete default categories
        guard !category.isDefault else { return }
        
        categories.remove(at: index)
        saveCategories()
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
        categories = defaultCategories
        saveCategories()
    }
    
    // Reorder
    
    func moveCategory(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex < categories.count, destinationIndex < categories.count else { return }
        
        let category = categories.remove(at: sourceIndex)
        categories.insert(category, at: destinationIndex)
        saveCategories()
    }
}

// Notification Names

extension Notification.Name {
    static let categoriesUpdated = Notification.Name("categoriesUpdated")
}
