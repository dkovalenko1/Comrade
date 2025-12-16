import Foundation

final class AchievementsViewModel {

    private let service = AchievementsService.shared
    private(set) var achievements: [Achievement] = []

    var onUpdate: (() -> Void)?

    func load() {
        achievements = service.all()
        onUpdate?()
    }

    func achievement(at index: Int) -> Achievement? {
        guard achievements.indices.contains(index) else { return nil }
        return achievements[index]
    }

    func progressText(for achievement: Achievement) -> String {
        if achievement.target <= 0 { return achievement.isUnlocked ? "Completed" : "Locked" }
        if achievement.isUnlocked { return "Completed" }
        let value = max(0, achievement.progress)
        return String(format: "%.0f / %.0f", value, achievement.target)
    }

    func progressValue(for achievement: Achievement) -> Float {
        guard achievement.target > 0 else { return achievement.isUnlocked ? 1 : 0 }
        let ratio = Float(achievement.progress / achievement.target)
        return max(0, min(ratio, 1))
    }
}
