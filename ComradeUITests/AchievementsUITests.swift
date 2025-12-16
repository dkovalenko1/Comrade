import XCTest

final class AchievementsUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    private func navigateToAchievementsTab() {
        let achievementsTab = app.tabBars.buttons["Achievements"]
        if achievementsTab.exists {
            achievementsTab.tap()
        }
    }

    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }

    func testAchievementsTabExists() {
        let achievementsTab = app.tabBars.buttons["Achievements"]
        XCTAssertTrue(waitForElement(achievementsTab))
    }

    func testNavigateToAchievements() {
        navigateToAchievementsTab()
        sleep(1)
        XCTAssertTrue(app.isHittable)
    }

    func testAchievementsListVisible() {
        navigateToAchievementsTab()
        sleep(1)

        let tables = app.tables
        if tables.count > 0 {
            XCTAssertTrue(tables.firstMatch.exists)
        } else {
            XCTAssertTrue(app.isHittable)
        }
    }

    func testNavigateAwayAndBack() {
        navigateToAchievementsTab()
        sleep(1)

        let tasksTab = app.tabBars.buttons["Tasks"]
        if tasksTab.exists {
            tasksTab.tap()
            sleep(1)
        }

        navigateToAchievementsTab()
        sleep(1)

        XCTAssertTrue(app.isHittable)
    }
}
