import XCTest
@testable import Comrade

final class PomodoroTemplateTests: XCTestCase {

    func testTemplateInitialization() {
        let template = PomodoroTemplateModel(
            name: "Test",
            icon: "🎯",
            workDuration: 25 * 60,
            shortBreakDuration: 5 * 60,
            longBreakDuration: 15 * 60,
            cyclesBeforeLongBreak: 4,
            isPreset: false
        )

        XCTAssertEqual(template.name, "Test")
        XCTAssertEqual(template.icon, "🎯")
        XCTAssertEqual(template.workDuration, 25 * 60)
        XCTAssertEqual(template.shortBreakDuration, 5 * 60)
        XCTAssertEqual(template.longBreakDuration, 15 * 60)
        XCTAssertEqual(template.cyclesBeforeLongBreak, 4)
        XCTAssertFalse(template.isPreset)
    }

    func testPresetTemplate() {
        let template = PomodoroTemplateModel(
            name: "Classic",
            icon: "📚",
            workDuration: 25 * 60,
            shortBreakDuration: 5 * 60,
            longBreakDuration: 15 * 60,
            cyclesBeforeLongBreak: 4,
            isPreset: true
        )

        XCTAssertTrue(template.isPreset)
    }

    func testCustomTemplate() {
        let template = PomodoroTemplateModel(
            name: "My Custom",
            icon: "⚡️",
            workDuration: 30 * 60,
            shortBreakDuration: 10 * 60,
            longBreakDuration: 20 * 60,
            cyclesBeforeLongBreak: 3,
            isPreset: false
        )

        XCTAssertFalse(template.isPreset)
        XCTAssertEqual(template.workDuration, 30 * 60)
    }

    func testShortWorkDuration() {
        let template = PomodoroTemplateModel(
            name: "Sprint",
            icon: "⚡️",
            workDuration: 15 * 60,
            shortBreakDuration: 3 * 60,
            longBreakDuration: 10 * 60,
            cyclesBeforeLongBreak: 4,
            isPreset: false
        )

        XCTAssertEqual(template.workDuration, 15 * 60)
    }

    func testLongWorkDuration() {
        let template = PomodoroTemplateModel(
            name: "Deep Work",
            icon: "🧠",
            workDuration: 50 * 60,
            shortBreakDuration: 10 * 60,
            longBreakDuration: 20 * 60,
            cyclesBeforeLongBreak: 2,
            isPreset: false
        )

        XCTAssertEqual(template.workDuration, 50 * 60)
    }

    func testSingleCycle() {
        let template = PomodoroTemplateModel(
            name: "Single",
            icon: "1️⃣",
            workDuration: 25 * 60,
            shortBreakDuration: 5 * 60,
            longBreakDuration: 15 * 60,
            cyclesBeforeLongBreak: 1,
            isPreset: false
        )

        XCTAssertEqual(template.cyclesBeforeLongBreak, 1)
    }

    func testMultipleCycles() {
        let template = PomodoroTemplateModel(
            name: "Multi",
            icon: "🔄",
            workDuration: 25 * 60,
            shortBreakDuration: 5 * 60,
            longBreakDuration: 15 * 60,
            cyclesBeforeLongBreak: 6,
            isPreset: false
        )

        XCTAssertEqual(template.cyclesBeforeLongBreak, 6)
    }

    func testTemplateWithDifferentIcons() {
        let icons = ["🎯", "📚", "⚡️", "🧠", "🎓"]

        for icon in icons {
            let template = PomodoroTemplateModel(
                name: "Test",
                icon: icon,
                workDuration: 25 * 60,
                shortBreakDuration: 5 * 60,
                longBreakDuration: 15 * 60,
                cyclesBeforeLongBreak: 4,
                isPreset: false
            )

            XCTAssertEqual(template.icon, icon)
        }
    }

    func testTemplateHasUniqueID() {
        let template1 = PomodoroTemplateModel(
            name: "Template 1",
            icon: "1️⃣",
            workDuration: 25 * 60,
            shortBreakDuration: 5 * 60,
            longBreakDuration: 15 * 60,
            cyclesBeforeLongBreak: 4,
            isPreset: false
        )

        let template2 = PomodoroTemplateModel(
            name: "Template 2",
            icon: "2️⃣",
            workDuration: 25 * 60,
            shortBreakDuration: 5 * 60,
            longBreakDuration: 15 * 60,
            cyclesBeforeLongBreak: 4,
            isPreset: false
        )

        XCTAssertNotEqual(template1.id, template2.id)
    }
}
