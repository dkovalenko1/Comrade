import XCTest
import CoreData
@testable import Comrade

final class TaskEditorViewModelTests: XCTestCase {
    
    var viewModel: TaskEditorViewModel!
    var taskService: TaskService!
    var notificationService: NotificationService!
    var categoryService: CategoryService!
    var coreDataStack: CoreDataStack!
    var mockNotificationCenter: MockNotificationCenter!
    var userDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack(inMemory: true)
        taskService = TaskService(coreDataStack: coreDataStack)
        
        mockNotificationCenter = MockNotificationCenter()
        notificationService = NotificationService(notificationCenter: mockNotificationCenter)
        
        userDefaults = UserDefaults(suiteName: "TestDefaults")
        userDefaults.removePersistentDomain(forName: "TestDefaults")
        categoryService = CategoryService(userDefaults: userDefaults)
    }
    
    override func tearDown() {
        viewModel = nil
        taskService = nil
        notificationService = nil
        categoryService = nil
        coreDataStack = nil
        mockNotificationCenter = nil
        userDefaults.removePersistentDomain(forName: "TestDefaults")
        userDefaults = nil
        super.tearDown()
    }
    
    func testCreateModeInitialization() {
        viewModel = TaskEditorViewModel(
            mode: .create,
            taskService: taskService,
            notificationService: notificationService,
            categoryService: categoryService
        )
        
        XCTAssertEqual(viewModel.name, "")
        XCTAssertEqual(viewModel.category, "Personal") // Default
    }
    
    func testEditModeInitialization() {
        let task = taskService.createTask(name: "Existing Task", category: "Work")
        
        viewModel = TaskEditorViewModel(
            mode: .edit(task),
            taskService: taskService,
            notificationService: notificationService,
            categoryService: categoryService
        )
        
        XCTAssertEqual(viewModel.name, "Existing Task")
        XCTAssertEqual(viewModel.category, "Work")
    }
    
    func testValidation() {
        viewModel = TaskEditorViewModel(
            mode: .create,
            taskService: taskService,
            notificationService: notificationService,
            categoryService: categoryService
        )
        
        // Empty name
        viewModel.name = ""
        XCTAssertFalse(viewModel.validate())
        
        // Valid name
        viewModel.name = "Valid Name"
        XCTAssertTrue(viewModel.validate())
    }
    
    func testSaveNewTask() {
        viewModel = TaskEditorViewModel(
            mode: .create,
            taskService: taskService,
            notificationService: notificationService,
            categoryService: categoryService
        )
        
        viewModel.name = "New Task"
        viewModel.category = "Work"
        
        let expectation = self.expectation(description: "Save Success")
        viewModel.onSaveSuccess = { task in
            XCTAssertEqual(task.name, "New Task")
            XCTAssertEqual(task.category, "Work")
            expectation.fulfill()
        }
        
        viewModel.save()
        
        waitForExpectations(timeout: 1.0, handler: nil)
        
        // Verify in service
        let tasks = taskService.getAllTasks()
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.name, "New Task")
    }
    
    func testUpdateTask() {
        let task = taskService.createTask(name: "Original Name")
        
        viewModel = TaskEditorViewModel(
            mode: .edit(task),
            taskService: taskService,
            notificationService: notificationService,
            categoryService: categoryService
        )
        
        viewModel.name = "Updated Name"
        
        let expectation = self.expectation(description: "Update Success")
        viewModel.onSaveSuccess = { updatedTask in
            XCTAssertEqual(updatedTask.name, "Updated Name")
            expectation.fulfill()
        }
        
        viewModel.save()
        
        waitForExpectations(timeout: 1.0, handler: nil)
        
        // Verify in service
        let tasks = taskService.getAllTasks()
        XCTAssertEqual(tasks.first?.name, "Updated Name")
    }
}
