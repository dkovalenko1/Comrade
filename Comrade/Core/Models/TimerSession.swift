import Foundation
import CoreData

extension TimerSession {

    // MARK: - Computed Properties

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var focusModeEnum: FocusMode {
        return FocusMode(rawValue: focusMode ?? "casual") ?? .casual
    }

    var pointsMultiplier: Int {
        return focusModeEnum == .hardcore ? 2 : 1
    }

    var formattedStartTime: String {
        guard let startTime = startTime else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }

    var statusEmoji: String {
        return wasCompleted ? "✅" : "❌"
    }


    /// Check if session was today
    func isToday() -> Bool {
        guard let startTime = startTime else { return false }
        return Calendar.current.isDateInToday(startTime)
    }

    /// Check if session was in last N days
    func isInLastDays(_ days: Int) -> Bool {
        guard let startTime = startTime else { return false }
        let daysAgo = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return startTime >= daysAgo
    }
}
