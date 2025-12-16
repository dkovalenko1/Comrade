import XCTest
@testable import Comrade

final class SocialCreditTests: XCTestCase {

    func testSocialCreditInitialization() {
        let credit = SocialCredit()

        XCTAssertEqual(credit.currentScore, 100)
        XCTAssertEqual(credit.totalEarned, 100)
        XCTAssertEqual(credit.totalLost, 0)
        XCTAssertEqual(credit.tier, .bronze)
    }

    func testCustomInitialization() {
        let credit = SocialCredit(
            currentScore: 250,
            totalEarned: 300,
            totalLost: 50,
            tier: .silver
        )

        XCTAssertEqual(credit.currentScore, 250)
        XCTAssertEqual(credit.totalEarned, 300)
        XCTAssertEqual(credit.totalLost, 50)
        XCTAssertEqual(credit.tier, .silver)
    }

    func testTierForBronze() {
        let tier = SocialCredit.tier(for: 50)
        XCTAssertEqual(tier, .bronze)
    }

    func testTierForSilver() {
        let tier = SocialCredit.tier(for: 250)
        XCTAssertEqual(tier, .silver)
    }

    func testTierForGold() {
        let tier = SocialCredit.tier(for: 600)
        XCTAssertEqual(tier, .gold)
    }

    func testTierForPlatinum() {
        let tier = SocialCredit.tier(for: 950)
        XCTAssertEqual(tier, .platinum)
    }

    func testTierBoundaries() {
        XCTAssertEqual(SocialCredit.tier(for: 0), .bronze)
        XCTAssertEqual(SocialCredit.tier(for: 199), .bronze)
        XCTAssertEqual(SocialCredit.tier(for: 200), .silver)
        XCTAssertEqual(SocialCredit.tier(for: 499), .silver)
        XCTAssertEqual(SocialCredit.tier(for: 500), .gold)
        XCTAssertEqual(SocialCredit.tier(for: 899), .gold)
        XCTAssertEqual(SocialCredit.tier(for: 900), .platinum)
    }

    func testTierMinScores() {
        XCTAssertEqual(SocialCreditTier.bronze.minScore, 0)
        XCTAssertEqual(SocialCreditTier.silver.minScore, 200)
        XCTAssertEqual(SocialCreditTier.gold.minScore, 500)
        XCTAssertEqual(SocialCreditTier.platinum.minScore, 900)
    }

    func testTierDisplayNames() {
        XCTAssertEqual(SocialCreditTier.bronze.displayName, "Bronze")
        XCTAssertEqual(SocialCreditTier.silver.displayName, "Silver")
        XCTAssertEqual(SocialCreditTier.gold.displayName, "Gold")
        XCTAssertEqual(SocialCreditTier.platinum.displayName, "Platinum")
    }

    func testZeroScore() {
        let credit = SocialCredit(currentScore: 0)
        XCTAssertEqual(credit.currentScore, 0)
        XCTAssertEqual(credit.tier, .bronze)
    }


    func testNegativeScoreHandling() {
        let credit = SocialCredit(currentScore: -10)
        XCTAssertEqual(credit.tier, .bronze)
    }
}
