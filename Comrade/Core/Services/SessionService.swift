import Foundation
import UIKit

enum FocusMode: String {
    case casual = "casual"      // Can leave app, standard rewards
    case hardcore = "hardcore"  // Exit app = fail, multiplied rewards
}

enum TimerState {
    case idle
    case running
    case completed
    case failed
}

enum SessionPhase {
    case work
    case shortBreak
    case longBreak
}

class SessionService {
        
    static let shared = SessionService()
    
    private init() {
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
        
    private let coreData = CoreDataStack.shared
    
    private var currentSessionEntity: TimerSession?
    
    private var timer: DispatchSourceTimer?
    
    private(set) var state: TimerState = .idle
    
    private(set) var focusMode: FocusMode = .casual
    
    private(set) var remainingTime: TimeInterval = 0
    
    private(set) var totalDuration: TimeInterval = 0
    
    private(set) var currentPhase: SessionPhase = .work

    private var currentTemplate: PomodoroTemplateModel?

    private(set) var totalCycles: Int = 1

    private(set) var currentCycle: Int = 1

    private var plannedWorkDuration: TimeInterval = 0
    
    private var associatedTaskId: UUID?
    
    private var sessionStartTime: Date?
    
    private let gracePeriod: TimeInterval = 9
    
    var onTick: ((TimeInterval) -> Void)?
    
    var onSessionComplete: (() -> Void)?
    
    var onSessionFail: ((String) -> Void)?
    
    var onStateChange: ((TimerState) -> Void)?
    
    var onPhaseChange: ((SessionPhase) -> Void)?
    

    func startSession(duration: TimeInterval, taskId: UUID? = nil, mode: FocusMode = .casual, plannedWork: TimeInterval? = nil) {
        guard state == .idle else {
            print("Cannot start session: Already active")
            return
        }
        
        let startDate = Date()

        if currentTemplate == nil {
            totalCycles = 1
            currentCycle = 1
        }
        plannedWorkDuration = plannedWork ?? plannedWorkDuration
        if plannedWorkDuration == 0 {
            plannedWorkDuration = duration
        }

        // Create new session entity in CoreData
        let session = coreData.create(TimerSession.self)
        session.id = UUID()
        session.startTime = startDate
        session.duration = Int32(duration)
        session.focusMode = mode.rawValue
        session.wasCompleted = false
        
        currentSessionEntity = session
        associatedTaskId = taskId
        focusMode = mode
        totalDuration = duration
        remainingTime = duration
        sessionStartTime = startDate
        currentPhase = .work
        
        // Save to CoreData
        coreData.save()
        
        startPhase(.work, duration: duration)

        updateState(.running)
        
        NotificationCenter.default.post(name: .sessionStarted, object: nil, userInfo: ["sessionId": session.id ?? UUID()])
        
        print("Session started: \(duration)s, mode: \(mode.rawValue)")
    }

    func startSession(template: PomodoroTemplateModel, taskId: UUID? = nil, mode: FocusMode = .casual, cycles: Int? = nil) {
        guard state == .idle else {
            print("Cannot start session: Already active")
            return
        }

        currentTemplate = template
        totalCycles = max(1, cycles ?? Int(template.cyclesBeforeLongBreak))
        currentCycle = 1
        plannedWorkDuration = template.workDuration * Double(totalCycles)

        startSession(duration: template.workDuration, taskId: taskId, mode: mode, plannedWork: plannedWorkDuration)
    }

    func completeSession() {
        guard let session = currentSessionEntity else {
            print("No active session to complete")
            return
        }
        
        guard state == .running else {
            cleanupToIdle()
            return
        }
        
        stopTimer()
        
        session.wasCompleted = true
        session.endTime = Date()
        
        // Calculate points based on focus mode
        let baseCredits = calculateCredits()
        let multiplier = focusMode == .hardcore ? 2 : 1
        let totalCredits = baseCredits * multiplier
        
        session.creditsEarned = Int32(totalCredits)
        
        coreData.save()
        
        // Rewards
        SocialCreditService.shared.addPoints(totalCredits, reason: "completed_session")
        let achievementsUnlocked = AchievementsService.shared.check(
            afterSession: session,
            context: .init(
                usedTemplate: currentTemplate != nil,
                completedCycles: currentCycle,
                totalCycles: totalCycles,
                plannedWorkDuration: plannedWorkDuration
            )
        )
        
        updateState(.completed)
        
        // Post notification for other services
        NotificationCenter.default.post(
            name: .sessionCompleted,
            object: nil,
            userInfo: [
                "sessionId": session.id ?? UUID(),
                "points": totalCredits,
                "taskId": associatedTaskId as Any,
                "achievementsUnlocked": achievementsUnlocked.map { $0.id }
            ]
        )
        
        onSessionComplete?()
        
        print("Session completed: +\(totalCredits) points")
        
        cleanupToIdle()
    }
    

    func failSession(reason: String = "Session interrupted") {
        guard let session = currentSessionEntity else {
            print("No active session to fail")
            return
        }
        
        guard state == .running else {
            cleanupToIdle()
            return
        }
        
        stopTimer()
        
        session.wasCompleted = false
        session.creditsEarned = 0
        session.endTime = Date()
        
        coreData.save()
        
        // Penalty
        SocialCreditService.shared.removePoints(15, reason: reason)
        
        updateState(.failed)
        
        // Post notification for penalties
        NotificationCenter.default.post(
            name: .sessionFailed,
            object: nil,
            userInfo: [
                "sessionId": session.id ?? UUID(),
                "reason": reason
            ]
        )
        
        onSessionFail?(reason)
        
        print("Session failed: \(reason)")
        
        cleanupToIdle()
    }
    
    func stopSession() {
        guard state != .idle else { return }
        
        guard state == .running else {
            cleanupToIdle()
            return
        }
        
        let elapsed = Date().timeIntervalSince(sessionStartTime ?? Date())
        if elapsed <= gracePeriod {
            cancelWithinGrace()
        } else {
            failSession(reason: "Session aborted")
        }
    }
    

    func getCurrentSession() -> TimerSession? {
        return currentSessionEntity
    }
    
    func getCompletedSessions() -> [TimerSession] {
        let predicate = NSPredicate(format: "wasCompleted == true")
        let sort = [NSSortDescriptor(key: "startTime", ascending: false)]
        return coreData.fetch(TimerSession.self, predicate: predicate, sortDescriptors: sort)
    }
    
    
    func getSessions(forTask taskId: UUID) -> [TimerSession] {
        let predicate = NSPredicate(format: "taskId == %@", taskId as CVarArg)
        let sort = [NSSortDescriptor(key: "startTime", ascending: false)]
        return coreData.fetch(TimerSession.self, predicate: predicate, sortDescriptors: sort)
    }
    
    
    func getTotalFocusTime(days: Int) -> TimeInterval {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = NSPredicate(format: "wasCompleted == true AND startTime >= %@", startDate as CVarArg)
        
        let sessions = coreData.fetch(TimerSession.self, predicate: predicate)
        
        return sessions.reduce(0) { total, session in
            return total + TimeInterval(session.duration)
        }
    }
    
    
    private func startPhase(_ phase: SessionPhase, duration: TimeInterval) {
        stopTimer()

        currentPhase = phase
        totalDuration = duration
        remainingTime = duration

        onPhaseChange?(phase)
        onTick?(remainingTime)

        startTimer()
    }

    private func startTimer() {
        let queue = DispatchQueue(label: "com.comrade.timer", qos: .userInteractive)
        let timer = DispatchSource.makeTimerSource(queue: queue)
        
        timer.schedule(deadline: .now(), repeating: 1.0)
        timer.setEventHandler { [weak self] in
            self?.timerTick()
        }
        
        timer.resume()
        self.timer = timer
    }
    
    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }
    
    private func timerTick() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.remainingTime -= 1
            self.onTick?(self.remainingTime)
            
            if self.remainingTime <= 0 {
                self.handlePhaseCompletion()
            }
        }
    }
    
    private func handlePhaseCompletion() {
        switch currentPhase {
        case .work:
            guard let template = currentTemplate else {
                completeSession()
                return
            }
            
            if currentCycle >= totalCycles {
                if template.longBreakDuration > 0 {
                    startPhase(.longBreak, duration: template.longBreakDuration)
                } else {
                    completeSession()
                }
            } else {
                if template.shortBreakDuration > 0 {
                    startPhase(.shortBreak, duration: template.shortBreakDuration)
                } else {
                    currentCycle += 1
                    startPhase(.work, duration: template.workDuration)
                }
            }
        case .shortBreak:
            currentCycle += 1
            if let template = currentTemplate {
                startPhase(.work, duration: template.workDuration)
            } else {
                completeSession()
            }
        case .longBreak:
            completeSession()
        }
    }
    
    private func calculateCredits() -> Int {
        // Base points: 1 point per minute of planned focus
        let minutes = Int(plannedWorkDuration / 60)
        return max(minutes, 1)
    }
    
    private func updateState(_ newState: TimerState) {
        state = newState
        onStateChange?(newState)
    }
    
    private func cancelWithinGrace() {
        stopTimer()
        
        if let session = currentSessionEntity {
            coreData.delete(session)
        }
        
        updateState(.idle)
        cleanupState()
        print("Session canceled within grace period")
    }
    
    private func cleanupToIdle() {
        stopTimer()
        cleanupState()
        updateState(.idle)
    }
    
    private func cleanupState() {
        currentSessionEntity = nil
        associatedTaskId = nil
        sessionStartTime = nil
        remainingTime = 0
        totalDuration = 0
        currentTemplate = nil
        totalCycles = 1
        currentCycle = 1
        plannedWorkDuration = 0
    }
        
    private func setupNotificationObservers() {
        // Hardcore mode: fail session if app goes to background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    @objc private func appWillResignActive() {
        if focusMode == .hardcore && state == .running {
            let elapsed = Date().timeIntervalSince(sessionStartTime ?? Date())
            if elapsed <= gracePeriod {
                cancelWithinGrace()
            } else {
                failSession(reason: "Left app in hardcore mode")
            }
        }
    }
}

extension Notification.Name {
    static let sessionCompleted = Notification.Name("sessionCompleted")
    static let sessionFailed = Notification.Name("sessionFailed")
    static let sessionStarted = Notification.Name("sessionStarted")
    static let socialCreditChanged = Notification.Name("socialCreditChanged")
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}
