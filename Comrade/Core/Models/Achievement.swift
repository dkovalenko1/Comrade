import Foundation

enum AchievementCategory: String {
    case focusTime
    case tasksCompleted
    case streaks
    case special
}

struct Achievement: Identifiable {
    let id: String
    var title: String
    var detail: String
    var icon: String
    var category: AchievementCategory
    var target: Double
    var progress: Double
    var isUnlocked: Bool
    var unlockedAt: Date?

    init(
        id: String,
        title: String,
        detail: String,
        icon: String,
        category: AchievementCategory,
        target: Double,
        progress: Double = 0,
        isUnlocked: Bool = false,
        unlockedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.icon = icon
        self.category = category
        self.target = target
        self.progress = progress
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
    }
}
