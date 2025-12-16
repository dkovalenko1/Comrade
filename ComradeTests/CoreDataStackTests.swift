import XCTest
import CoreData
@testable import Comrade

final class CoreDataStackTests: XCTestCase {
    
    var coreDataStack: CoreDataStack!
    
    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack(inMemory: true)
    }
    
    override func tearDown() {
        coreDataStack = nil
        super.tearDown()
    }
    
    func testPersistentContainerInitialization() {
        XCTAssertNotNil(coreDataStack.persistentContainer)
        XCTAssertEqual(coreDataStack.persistentContainer.persistentStoreDescriptions.first?.url?.path, "/dev/null")
    }
    
    func testContextInitialization() {
        XCTAssertNotNil(coreDataStack.context)
        XCTAssertEqual(coreDataStack.context.concurrencyType, .mainQueueConcurrencyType)
    }
    
    func testSaveContext() {
        let expectation = self.expectation(description: "Save context")
        
        coreDataStack.save { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
