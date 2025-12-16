import XCTest
import CoreData
@testable import Comrade

final class DependencyViewModelTests: XCTestCase {

    var viewModel: DependencyViewModel!
    var taskService: TaskService!
    var coreDataStack: CoreDataStack!
    var testTask: TaskEntity!

    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack(inMemory: true)
        taskService = TaskService(coreDataStack: coreDataStack)

        testTask = taskService.createTask(name: "Test Task")
        viewModel = DependencyViewModel(task: testTask, taskService: taskService)
    }

    override func tearDown() {
        viewModel = nil
        testTask = nil
        taskService = nil
        coreDataStack = nil
        super.tearDown()
    }


    func testInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.rootTaskName, "Test Task")
        XCTAssertFalse(viewModel.hasDependencies)
        XCTAssertFalse(viewModel.hasDependents)
    }

    func testNoDependenciesInitially() {
        XCTAssertFalse(viewModel.hasDependencies)
        XCTAssertEqual(viewModel.totalDependencies, 0)
        XCTAssertEqual(viewModel.completedDependencies, 0)
    }

    func testCanCompleteTaskWithoutDependencies() {
        XCTAssertTrue(viewModel.canCompleteRootTask)
    }

    func testAddDependency() {
        let dependency = taskService.createTask(name: "Dependency Task")

        viewModel.addDependency(dependency)

        XCTAssertTrue(viewModel.hasDependencies)
        XCTAssertEqual(viewModel.currentDependencies.count, 1)
        XCTAssertEqual(viewModel.totalDependencies, 1)
    }

    func testAddMultipleDependencies() {
        let dep1 = taskService.createTask(name: "Dep 1")
        let dep2 = taskService.createTask(name: "Dep 2")
        let dep3 = taskService.createTask(name: "Dep 3")

        viewModel.addDependency(dep1)
        viewModel.addDependency(dep2)
        viewModel.addDependency(dep3)

        XCTAssertEqual(viewModel.totalDependencies, 3)
    }

    func testCannotAddSelfAsDependency() {
        var errorReceived = false

        viewModel.onError = { message in
            errorReceived = true
            XCTAssertTrue(message.contains("cannot depend on itself"))
        }

        viewModel.addDependency(testTask)

        XCTAssertTrue(errorReceived)
        XCTAssertEqual(viewModel.totalDependencies, 0)
    }

    func testCannotAddDuplicateDependency() {
        let dependency = taskService.createTask(name: "Dependency")

        viewModel.addDependency(dependency)
        XCTAssertEqual(viewModel.totalDependencies, 1)

        var errorReceived = false
        viewModel.onError = { message in
            errorReceived = true
            XCTAssertTrue(message.contains("already a dependency"))
        }

        viewModel.addDependency(dependency)

        XCTAssertTrue(errorReceived)
        XCTAssertEqual(viewModel.totalDependencies, 1, "Should not add duplicate")
    }


    func testRemoveDependency() {
        let dependency = taskService.createTask(name: "Dependency")

        viewModel.addDependency(dependency)
        XCTAssertEqual(viewModel.totalDependencies, 1)

        viewModel.removeDependency(at: 0)

        XCTAssertEqual(viewModel.totalDependencies, 0)
        XCTAssertFalse(viewModel.hasDependencies)
    }


    func testCanCompleteWithUncompletedDependency() {
        let dependency = taskService.createTask(name: "Uncompleted Dep")
        viewModel.addDependency(dependency)

        XCTAssertFalse(viewModel.canCompleteRootTask, "Cannot complete with uncompleted dependency")
    }

    func testCanCompleteWithAllDependenciesCompleted() {
        let dependency = taskService.createTask(name: "Completed Dep")
        viewModel.addDependency(dependency)

        taskService.completeTask(id: dependency.id!)

        viewModel.loadDependencies()

        XCTAssertTrue(viewModel.canCompleteRootTask, "Should be able to complete")
        XCTAssertEqual(viewModel.completedDependencies, 1)
    }


    func testGetAvailableTasksForDependency() {
        let task1 = taskService.createTask(name: "Available 1")
        let task2 = taskService.createTask(name: "Available 2")

        let availableTasks = viewModel.getAvailableTasksForDependency()

        XCTAssertTrue(availableTasks.contains(task1))
        XCTAssertTrue(availableTasks.contains(task2))
        XCTAssertFalse(availableTasks.contains(testTask), "Should not include self")
    }

    func testAvailableTasksExcludeExistingDependencies() {
        let dependency = taskService.createTask(name: "Existing Dep")
        viewModel.addDependency(dependency)

        let availableTasks = viewModel.getAvailableTasksForDependency()

        XCTAssertFalse(availableTasks.contains(dependency), "Should not include existing dependency")
    }


    func testSectionManagement() {
        XCTAssertGreaterThanOrEqual(viewModel.numberOfSections, 1)

        let dependency = taskService.createTask(name: "Dep")
        viewModel.addDependency(dependency)

        XCTAssertTrue(viewModel.isDependencySection(0))
    }

    func testNumberOfRowsInSection() {
        let dep1 = taskService.createTask(name: "Dep 1")
        let dep2 = taskService.createTask(name: "Dep 2")

        viewModel.addDependency(dep1)
        viewModel.addDependency(dep2)

        let rows = viewModel.numberOfRows(in: 0)
        XCTAssertEqual(rows, 2)
    }

    func testNodeAtIndexPath() {
        let dependency = taskService.createTask(name: "Test Dep")
        viewModel.addDependency(dependency)

        let node = viewModel.node(at: 0, row: 0)

        XCTAssertNotNil(node)
        XCTAssertEqual(node?.name, "Test Dep")
        XCTAssertEqual(node?.level, 1)
    }

    func testBlockingDependencies() {
        let incompleteDep = taskService.createTask(name: "Incomplete")
        let completedDep = taskService.createTask(name: "Completed")
        taskService.completeTask(id: completedDep.id!)

        viewModel.addDependency(incompleteDep)
        viewModel.addDependency(completedDep)
        viewModel.loadDependencies()

        XCTAssertEqual(viewModel.blockingDependencies, 1, "Only incomplete dep is blocking")
    }
}
