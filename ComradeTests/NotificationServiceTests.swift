import XCTest
import UserNotifications

@testable import Comrade

class MockNotificationCenter: NotificationCenterProtocol {
    var requestAuthorizationCalled = false
    var addRequestCalled = false
    var lastRequest: UNNotificationRequest?
    var delegate: UNUserNotificationCenterDelegate?
    
    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> Void) {
        requestAuthorizationCalled = true
        completionHandler(true, nil)
    }
    
    func getNotificationSettings(completionHandler: @escaping (UNNotificationSettings) -> Void) {
        // Cannot easily mock UNNotificationSettings
    }
    
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?) {
        addRequestCalled = true
        lastRequest = request
        completionHandler?(nil)
    }
    
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        
    }
    
    func removeAllPendingNotificationRequests() {
        
    }
    
    func getPendingNotificationRequests(completionHandler: @escaping ([UNNotificationRequest]) -> Void) {
        completionHandler([])
    }
}

final class NotificationServiceTests: XCTestCase {
    
    var notificationService: NotificationService!
    var mockCenter: MockNotificationCenter!
    var coreDataStack: CoreDataStack!
    
    override func setUp() {
        super.setUp()
        mockCenter = MockNotificationCenter()
        notificationService = NotificationService(notificationCenter: mockCenter)
        coreDataStack = CoreDataStack(inMemory: true)
    }
    
    override func tearDown() {
        notificationService = nil
        mockCenter = nil
        coreDataStack = nil
        super.tearDown()
    }
    
    func testRequestPermission() {
        let expectation = self.expectation(description: "Permission Request")
        
        notificationService.requestPermission { granted in
            XCTAssertTrue(granted)
            expectation.fulfill()
        }
        
        XCTAssertTrue(mockCenter.requestAuthorizationCalled)
        waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testScheduleReminder() {
        let task = coreDataStack.create(TaskEntity.self)
        task.id = UUID()
        task.name = "Test Task"
        
        let futureDate = Date().addingTimeInterval(3600) // 1 hour later
        
        notificationService.scheduleReminder(for: task, at: futureDate)
        
        XCTAssertTrue(mockCenter.addRequestCalled)
        XCTAssertNotNil(mockCenter.lastRequest)
        XCTAssertEqual(mockCenter.lastRequest?.content.title, "Task Reminder")
        XCTAssertEqual(mockCenter.lastRequest?.content.body, "Test Task")
    }
}
