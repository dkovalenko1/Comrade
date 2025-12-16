import XCTest

final class ComradeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false

    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testTimerScreenBasicElements() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should exist")

        let playButton = app.buttons["playButton"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 5), "Play button should exist")

        let stopButton = app.buttons["stopButton"]
        XCTAssertTrue(stopButton.waitForExistence(timeout: 2), "Stop button should exist")

        let modeButton = app.buttons["modeToggleButton"]
        XCTAssertTrue(modeButton.waitForExistence(timeout: 2), "Mode toggle button should exist")

        let templateButton = app.buttons["templateButton"]
        XCTAssertTrue(templateButton.waitForExistence(timeout: 2), "Template button should exist")
    }

    @MainActor
    func testModeToggle() throws {
        let app = XCUIApplication()
        app.launch()

        let modeButton = app.buttons["modeToggleButton"]
        XCTAssertTrue(modeButton.waitForExistence(timeout: 5), "Mode button should exist")

        let initialLabel = modeButton.label

        modeButton.tap()

        let newLabel = modeButton.label
        XCTAssertNotEqual(initialLabel, newLabel, "Mode button label should change after tap")

        modeButton.tap()

        XCTAssertEqual(modeButton.label, initialLabel, "Should return to initial mode")
    }

    @MainActor
    func testNavigationBetweenTabs() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should exist")

        let tabButtons = tabBar.buttons
        XCTAssertGreaterThanOrEqual(tabButtons.count, 4, "Should have at least 4 tabs")

        let tasksTab = tabButtons.element(boundBy: 1)
        tasksTab.tap()
        XCTAssertTrue(tasksTab.waitForExistence(timeout: 2), "Should navigate to Tasks tab")

        let calendarTab = tabButtons.element(boundBy: 2)
        calendarTab.tap()
        XCTAssertTrue(calendarTab.waitForExistence(timeout: 2), "Should navigate to Calendar tab")

        let achievementsTab = tabButtons.element(boundBy: 3)
        achievementsTab.tap()
        XCTAssertTrue(achievementsTab.waitForExistence(timeout: 2), "Should navigate to Achievements tab")

        let timerTab = tabButtons.element(boundBy: 0)
        timerTab.tap()
        XCTAssertTrue(timerTab.waitForExistence(timeout: 2), "Should navigate back to Timer tab")
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
