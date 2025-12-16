//
//  TemplateEditorViewModel.swift
//  Comrade
//
//  Created by Bohdan Hupalo on 15.12.2025.
//


import Foundation

final class TemplateEditorViewModel {
    
    private let templateService = TemplateService.shared
    
    // MARK: - Properties
    
    var name: String = ""
    var icon: String = "🍅"
    
    var workDuration: Int = 25
    var shortBreakDuration: Int = 5
    var longBreakDuration: Int = 15
    var cycles: Int = 4
    
    var onPatternUpdate: ((String) -> Void)?
    var onError: ((String) -> Void)?
    var onSaveSuccess: (() -> Void)?
    
    let availableEmojis = ["🍅", "⚡", "🧠", "📚", "🏋️", "🧘", "💻", "🎨", "🎵", "🎓", "💼", "🏠"]
    
    init() {
        updatePattern()
    }
    
    // MARK: - Logic
    
    func updatePattern() {
        var pattern = ""
        
        for i in 1...cycles {
            pattern += "\(workDuration)-"
            if i < cycles {
                pattern += "\(shortBreakDuration)-"
            } else {
                pattern += "\(longBreakDuration)"
            }
        }
        
        onPatternUpdate?(pattern)
    }
    
    func validate() -> Bool {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            onError?("Please enter a template name")
            return false
        }
        
        if workDuration <= shortBreakDuration {
            onError?("Work duration must be longer than short break")
            return false
        }
        
        if longBreakDuration <= shortBreakDuration {
            onError?("Long break must be longer than short break")
            return false
        }
        
        return true
    }
    
    func save() {
        guard validate() else { return }
        
        // append the icon to the name
        let finalName = "\(icon) \(name)"
        
        _ = templateService.createCustomTemplate(
            name: finalName,
            work: workDuration,
            short: shortBreakDuration,
            long: longBreakDuration,
            cycles: cycles
        )
        
        onSaveSuccess?()
    }
}
