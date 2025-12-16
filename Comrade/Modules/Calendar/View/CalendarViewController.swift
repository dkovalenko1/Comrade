import UIKit
import SnapKit

final class CalendarViewController: UIViewController {
    
    private let viewModel = CalendarViewModel()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Calendar"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        return label
    }()
    
    private lazy var monthSelectorButton: UIButton = {
        let btn = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .systemGray6
        config.baseForegroundColor = .label
        config.image = UIImage(systemName: "chevron.down")
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.cornerStyle = .capsule
        btn.configuration = config
        btn.addTarget(self, action: #selector(toggleMode), for: .touchUpInside)
        return btn
    }()
    
    private let daysHeaderStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.isHidden = true
        
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        for day in days {
            let label = UILabel()
            label.text = day
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 14, weight: .bold)
            label.textColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
            stack.addArrangedSubview(label)
        }
        return stack
    }()
    
    private lazy var calendarCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.delegate = self
        cv.dataSource = self
        cv.register(WeekDayCell.self, forCellWithReuseIdentifier: WeekDayCell.identifier)
        cv.register(MonthDayCell.self, forCellWithReuseIdentifier: MonthDayCell.identifier)
        cv.isScrollEnabled = false
        return cv
    }()
    
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.delegate = self
        tv.dataSource = self
        tv.register(CalendarTaskCell.self, forCellReuseIdentifier: CalendarTaskCell.identifier)
        tv.backgroundColor = .systemBackground
        tv.separatorStyle = .none
        return tv
    }()
    
    private lazy var fabButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        button.layer.cornerRadius = 28
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.2
        button.addTarget(self, action: #selector(fabTapped), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
        bindViewModel()
        updateHeader()
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: .taskCreated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: .taskUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: .taskDeleted, object: nil)
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        view.addSubview(titleLabel)
        view.addSubview(monthSelectorButton)
        view.addSubview(daysHeaderStack)
        view.addSubview(calendarCollectionView)
        view.addSubview(tableView)
        view.addSubview(fabButton)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.equalToSuperview().offset(20)
        }
        
        monthSelectorButton.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(20)
            make.height.equalTo(36)
        }
        
        daysHeaderStack.snp.makeConstraints { make in
            make.top.equalTo(monthSelectorButton.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(10)
            make.height.equalTo(20)
        }
        
        calendarCollectionView.snp.makeConstraints { make in
            make.top.equalTo(monthSelectorButton.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(10)
            make.height.equalTo(80)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(calendarCollectionView.snp.bottom).offset(20)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        fabButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.width.height.equalTo(56)
        }
    }
    
    private func setupGestures() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        calendarCollectionView.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        calendarCollectionView.addGestureRecognizer(swipeRight)
    }
    
    private func bindViewModel() {
        viewModel.onDateChanged = { [weak self] in
            self?.updateHeader()
            self?.calendarCollectionView.reloadData()
            self?.tableView.reloadData()
        }
        
        viewModel.onDataUpdated = { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    private func updateHeader() {
        var config = monthSelectorButton.configuration
        config?.title = viewModel.titleString
        monthSelectorButton.configuration = config
    }
    
    @objc private func refreshData() {
        viewModel.selectDate(viewModel.selectedDate)
    }
    
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .left {
            viewModel.moveTime(direction: 1)
        } else {
            viewModel.moveTime(direction: -1)
        }
    }
    
    @objc private func toggleMode() {
        let newMode: CalendarMode = viewModel.mode == .week ? .month : .week
        viewModel.switchMode(newMode)
        
        let isWeek = newMode == .week
        let newHeight: CGFloat = isWeek ? 80 : 340
        
        daysHeaderStack.isHidden = isWeek
        
        calendarCollectionView.snp.remakeConstraints { make in
            if isWeek {
                make.top.equalTo(monthSelectorButton.snp.bottom).offset(20)
            } else {
                make.top.equalTo(daysHeaderStack.snp.bottom).offset(10)
            }
            make.leading.trailing.equalToSuperview().inset(10)
            make.height.equalTo(newHeight)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.calendarCollectionView.reloadData()
        }
    }
    
    @objc private func fabTapped() {
        let editorVC = TaskEditorViewController(mode: .create)
        present(editorVC, animated: true)
    }
}

extension CalendarViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.mode == .week ? viewModel.currentWeekDays.count : viewModel.currentMonthGrid.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if viewModel.mode == .week {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: WeekDayCell.identifier, for: indexPath) as? WeekDayCell else { return UICollectionViewCell() }
            
            let date = viewModel.currentWeekDays[indexPath.item]
            let isSelected = Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate)
            let hasDeadline = viewModel.hasDeadline(on: date)
            
            cell.configure(date: date, isSelected: isSelected, hasDeadline: hasDeadline)
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MonthDayCell.identifier, for: indexPath) as? MonthDayCell else { return UICollectionViewCell() }
            
            let date = viewModel.currentMonthGrid[indexPath.item]
            var isSelected = false
            var hasDeadline = false
            
            if let date = date {
                isSelected = Calendar.current.isDate(date, inSameDayAs: viewModel.selectedDate)
                hasDeadline = viewModel.hasDeadline(on: date)
            }
            
            cell.configure(date: date, isSelected: isSelected, hasDeadline: hasDeadline)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 5) / 7.0
        return viewModel.mode == .week ? CGSize(width: width, height: 70) : CGSize(width: width, height: 45)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if viewModel.mode == .week {
            let date = viewModel.currentWeekDays[indexPath.item]
            viewModel.selectDate(date)
        } else {
            guard let date = viewModel.currentMonthGrid[indexPath.item] else { return }
            viewModel.selectDate(date)
            
            toggleMode()
        }
    }
}

extension CalendarViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = viewModel.tasksForSelectedDate.count
        if count == 0 {
            tableView.setEmptyMessage("No tasks for this day")
        } else {
            tableView.restore()
        }
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CalendarTaskCell.identifier, for: indexPath) as? CalendarTaskCell else { return UITableViewCell() }
        cell.configure(with: viewModel.tasksForSelectedDate[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 84
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let task = viewModel.tasksForSelectedDate[indexPath.row]
        let editorVC = TaskEditorViewController(mode: .edit(task))
        present(editorVC, animated: true)
    }
}

extension UITableView {
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = .systemFont(ofSize: 15, weight: .medium)
        messageLabel.sizeToFit()
        self.backgroundView = messageLabel
    }

    func restore() {
        self.backgroundView = nil
    }
}
