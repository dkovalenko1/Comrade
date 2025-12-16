//
//  TemplateEditorViewModelTests.swift
//  Comrade
//
//  Created by Bohdan Hupalo on 15.12.2025.
//


import XCTest
@testable import Comrade

final class TemplateEditorViewModelTests: XCTestCase {
    
    var viewModel: TemplateEditorViewModel!
    var service: TemplateService!
    
    override func setUp() {
        super.setUp()
        service = TemplateService.shared
        viewModel = TemplateEditorViewModel()
        
        deleteAllCustomTemplates()
    }
    
    override func tearDown() {
        deleteAllCustomTemplates()
        viewModel = nil
        service = nil
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
    
    // MARK: - Tests
    
    func testPatternGeneration() {
        // Given
        viewModel.workDuration = 25
        viewModel.shortBreakDuration = 5
        viewModel.longBreakDuration = 15
        viewModel.cycles = 4
        
        // When
        var pattern = ""
        viewModel.onPatternUpdate = { text in
            pattern = text
        }
        viewModel.updatePattern()
        
        // Then
        let expected = "25-5-25-5-25-5-25-15"
        XCTAssertEqual(pattern, expected)
    }
    
    func testValidationSuccess() {
        // Given valid inputs
        viewModel.name = "Valid Name"
        viewModel.workDuration = 25
        viewModel.shortBreakDuration = 5
        viewModel.longBreakDuration = 15
        
        // Then
        XCTAssertTrue(viewModel.validate(), "Validation should pass for valid inputs")
    }
    
    func testValidationFailure_EmptyName() {
        // Given
        viewModel.name = "   "
        
        // When
        var errorMessage: String?
        viewModel.onError = { msg in errorMessage = msg }
        
        // Then
        XCTAssertFalse(viewModel.validate())
        XCTAssertEqual(errorMessage, "Please enter a template name")
    }
    
    func testValidationFailure_WorkLessThanShortBreak() {
        // Given
        viewModel.name = "Test"
        viewModel.workDuration = 5
        viewModel.shortBreakDuration = 10 
        
        // When
        var errorMessage: String?
        viewModel.onError = { msg in errorMessage = msg }
        
        // Then
        XCTAssertFalse(viewModel.validate())
        XCTAssertEqual(errorMessage, "Work duration must be longer than short break")
    }
    
    func testValidationFailure_LongBreakLessThanShortBreak() {
        // Given
        viewModel.name = "Test"
        viewModel.workDuration = 25
        viewModel.shortBreakDuration = 10
        viewModel.longBreakDuration = 5
        
        // When
        var errorMessage: String?
        viewModel.onError = { msg in errorMessage = msg }
        
        // Then
        XCTAssertFalse(viewModel.validate())
        XCTAssertEqual(errorMessage, "Long break must be longer than short break")
    }
    
    func testSaveCreatesTemplate() {
        // Given
        viewModel.name = "My Focus"
        viewModel.icon = "⚡"
        viewModel.workDuration = 40
        
        var successCalled = false
        viewModel.onSaveSuccess = { successCalled = true }
        
        // When
        viewModel.save()
        
        // Then
        XCTAssertTrue(successCalled, "Should call onSaveSuccess")
        
        // Verify in Service
        let templates = service.getCustomTemplates()
        XCTAssertEqual(templates.count, 1, "Service should have 1 custom template")
        
        let saved = templates.first
        // ViewModel logic prepends icon to name
        XCTAssertEqual(saved?.name, "⚡ My Focus")
        XCTAssertEqual(saved?.workDuration, 40)
    }
}
