import UIKit
import SnapKit

final class TemplateCell: UITableViewCell {

    private let nameLabel = UILabel()
    private let detailLabel = UILabel()
    private let editButton = UIButton(type: .system)

    var onEdit: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        detailLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 2

        editButton.setTitle("Edit", for: .normal)
        editButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        editButton.setTitleColor(.systemRed, for: .normal)
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)

        contentView.addSubview(nameLabel)
        contentView.addSubview(detailLabel)
        contentView.addSubview(editButton)

        nameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(10)
            make.trailing.lessThanOrEqualTo(editButton.snp.leading).offset(-8)
        }

        detailLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(10)
        }

        editButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
            make.size.equalTo(CGSize(width: 60, height: 30))
        }
    }

    func configure(with template: PomodoroTemplateModel) {
        nameLabel.text = "\(template.icon) \(template.name)"
        let work = Int(template.workDuration / 60)
        let short = Int(template.shortBreakDuration / 60)
        let long = Int(template.longBreakDuration / 60)
        detailLabel.text = "Work \(work)m • Break \(short)m • Long \(long)m • Cycles \(template.cyclesBeforeLongBreak)"
        editButton.isHidden = template.isPreset
        detailLabel.numberOfLines = template.isPreset ? 2 : 2
    }

    @objc private func editTapped() {
        onEdit?()
    }
}
