import XCTest
import CoreData
@testable import Comrade

final class TasksViewModelTests: XCTestCase {
    
    var viewModel: TasksViewModel!
    var taskService: TaskService!
    var coreDataStack: CoreDataStack!
    
    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack(inMemory: true)
        taskService = TaskService(coreDataStack: coreDataStack)
        viewModel = TasksViewModel(taskService: taskService)
    }
    
    override func tearDown() {
        viewModel = nil
        taskService = nil
        coreDataStack = nil
        super.tearDown()
    }
    
    func testLoadTasks() {
        taskService.createTask(name: "Task 1", category: "Personal")
        taskService.createTask(name: "Task 2", category: "Work")
        
        viewModel.loadTasks()
        
        XCTAssertEqual(viewModel.totalTaskCount, 2)
        XCTAssertEqual(viewModel.taskCount(for: .personal), 1)
        XCTAssertEqual(viewModel.taskCount(for: .work), 1)
    }
    
    func testSearch() {
        taskService.createTask(name: "Buy Milk")
        taskService.createTask(name: "Walk Dog")
        
        viewModel.search("Milk")
        
        XCTAssertEqual(viewModel.totalTaskCount, 1)
        XCTAssertEqual(viewModel.task(at: TaskSection.personal.rawValue, row: 0)?.name, "Buy Milk")
    }
    
    func testSectionGrouping() {
        let today = Date()
        taskService.createTask(name: "Today Task", deadline: today)
        
        taskService.createTask(name: "Personal Task", category: "Personal")
        
        viewModel.loadTasks()
        
        XCTAssertEqual(viewModel.taskCount(for: .today), 1)
        XCTAssertEqual(viewModel.taskCount(for: .personal), 1)
    }
    
    func testToggleTaskCompletion() {
        _ = taskService.createTask(name: "Task to Complete")
        viewModel.loadTasks()
        
        guard let sectionIndex = TaskSection.allCases.firstIndex(where: { viewModel.taskCount(for: $0) > 0 }) else {
            XCTFail("Task not found in any section")
            return
        }
        
        viewModel.toggleTaskCompletion(at: sectionIndex, row: 0)
        
        viewModel.loadTasks()
        
        XCTAssertEqual(viewModel.completedTaskCount, 1)
        XCTAssertEqual(viewModel.activeTaskCount, 0)
        
        viewModel.toggleTaskCompletion(at: TaskSection.completed.rawValue, row: 0)
        viewModel.loadTasks()
        
        XCTAssertEqual(viewModel.completedTaskCount, 0)
        XCTAssertEqual(viewModel.activeTaskCount, 1)
    }
    
    func testDeleteTask() {
        taskService.createTask(name: "Task to Delete")
        viewModel.loadTasks()
        
        guard let sectionIndex = TaskSection.allCases.firstIndex(where: { viewModel.taskCount(for: $0) > 0 }) else {
            XCTFail("Task not found")
            return
        }
        
        viewModel.deleteTask(at: sectionIndex, row: 0)
        viewModel.loadTasks()
        
        XCTAssertEqual(viewModel.totalTaskCount, 0)
    }
}
