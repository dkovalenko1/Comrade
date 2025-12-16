import XCTest
import CoreData
@testable import Comrade

final class SocialCreditServiceTests: XCTestCase {

    var service: SocialCreditService!

    override func setUp() {
        super.setUp()
        service = SocialCreditService.shared
        service.resetToBaseline()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    func testCurrentCredit() {
        let credit = service.current
        XCTAssertGreaterThanOrEqual(credit.currentScore, 0)
        XCTAssertNotNil(credit.id)
    }

    func testAddPoints() {
        let initialScore = service.current.currentScore
        let initialEarned = service.current.totalEarned

        service.addPoints(50, reason: "Test")

        let credit = service.current
        XCTAssertEqual(credit.currentScore, initialScore + 50)
        XCTAssertEqual(credit.totalEarned, initialEarned + 50)
        XCTAssertEqual(credit.totalLost, 0, "Total lost should not change")
    }

    func testRemovePoints() {
        service.resetToBaseline()
        let initialScore = service.current.currentScore
        let initialLost = service.current.totalLost

        service.removePoints(20, reason: "Penalty")

        let credit = service.current
        XCTAssertEqual(credit.currentScore, initialScore - 20)
        XCTAssertEqual(credit.totalLost, initialLost + 20)
    }

    func testScoreCannotGoNegative() {
        service.resetToBaseline()
        service.removePoints(200, reason: "Large penalty")

        let credit = service.current
        XCTAssertEqual(credit.currentScore, 0, "Score should not go below 0")
        XCTAssertGreaterThanOrEqual(credit.totalLost, 0)
    }

    func testTierProgression() {
        service.resetToBaseline()

        XCTAssertEqual(service.getCurrentTier(), .bronze)

        service.addPoints(110, reason: "Progress to Silver")
        XCTAssertEqual(service.getCurrentTier(), .silver)

        service.addPoints(300, reason: "Progress to Gold")
        XCTAssertEqual(service.getCurrentTier(), .gold)

        service.addPoints(500, reason: "Progress to Platinum")
        XCTAssertEqual(service.getCurrentTier(), .platinum)
    }

    func testTierDowngrade() {
        service.resetToBaseline()
        service.addPoints(400, reason: "Reach Gold")

        XCTAssertEqual(service.getCurrentTier(), .gold)

        service.removePoints(150, reason: "Downgrade")

        let tier = service.getCurrentTier()
        XCTAssertEqual(tier, .silver, "Should downgrade to Silver")
    }

    func testResetToBaseline() {
        service.addPoints(500, reason: "Setup")
        service.removePoints(50, reason: "Setup")

        service.resetToBaseline()

        let credit = service.current
        XCTAssertEqual(credit.currentScore, 100)
        XCTAssertEqual(credit.totalEarned, 100)
        XCTAssertEqual(credit.totalLost, 0)
        XCTAssertEqual(credit.tier, .bronze)
    }

    func testMultipleOperations() {
        service.resetToBaseline()

        service.addPoints(50, reason: "Op1")
        service.addPoints(30, reason: "Op2")
        service.removePoints(20, reason: "Op3")
        service.addPoints(40, reason: "Op4")

        let credit = service.current
        XCTAssertEqual(credit.currentScore, 100 + 50 + 30 - 20 + 40)
        XCTAssertEqual(credit.totalEarned, 100 + 50 + 30 + 40)
        XCTAssertEqual(credit.totalLost, 20)
    }
}
