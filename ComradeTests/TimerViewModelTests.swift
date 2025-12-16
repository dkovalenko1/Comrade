import XCTest
import CoreData
@testable import Comrade

final class TimerViewModelTests: XCTestCase {

    var viewModel: TimerViewModel!

    override func setUp() {
        super.setUp()
        viewModel = TimerViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.selectedMode, .casual)
    }

    func testApplyTemplate() {
        let template = PomodoroTemplateModel(
            name: "Custom",
            icon: "⚡️",
            workDuration: 30 * 60,
            shortBreakDuration: 5 * 60,
            longBreakDuration: 15 * 60,
            cyclesBeforeLongBreak: 3,
            isPreset: false
        )

        viewModel.applyTemplate(template)
        XCTAssertNotNil(viewModel)
    }

    func testCurrentDurationWithoutTemplate() {
        let duration = viewModel.currentDuration
        XCTAssertEqual(duration, 25 * 60)
    }

    func testCurrentDurationWithTemplate() {
        let template = PomodoroTemplateModel(
            name: "Short",
            icon: "⚡️",
            workDuration: 15 * 60,
            shortBreakDuration: 3 * 60,
            longBreakDuration: 10 * 60,
            cyclesBeforeLongBreak: 2,
            isPreset: false
        )

        viewModel.applyTemplate(template)
        XCTAssertEqual(viewModel.currentDuration, 15 * 60)
    }

    func testIsAfterGracePeriodInitialState() {
        XCTAssertFalse(viewModel.isAfterGrace)
    }
}
