//
//  TemplateServiceTests.swift
//  Comrade
//
//  Created by Bohdan Hupalo on 15.12.2025.
//


import XCTest
import CoreData
@testable import Comrade

final class TemplateServiceTests: XCTestCase {
    
    var service: TemplateService!
    var coreDataStack: CoreDataStack!
    
    override func setUp() {
        super.setUp()
        service = TemplateService.shared
        coreDataStack = CoreDataStack.shared
        
        // Clear only custom templates before each test to ensure a clean state
        deleteAllCustomTemplates()
    }
    
    override func tearDown() {
        // Clean up after tests
        deleteAllCustomTemplates()
        service = nil
        coreDataStack = nil
        super.tearDown()
    }
    
    private func deleteAllCustomTemplates() {
        let customTemplates = service.getCustomTemplates()
        for template in customTemplates {
            if let id = template.id {
                service.deleteTemplate(id: id)
            }
        }
    }
    
    // MARK: - CRUD Tests
    
    func testCreateCustomTemplate() {
        // Given
        let name = "My Custom Focus"
        let work = 40
        let short = 10
        let long = 25
        let cycles = 5
        
        // When
        let newTemplate = service.createCustomTemplate(
            name: name,
            work: work,
            short: short,
            long: long,
            cycles: cycles
        )
        
        // Then
        XCTAssertNotNil(newTemplate.id, "Template should have a valid UUID")
        XCTAssertEqual(newTemplate.name, name)
        XCTAssertEqual(newTemplate.workDuration, Int32(work))
        XCTAssertEqual(newTemplate.shortBreakDuration, Int32(short))
        XCTAssertEqual(newTemplate.longBreakDuration, Int32(long))
        XCTAssertEqual(newTemplate.cycles, Int32(cycles))
        XCTAssertTrue(newTemplate.isCustom, "Template should be marked as custom")
        
        // Verify it exists in persistence
        let fetchedTemplate = service.getTemplate(id: newTemplate.id!)
        XCTAssertNotNil(fetchedTemplate, "Should be able to fetch the created template")
    }
    
    func testGetPresetTemplates() {
        // When
        let presets = service.getPresetTemplates()
        
        // Then
        // We expect the 4 defaults: Classic, Deep Work, Sprint, Student
        XCTAssertEqual(presets.count, 4, "Should return 4 preset templates")
        XCTAssertFalse(presets.isEmpty)
        
        // Verify they are NOT custom
        for template in presets {
            XCTAssertFalse(template.isCustom, "Preset template should not be custom")
        }
        
        // Verify specific preset existence (e.g., Classic)
        let hasClassic = presets.contains { $0.name == "Classic" }
        XCTAssertTrue(hasClassic, "Presets should include 'Classic'")
    }
    
    func testGetCustomTemplatesOnlyReturnsCustom() {
        // Given
        // Create 2 custom templates
        _ = service.createCustomTemplate(name: "Custom 1", work: 25, short: 5, long: 15, cycles: 4)
        _ = service.createCustomTemplate(name: "Custom 2", work: 50, short: 10, long: 30, cycles: 3)
        
        // When
        let customTemplates = service.getCustomTemplates()
        let presetTemplates = service.getPresetTemplates()
        
        // Then
        XCTAssertEqual(customTemplates.count, 2, "Should return exactly 2 custom templates")
        XCTAssertEqual(presetTemplates.count, 4, "Presets count should remain unchanged")
        
        for template in customTemplates {
            XCTAssertTrue(template.isCustom, "Template in custom list must be marked custom")
        }
    }
    
    func testUpdateTemplate() {
        // Given
        let template = service.createCustomTemplate(name: "Old Name", work: 25, short: 5, long: 15, cycles: 4)
        guard let id = template.id else { return XCTFail("Template ID is nil") }
        
        // When
        template.name = "New Name"
        template.workDuration = 60
        service.updateTemplate(template)
        
        // Then
        // Fetch a fresh copy to verify persistence
        // (In CoreData context this is often the same object, but good to simulate flow)
        let updatedTemplate = service.getTemplate(id: id)
        XCTAssertEqual(updatedTemplate?.name, "New Name")
        XCTAssertEqual(updatedTemplate?.workDuration, 60)
    }
    
    func testDeleteCustomTemplate() {
        // Given
        let template = service.createCustomTemplate(name: "To Delete", work: 25, short: 5, long: 15, cycles: 4)
        guard let id = template.id else { return XCTFail("Template ID is nil") }
        
        // When
        service.deleteTemplate(id: id)
        
        // Then
        let deletedTemplate = service.getTemplate(id: id)
        XCTAssertNil(deletedTemplate, "Template should be nil after deletion")
    }
    
    func testCannotDeletePresetTemplate() {
        // Given
        let presets = service.getPresetTemplates()
        guard let classicTemplate = presets.first(where: { $0.name == "Classic" }),
              let id = classicTemplate.id else {
            return XCTFail("Classic preset not found")
        }
        
        // When
        service.deleteTemplate(id: id)
        
        // Then
        let fetchedTemplate = service.getTemplate(id: id)
        XCTAssertNotNil(fetchedTemplate, "Preset template should NOT be deleted")
    }
}