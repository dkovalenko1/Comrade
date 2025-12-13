import Foundation
import UserNotifications

// NotificationService

final class NotificationService: NSObject {
    
    // Singleton
    
    static let shared = NotificationService()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    // Permission
    
    /// Requests notification permission from the user
    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                }
                completion?(granted)
            }
        }
    }
    
    /// Checks current authorization status
    func checkPermissionStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    // Schedule Notifications
    
    /// Schedules a reminder for a task at a specific date
    func scheduleReminder(for task: TaskEntity, at date: Date, title: String? = nil, body: String? = nil) {
        guard let taskId = task.id else { return }
        
        // Don't schedule notifications in the past
        guard date > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title ?? "Task Reminder"
        content.body = body ?? task.name ?? "You have a task to complete"
        content.sound = .default
        content.userInfo = ["taskId": taskId.uuidString]
        
        // Add category color badge if available
        if let category = task.category {
            content.subtitle = category
        }
        
        // Create trigger from date
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create unique identifier for this reminder
        let identifier = makeIdentifier(taskId: taskId, date: date)
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }
    
    /// Schedules a deadline reminder for a task
    func scheduleDeadlineReminder(for task: TaskEntity) {
        guard let deadline = task.deadline else { return }
        
        let body = "Deadline: \(task.name ?? "Task")"
        scheduleReminder(for: task, at: deadline, title: "Deadline Approaching", body: body)
    }
    
    /// Schedules multiple reminders for a task based on ReminderEntity objects
    func scheduleReminders(for task: TaskEntity) {
        guard let taskId = task.id,
              let reminders = task.reminders as? Set<ReminderEntity> else { return }
        
        // First, cancel existing reminders for this task
        cancelReminders(for: taskId)
        
        for reminder in reminders {
            let notificationDate: Date?
            
            if reminder.isRelative {
                // Relative reminder - calculate from deadline
                guard let deadline = task.deadline else { continue }
                notificationDate = Calendar.current.date(
                    byAdding: .minute,
                    value: -Int(reminder.relativeMinutes),
                    to: deadline
                )
            } else {
                // Absolute reminder - use the stored date
                notificationDate = reminder.absoluteDate
            }
            
            guard let date = notificationDate else { continue }
            
            scheduleReminder(
                for: task,
                at: date,
                title: "Reminder",
                body: task.name ?? "You have a task"
            )
        }
    }
    
    /// Schedules a reminder relative to deadline (e.g., 30 minutes before)
    func scheduleRelativeReminder(for task: TaskEntity, minutesBefore: Int) {
        guard let deadline = task.deadline else { return }
        
        let reminderDate = Calendar.current.date(
            byAdding: .minute,
            value: -minutesBefore,
            to: deadline
        )
        
        guard let date = reminderDate else { return }
        
        let timeDescription = formatRelativeTime(minutes: minutesBefore)
        let body = "\(task.name ?? "Task") is due in \(timeDescription)"
        
        scheduleReminder(for: task, at: date, title: "Upcoming Deadline", body: body)
    }
    
    // Cancel Notifications
    
    /// Cancels all reminders for a specific task
    func cancelReminders(for taskId: UUID) {
        notificationCenter.getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.hasPrefix(taskId.uuidString) }
                .map { $0.identifier }
            
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
    }
    
    /// Cancels a specific reminder
    func cancelReminder(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    /// Cancels all pending notifications
    func cancelAllReminders() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    // Timer Notifications
    
    /// Schedules a notification for when a timer session ends
    func scheduleTimerEndNotification(in seconds: TimeInterval, taskName: String?) {
        let content = UNMutableNotificationContent()
        content.title = "Session Complete!"
        content.body = taskName != nil ? "Great work on \(taskName!)!" : "Great work! Time for a break."
        content.sound = .default
        content.categoryIdentifier = "TIMER_COMPLETE"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "timer_session_end",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request)
    }
    
    /// Schedules a notification for when a break ends
    func scheduleBreakEndNotification(in seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Break Over!"
        content.body = "Ready to get back to work?"
        content.sound = .default
        content.categoryIdentifier = "BREAK_COMPLETE"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "timer_break_end",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request)
    }
    
    /// Cancels timer-related notifications
    func cancelTimerNotifications() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["timer_session_end", "timer_break_end"]
        )
    }
    
    // Badge Management
    
    /// Updates the app badge with the count of overdue tasks
    func updateBadgeCount(_ count: Int) {
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().setBadgeCount(count)
        }
    }
    
    /// Clears the app badge
    func clearBadge() {
        updateBadgeCount(0)
    }
    
    // Pending Notifications
    
    /// Gets all pending notification requests
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
    
    /// Gets pending notifications for a specific task
    func getPendingNotifications(for taskId: UUID, completion: @escaping ([UNNotificationRequest]) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            let taskRequests = requests.filter { $0.identifier.hasPrefix(taskId.uuidString) }
            DispatchQueue.main.async {
                completion(taskRequests)
            }
        }
    }
    
    // Helpers
    
    /// Creates a unique identifier for a notification
    private func makeIdentifier(taskId: UUID, date: Date) -> String {
        let timestamp = Int(date.timeIntervalSince1970)
        return "\(taskId.uuidString)_\(timestamp)"
    }
    
    /// Formats minutes into a readable string
    private func formatRelativeTime(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else if minutes < 1440 {
            let hours = minutes / 60
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            let days = minutes / 1440
            return "\(days) day\(days == 1 ? "" : "s")"
        }
    }
}

// UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    
    /// Called when notification is delivered while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Called when user interacts with a notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle task notification tap
        if let taskIdString = userInfo["taskId"] as? String,
           let taskId = UUID(uuidString: taskIdString) {
            // Post notification for navigation to task
            NotificationCenter.default.post(
                name: .notificationTappedForTask,
                object: nil,
                userInfo: ["taskId": taskId]
            )
        }
        
        // Handle timer notifications
        let identifier = response.notification.request.identifier
        if identifier == "timer_session_end" || identifier == "timer_break_end" {
            NotificationCenter.default.post(
                name: .timerNotificationTapped,
                object: nil,
                userInfo: ["type": identifier]
            )
        }
        
        completionHandler()
    }
}

// Notification Names

extension Notification.Name {
    static let notificationTappedForTask = Notification.Name("notificationTappedForTask")
    static let timerNotificationTapped = Notification.Name("timerNotificationTapped")
}

// Convenience Extensions

extension NotificationService {
    
    /// Common reminder intervals (in minutes)
    struct ReminderInterval {
        static let atTime = 0
        static let fiveMinutes = 5
        static let fifteenMinutes = 15
        static let thirtyMinutes = 30
        static let oneHour = 60
        static let twoHours = 120
        static let oneDay = 1440
        static let twoDays = 2880
        static let oneWeek = 10080
    }
    
    /// Schedules default reminders for a task with deadline
    func scheduleDefaultReminders(for task: TaskEntity) {
        guard task.deadline != nil else { return }
        
        // Schedule reminders at common intervals
        scheduleRelativeReminder(for: task, minutesBefore: ReminderInterval.fifteenMinutes)
        scheduleRelativeReminder(for: task, minutesBefore: ReminderInterval.oneHour)
        scheduleRelativeReminder(for: task, minutesBefore: ReminderInterval.oneDay)
    }
}
