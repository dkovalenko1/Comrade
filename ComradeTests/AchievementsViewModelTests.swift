import XCTest
import CoreData
@testable import Comrade

final class AchievementsViewModelTests: XCTestCase {

    var viewModel: AchievementsViewModel!

    override func setUp() {
        super.setUp()
        viewModel = AchievementsViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testLoadAchievements() {
        viewModel.load()
        XCTAssertGreaterThan(viewModel.achievements.count, 0)
    }

    func testAchievementAtIndex() {
        viewModel.load()
        let achievement = viewModel.achievement(at: 0)
        XCTAssertNotNil(achievement)
    }

    func testAchievementAtInvalidIndex() {
        viewModel.load()
        let achievement = viewModel.achievement(at: 999)
        XCTAssertNil(achievement)
    }

    func testProgressTextForUnlocked() {
        let achievement = Achievement(
            id: "test",
            title: "Test",
            detail: "Test",
            icon: "🎯",
            category: .focusTime,
            target: 10,
            progress: 10,
            isUnlocked: true
        )

        let text = viewModel.progressText(for: achievement)
        XCTAssertEqual(text, "Completed")
    }

    func testProgressTextForLocked() {
        let achievement = Achievement(
            id: "test",
            title: "Test",
            detail: "Test",
            icon: "🎯",
            category: .focusTime,
            target: 10,
            progress: 5
        )

        let text = viewModel.progressText(for: achievement)
        XCTAssertEqual(text, "5 / 10")
    }

    func testProgressValueCalculation() {
        let achievement = Achievement(
            id: "test",
            title: "Test",
            detail: "Test",
            icon: "🎯",
            category: .focusTime,
            target: 10,
            progress: 5
        )

        let value = viewModel.progressValue(for: achievement)
        XCTAssertEqual(value, 0.5)
    }
}
