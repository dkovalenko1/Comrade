import UIKit
import SnapKit

final class TaskSectionHeaderView: UITableViewHeaderFooterView {
    
    static let identifier = "TaskSectionHeaderView"
    
    var onHeaderTapped: (() -> Void)?
    
    // UI Elements
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGroupedBackground
        return view
    }()
    
    private let iconView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 0.15)
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        imageView.image = UIImage(systemName: "list.bullet", withConfiguration: config)
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        return label
    }()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
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
    
    // Properties
    
    private var isExpanded = false
    private var hasItems = false
    
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
        isExpanded = false
        hasItems = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateCorners()
    }
    
    // Setup
    
    private func setupUI() {
        contentView.backgroundColor = .clear
        backgroundView = UIView()
        backgroundView?.backgroundColor = .clear
        
        contentView.addSubview(containerView)
        containerView.addSubview(iconView)
        iconView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(countLabel)
        containerView.addSubview(chevronImageView)
        
        containerView.addGestureRecognizer(tapGesture)
        
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }
        
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 32, height: 32))
        }
        
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 16, height: 16))
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
        }
        
        countLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(6)
            make.centerY.equalToSuperview()
        }
        
        chevronImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 16, height: 16))
        }
    }
    
    // Configuration
    
    func configure(title: String, count: Int, isExpanded: Bool) {
        titleLabel.text = title
        countLabel.text = "\(count)"
        self.isExpanded = isExpanded
        self.hasItems = count > 0 && isExpanded
        
        // Chevron rotation
        if isExpanded {
            chevronImageView.transform = .identity
        } else {
            chevronImageView.transform = CGAffineTransform(rotationAngle: -.pi / 2)
        }
        
        updateCorners()
    }
    
    private func updateCorners() {
        if isExpanded && hasItems {
            containerView.layer.cornerRadius = 12
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else {
            containerView.layer.cornerRadius = 12
            containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        }
    }
    
    // Actions
    
    @objc private func headerTapped() {
        onHeaderTapped?()
    }
}
