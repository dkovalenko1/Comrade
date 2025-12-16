import UIKit
import SnapKit

final class TasksViewController: UIViewController {
    
    // Properties
    
    private let viewModel = TasksViewModel()
    
    // UI Elements
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(TaskCell.self, forCellReuseIdentifier: TaskCell.identifier)
        table.register(TaskSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: TaskSectionHeaderView.identifier)
        table.register(TaskSectionFooterView.self, forHeaderFooterViewReuseIdentifier: TaskSectionFooterView.identifier)
        table.separatorStyle = .none
        table.backgroundColor = .systemBackground
        table.showsVerticalScrollIndicator = false
        table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
        return table
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let image = UIImage(systemName: "plus", withConfiguration: config)
        button.setImage(image, for: .normal)
        
        button.tintColor = .white
        button.backgroundColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        button.layer.cornerRadius = 28
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.2
        
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        button.setImage(UIImage(systemName: "line.3.horizontal.decrease.circle", withConfiguration: config), for: .normal)
        button.tintColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        button.backgroundColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 0.15)
        button.layer.cornerRadius = 18
        button.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Tasks"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        return label
    }()
    
    private lazy var emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16
        
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark.circle")
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        imageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 80, height: 80))
        }
        
        let titleLabel = UILabel()
        titleLabel.text = "No Tasks"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .systemGray
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Tap + to create your first task"
        subtitleLabel.font = .systemFont(ofSize: 16)
        subtitleLabel.textColor = .systemGray2
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        return view
    }()
    
    // Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.loadTasks()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.loadTasks()
    }
    
    // Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(filterButton)
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(addButton)
        
        filterButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.trailing.equalToSuperview().inset(16)
            make.size.equalTo(CGSize(width: 36, height: 36))
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(filterButton.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        emptyStateView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        addButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 56, height: 56))
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
        }
    }
    
    private func bindViewModel() {
        viewModel.onDataUpdated = { [weak self] in
            self?.updateUI()
        }
        
        viewModel.onError = { [weak self] message in
            self?.showError(message)
        }
        
        viewModel.onTaskCompleted = { [weak self] task in
            self?.showTaskCompletedFeedback(task)
        }
        
        viewModel.onTaskCompletionFailed = { [weak self] task, blockers in
            self?.showDependencyAlert(for: task, blockers: blockers)
        }
    }
    
    // UI Updates
    
    private func updateUI() {
        tableView.reloadData()
        
        let isEmpty = viewModel.totalTaskCount == 0
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showTaskCompletedFeedback(_ task: TaskEntity) {
        // Haptic feedback - can be implemented further
    }
    
    private func showDependencyAlert(for task: TaskEntity, blockers: [TaskEntity]) {
        let blockerNames = blockers.compactMap { $0.name }.joined(separator: ", ")
        let message = "This task depends on: \(blockerNames). Complete those tasks first."
        
        let alert = UIAlertController(
            title: "Cannot Complete Task",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // Actions
    
    @objc private func addButtonTapped() {
        let editorVC = TaskEditorViewController(mode: .create)
        editorVC.modalPresentationStyle = .pageSheet
        present(editorVC, animated: true)
    }
    
    @objc private func filterButtonTapped() {
        showSortOptions()
    }
    
    private func showSortOptions() {
        let alert = UIAlertController(title: "Sort By", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Created Date", style: .default) { [weak self] _ in
            self?.viewModel.sort(by: .createdAt)
        })
        
        alert.addAction(UIAlertAction(title: "Deadline", style: .default) { [weak self] _ in
            self?.viewModel.sort(by: .deadline)
        })
        
        alert.addAction(UIAlertAction(title: "Priority", style: .default) { [weak self] _ in
            self?.viewModel.sort(by: .priority)
        })
        
        alert.addAction(UIAlertAction(title: "Name", style: .default) { [weak self] _ in
            self?.viewModel.sort(by: .name)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = filterButton
        }
        
        present(alert, animated: true)
    }
    
    private func editTask(_ task: TaskEntity) {
        let editorVC = TaskEditorViewController(mode: .edit(task))
        editorVC.modalPresentationStyle = .pageSheet
        present(editorVC, animated: true)
    }
}

// UITableViewDataSource

extension TasksViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return TaskSection.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let taskSection = TaskSection(rawValue: section) else { return 0 }
        return viewModel.numberOfRows(in: taskSection)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TaskCell.identifier, for: indexPath) as? TaskCell,
              let task = viewModel.task(at: indexPath.section, row: indexPath.row) else {
            return UITableViewCell()
        }
        
        // Check if last item in section
        guard let taskSection = TaskSection(rawValue: indexPath.section) else { return cell }
        let rowCount = viewModel.numberOfRows(in: taskSection)
        cell.isLastInSection = (indexPath.row == rowCount - 1)
        
        cell.configure(with: task)
        
        cell.onCheckboxTapped = { [weak self] in
            self?.viewModel.toggleTaskCompletion(at: indexPath.section, row: indexPath.row)
        }
        
        // Connect edit button callback
        cell.onEditTapped = { [weak self] in
            self?.editTask(task)
        }
        
        return cell
    }
}

// UITableViewDelegate

extension TasksViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let taskSection = TaskSection(rawValue: section),
              let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TaskSectionHeaderView.identifier) as? TaskSectionHeaderView else {
            return nil
        }
        
        let data = viewModel.headerData(for: taskSection)
        headerView.configure(title: data.title, count: data.count, isExpanded: data.isExpanded)
        
        headerView.onHeaderTapped = { [weak self] in
            self?.viewModel.toggleSection(taskSection)
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let taskSection = TaskSection(rawValue: section) else { return nil }
        
        let isExpanded = viewModel.isSectionExpanded(taskSection)
        let count = viewModel.taskCount(for: taskSection)
        
        if isExpanded && count > 0 {
            let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TaskSectionFooterView.identifier) as? TaskSectionFooterView
            return footerView
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 56
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let taskSection = TaskSection(rawValue: section) else { return 0 }
        
        let isExpanded = viewModel.isSectionExpanded(taskSection)
        let count = viewModel.taskCount(for: taskSection)
        
        if isExpanded && count > 0 {
            return 12
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let task = viewModel.task(at: indexPath.section, row: indexPath.row) else { return }
        editTask(task)
    }
    
    // Swipe actions
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
            self?.confirmDelete(at: indexPath)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = .systemRed
        
        let editAction = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completion in
            if let task = self?.viewModel.task(at: indexPath.section, row: indexPath.row) {
                self?.editTask(task)
            }
            completion(true)
        }
        editAction.image = UIImage(systemName: "pencil")
        editAction.backgroundColor = .systemBlue
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        guard let task = viewModel.task(at: indexPath.section, row: indexPath.row) else { return nil }
        
        let completeAction = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completion in
            self?.viewModel.toggleTaskCompletion(at: indexPath.section, row: indexPath.row)
            completion(true)
        }
        
        if task.isCompleted {
            completeAction.image = UIImage(systemName: "arrow.uturn.backward")
            completeAction.backgroundColor = .systemOrange
        } else {
            completeAction.image = UIImage(systemName: "checkmark")
            completeAction.backgroundColor = .systemGreen
        }
        
        return UISwipeActionsConfiguration(actions: [completeAction])
    }
    
    private func confirmDelete(at indexPath: IndexPath) {
        guard let task = viewModel.task(at: indexPath.section, row: indexPath.row) else { return }
        
        let alert = UIAlertController(
            title: "Delete Task",
            message: "Are you sure you want to delete \"\(task.name ?? "this task")\"?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteTask(at: indexPath.section, row: indexPath.row)
        })
        
        present(alert, animated: true)
    }
}
