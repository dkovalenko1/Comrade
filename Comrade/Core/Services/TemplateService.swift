//
//  TemplateService.swift
//  Comrade
//
//  Created by Bohdan Hupalo on 15.12.2025.
//


import Foundation
import CoreData

final class TemplateService {
    
    static let shared = TemplateService()
    private let coreDataStack = CoreDataStack.shared
    
    private init() {
        seedDefaultTemplatesIfNeeded()
    }
    
    func getPresetTemplates() -> [PomodoroTemplate] {
        let predicate = NSPredicate(format: "isCustom == NO")
        let sort = NSSortDescriptor(key: "workDuration", ascending: true)
        return coreDataStack.fetch(PomodoroTemplate.self, predicate: predicate, sortDescriptors: [sort])
    }
    
    func getCustomTemplates() -> [PomodoroTemplate] {
        let predicate = NSPredicate(format: "isCustom == YES")
        let sort = NSSortDescriptor(key: "name", ascending: true)
        return coreDataStack.fetch(PomodoroTemplate.self, predicate: predicate, sortDescriptors: [sort])
    }
    
    func createCustomTemplate(name: String, work: Int, short: Int, long: Int, cycles: Int) -> PomodoroTemplate {
        let template: PomodoroTemplate = coreDataStack.create(PomodoroTemplate.self)
        template.id = UUID()
        template.name = name
        template.workDuration = Int32(work)
        template.shortBreakDuration = Int32(short)
        template.longBreakDuration = Int32(long)
        template.cycles = Int32(cycles)
        template.isCustom = true
        
        saveContext()
        return template
    }
    
    func updateTemplate(_ template: PomodoroTemplate) {
        if template.managedObjectContext == coreDataStack.context {
            saveContext()
        }
    }
    
    func deleteTemplate(id: UUID) {
        guard let template = getTemplate(id: id) else { return }
    
        guard template.isCustom else { return }
        
        coreDataStack.delete(template)
        saveContext()
    }
    
    func getTemplate(id: UUID) -> PomodoroTemplate? {
        let predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return coreDataStack.fetchFirst(PomodoroTemplate.self, predicate: predicate)
    }

    
    private func saveContext() {
        coreDataStack.save()
        NotificationCenter.default.post(name: .templatesUpdated, object: nil)
    }
    
    private func seedDefaultTemplatesIfNeeded() {
        let presets = getPresetTemplates()
        guard presets.isEmpty else { return }
        
        let defaults: [(name: String, work: Int, short: Int, long: Int, cycles: Int)] = [
            ("Classic", 25, 5, 15, 4),
            ("Deep Work", 50, 10, 20, 3),
            ("Sprint", 15, 3, 10, 4),
            ("Student", 45, 15, 30, 2)
        ]
        
        for data in defaults {
            let template: PomodoroTemplate = coreDataStack.create(PomodoroTemplate.self)
            template.id = UUID()
            template.name = data.name
            template.workDuration = Int32(data.work)
            template.shortBreakDuration = Int32(data.short)
            template.longBreakDuration = Int32(data.long)
            template.cycles = Int32(data.cycles)
            template.isCustom = false
        }
        
        coreDataStack.save()
    }
}

extension Notification.Name {
    static let templatesUpdated = Notification.Name("templatesUpdated")
}
