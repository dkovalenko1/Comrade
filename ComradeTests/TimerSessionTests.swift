import XCTest
import CoreData
@testable import Comrade

final class TimerSessionTests: XCTestCase {

    var coreDataStack: CoreDataStack!
    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack(inMemory: true)
        context = coreDataStack.context
    }

    override func tearDown() {
        coreDataStack = nil
        context = nil
        super.tearDown()
    }

    private func createTimerSession(
        duration: Int32 = 1500,
        focusMode: String = "casual",
        wasCompleted: Bool = true,
        creditsEarned: Int32 = 25,
        startTime: Date? = nil
    ) -> TimerSession {
        let session = TimerSession(context: context)
        session.id = UUID()
        session.duration = duration
        session.focusMode = focusMode
        session.wasCompleted = wasCompleted
        session.creditsEarned = creditsEarned
        session.startTime = startTime ?? Date()
        session.endTime = Date()
        return session
    }

    func testFormattedDuration() {
        let session = createTimerSession(duration: 1500)
        XCTAssertEqual(session.formattedDuration, "25:00")
    }

    func testFormattedDurationWithSeconds() {
        let session = createTimerSession(duration: 1525)
        XCTAssertEqual(session.formattedDuration, "25:25")
    }

    func testFocusModeEnumCasual() {
        let session = createTimerSession(focusMode: "casual")
        XCTAssertEqual(session.focusModeEnum, .casual)
    }

    func testFocusModeEnumHardcore() {
        let session = createTimerSession(focusMode: "hardcore")
        XCTAssertEqual(session.focusModeEnum, .hardcore)
    }

    func testPointsMultiplierCasual() {
        let session = createTimerSession(focusMode: "casual")
        XCTAssertEqual(session.pointsMultiplier, 1)
    }

    func testPointsMultiplierHardcore() {
        let session = createTimerSession(focusMode: "hardcore")
        XCTAssertEqual(session.pointsMultiplier, 2)
    }

    func testStatusEmojiCompleted() {
        let session = createTimerSession(wasCompleted: true)
        XCTAssertEqual(session.statusEmoji, "✅")
    }

    func testStatusEmojiFailed() {
        let session = createTimerSession(wasCompleted: false)
        XCTAssertEqual(session.statusEmoji, "❌")
    }

    func testIsToday() {
        let today = Date()
        let session = createTimerSession(startTime: today)
        XCTAssertTrue(session.isToday())
    }

    func testIsInLastDays() {
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let session = createTimerSession(startTime: threeDaysAgo)

        XCTAssertTrue(session.isInLastDays(7))
        XCTAssertFalse(session.isInLastDays(2))
    }

    func testSessionPersistence() {
        let session = createTimerSession(
            duration: 900,
            focusMode: "casual",
            wasCompleted: true,
            creditsEarned: 15
        )

        coreDataStack.save()

        let fetchRequest: NSFetchRequest<TimerSession> = TimerSession.fetchRequest()
        let fetchedSessions = try? context.fetch(fetchRequest)

        XCTAssertNotNil(fetchedSessions)
        XCTAssertGreaterThan(fetchedSessions?.count ?? 0, 0)

        if let fetchedSession = fetchedSessions?.first(where: { $0.id == session.id }) {
            XCTAssertEqual(fetchedSession.duration, 900)
            XCTAssertEqual(fetchedSession.focusMode, "casual")
            XCTAssertTrue(fetchedSession.wasCompleted)
        }
    }
}
