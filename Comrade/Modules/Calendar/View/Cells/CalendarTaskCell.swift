import UIKit
import SnapKit

final class CalendarTaskCell: UITableViewCell {
    
    static let identifier = "CalendarTaskCell"
    
    // MARK: - UI Elements
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.04
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 5
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private let priorityIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "exclamationmark.2")
        iv.tintColor = .systemRed
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()
    
    private let timeDot: UIView = {
        let view = UIView()
        view.backgroundColor = .appRed
        view.layer.cornerRadius = 3
        return view
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = UIColor(white: 0.32, alpha: 1.0)
        return label
    }()
    
    private let menuIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "ellipsis")
        iv.tintColor = .secondaryLabel
        iv.contentMode = .scaleAspectFit
        iv.transform = CGAffineTransform(rotationAngle: .pi / 2)
        return iv
    }()
    
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(priorityIcon)
        containerView.addSubview(timeDot)
        containerView.addSubview(timeLabel)
        containerView.addSubview(menuIcon)
        
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-6)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(72)
        }
        
        menuIcon.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
            make.width.equalTo(20)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(priorityIcon.snp.leading).offset(-8)
        }
        
        priorityIcon.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.leading.equalTo(titleLabel.snp.trailing).offset(6)
            make.trailing.lessThanOrEqualTo(menuIcon.snp.leading).offset(-8)
            make.width.height.equalTo(18)
        }
        
        timeDot.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.size.equalTo(6)
        }
        
        timeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(timeDot)
            make.leading.equalTo(timeDot.snp.trailing).offset(6)
        }
    }
    
    func configure(with task: TaskEntity) {
        titleLabel.text = task.name ?? "Untitled Task"
        
        let isHighPriority = task.priority == 2
        priorityIcon.isHidden = !isHighPriority
        
        if let hex = task.categoryColorHex {
            timeDot.backgroundColor = UIColor(hex: hex)
        } else {
            timeDot.backgroundColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        }
        
        if let deadline = task.deadline {
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: Date())
            let startOfDeadline = calendar.startOfDay(for: deadline)
            
            let isOverdue = startOfDeadline < startOfToday
            
            timeLabel.textColor = isOverdue ? .systemRed : .secondaryLabel
            
            if task.deadlineIsAllDay {
                if isOverdue {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMM d"
                    timeLabel.text = formatter.string(from: deadline)
                } else {
                    timeLabel.text = "All Day"
                }
            } else {
                let formatter = DateFormatter()
                if isOverdue {
                    formatter.dateFormat = "MMM d, hh:mm a"
                } else {
                    formatter.dateFormat = "hh:mm a"
                }
                timeLabel.text = formatter.string(from: deadline)
            }
        } else {
            timeLabel.text = "No time"
            timeLabel.textColor = .secondaryLabel
        }
    }
}
