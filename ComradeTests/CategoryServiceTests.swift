import XCTest
@testable import Comrade

final class CategoryServiceTests: XCTestCase {
    
    var categoryService: CategoryService!
    var coreDataStack: CoreDataStack!
    
    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack(inMemory: true)
        categoryService = CategoryService(coreDataStack: coreDataStack)
    }
    
    override func tearDown() {
        coreDataStack = nil
        categoryService = nil
        super.tearDown()
    }
    
    func testDefaultCategoriesLoading() {
        XCTAssertFalse(categoryService.categories.isEmpty)
        XCTAssertTrue(categoryService.categories.contains(where: { $0.name == "Personal" }))
    }
    
    func testAddCategory() {
        let initialCount = categoryService.categories.count
        let name = "New Category"
        let color = "#123456"
        
        categoryService.createCategory(name: name, colorHex: color)
        
        XCTAssertEqual(categoryService.categories.count, initialCount + 1)
        XCTAssertTrue(categoryService.categories.contains(where: { $0.name == name && $0.colorHex == color }))
    }
    
    func testUpdateCategory() {
        let name = "Category to Update"
        categoryService.createCategory(name: name, colorHex: "#000000")
        
        guard let category = categoryService.categories.first(where: { $0.name == name }) else {
            XCTFail("Category not found")
            return
        }
        
        let newName = "Updated Category"
        categoryService.updateCategory(category, name: newName, colorHex: "#FFFFFF")
        
        XCTAssertTrue(categoryService.categories.contains(where: { $0.name == newName }))
        XCTAssertFalse(categoryService.categories.contains(where: { $0.name == name }))
    }
    
    func testDeleteCategory() {
        let name = "Category to Delete"
        categoryService.createCategory(name: name, colorHex: "#000000")
        
        guard let category = categoryService.categories.first(where: { $0.name == name }) else {
            XCTFail("Category not found")
            return
        }
        
        categoryService.deleteCategory(category)
        
        XCTAssertFalse(categoryService.categories.contains(where: { $0.id == category.id }))
    }
}
