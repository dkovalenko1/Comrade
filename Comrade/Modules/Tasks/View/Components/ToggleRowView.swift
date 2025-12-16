//
//  ToggleRowView.swift
//  Comrade
//
//  Created by Savelii Kozlov on 12.12.2025.
//

import UIKit

final class ToggleRowView: UIView {

    var onToggle: ((Bool) -> Void)?
    
    // Properties
    
    var isOn: Bool {
        get { toggle.isOn }
        set { toggle.isOn = newValue }
    }
    
    // UI Elements
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label
        return label
    }()
    
    private lazy var toggle: UISwitch = {
        let toggle = UISwitch()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.onTintColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)
        return toggle
    }()
    
    // Init
    
    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Setup
    
    private func setupUI() {
        addSubview(titleLabel)
        addSubview(toggle)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            toggle.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            toggle.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    
    // Actions
    
    @objc private func toggleChanged() {
        onToggle?(toggle.isOn)
    }
}
