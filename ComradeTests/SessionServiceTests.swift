import XCTest
import CoreData
@testable import Comrade

final class SessionServiceTests: XCTestCase {

    var coreDataStack: CoreDataStack!

    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack(inMemory: true)
    }

    override func tearDown() {
        coreDataStack = nil
        super.tearDown()
    }


    func testStartSession() {
        let service = SessionService.shared
        let duration: TimeInterval = 25 * 60

        service.startSession(duration: duration, mode: .casual)

        XCTAssertNotNil(service.getCurrentSession())
    }

    func testCompleteSession() {
        let service = SessionService.shared
        service.startSession(duration: 1, mode: .casual)

        let session = service.getCurrentSession()
        XCTAssertNotNil(session)

        service.completeSession()

        XCTAssertNil(service.getCurrentSession())
    }

    func testGetTotalFocusTime() {
        let service = SessionService.shared
        let focusTime = service.getTotalFocusTime(days: 7)
        XCTAssertGreaterThanOrEqual(focusTime, 0)
    }
}
