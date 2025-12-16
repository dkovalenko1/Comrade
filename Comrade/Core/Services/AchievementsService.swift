import Foundation
import CoreData

final class AchievementsService {

    static let shared = AchievementsService()

    private let coreData = CoreDataStack.shared
    private let sessionService = SessionService.shared
    private let taskService = TaskService.shared
    private let templateService = TemplateService.shared

    private init() {
        CoreDataStack.shared.performBackground { [weak self] context in
            self?.seedIfNeeded(in: context)
        }
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
        evaluateAchievements(session: nil, context: nil, completedTask: task, managedObjectContext: coreData.context)
    }

    /// Async variant to avoid blocking the main queue; completion called on main.
    func refreshAllAsync(task: TaskEntity? = nil, completion: (([Achievement]) -> Void)? = nil) {
        let taskID = task?.objectID
        coreData.performBackground { [weak self] context in
            guard let self else { return }
            let backgroundTask = taskID.flatMap { context.object(with: $0) as? TaskEntity }
            let unlocked = self.evaluateAchievements(
                session: nil,
                context: nil,
                completedTask: backgroundTask,
                managedObjectContext: context
            )
            if let completion {
                DispatchQueue.main.async {
                    completion(unlocked)
                }
            }
        }
    }

    func resetAllAchievements(completion: ((Bool) -> Void)? = nil) {
        coreData.performBackground { context in
            let request: NSFetchRequest<AchievementEntity> = AchievementEntity.fetchRequest()
            let entities = (try? context.fetch(request)) ?? []
            entities.forEach { context.delete($0) }

            self.seedIfNeeded(in: context)

            DispatchQueue.main.async {
                completion?(true)
            }
        }
    }

    private func evaluateAchievements(
        session: TimerSession?,
        context: SessionAchievementContext?,
        completedTask: TaskEntity?,
        managedObjectContext: NSManagedObjectContext? = nil
    ) -> [Achievement] {
        let workingContext = managedObjectContext ?? coreData.context
        let request: NSFetchRequest<AchievementEntity> = AchievementEntity.fetchRequest()
        let achievements = (try? workingContext.fetch(request)) ?? []
        var unlockedNow: [Achievement] = []

        achievements.forEach { entity in
            guard var model = map(entity: entity) else { return }
            guard model.isUnlocked == false else { return }

            let shouldUnlock = shouldUnlockAchievement(
                id: model.id,
                session: session,
                context: context,
                task: completedTask,
                managedObjectContext: workingContext
            )

            if shouldUnlock {
                model.isUnlocked = true
                model.unlockedAt = Date()
                model.progress = max(model.progress, model.target)
                apply(model: model, to: entity)
                coreData.save(context: workingContext)

                if let unlockedModel = map(entity: entity) {
                    unlockedNow.append(unlockedModel)
                    let post = {
                        NotificationCenter.default.post(
                            name: .achievementUnlocked,
                            object: nil,
                            userInfo: ["id": unlockedModel.id]
                        )
                    }
                    if Thread.isMainThread {
                        post()
                    } else {
                        DispatchQueue.main.async { post() }
                    }
                }
            } else {
                // Update progress where applicable
                model.progress = progressValue(
                    for: model.id,
                    session: session,
                    context: context,
                    task: completedTask,
                    managedObjectContext: workingContext
                )
                apply(model: model, to: entity)
                coreData.save(context: workingContext)
            }
        }

        return unlockedNow
    }


    private func seedIfNeeded() {
        seedIfNeeded(in: coreData.context)
    }

    private func seedIfNeeded(in context: NSManagedObjectContext) {
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

        let existingRequest: NSFetchRequest<AchievementEntity> = AchievementEntity.fetchRequest()
        let existing = (try? context.fetch(existingRequest)) ?? []
        let existingIds = Set(existing.compactMap { $0.id })

        presets.forEach { model in
            guard existingIds.contains(model.id) == false else { return }
            guard let entity = NSEntityDescription.insertNewObject(forEntityName: "AchievementEntity", into: context) as? AchievementEntity else { return }
            apply(model: model, to: entity)
        }

        if context.hasChanges {
            coreData.save(context: context)
        }
    }

    private func shouldUnlockAchievement(
        id: String,
        session: TimerSession?,
        context: SessionAchievementContext?,
        task: TaskEntity?,
        managedObjectContext: NSManagedObjectContext?
    ) -> Bool {
        let fetchContext = managedObjectContext
        switch id {
        case "first_blood":
            return session != nil
        case "dedicated":
            return currentStreak(context: fetchContext) >= 7
        case "marathon":
            return totalFocusHours(context: fetchContext) >= 50
        case "night_owl":
            return session.map { isNight(session: $0) } ?? false
        case "early_bird":
            return session.map { isEarly(session: $0) } ?? false
        case "productive":
            return totalCompletedTasks(context: fetchContext) >= 100
        case "inbox_zero":
            return activeTasksCount(context: fetchContext) == 0
        case "deadline_hero":
            return task.map { completedBeforeDeadline($0) } ?? false
        case "mentor":
            return totalCompletedSessions(context: fetchContext) >= 50
        case "focus_25":
            let duration = context?.plannedWorkDuration ?? TimeInterval(session?.duration ?? 0)
            return duration >= 25 * 60
        case "collector":
            return customTemplatesCount(context: fetchContext) >= 10
        case "polisher":
            return editedCustomTemplatesCount(context: fetchContext) >= 3
        case "streak_5":
            return consecutiveDaysWith(minSessionsPerDay: 3, context: fetchContext) >= 5
        default:
            return false
        }
    }

    private func currentStreak(context: NSManagedObjectContext?) -> Int {
        let sessions = completedSessions(in: context)
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

    private func totalFocusHours(context: NSManagedObjectContext?) -> Double {
        let sessions = completedSessions(in: context, limitDays: 365)
        let seconds = sessions.reduce(0) { $0 + TimeInterval($1.duration) }
        return seconds / 3600.0
    }

    private func totalCompletedSessions(context: NSManagedObjectContext?) -> Int {
        completedSessions(in: context).count
    }

    private func longestSessionMinutes(context: NSManagedObjectContext? = nil) -> Double {
        let sessions = completedSessions(in: context)
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

    private func activeTasksCount(context: NSManagedObjectContext?) -> Int {
        let context = context ?? coreData.context
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == NO")
        return (try? context.count(for: request)) ?? 0
    }

    private func totalCompletedTasks(context: NSManagedObjectContext?) -> Int {
        let context = context ?? coreData.context
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == YES")
        return (try? context.count(for: request)) ?? 0
    }

    private func completedBeforeDeadline(_ task: TaskEntity) -> Bool {
        guard
            task.isCompleted,
            let deadline = task.deadline,
            let completedAt = task.completedAt
        else { return false }

        return deadline.timeIntervalSince(completedAt) >= 5 * 60
    }

    private func customTemplatesCount(context: NSManagedObjectContext?) -> Int {
        let context = context ?? coreData.context
        let request: NSFetchRequest<PomodoroTemplate> = PomodoroTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "isPreset == NO")
        return (try? context.count(for: request)) ?? 0
    }

    private func editedCustomTemplatesCount(context: NSManagedObjectContext?) -> Int {
        let context = context ?? coreData.context
        let request: NSFetchRequest<PomodoroTemplate> = PomodoroTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "isPreset == NO AND updatedAt > createdAt")
        return (try? context.count(for: request)) ?? 0
    }

    private func consecutiveDaysWith(minSessionsPerDay: Int, context: NSManagedObjectContext?) -> Int {
        let sessions = completedSessions(in: context)
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
        task: TaskEntity?,
        managedObjectContext: NSManagedObjectContext?
    ) -> Double {
        let fetchContext = managedObjectContext
        switch id {
        case "marathon":
            return totalFocusHours(context: fetchContext)
        case "dedicated":
            return Double(currentStreak(context: fetchContext))
        case "productive":
            return Double(totalCompletedTasks(context: fetchContext))
        case "mentor":
            return Double(totalCompletedSessions(context: fetchContext))
        case "focus_25":
            return longestSessionMinutes(context: fetchContext)
        case "collector":
            return Double(customTemplatesCount(context: fetchContext))
        case "polisher":
            return Double(editedCustomTemplatesCount(context: fetchContext))
        case "inbox_zero":
            return activeTasksCount(context: fetchContext) == 0 ? 1 : 0
        case "deadline_hero":
            return task.map { completedBeforeDeadline($0) ? 1.0 : 0.0 } ?? 0
        case "streak_5":
            return Double(consecutiveDaysWith(minSessionsPerDay: 3, context: fetchContext))
        default:
            return 0
        }
    }

    private func completedSessions(in context: NSManagedObjectContext?, limitDays: Int? = nil) -> [TimerSession] {
        let context = context ?? coreData.context
        let request: NSFetchRequest<TimerSession> = TimerSession.fetchRequest()
        var predicates: [NSPredicate] = [NSPredicate(format: "wasCompleted == YES")]

        if let limitDays {
            let startDate = Calendar.current.date(byAdding: .day, value: -limitDays, to: Date()) ?? Date()
            predicates.append(NSPredicate(format: "startTime >= %@", startDate as CVarArg))
        }

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]

        return (try? context.fetch(request)) ?? []
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
