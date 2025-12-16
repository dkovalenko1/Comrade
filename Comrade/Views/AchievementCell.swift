import UIKit
import SnapKit

final class AchievementCell: UITableViewCell {

    private let iconLabel = UILabel()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let statusLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        iconLabel.font = UIFont.systemFont(ofSize: 28)
        iconLabel.textAlignment = .center

        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label

        detailLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 2

        progressView.trackTintColor = UIColor.systemGray5
        progressView.progressTintColor = .systemGreen
        progressView.layer.cornerRadius = 3
        progressView.clipsToBounds = true

        statusLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        statusLabel.textColor = .systemGreen

        let textStack = UIStackView(arrangedSubviews: [titleLabel, detailLabel, progressView, statusLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        contentView.addSubview(iconLabel)
        contentView.addSubview(textStack)

        iconLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(12)
            make.size.equalTo(CGSize(width: 36, height: 36))
        }

        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconLabel.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().inset(10)
        }
    }

    func configure(with achievement: Achievement, progressText: String, progressValue: Float) {
        iconLabel.text = achievement.icon
        titleLabel.text = achievement.title
        detailLabel.text = achievement.detail
        progressView.progress = progressValue
        statusLabel.text = achievement.isUnlocked ? "Unlocked" : progressText
        statusLabel.textColor = achievement.isUnlocked ? .systemGreen : .secondaryLabel
        contentView.alpha = achievement.isUnlocked ? 1.0 : 0.8
    }
}
