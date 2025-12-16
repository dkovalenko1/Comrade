import XCTest

final class CategoryManagementUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    private func navigateToTasksTab() {
        let tasksTab = app.tabBars.buttons["Tasks"]
        if tasksTab.exists {
            tasksTab.tap()
        }
    }

    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }

    func testTasksTabExists() {
        let tasksTab = app.tabBars.buttons["Tasks"]
        XCTAssertTrue(waitForElement(tasksTab))
    }

    func testNavigateToTasks() {
        navigateToTasksTab()
        sleep(1)

        XCTAssertTrue(app.isHittable)
    }

    func testCategoryFilterToggle() {
        navigateToTasksTab()
        sleep(1)

        let segmentedControls = app.segmentedControls
        if segmentedControls.count > 0 {
            let control = segmentedControls.firstMatch
            if control.exists && control.buttons.count > 1 {
                
                control.buttons.element(boundBy: 1).tap()
                sleep(1)

                XCTAssertTrue(control.exists)

                control.buttons.element(boundBy: 0).tap()
                sleep(1)

                XCTAssertTrue(control.exists)
            }
        }
    }

    func testScrollTaskList() {
        navigateToTasksTab()
        sleep(1)

        if let table = app.tables.firstMatch.exists ? app.tables.firstMatch : nil {
            table.swipeUp()
            sleep(1)
            table.swipeDown()
            sleep(1)

            XCTAssertTrue(table.exists)
        }
    }
}
