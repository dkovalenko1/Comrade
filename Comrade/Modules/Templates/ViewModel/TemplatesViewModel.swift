import Foundation
import UIKit

enum TemplateListItem {
    case preset(PomodoroTemplate)
    case custom(PomodoroTemplate)
    case createCustom
    
    var id: String {
        switch self {
        case .preset(let t): return t.id?.uuidString ?? ""
        case .custom(let t): return t.id?.uuidString ?? ""
        case .createCustom: return "create_custom"
        }
    }
}

final class TemplatesViewModel {
    
    private let templateService = TemplateService.shared
    
    // Data Source
    private(set) var items: [TemplateListItem] = []
    
    // State
    private(set) var expandedItemId: String? = nil
    
    // Output
    var onDataUpdated: (() -> Void)?
    
    init() {
        setupObservers()
        loadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUpdates),
            name: .templatesUpdated,
            object: nil
        )
    }
    
    @objc private func handleUpdates() {
        loadData()
    }
    
    func loadData() {
        var newItems: [TemplateListItem] = []
        
        let presets = templateService.getPresetTemplates()
        newItems.append(contentsOf: presets.map { .preset($0) })
        
        let customs = templateService.getCustomTemplates()
        newItems.append(contentsOf: customs.map { .custom($0) })
        
        newItems.append(.createCustom)
        
        self.items = newItems
        onDataUpdated?()
    }
    
    func toggleExpansion(for item: TemplateListItem) {
        if expandedItemId == item.id {
            expandedItemId = nil // Collapse
        } else {
            expandedItemId = item.id // Expand
        }
        onDataUpdated?()
    }
    
    func isExpanded(_ item: TemplateListItem) -> Bool {
        return item.id == expandedItemId
    }
    
    // MARK: - Helpers
    
    func getDetails(for item: TemplateListItem) -> (title: String, subtitle: String, details: String?, icon: String, button: String) {
        switch item {
        case .preset(let t), .custom(let t):
            let total = (Int(t.workDuration) + Int(t.shortBreakDuration)) * Int(t.cycles)
            let subtitle = "\(total) minutes"
            
            var pattern = ""
            for i in 1...t.cycles {
                pattern += "\(t.workDuration)-"
                if i < t.cycles {
                    pattern += "\(t.shortBreakDuration)-"
                } else {
                    pattern += "\(t.longBreakDuration)"
                }
            }
            
            let details = """
            - Work: \(t.workDuration) min
            - Short break: \(t.shortBreakDuration) min
            - Long break: \(t.longBreakDuration) min (after \(t.cycles) cycles)
            - Pattern: \(pattern)
            """
            
            let icon: String
            switch t.name {
            case "Classic": icon = "list.bullet.clipboard"
            case "Deep Work": icon = "brain.head.profile"
            case "Sprint": icon = "bolt.fill"
            case "Student": icon = "graduationcap.fill"
            default: icon = "slider.horizontal.3"
            }
            
            return (t.name ?? "Unknown", subtitle, details, icon, "Use this template")
            
        case .createCustom:
            return ("Custom", "Create your own", "Adjust work duration, breaks, and intervals to fit your workflow.", "slider.horizontal.3", "Create template")
        }
    }
}
