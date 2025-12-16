import XCTest
@testable import Comrade

final class CategoryManagerViewModelTests: XCTestCase {

    var viewModel: CategoryManagerViewModel!

    override func setUp() {
        super.setUp()
        viewModel = CategoryManagerViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertGreaterThan(viewModel.categories.count, 0)
    }

    func testReload() {
        let initialCount = viewModel.categories.count
        viewModel.reload()
        XCTAssertEqual(viewModel.categories.count, initialCount)
    }

    func testCategoryAtIndex() {
        let category = viewModel.category(at: 0)
        XCTAssertNotNil(category)
        XCTAssertFalse(category?.name.isEmpty ?? true)
    }

    func testCategoryAtInvalidIndex() {
        let category = viewModel.category(at: 999)
        XCTAssertNil(category)
    }

    func testCanEditDefaultCategory() {
        viewModel.reload()

        if let firstCategory = viewModel.category(at: 0), firstCategory.isDefault {
            let canEdit = viewModel.canEditCategory(at: 0)
            XCTAssertFalse(canEdit, "Should not be able to edit default category")
        }
    }

    func testCreateCategory() {
        let initialCount = viewModel.categories.count

        viewModel.createCategory(name: "Test Category", colorHex: "#FF0000")

        viewModel.reload()
        XCTAssertEqual(viewModel.categories.count, initialCount + 1, "Should add new category")

        // Проверяем что категория создана с правильным именем
        let created = viewModel.categories.first { $0.name == "Test Category" }
        XCTAssertNotNil(created)
        XCTAssertEqual(created?.colorHex, "#FF0000")
        XCTAssertFalse(created?.isDefault ?? true)
    }

    func testCreateCategoryWithEmptyName() {
        let initialCount = viewModel.categories.count
        var errorReceived = false

        viewModel.onError = { message in
            errorReceived = true
            XCTAssertEqual(message, "Category name is required")
        }

        viewModel.createCategory(name: "   ", colorHex: "#FF0000")

        XCTAssertTrue(errorReceived, "Should receive error for empty name")
        XCTAssertEqual(viewModel.categories.count, initialCount, "Should not create category")
    }

    func testUpdateCategory() {
        viewModel.createCategory(name: "Original", colorHex: "#FF0000")
        viewModel.reload()

        guard let index = viewModel.categories.firstIndex(where: { $0.name == "Original" }) else {
            XCTFail("Category not created")
            return
        }

        viewModel.updateCategory(at: index, name: "Updated", colorHex: "#00FF00")
        viewModel.reload()

        let updated = viewModel.category(at: index)
        XCTAssertEqual(updated?.name, "Updated")
        XCTAssertEqual(updated?.colorHex, "#00FF00")
    }

    func testCannotUpdateDefaultCategory() {
        var errorReceived = false

        viewModel.onError = { message in
            errorReceived = true
            XCTAssertTrue(message.contains("Default categories"))
        }

        if let firstCategory = viewModel.category(at: 0), firstCategory.isDefault {
            viewModel.updateCategory(at: 0, name: "Try Update", colorHex: "#FF0000")
            XCTAssertTrue(errorReceived, "Should not allow updating default category")
        }
    }

    func testDeleteCategory() {
        viewModel.createCategory(name: "To Delete", colorHex: "#FF0000")
        viewModel.reload()

        let initialCount = viewModel.categories.count

        if let index = viewModel.categories.firstIndex(where: { $0.name == "To Delete" }) {
            viewModel.deleteCategory(at: index)
            viewModel.reload()

            XCTAssertEqual(viewModel.categories.count, initialCount - 1)
            XCTAssertNil(viewModel.categories.first { $0.name == "To Delete" })
        }
    }

    func testCannotDeleteDefaultCategory() {
        var errorReceived = false

        viewModel.onError = { message in
            errorReceived = true
            XCTAssertTrue(message.contains("Default categories"))
        }

        if let firstCategory = viewModel.category(at: 0), firstCategory.isDefault {
            let initialCount = viewModel.categories.count
            viewModel.deleteCategory(at: 0)

            XCTAssertTrue(errorReceived, "Should not allow deleting default category")
            XCTAssertEqual(viewModel.categories.count, initialCount, "Count should not change")
        }
    }
}
