import XCTest
import CoreData
@testable import Comrade

final class AchievementsServiceTests: XCTestCase {

    var service: AchievementsService!

    override func setUp() {
        super.setUp()
        service = AchievementsService.shared
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    func testAllAchievements() {
        let achievements = service.all()
        XCTAssertGreaterThan(achievements.count, 0)
    }

    func testUnlockedAchievements() {
        let unlocked = service.unlocked()
        XCTAssertGreaterThanOrEqual(unlocked.count, 0)
    }

    func testResetAllAchievements() {
        let expectation = XCTestExpectation(description: "Reset completed")

        service.resetAllAchievements { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }
}
