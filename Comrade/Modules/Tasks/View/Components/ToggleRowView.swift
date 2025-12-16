//
//  ToggleRowView.swift
//  Comrade
//
//  Created by Savelii Kozlov on 12.12.2025.
//

import UIKit
import SnapKit

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
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label
        return label
    }()
    
    private lazy var toggle: UISwitch = {
        let toggle = UISwitch()
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
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        toggle.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }
    
    // Actions
    
    @objc private func toggleChanged() {
        onToggle?(toggle.isOn)
    }
}
