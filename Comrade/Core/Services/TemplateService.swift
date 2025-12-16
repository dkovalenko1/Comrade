import Foundation
import CoreData

final class TemplateService {

    static let shared = TemplateService()
    private let coreData = CoreDataStack.shared

    private init() {
        seedPresetsIfNeeded()
    }

    func getAllTemplates() -> [PomodoroTemplateModel] {
        let sort = [NSSortDescriptor(key: "isPreset", ascending: false),
                    NSSortDescriptor(key: "createdAt", ascending: true)]
        return coreData.fetch(PomodoroTemplate.self, sortDescriptors: sort).compactMap { PomodoroTemplateModel(entity: $0) }
    }

    func getPresetTemplates() -> [PomodoroTemplateModel] {
        let predicate = NSPredicate(format: "isPreset == YES")
        let sort = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return coreData.fetch(PomodoroTemplate.self, predicate: predicate, sortDescriptors: sort).compactMap { PomodoroTemplateModel(entity: $0) }
    }

    func getTemplate(id: UUID) -> PomodoroTemplateModel? {
        let predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return coreData.fetchFirst(PomodoroTemplate.self, predicate: predicate).flatMap { PomodoroTemplateModel(entity: $0) }
    }

    @discardableResult
    func upsert(_ template: PomodoroTemplateModel) -> PomodoroTemplateModel {
        let entity: PomodoroTemplate
        if let existing = findEntity(id: template.id) {
            entity = existing
        } else {
            entity = coreData.create(PomodoroTemplate.self)
        }

        template.apply(to: entity)
        entity.updatedAt = Date()
        coreData.save()
        NotificationCenter.default.post(name: .templatesChanged, object: nil)
        return PomodoroTemplateModel(entity: entity) ?? template
    }

    func delete(id: UUID) {
        guard let entity = findEntity(id: id) else { return }
        coreData.delete(entity)
        NotificationCenter.default.post(name: .templatesChanged, object: nil)
    }


    private func findEntity(id: UUID) -> PomodoroTemplate? {
        let predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return coreData.fetchFirst(PomodoroTemplate.self, predicate: predicate)
    }

    private func seedPresetsIfNeeded() {
        let existingPresets = getPresetTemplates()
        guard existingPresets.isEmpty else { return }

        let presets: [PomodoroTemplateModel] = [
            .init(name: "Classic", icon: "📚", workDuration: 25 * 60, shortBreakDuration: 5 * 60, longBreakDuration: 15 * 60, cyclesBeforeLongBreak: 4, isPreset: true),
            .init(name: "Deep Work", icon: "🧠", workDuration: 50 * 60, shortBreakDuration: 10 * 60, longBreakDuration: 20 * 60, cyclesBeforeLongBreak: 3, isPreset: true),
            .init(name: "Sprint", icon: "⚡️", workDuration: 15 * 60, shortBreakDuration: 3 * 60, longBreakDuration: 10 * 60, cyclesBeforeLongBreak: 4, isPreset: true),
            .init(name: "Student", icon: "🎓", workDuration: 45 * 60, shortBreakDuration: 15 * 60, longBreakDuration: 30 * 60, cyclesBeforeLongBreak: 2, isPreset: true)
        ]

        presets.forEach { upsert($0) }
    }
}

extension Notification.Name {
    static let templatesChanged = Notification.Name("templatesChanged")
}
