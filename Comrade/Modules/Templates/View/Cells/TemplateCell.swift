import UIKit
import SnapKit

final class TemplateCell: UICollectionViewCell {
    
    static let identifier = "TemplateCell"
    
    var onMainButtonTapped: (() -> Void)?
    
    // MARK: - UI Elements
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()
    
    private let mainStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.alignment = .fill
        return stack
    }()
    
    // Header
    
    private let headerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let iconBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        view.layer.cornerRadius = 10
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        return label
    }()
    
    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    // Expanded
    
    private let expandedContainer: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()
    
    private let detailsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        button.layer.cornerRadius = 14
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(mainStackView)
        
        mainStackView.addArrangedSubview(headerView)
        mainStackView.addArrangedSubview(expandedContainer)
        
        headerView.addSubview(iconBackground)
        iconBackground.addSubview(iconImageView)
        headerView.addSubview(nameLabel)
        headerView.addSubview(durationLabel)
        
        expandedContainer.addSubview(detailsLabel)
        expandedContainer.addSubview(actionButton)
        
        // MARK: - Constraints
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        mainStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Compact Header Height
        headerView.snp.makeConstraints { make in
            make.height.equalTo(68)
        }
        
        iconBackground.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(22)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconBackground.snp.trailing).offset(12)
            make.top.equalTo(iconBackground).offset(0)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        durationLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
        }
        
        // Details Layout
        detailsLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(0)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        actionButton.snp.makeConstraints { make in
            make.top.equalTo(detailsLabel.snp.bottom).offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.width.equalTo(160)
            make.height.equalTo(40)
            make.bottom.equalToSuperview().offset(-16)
        }
    }
    
    func configure(
        title: String,
        subtitle: String,
        details: String?,
        iconName: String,
        buttonTitle: String,
        isExpanded: Bool
    ) {
        nameLabel.text = title
        durationLabel.text = subtitle
        iconImageView.image = UIImage(systemName: iconName)
        actionButton.setTitle(buttonTitle, for: .normal)
        
        if let details = details {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 4
            detailsLabel.attributedText = NSAttributedString(
                string: details,
                attributes: [.paragraphStyle: paragraphStyle, .font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.secondaryLabel]
            )
        } else {
            detailsLabel.text = nil
        }
        
        setExpandedState(isExpanded, animated: false)
    }
    
    func setExpandedState(_ isExpanded: Bool, animated: Bool) {
        let block = {
            self.expandedContainer.isHidden = !isExpanded
            self.expandedContainer.alpha = isExpanded ? 1 : 0
        }
        
        if animated {
            UIView.animate(withDuration: 0.3, animations: block)
        } else {
            block()
        }
    }
    
    @objc private func buttonTapped() {
        onMainButtonTapped?()
    }
}
