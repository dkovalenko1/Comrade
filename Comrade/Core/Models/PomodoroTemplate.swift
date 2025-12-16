import Foundation
import CoreData

struct PomodoroTemplateModel: Identifiable {
    let id: UUID
    var name: String
    var icon: String
    var workDuration: TimeInterval
    var shortBreakDuration: TimeInterval
    var longBreakDuration: TimeInterval
    var cyclesBeforeLongBreak: Int
    var isPreset: Bool
    var createdAt: Date
    var updatedAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        workDuration: TimeInterval,
        shortBreakDuration: TimeInterval,
        longBreakDuration: TimeInterval,
        cyclesBeforeLongBreak: Int,
        isPreset: Bool,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.workDuration = workDuration
        self.shortBreakDuration = shortBreakDuration
        self.longBreakDuration = longBreakDuration
        self.cyclesBeforeLongBreak = cyclesBeforeLongBreak
        self.isPreset = isPreset
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init?(entity: PomodoroTemplate) {
        guard
            let id = entity.id,
            let name = entity.name,
            let icon = entity.icon,
            let createdAt = entity.createdAt
        else { return nil }

        self.id = id
        self.name = name
        self.icon = icon
        self.workDuration = TimeInterval(entity.workDuration)
        self.shortBreakDuration = TimeInterval(entity.shortBreakDuration)
        self.longBreakDuration = TimeInterval(entity.longBreakDuration)
        self.cyclesBeforeLongBreak = Int(entity.cyclesBeforeLongBreak)
        self.isPreset = entity.isPreset
        self.createdAt = createdAt
        self.updatedAt = entity.updatedAt
    }

    func apply(to entity: PomodoroTemplate) {
        entity.id = id
        entity.name = name
        entity.icon = icon
        entity.workDuration = Int32(workDuration)
        entity.shortBreakDuration = Int32(shortBreakDuration)
        entity.longBreakDuration = Int32(longBreakDuration)
        entity.cyclesBeforeLongBreak = Int16(cyclesBeforeLongBreak)
        entity.isPreset = isPreset
        entity.createdAt = createdAt
        entity.updatedAt = updatedAt
    }
}
