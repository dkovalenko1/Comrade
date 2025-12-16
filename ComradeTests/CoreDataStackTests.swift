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

    func testPerformBackgroundSavesAndMerges() {
        let saveExpectation = expectation(description: "Background save merges to main")

        let notificationToken = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: .main
        ) { notification in
            guard
                let userInfo = notification.userInfo,
                let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>,
                inserts.contains(where: { $0 is SocialCreditEntity })
            else { return }
            saveExpectation.fulfill()
        }

        coreDataStack.performBackground { context in
            let entity = SocialCreditEntity(context: context)
            entity.id = UUID()
            entity.currentScore = 200
            entity.totalEarned = 200
            entity.totalLost = 0
            entity.tier = SocialCreditTier.bronze.rawValue
            entity.lastUpdate = Date()
        }

        waitForExpectations(timeout: 2.0, handler: nil)
        NotificationCenter.default.removeObserver(notificationToken)

        let mergedCountExpectation = expectation(description: "Main context sees inserted entity")
        coreDataStack.context.perform {
            let merged = self.coreDataStack.count(SocialCreditEntity.self)
            if merged == 1 {
                mergedCountExpectation.fulfill()
            }
        }
        waitForExpectations(timeout: 1.0, handler: nil)
    }
}
