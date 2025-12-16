import XCTest
import CoreData
@testable import Comrade

final class TaskServiceTests: XCTestCase {
    
    var taskService: TaskService!
    var coreDataStack: CoreDataStack!
    
    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack(inMemory: true)
        taskService = TaskService(coreDataStack: coreDataStack)
    }
    
    override func tearDown() {
        taskService = nil
        coreDataStack = nil
        super.tearDown()
    }
    
    func testCreateTask() {
        let name = "Test Task"
        let description = "Test Description"
        let category = "Work"
        let priority = TaskPriority.high
        
        let task = taskService.createTask(
            name: name,
            taskDescription: description,
            category: category,
            priority: priority
        )
        
        XCTAssertNotNil(task.id)
        XCTAssertEqual(task.name, name)
        XCTAssertEqual(task.taskDescription, description)
        XCTAssertEqual(task.category, category)
        XCTAssertEqual(task.priority, priority.rawValue)
        XCTAssertFalse(task.isCompleted)
        
        // Verify it's saved in Core Data
        let fetchRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        let tasks = try? coreDataStack.context.fetch(fetchRequest)
        
        XCTAssertEqual(tasks?.count, 1)
        XCTAssertEqual(tasks?.first?.name, name)
    }
    
    func testUpdateTask() {
        let task = taskService.createTask(name: "Original Name")
        
        task.name = "Updated Name"
        task.isCompleted = true
        
        taskService.updateTask(task)
        
        let fetchRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        let tasks = try? coreDataStack.context.fetch(fetchRequest)
        
        XCTAssertEqual(tasks?.first?.name, "Updated Name")
        XCTAssertTrue(tasks?.first?.isCompleted ?? false)
    }
    
    func testDeleteTask() {
        let task = taskService.createTask(name: "Task to Delete")
        guard let id = task.id else {
            XCTFail("Task ID should not be nil")
            return
        }
        
        taskService.deleteTask(task)
        
        let fetchedTask = taskService.getTask(id: id)
        XCTAssertNil(fetchedTask)
    }
}
