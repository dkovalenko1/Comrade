import XCTest
import CoreData
@testable import Comrade

final class TagsPickerViewModelTests: XCTestCase {

    var viewModel: TagsPickerViewModel!
    var tagService: TagService!
    var coreDataStack: CoreDataStack!

    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack(inMemory: true)
        tagService = TagService(coreDataStack: coreDataStack)
        viewModel = TagsPickerViewModel(tagService: tagService)
    }

    override func tearDown() {
        viewModel = nil
        tagService = nil
        coreDataStack = nil
        super.tearDown()
    }

    func testInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertGreaterThanOrEqual(viewModel.allTags.count, 0)
        XCTAssertEqual(viewModel.selectedTags.count, 0)
    }

    func testTagAtIndex() {
        tagService.createTag(name: "Test Tag", colorHex: "#FF0000")
        viewModel.loadTags()

        if viewModel.allTags.count > 0 {
            let tag = viewModel.tag(at: 0)
            XCTAssertNotNil(tag)
            XCTAssertFalse(tag?.name?.isEmpty ?? true)
        }
    }

    func testTagAtInvalidIndex() {
        let tag = viewModel.tag(at: 999)
        XCTAssertNil(tag)
    }

    func testSelectAndDeselectTag() {
        let tag = tagService.createTag(name: "Selectable", colorHex: "#FF0000")!
        viewModel.loadTags()

        let index = viewModel.allTags.firstIndex(of: tag)!

        viewModel.selectTag(at: index)
        XCTAssertTrue(viewModel.isTagSelected(tag))
        XCTAssertEqual(viewModel.selectedTags.count, 1)

        viewModel.deselectTag(at: index)
        XCTAssertFalse(viewModel.isTagSelected(tag))
        XCTAssertEqual(viewModel.selectedTags.count, 0)
    }

    func testSelectMultipleTags() {
        let tag1 = tagService.createTag(name: "Tag1", colorHex: "#FF0000")!
        let tag2 = tagService.createTag(name: "Tag2", colorHex: "#00FF00")!
        viewModel.loadTags()

        let index1 = viewModel.allTags.firstIndex(of: tag1)!
        let index2 = viewModel.allTags.firstIndex(of: tag2)!

        viewModel.selectTag(at: index1)
        viewModel.selectTag(at: index2)

        XCTAssertEqual(viewModel.selectedTags.count, 2)
        XCTAssertTrue(viewModel.isTagSelected(tag1))
        XCTAssertTrue(viewModel.isTagSelected(tag2))
    }

    func testCreateTag() {
        let initialCount = viewModel.allTags.count

        viewModel.createTag(named: "New Tag")

        viewModel.loadTags()
        XCTAssertEqual(viewModel.allTags.count, initialCount + 1)

        let newTag = viewModel.allTags.first { $0.name == "New Tag" }
        XCTAssertNotNil(newTag)
        XCTAssertTrue(viewModel.isTagSelected(newTag!))
    }

    func testCreateTagWithEmptyName() {
        let initialCount = viewModel.allTags.count
        var errorReceived = false

        viewModel.onError = { message in
            errorReceived = true
            XCTAssertEqual(message, "Tag name is required")
        }

        viewModel.createTag(named: "   ")

        XCTAssertTrue(errorReceived, "Should receive error")
        XCTAssertEqual(viewModel.allTags.count, initialCount)
    }


    func testDeleteTag() {
        let tag = tagService.createTag(name: "To Delete", colorHex: "#FF0000")!
        viewModel.loadTags()

        let initialCount = viewModel.allTags.count
        let index = viewModel.allTags.firstIndex(of: tag)!

        viewModel.selectTag(at: index)
        XCTAssertTrue(viewModel.isTagSelected(tag))

        viewModel.deleteTag(at: index)
        viewModel.loadTags()

        XCTAssertEqual(viewModel.allTags.count, initialCount - 1)
        XCTAssertFalse(viewModel.isTagSelected(tag), "Should deselect deleted tag")
    }

    func testSelectedTagsArray() {
        let tag1 = tagService.createTag(name: "Tag1", colorHex: "#FF0000")!
        let tag2 = tagService.createTag(name: "Tag2", colorHex: "#00FF00")!
        viewModel.loadTags()

        let index1 = viewModel.allTags.firstIndex(of: tag1)!
        let index2 = viewModel.allTags.firstIndex(of: tag2)!

        viewModel.selectTag(at: index1)
        viewModel.selectTag(at: index2)

        let selectedArray = viewModel.selectedTagsArray
        XCTAssertEqual(selectedArray.count, 2)
        XCTAssertTrue(selectedArray.contains(tag1))
        XCTAssertTrue(selectedArray.contains(tag2))
    }
}
