//
//  TaskSectionHeaderView.swift
//  Comrade
//
//  Created by Savelii Kozlov on 11.12.2025.
//

import UIKit

final class TaskSectionHeaderView: UITableViewHeaderFooterView {
        
    static let identifier = "TaskSectionHeaderView"
        
    var onHeaderTapped: (() -> Void)?
    
    // UI Elements
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let iconView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 0.15)
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        imageView.image = UIImage(systemName: "list.bullet", withConfiguration: config)
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        return label
    }()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray3
        
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        imageView.image = UIImage(systemName: "chevron.down", withConfiguration: config)
        return imageView
    }()
    
    private lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(headerTapped))
        return gesture
    }()
    
    // Init
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        countLabel.text = nil
        onHeaderTapped = nil
    }
    
    // Setup
    
    private func setupUI() {
        contentView.backgroundColor = .clear
        
        contentView.addSubview(containerView)
        containerView.addSubview(iconView)
        iconView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(countLabel)
        containerView.addSubview(chevronImageView)
        
        containerView.addGestureRecognizer(tapGesture)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 32),
            iconView.heightAnchor.constraint(equalToConstant: 32),
            
            iconImageView.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 16),
            iconImageView.heightAnchor.constraint(equalToConstant: 16),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            countLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 4),
            countLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            chevronImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            chevronImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 16),
            chevronImageView.heightAnchor.constraint(equalToConstant: 16),
        ])
    }
    
    // Configuration
    
    func configure(title: String, count: Int, isExpanded: Bool) {
        titleLabel.text = title
        countLabel.text = "\(count)"
        
        // Animate chevron rotation
        UIView.animate(withDuration: 0.2) {
            if isExpanded {
                self.chevronImageView.transform = .identity
            } else {
                self.chevronImageView.transform = CGAffineTransform(rotationAngle: -.pi / 2)
            }
        }
    }
    
    // Actions
    
    @objc private func headerTapped() {
        onHeaderTapped?()
        
        // Haptic feedback - can be implemented further
    }
}
