import XCTest
import CoreData
@testable import Comrade

final class TagServiceTests: XCTestCase {
    
    var tagService: TagService!
    var coreDataStack: CoreDataStack!
    
    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack(inMemory: true)
        tagService = TagService(coreDataStack: coreDataStack)
    }
    
    override func tearDown() {
        tagService = nil
        coreDataStack = nil
        super.tearDown()
    }
    
    func testDefaultTagsCreation() {
        // Default tags are created on init
        let tags = tagService.fetchAllTags()
        XCTAssertFalse(tags.isEmpty)
    }
    
    func testCreateTag() {
        let name = "New Tag"
        let color = "#000000"
        
        let tag = tagService.createTag(name: name, colorHex: color)
        
        XCTAssertNotNil(tag)
        XCTAssertEqual(tag?.name, name)
        XCTAssertEqual(tag?.colorHex, color)
        
        let tags = tagService.fetchAllTags()
        XCTAssertTrue(tags.contains(where: { $0.name == name }))
    }
    
    func testFetchAllTags() {
        let initialCount = tagService.fetchAllTags().count
        
        tagService.createTag(name: "Tag 1", colorHex: "#111111")
        tagService.createTag(name: "Tag 2", colorHex: "#222222")
        
        let finalCount = tagService.fetchAllTags().count
        XCTAssertEqual(finalCount, initialCount + 2)
    }
}
