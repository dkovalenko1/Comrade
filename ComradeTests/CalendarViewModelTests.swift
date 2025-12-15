//
//  CalendarViewModelTests.swift
//  Comrade
//
//  Created by Bohdan Hupalo on 15.12.2025.
//


import XCTest
@testable import Comrade

final class CalendarViewModelTests: XCTestCase {
    
    var viewModel: CalendarViewModel!
    var taskService: TaskService!
    
    override func setUp() {
        super.setUp()
        taskService = TaskService.shared
        viewModel = CalendarViewModel()
        
        deleteAllTasks()
    }
    
    override func tearDown() {
        deleteAllTasks()
        viewModel = nil
        taskService = nil
        super.tearDown()
    }
    
    private func deleteAllTasks() {
        let tasks = taskService.getAllTasks()
        for task in tasks {
            if let id = task.id {
                taskService.deleteTask(id: id)
            }
        }
    }
    
    // MARK: - Date Calculation Tests
    
    func testGenerateWeekDays() {
        // Given
        // Force specific date: Wed Jan 15 2025
        let components = DateComponents(year: 2025, month: 1, day: 15)
        let date = Calendar.current.date(from: components)!
        
        // When
        viewModel.selectDate(date) // selectDate triggers data generation
        
        // Then
        // Week starts Monday (Jan 13) to Sunday (Jan 19)
        let weekDays = viewModel.currentWeekDays
        XCTAssertEqual(weekDays.count, 7)
        
        let calendar = Calendar.current
        let firstDay = weekDays.first!
        let lastDay = weekDays.last!
        
        // Verify Monday start (weekday 2)
        XCTAssertEqual(calendar.component(.weekday, from: firstDay), 2) // Monday
        XCTAssertEqual(calendar.component(.day, from: firstDay), 13)
        XCTAssertEqual(calendar.component(.day, from: lastDay), 19)
    }
    
    func testMoveTimeWeekMode() {
        // Given
        // Start: Wed Jan 15 2025
        let startComponents = DateComponents(year: 2025, month: 1, day: 15)
        let startDate = Calendar.current.date(from: startComponents)!
        viewModel.switchMode(.week)
        viewModel.selectDate(startDate)
        
        // When: Move Next Week
        viewModel.moveTime(direction: 1)
        
        // Then: Should be Jan 22 (Wed)
        let calendar = Calendar.current
        let newDate = viewModel.currentDate
        XCTAssertEqual(calendar.component(.day, from: newDate), 22)
        XCTAssertEqual(calendar.component(.month, from: newDate), 1)
        
        // Verify Week Grid updated (Jan 20 - Jan 26)
        let firstDay = viewModel.currentWeekDays.first!
        XCTAssertEqual(calendar.component(.day, from: firstDay), 20)
    }
    
    func testMoveTimeMonthMode() {
        // Given
        // Start: Jan 15 2025
        let startComponents = DateComponents(year: 2025, month: 1, day: 15)
        let startDate = Calendar.current.date(from: startComponents)!
        viewModel.switchMode(.month)
        viewModel.selectDate(startDate)
        
        // When: Move Next Month
        viewModel.moveTime(direction: 1)
        
        // Then: Should be Feb 15
        let calendar = Calendar.current
        let newDate = viewModel.currentDate
        XCTAssertEqual(calendar.component(.month, from: newDate), 2)
        
        // Verify Grid generated (February has 28 days in 2025)
        // Grid size depends on padding + days.
        // Feb 1 2025 is Saturday. Monday-start padding: Mon(0)..Sat(5) = 5 days padding.
        // Total = 5 padding + 28 days = 33 cells.
        let grid = viewModel.currentMonthGrid
        XCTAssertEqual(grid.count, 33)
        XCTAssertNil(grid[0]) // Padding
        XCTAssertNotNil(grid[5]) // First day
    }
    
    // MARK: - Task Filtering & Sorting Tests
    
    func testFilterTasksForSelectedDate() {
        // Given
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        _ = taskService.createTask(name: "Task Today", deadline: today)
        _ = taskService.createTask(name: "Task Tomorrow", deadline: tomorrow)
        
        // When
        viewModel.selectDate(today)
        
        // Then
        XCTAssertEqual(viewModel.tasksForSelectedDate.count, 1)
        XCTAssertEqual(viewModel.tasksForSelectedDate.first?.name, "Task Today")
        
        // Switch to tomorrow
        viewModel.selectDate(tomorrow)
        XCTAssertEqual(viewModel.tasksForSelectedDate.count, 1)
        XCTAssertEqual(viewModel.tasksForSelectedDate.first?.name, "Task Tomorrow")
    }
    
    func testOverdueTaskLogic() {
        // Logic: Task due yesterday should appear on Today
        // Given
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        _ = taskService.createTask(name: "Overdue Task", deadline: yesterday)
        
        // When: Select Today
        viewModel.selectDate(today)
        
        // Then: Should see the overdue task
        XCTAssertEqual(viewModel.tasksForSelectedDate.count, 1)
        XCTAssertEqual(viewModel.tasksForSelectedDate.first?.name, "Overdue Task")
        
        // When: Select Yesterday (Original Date)
        viewModel.selectDate(yesterday)
        
        // Then: Should also see it there
        XCTAssertEqual(viewModel.tasksForSelectedDate.count, 1)
    }
    
    func testTaskSorting() {
        // Sort Order: Priority (High > Med > Low) -> All Day -> Time
        // Given
        let today = Date()
        
        // 1. Medium Priority, 10:00 AM
        let date10am = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: today)!
        _ = taskService.createTask(name: "Med 10am", priority: .medium, deadline: date10am, deadlineIsAllDay: false)
        
        // 2. High Priority, 12:00 PM
        let date12pm = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: today)!
        _ = taskService.createTask(name: "High 12pm", priority: .high, deadline: date12pm, deadlineIsAllDay: false)
        
        // 3. High Priority, All Day (Should be before High Time)
        _ = taskService.createTask(name: "High AllDay", priority: .high, deadline: today, deadlineIsAllDay: true)
        
        // 4. Medium Priority, All Day
        _ = taskService.createTask(name: "Med AllDay", priority: .medium, deadline: today, deadlineIsAllDay: true)
        
        // When
        viewModel.selectDate(today)
        let tasks = viewModel.tasksForSelectedDate
        
        // Then
        XCTAssertEqual(tasks.count, 4)
        
        // Expected Order:
        // 1. High AllDay (Priority High, AllDay)
        // 2. High 12pm   (Priority High, Time)
        // 3. Med AllDay  (Priority Med, AllDay)
        // 4. Med 10am    (Priority Med, Time)
        
        XCTAssertEqual(tasks[0].name, "High AllDay")
        XCTAssertEqual(tasks[1].name, "High 12pm")
        XCTAssertEqual(tasks[2].name, "Med AllDay")
        XCTAssertEqual(tasks[3].name, "Med 10am")
    }
    
    func testHasDeadlineIndicator() {
        // Given
        let today = Date()
        _ = taskService.createTask(name: "Task", deadline: today)
        
        // When
        // Force refresh internal sets
        viewModel.selectDate(today) 
        
        // Then
        XCTAssertTrue(viewModel.hasDeadline(on: today))
        
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        XCTAssertFalse(viewModel.hasDeadline(on: tomorrow))
    }
}
