import XCTest

final class TimerUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    private func navigateToTimerTab() {
        let timerTab = app.tabBars.buttons["Timer"]
        if timerTab.exists {
            timerTab.tap()
        }
    }

    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }

    func testTimerTabExists() {
        let timerTab = app.tabBars.buttons["Timer"]
        XCTAssertTrue(waitForElement(timerTab))
    }

    func testTimerScreenElements() {
        navigateToTimerTab()

        let playButton = app.buttons["playButton"]
        XCTAssertTrue(waitForElement(playButton))

        let stopButton = app.buttons["stopButton"]
        XCTAssertTrue(waitForElement(stopButton))

        let modeToggleButton = app.buttons["modeToggleButton"]
        XCTAssertTrue(waitForElement(modeToggleButton))

        let templateButton = app.buttons["templateButton"]
        XCTAssertTrue(waitForElement(templateButton))
    }

    func testInitialTimerState() {
        navigateToTimerTab()

        let playButton = app.buttons["playButton"]
        let stopButton = app.buttons["stopButton"]

        XCTAssertTrue(playButton.isEnabled)
        XCTAssertFalse(stopButton.isEnabled)
    }

    func testModeToggleCasualToHardcore() {
        navigateToTimerTab()

        let modeToggleButton = app.buttons["modeToggleButton"]
        XCTAssertTrue(waitForElement(modeToggleButton))

        let initialLabel = modeToggleButton.label
        modeToggleButton.tap()

        sleep(1)

        let newLabel = modeToggleButton.label
        XCTAssertNotEqual(initialLabel, newLabel)
    }


    func testTemplateButtonTap() {
        navigateToTimerTab()

        let templateButton = app.buttons["templateButton"]
        XCTAssertTrue(waitForElement(templateButton))

        templateButton.tap()
        sleep(1)

        XCTAssertTrue(templateButton.exists)
    }


    func testNavigateToTimerAndBack() {
        navigateToTimerTab()

        let tasksTab = app.tabBars.buttons["Tasks"]
        if tasksTab.exists {
            tasksTab.tap()
            sleep(1)
        }

        let timerTab = app.tabBars.buttons["Timer"]
        if timerTab.exists {
            timerTab.tap()
            sleep(1)
        }

        let playButton = app.buttons["playButton"]
        XCTAssertTrue(playButton.exists)
    }
}
