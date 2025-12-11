//
//  TaskCell.swift
//  Comrade
//
//  Created by Savelii Kozlov on 11.12.2025.
//

import UIKit

final class TaskCell: UITableViewCell {
    
    static let identifier = "TaskCell"
    
    var onCheckboxTapped: (() -> Void)?
    
    // UI Elements
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        return view
    }()
    
    private lazy var checkboxButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(checkboxTapped), for: .touchUpInside)
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()
    
    private let categoryDot: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 4
        view.backgroundColor = .systemGray4
        return view
    }()
    
    private let deadlineLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let priorityIndicator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 3
        view.isHidden = true
        return view
    }()
    
    private let tagsStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 4
        stack.distribution = .fill
        return stack
    }()
    
    private let indicatorsStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 8
        return stack
    }()
    
    private let editButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        button.setImage(UIImage(systemName: "square.and.pencil", withConfiguration: config), for: .normal)
        button.tintColor = .systemGray3
        return button
    }()
    
    // Properties
    
    private var isTaskCompleted = false
    
    // Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.attributedText = nil
        titleLabel.text = nil
        deadlineLabel.text = nil
        deadlineLabel.textColor = .secondaryLabel
        priorityIndicator.isHidden = true
        tagsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        indicatorsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        categoryDot.backgroundColor = .systemGray4
        onCheckboxTapped = nil
    }
    
    // Setup
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(checkboxButton)
        containerView.addSubview(titleLabel)
        containerView.addSubview(categoryDot)
        containerView.addSubview(deadlineLabel)
        containerView.addSubview(priorityIndicator)
        containerView.addSubview(editButton)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            checkboxButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            checkboxButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            checkboxButton.widthAnchor.constraint(equalToConstant: 28),
            checkboxButton.heightAnchor.constraint(equalToConstant: 28),
            
            categoryDot.leadingAnchor.constraint(equalTo: checkboxButton.trailingAnchor, constant: 12),
            categoryDot.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            categoryDot.widthAnchor.constraint(equalToConstant: 8),
            categoryDot.heightAnchor.constraint(equalToConstant: 8),
            
            titleLabel.leadingAnchor.constraint(equalTo: categoryDot.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: editButton.leadingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            editButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            editButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            editButton.widthAnchor.constraint(equalToConstant: 24),
            editButton.heightAnchor.constraint(equalToConstant: 24),
            
            priorityIndicator.trailingAnchor.constraint(equalTo: editButton.leadingAnchor, constant: -8),
            priorityIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            priorityIndicator.widthAnchor.constraint(equalToConstant: 6),
            priorityIndicator.heightAnchor.constraint(equalToConstant: 6),
        ])
    }
    
    // Configuration
    
    func configure(with task: TaskEntity) {
        isTaskCompleted = task.isCompleted
        
        // Title
        let taskName = task.name ?? "Untitled"
        if task.isCompleted {
            let attributedString = NSMutableAttributedString(string: taskName)
            attributedString.addAttributes([
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: UIColor.systemGray
            ], range: NSRange(location: 0, length: taskName.count))
            titleLabel.attributedText = attributedString
        } else {
            titleLabel.text = taskName
            titleLabel.textColor = .label
        }
        
        // Checkbox
        updateCheckboxAppearance()
        
        // Category color
        if let colorHex = task.categoryColorHex {
            categoryDot.backgroundColor = UIColor(hex: colorHex)
        } else {
            categoryDot.backgroundColor = getCategoryColor(task.category)
        }
        
        // Priority indicator
        let priority = TaskPriority(rawValue: task.priority) ?? .medium
        switch priority {
        case .high:
            priorityIndicator.backgroundColor = .systemRed
            priorityIndicator.isHidden = false
        case .medium:
            priorityIndicator.isHidden = true
        case .low:
            priorityIndicator.isHidden = true
        }
        
        // Deadline
        if let deadline = task.deadline {
            deadlineLabel.text = formatDeadline(deadline)
            
            if deadline < Date() && !task.isCompleted {
                deadlineLabel.textColor = .systemRed
            }
        }
    }
    
    private func updateCheckboxAppearance() {
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
        
        if isTaskCompleted {
            let image = UIImage(systemName: "checkmark.square.fill", withConfiguration: config)
            checkboxButton.setImage(image, for: .normal)
            checkboxButton.tintColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        } else {
            let image = UIImage(systemName: "square", withConfiguration: config)
            checkboxButton.setImage(image, for: .normal)
            checkboxButton.tintColor = .systemGray3
        }
    }
    
    private func getCategoryColor(_ category: String?) -> UIColor {
        guard let category = category?.lowercased() else {
            return .systemGray4
        }
        
        switch category {
        case "personal":
            return .systemBlue
        case "work":
            return .systemGreen
        case "studies":
            return UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        default:
            return .systemGray4
        }
    }
    
    private func formatDeadline(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "Today, \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
    
    // Actions
    
    @objc private func checkboxTapped() {
        onCheckboxTapped?()
    }
}

// UIColor Hex Extension

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
