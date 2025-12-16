import UIKit
import SnapKit

// MARK: - Week Day Cell
final class WeekDayCell: UICollectionViewCell {
    static let identifier = "WeekDayCell"
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 18
        return view
    }()
    
    private let dayLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        label.textAlignment = .center
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private let dotView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0) // App Red
        view.layer.cornerRadius = 2.5
        view.isHidden = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(dayLabel)
        containerView.addSubview(dateLabel)
        containerView.addSubview(dotView)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        dayLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(dayLabel.snp.bottom).offset(2)
            make.centerX.equalToSuperview()
        }
        
        dotView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-8)
            make.centerX.equalToSuperview()
            make.size.equalTo(5)
        }
    }
    
    func configure(date: Date, isSelected: Bool, hasDeadline: Bool) {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        dayLabel.text = formatter.string(from: date).prefix(1).description
        
        formatter.dateFormat = "d"
        dateLabel.text = formatter.string(from: date)
        
        dotView.isHidden = !hasDeadline
        
        if isSelected {
            containerView.backgroundColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
            dayLabel.textColor = .white.withAlphaComponent(0.8)
            dateLabel.textColor = .white
            dotView.backgroundColor = .white
        } else {
            containerView.backgroundColor = .systemGray6
            dayLabel.textColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
            dateLabel.textColor = .label
            dotView.backgroundColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        }
    }
}

// MARK: - Month Day Cell
final class MonthDayCell: UICollectionViewCell {
    static let identifier = "MonthDayCell"
    
    private let selectionCircle: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        view.layer.cornerRadius = 20
        view.isHidden = true
        return view
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private let dotView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        view.layer.cornerRadius = 2.5
        view.isHidden = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(selectionCircle)
        contentView.addSubview(dateLabel)
        contentView.addSubview(dotView)
        
        selectionCircle.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(40)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        dotView.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(2)
            make.centerX.equalToSuperview()
            make.size.equalTo(5)
        }
    }
    
    func configure(date: Date?, isSelected: Bool, hasDeadline: Bool) {
        guard let date = date else {
            dateLabel.text = ""
            selectionCircle.isHidden = true
            dotView.isHidden = true
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        dateLabel.text = formatter.string(from: date)
        
        selectionCircle.isHidden = !isSelected
        dotView.isHidden = !hasDeadline
        
        if isSelected {
            dateLabel.textColor = .white
            dateLabel.font = .systemFont(ofSize: 16, weight: .bold)
            dotView.backgroundColor = .white
        } else {
            dateLabel.textColor = .label
            dateLabel.font = .systemFont(ofSize: 16, weight: .regular)
            dotView.backgroundColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        }
    }
}
