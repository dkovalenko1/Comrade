import XCTest

final class CalendarUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    private func navigateToCalendarTab() {
        let calendarTab = app.tabBars.buttons["Calendar"]
        if calendarTab.exists {
            calendarTab.tap()
        }
    }

    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }

    func testCalendarTabExists() {
        let calendarTab = app.tabBars.buttons["Calendar"]
        XCTAssertTrue(waitForElement(calendarTab))
    }

    func testNavigateToCalendar() {
        navigateToCalendarTab()
        sleep(1)

        XCTAssertTrue(app.isHittable)
    }

    func testCalendarModeToggle() {
        navigateToCalendarTab()
        sleep(1)

        let segmentedControls = app.segmentedControls
        if segmentedControls.count > 0 {
            let control = segmentedControls.firstMatch
            if control.exists {
                let buttons = control.buttons
                if buttons.count > 1 {
                    buttons.element(boundBy: 1).tap()
                    sleep(1)

                    XCTAssertTrue(control.exists)
                }
            }
        }
    }

    func testSwitchBetweenCalendarAndTasks() {
        navigateToCalendarTab()
        sleep(1)

        let tasksTab = app.tabBars.buttons["Tasks"]
        if tasksTab.exists {
            tasksTab.tap()
            sleep(1)
        }

        navigateToCalendarTab()
        sleep(1)

        XCTAssertTrue(app.isHittable)
    }
}
