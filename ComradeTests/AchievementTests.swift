import XCTest
@testable import Comrade

final class AchievementTests: XCTestCase {


    func testAchievementInitialization() {
        let achievement = Achievement(
            id: "test",
            title: "Test Title",
            detail: "Test Detail",
            icon: "🎯",
            category: .focusTime,
            target: 100
        )

        XCTAssertEqual(achievement.id, "test")
        XCTAssertEqual(achievement.title, "Test Title")
        XCTAssertEqual(achievement.detail, "Test Detail")
        XCTAssertEqual(achievement.icon, "🎯")
        XCTAssertEqual(achievement.category, .focusTime)
        XCTAssertEqual(achievement.target, 100)
        XCTAssertEqual(achievement.progress, 0)
        XCTAssertFalse(achievement.isUnlocked)
        XCTAssertNil(achievement.unlockedAt)
    }

    func testAchievementWithProgress() {
        let achievement = Achievement(
            id: "test",
            title: "Test",
            detail: "Detail",
            icon: "🔥",
            category: .tasksCompleted,
            target: 50,
            progress: 25
        )

        XCTAssertEqual(achievement.progress, 25)
        XCTAssertFalse(achievement.isUnlocked)
    }

    func testUnlockedAchievement() {
        let date = Date()
        let achievement = Achievement(
            id: "test",
            title: "Test",
            detail: "Detail",
            icon: "✅",
            category: .streaks,
            target: 7,
            progress: 7,
            isUnlocked: true,
            unlockedAt: date
        )

        XCTAssertTrue(achievement.isUnlocked)
        XCTAssertEqual(achievement.unlockedAt, date)
    }


    func testAchievementCategoryFocusTime() {
        let achievement = Achievement(
            id: "test",
            title: "Test",
            detail: "Detail",
            icon: "⏰",
            category: .focusTime,
            target: 100
        )

        XCTAssertEqual(achievement.category, .focusTime)
    }

    func testAchievementCategoryTasksCompleted() {
        let achievement = Achievement(
            id: "test",
            title: "Test",
            detail: "Detail",
            icon: "📋",
            category: .tasksCompleted,
            target: 50
        )

        XCTAssertEqual(achievement.category, .tasksCompleted)
    }

    func testAchievementCategoryStreaks() {
        let achievement = Achievement(
            id: "test",
            title: "Test",
            detail: "Detail",
            icon: "🔥",
            category: .streaks,
            target: 7
        )

        XCTAssertEqual(achievement.category, .streaks)
    }

    func testAchievementCategorySpecial() {
        let achievement = Achievement(
            id: "test",
            title: "Test",
            detail: "Detail",
            icon: "⭐",
            category: .special,
            target: 1
        )

        XCTAssertEqual(achievement.category, .special)
    }

    func testProgressZero() {
        let achievement = Achievement(
            id: "test",
            title: "Test",
            detail: "Detail",
            icon: "🎯",
            category: .focusTime,
            target: 100,
            progress: 0
        )

        XCTAssertEqual(achievement.progress, 0)
    }

    func testProgressPartial() {
        let achievement = Achievement(
            id: "test",
            title: "Test",
            detail: "Detail",
            icon: "🎯",
            category: .focusTime,
            target: 100,
            progress: 50
        )

        XCTAssertEqual(achievement.progress, 50)
    }

    func testProgressComplete() {
        let achievement = Achievement(
            id: "test",
            title: "Test",
            detail: "Detail",
            icon: "🎯",
            category: .focusTime,
            target: 100,
            progress: 100
        )

        XCTAssertEqual(achievement.progress, 100)
    }
}
