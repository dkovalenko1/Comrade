import Foundation

final class CategoryManagerViewModel {
    
    // Properties
    
    private let categoryService: CategoryService
    private(set) var categories: [Category]
    
    // Outputs
    
    var onCategoriesUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    
    // Init
    
    init(categoryService: CategoryService = .shared) {
        self.categoryService = categoryService
        self.categories = categoryService.categories
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCategoriesUpdated),
            name: .categoriesUpdated,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Data
    
    func reload() {
        categories = categoryService.categories
        onCategoriesUpdated?()
    }
    
    func category(at index: Int) -> Category? {
        guard index < categories.count else { return nil }
        return categories[index]
    }
    
    func canEditCategory(at index: Int) -> Bool {
        guard let category = category(at: index) else { return false }
        return !category.isDefault
    }
    
    // CRUD
    
    func createCategory(name: String, colorHex: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            onError?("Category name is required")
            return
        }
        
        categoryService.createCategory(name: trimmed, colorHex: colorHex)
        reload()
    }
    
    func updateCategory(at index: Int, name: String, colorHex: String) {
        guard let category = category(at: index) else { return }
        
        if category.isDefault {
            onError?("Default categories cannot be edited.")
            return
        }
        
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            onError?("Category name is required")
            return
        }
        
        categoryService.updateCategory(category, name: trimmed, colorHex: colorHex)
        reload()
    }
    
    func deleteCategory(at index: Int) {
        guard let category = category(at: index) else { return }
        
        if category.isDefault {
            onError?("Default categories cannot be deleted.")
            return
        }
        
        categoryService.deleteCategory(category)
        reload()
    }
    
    func resetToDefaults() {
        categoryService.resetToDefaults()
        reload()
    }
    
    func moveCategory(from sourceIndex: Int, to destinationIndex: Int) {
        categoryService.moveCategory(from: sourceIndex, to: destinationIndex)
        reload()
    }
    
    // Notification
    
    @objc private func handleCategoriesUpdated() {
        reload()
    }
}
