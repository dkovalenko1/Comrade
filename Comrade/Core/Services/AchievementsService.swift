import Foundation
import CoreData

final class AchievementsService {

    static let shared = AchievementsService()

    private let coreData = CoreDataStack.shared
    private let sessionService = SessionService.shared
    private let taskService = TaskService.shared
    private let templateService = TemplateService.shared

    private init() {
        seedIfNeeded()
        setupObservers()
    }

    // MARK: - Public API

    func all() -> [Achievement] {
        let sort = [NSSortDescriptor(key: "isUnlocked", ascending: false),
                    NSSortDescriptor(key: "title", ascending: true)]
        return coreData.fetch(AchievementEntity.self, sortDescriptors: sort).compactMap { map(entity: $0) }
    }

    func unlocked() -> [Achievement] {
        let predicate = NSPredicate(format: "isUnlocked == YES")
        return coreData.fetch(AchievementEntity.self, predicate: predicate).compactMap { map(entity: $0) }
    }

    struct SessionAchievementContext {
        let usedTemplate: Bool
        let completedCycles: Int
        let totalCycles: Int
        let plannedWorkDuration: TimeInterval
    }

    @discardableResult
    func check(afterSession session: TimerSession, context: SessionAchievementContext? = nil) -> [Achievement] {
        evaluateAchievements(session: session, context: context, completedTask: nil)
    }

    @discardableResult
    func checkAfterTaskCompletion(_ task: TaskEntity) -> [Achievement] {
        evaluateAchievements(session: nil, context: nil, completedTask: task)
    }

    @discardableResult
    func refreshAll(task: TaskEntity? = nil) -> [Achievement] {
        evaluateAchievements(session: nil, context: nil, completedTask: task)
    }

    func resetAllAchievements(completion: ((Bool) -> Void)? = nil) {
        let entities = coreData.fetch(AchievementEntity.self)
        entities.forEach { coreData.context.delete($0) }
        coreData.save { _ in
            self.seedIfNeeded()
            completion?(true)
        }
    }

    private func evaluateAchievements(
        session: TimerSession?,
        context: SessionAchievementContext?,
        completedTask: TaskEntity?
    ) -> [Achievement] {
        let achievements = coreData.fetch(AchievementEntity.self)
        var unlockedNow: [Achievement] = []

        achievements.forEach { entity in
            guard var model = map(entity: entity) else { return }
            guard model.isUnlocked == false else { return }

            let shouldUnlock = shouldUnlockAchievement(
                id: model.id,
                session: session,
                context: context,
                task: completedTask
            )

            if shouldUnlock {
                model.isUnlocked = true
                model.unlockedAt = Date()
                model.progress = max(model.progress, model.target)
                apply(model: model, to: entity)
                coreData.save()

                if let unlockedModel = map(entity: entity) {
                    unlockedNow.append(unlockedModel)
                    NotificationCenter.default.post(
                        name: .achievementUnlocked,
                        object: nil,
                        userInfo: ["id": unlockedModel.id]
                    )
                }
            } else {
                // Update progress where applicable
                model.progress = progressValue(
                    for: model.id,
                    session: session,
                    context: context,
                    task: completedTask
                )
                apply(model: model, to: entity)
                coreData.save()
            }
        }

        return unlockedNow
    }


    private func seedIfNeeded() {
        let presets: [Achievement] = [
            .init(id: "first_blood", title: "First Blood", detail: "Complete your first focus session", icon: "🔥", category: .focusTime, target: 1),
            .init(id: "dedicated", title: "Dedicated", detail: "Maintain a 7-day focus streak", icon: "📅", category: .streaks, target: 7),
            .init(id: "marathon", title: "Marathon", detail: "Accumulate 50 hours of focus time", icon: "🏃‍♂️", category: .focusTime, target: 50),
            .init(id: "productive", title: "Productive", detail: "Complete 100 tasks", icon: "✅", category: .tasksCompleted, target: 100),
            .init(id: "night_owl", title: "Night Owl", detail: "Complete a session after midnight", icon: "🌙", category: .special, target: 1),
            .init(id: "early_bird", title: "Early Bird", detail: "Complete a session before 8am", icon: "🌅", category: .special, target: 1),
            .init(id: "inbox_zero", title: "Clear inbox", detail: "Complete all tasks for Today", icon: "📥", category: .tasksCompleted, target: 1),
            .init(id: "deadline_hero", title: "Deadline Hero", detail: "Complete a task no later than 5 minutes from its deadline", icon: "⏰", category: .tasksCompleted, target: 1),
            .init(id: "mentor", title: "Mentor", detail: "Complete 50 focus sessions", icon: "🧠", category: .focusTime, target: 50),
            .init(id: "focus_25", title: "Focus 25", detail: "Complete session for 25 minutes", icon: "🎯", category: .focusTime, target: 25),
            .init(id: "collector", title: "Collector", detail: "Create 10 custom templates", icon: "📚", category: .special, target: 10),
            .init(id: "polisher", title: "Polisher", detail: "Edit 3 custom templates", icon: "🛠️", category: .special, target: 3),
            .init(id: "streak_5", title: "Streak 5", detail: "Complete 3 sessions per day for 5 days in a row", icon: "📆", category: .streaks, target: 5)
        ]

        let existing = coreData.fetch(AchievementEntity.self)
        let existingIds = Set(existing.compactMap { $0.id })

        presets.forEach { model in
            guard existingIds.contains(model.id) == false else { return }
            let entity = coreData.create(AchievementEntity.self)
            apply(model: model, to: entity)
        }

        if coreData.context.hasChanges {
            coreData.save()
        }
    }

    private func shouldUnlockAchievement(
        id: String,
        session: TimerSession?,
        context: SessionAchievementContext?,
        task: TaskEntity?
    ) -> Bool {
        switch id {
        case "first_blood":
            return session != nil
        case "dedicated":
            return currentStreak() >= 7
        case "marathon":
            return totalFocusHours() >= 50
        case "night_owl":
            return session.map { isNight(session: $0) } ?? false
        case "early_bird":
            return session.map { isEarly(session: $0) } ?? false
        case "productive":
            return totalCompletedTasks() >= 100
        case "inbox_zero":
            return activeTasksCount() == 0
        case "deadline_hero":
            return task.map { completedBeforeDeadline($0) } ?? false
        case "mentor":
            return totalCompletedSessions() >= 50
        case "focus_25":
            let duration = context?.plannedWorkDuration ?? TimeInterval(session?.duration ?? 0)
            return duration >= 25 * 60
        case "collector":
            return customTemplatesCount() >= 10
        case "polisher":
            return editedCustomTemplatesCount() >= 3
        case "streak_5":
            return consecutiveDaysWith(minSessionsPerDay: 3) >= 5
        default:
            return false
        }
    }

    private func currentStreak() -> Int {
        let sessions = sessionService.getCompletedSessions()
        let calendar = Calendar.current
        let days = sessions.compactMap { $0.startTime }.map { calendar.startOfDay(for: $0) }
        let uniqueDays = Array(Set(days)).sorted(by: >)

        guard let latest = uniqueDays.first else { return 0 }

        var streak = 0
        var cursor = latest

        for day in uniqueDays {
            if calendar.isDate(day, inSameDayAs: cursor) {
                streak += 1
                if let previous = calendar.date(byAdding: .day, value: -1, to: cursor) {
                    cursor = previous
                }
            } else {
                break
            }
        }

        return streak
    }

    private func totalFocusHours() -> Double {
        let seconds = sessionService.getTotalFocusTime(days: 365)
        return seconds / 3600.0
    }

    private func totalCompletedSessions() -> Int {
        sessionService.getCompletedSessions().count
    }

    private func longestSessionMinutes() -> Double {
        let sessions = sessionService.getCompletedSessions()
        let maxDuration = sessions.map { Double($0.duration) }.max() ?? 0
        return maxDuration / 60.0
    }

    private func isNight(session: TimerSession) -> Bool {
        guard let start = session.startTime else { return false }
        let hour = Calendar.current.component(.hour, from: start)
        return hour >= 0 && hour < 6
    }

    private func isEarly(session: TimerSession) -> Bool {
        guard let start = session.startTime else { return false }
        let hour = Calendar.current.component(.hour, from: start)
        return hour < 8
    }

    private func activeTasksCount() -> Int {
        taskService.getActiveTasks().count
    }

    private func totalCompletedTasks() -> Int {
        taskService.getCompletedTasks().count
    }

    private func completedBeforeDeadline(_ task: TaskEntity) -> Bool {
        guard
            task.isCompleted,
            let deadline = task.deadline,
            let completedAt = task.completedAt
        else { return false }

        return deadline.timeIntervalSince(completedAt) >= 5 * 60
    }

    private func customTemplatesCount() -> Int {
        templateService.getAllTemplates().filter { !$0.isPreset }.count
    }

    private func editedCustomTemplatesCount() -> Int {
        templateService
            .getAllTemplates()
            .filter { !$0.isPreset }
            .filter { template in
                if let updated = template.updatedAt {
                    return updated > template.createdAt
                }
                return false
            }
            .count
    }

    private func consecutiveDaysWith(minSessionsPerDay: Int) -> Int {
        let sessions = sessionService.getCompletedSessions()
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: sessions.compactMap { $0.startTime }) { date in
            calendar.startOfDay(for: date)
        }

        let qualifyingDays = grouped.filter { $0.value.count >= minSessionsPerDay }.map { $0.key }.sorted(by: >)
        guard let latest = qualifyingDays.first else { return 0 }

        var streak = 0
        var cursor = latest

        for day in qualifyingDays {
            if calendar.isDate(day, inSameDayAs: cursor) {
                streak += 1
                if let previous = calendar.date(byAdding: .day, value: -1, to: cursor) {
                    cursor = previous
                }
            } else {
                break
            }
        }

        return streak
    }

    private func progressValue(
        for id: String,
        session: TimerSession?,
        context: SessionAchievementContext?,
        task: TaskEntity?
    ) -> Double {
        switch id {
        case "marathon":
            return totalFocusHours()
        case "dedicated":
            return Double(currentStreak())
        case "productive":
            return Double(totalCompletedTasks())
        case "mentor":
            return Double(totalCompletedSessions())
        case "focus_25":
            return longestSessionMinutes()
        case "collector":
            return Double(customTemplatesCount())
        case "polisher":
            return Double(editedCustomTemplatesCount())
        case "inbox_zero":
            return activeTasksCount() == 0 ? 1 : 0
        case "deadline_hero":
            return task.map { completedBeforeDeadline($0) ? 1.0 : 0.0 } ?? 0я
        case "streak_5":
            return Double(consecutiveDaysWith(minSessionsPerDay: 3))
        default:
            return 0
        }
    }


    private func map(entity: AchievementEntity) -> Achievement? {
        guard
            let id = entity.id,
            let title = entity.title,
            let detail = entity.detail,
            let categoryRaw = entity.category,
            let category = AchievementCategory(rawValue: categoryRaw),
            let icon = entity.icon
        else { return nil }

        return Achievement(
            id: id,
            title: title,
            detail: detail,
            icon: icon,
            category: category,
            target: entity.target,
            progress: entity.progress,
            isUnlocked: entity.isUnlocked,
            unlockedAt: entity.unlockedAt
        )
    }

    private func apply(model: Achievement, to entity: AchievementEntity) {
        entity.id = model.id
        entity.title = model.title
        entity.detail = model.detail
        entity.icon = model.icon
        entity.category = model.category.rawValue
        entity.progress = model.progress
        entity.target = model.target
        entity.isUnlocked = model.isUnlocked
        entity.unlockedAt = model.unlockedAt
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            forName: .templatesChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshAll()
        }
    }
}
