import XCTest
import CoreData
@testable import Comrade

final class TemplateServiceTests: XCTestCase {

    var service: TemplateService!

    override func setUp() {
        super.setUp()
        service = TemplateService.shared
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    func testGetAllTemplates() {
        let templates = service.getAllTemplates()
        XCTAssertGreaterThan(templates.count, 0)

        let presetCount = templates.prefix(while: { $0.isPreset }).count
        XCTAssertGreaterThan(presetCount, 0, "Should have preset templates first")
    }

    func testGetPresetTemplates() {
        let presets = service.getPresetTemplates()
        XCTAssertGreaterThan(presets.count, 0)
        XCTAssertTrue(presets.allSatisfy { $0.isPreset })

        let hasClassic = presets.contains { $0.name == "Classic" }
        XCTAssertTrue(hasClassic, "Should contain Classic template")
    }

    func testUpsertNewTemplate() {
        let initialCount = service.getAllTemplates().count

        let template = PomodoroTemplateModel(
            name: "Test Template",
            icon: "🧪",
            workDuration: 30 * 60,
            shortBreakDuration: 5 * 60,
            longBreakDuration: 10 * 60,
            cyclesBeforeLongBreak: 3,
            isPreset: false
        )

        let result = service.upsert(template)

        XCTAssertEqual(result.name, "Test Template")
        XCTAssertEqual(result.workDuration, 30 * 60)

        let newCount = service.getAllTemplates().count
        XCTAssertEqual(newCount, initialCount + 1, "Should add new template")
    }

    func testUpdateExistingTemplate() {
        let template = PomodoroTemplateModel(
            name: "Original Name",
            icon: "🎯",
            workDuration: 25 * 60,
            shortBreakDuration: 5 * 60,
            longBreakDuration: 15 * 60,
            cyclesBeforeLongBreak: 4,
            isPreset: false
        )

        let saved = service.upsert(template)
        let templateId = saved.id

        var updated = saved
        updated.name = "Updated Name"
        updated.workDuration = 30 * 60

        let result = service.upsert(updated)

        XCTAssertEqual(result.id, templateId, "ID should remain the same")
        XCTAssertEqual(result.name, "Updated Name")
        XCTAssertEqual(result.workDuration, 30 * 60)

        let retrieved = service.getTemplate(id: templateId)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.name, "Updated Name")
    }

    func testDeleteTemplate() {
        let template = PomodoroTemplateModel(
            name: "To Delete",
            icon: "🗑️",
            workDuration: 25 * 60,
            shortBreakDuration: 5 * 60,
            longBreakDuration: 15 * 60,
            cyclesBeforeLongBreak: 4,
            isPreset: false
        )

        let saved = service.upsert(template)
        let templateId = saved.id

        XCTAssertNotNil(service.getTemplate(id: templateId))

        service.delete(id: templateId)

        let retrieved = service.getTemplate(id: templateId)
        XCTAssertNil(retrieved, "Template should be deleted")
    }

    func testGetTemplateById() {
        let template = PomodoroTemplateModel(
            name: "Findable",
            icon: "🔍",
            workDuration: 25 * 60,
            shortBreakDuration: 5 * 60,
            longBreakDuration: 15 * 60,
            cyclesBeforeLongBreak: 4,
            isPreset: false
        )

        let saved = service.upsert(template)

        let found = service.getTemplate(id: saved.id)

        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, saved.id)
        XCTAssertEqual(found?.name, "Findable")
    }
}
