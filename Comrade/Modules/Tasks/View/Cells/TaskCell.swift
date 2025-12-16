import UIKit
import SnapKit

final class TaskCell: UITableViewCell {
    
    static let identifier = "TaskCell"
    
    // Callbacks
    
    var onCheckboxTapped: (() -> Void)?
    var onEditTapped: (() -> Void)?
    
    // UI Elements
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGroupedBackground
        return view
    }()
    
    private lazy var checkboxButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(checkboxTapped), for: .touchUpInside)
        return button
    }()
    
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        return stack
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()
    
    private let tagsContainerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let tagsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        return stack
    }()
    
    private let categoryDot: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.backgroundColor = .systemGray4
        return view
    }()
    
    private let deadlineLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let priorityIndicator: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 3
        view.isHidden = true
        return view
    }()
    
    private lazy var editButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        button.setImage(UIImage(systemName: "square.and.pencil", withConfiguration: config), for: .normal)
        button.tintColor = .systemGray3
        button.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        return button
    }()
    
    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        return view
    }()
    
    // Properties
    
    private var isTaskCompleted = false
    private var tagsHeightConstraint: Constraint?
    
    var isLastInSection = false {
        didSet {
            separatorView.isHidden = isLastInSection
            updateCorners()
        }
    }
    
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
        categoryDot.backgroundColor = .systemGray4
        onCheckboxTapped = nil
        onEditTapped = nil
        isLastInSection = false
        separatorView.isHidden = false
        containerView.layer.cornerRadius = 0
        containerView.layer.maskedCorners = []
        clearTags()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateCorners()
    }
    
    // Setup
    
    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(checkboxButton)
        containerView.addSubview(categoryDot)
        containerView.addSubview(contentStackView)
        containerView.addSubview(priorityIndicator)
        containerView.addSubview(editButton)
        containerView.addSubview(separatorView)
        
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(tagsContainerView)
        
        tagsContainerView.addSubview(tagsStackView)
        
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }
        
        checkboxButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 28, height: 28))
        }
        
        categoryDot.snp.makeConstraints { make in
            make.leading.equalTo(checkboxButton.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(18)
            make.size.equalTo(CGSize(width: 8, height: 8))
        }
        
        contentStackView.snp.makeConstraints { make in
            make.leading.equalTo(categoryDot.snp.trailing).offset(10)
            make.trailing.equalTo(editButton.snp.leading).offset(-8)
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().inset(12)
        }
        
        tagsContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            tagsHeightConstraint = make.height.equalTo(0).constraint
        }
        
        tagsStackView.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        
        editButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 44, height: 44))
        }
        
        priorityIndicator.snp.makeConstraints { make in
            make.trailing.equalTo(editButton.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 6, height: 6))
        }
        
        separatorView.snp.makeConstraints { make in
            make.leading.equalTo(contentStackView)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }
    
    private func updateCorners() {
        if isLastInSection {
            containerView.layer.cornerRadius = 12
            containerView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        } else {
            containerView.layer.cornerRadius = 0
            containerView.layer.maskedCorners = []
        }
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
        
        // Tags
        configureTags(for: task)
    }
    
    private func configureTags(for task: TaskEntity) {
        clearTags()
        
        guard let tags = task.tags as? Set<TagEntity>, !tags.isEmpty else {
            tagsHeightConstraint?.update(offset: 0)
            tagsContainerView.isHidden = true
            return
        }
        
        tagsContainerView.isHidden = false
        tagsHeightConstraint?.update(offset: 20)
        
        let sortedTags = Array(tags).sorted { ($0.name ?? "") < ($1.name ?? "") }
        let maxVisibleTags = 3
        
        for tag in sortedTags.prefix(maxVisibleTags) {
            let tagView = createTagView(for: tag)
            tagsStackView.addArrangedSubview(tagView)
        }
        
        // Show "+N" if more tags
        if sortedTags.count > maxVisibleTags {
            let moreLabel = UILabel()
            moreLabel.text = "+\(sortedTags.count - maxVisibleTags)"
            moreLabel.font = .systemFont(ofSize: 10, weight: .medium)
            moreLabel.textColor = .secondaryLabel
            tagsStackView.addArrangedSubview(moreLabel)
        }
    }
    
    private func createTagView(for tag: TagEntity) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor(hex: tag.colorHex ?? "#888888").withAlphaComponent(0.2)
        container.layer.cornerRadius = 4
        
        let label = UILabel()
        label.text = tag.name
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = UIColor(hex: tag.colorHex ?? "#888888")
        
        container.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(2)
            make.bottom.equalToSuperview().inset(2)
            make.leading.equalToSuperview().offset(6)
            make.trailing.equalToSuperview().inset(6)
        }
        
        return container
    }
    
    private func clearTags() {
        tagsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
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
    
    @objc private func editTapped() {
        onEditTapped?()
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
