//
//  SettingsRowView.swift
//  Comrade
//
//  Created by Savelii Kozlov on 12.12.2025.
//

import UIKit
import SnapKit

final class SettingsRowView: UIView {
    
    var onTap: (() -> Void)?
    
    // UI Elements
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .label
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        return label
    }()
    
    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        imageView.image = UIImage(systemName: "chevron.right", withConfiguration: config)
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    // Init
    
    init(title: String, value: String = "") {
        super.init(frame: .zero)
        titleLabel.text = title
        valueLabel.text = value
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Setup
    
    private func setupUI() {
        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(chevronImageView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        chevronImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 12, height: 12))
        }
        
        valueLabel.snp.makeConstraints { make in
            make.trailing.equalTo(chevronImageView.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(16)
        }
    }
    
    // Public Methods
    
    func setValue(_ value: String) {
        valueLabel.text = value
    }
    
    func getValue() -> String {
        return valueLabel.text ?? ""
    }
    
    // Actions
    
    @objc private func handleTap() {
        onTap?()
    }
}
