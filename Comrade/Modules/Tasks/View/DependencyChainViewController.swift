import UIKit

final class DependencyChainViewController: UIViewController {
    
    // Properties
    
    private let viewModel: DependencyViewModel
    var onDependenciesChanged: (([TaskEntity]) -> Void)?
    
    // UI Elements
    
    private lazy var headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        return view
    }()
    
    private lazy var rootTaskCard: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGroupedBackground
        view.layer.cornerRadius = 12
        return view
    }()
    
    private lazy var rootTaskColorDot: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 6
        view.backgroundColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        return view
    }()
    
    private lazy var rootTaskLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(DependencyCell.self, forCellReuseIdentifier: DependencyCell.identifier)
        table.backgroundColor = .systemBackground
        return table
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("+ Add Dependency", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0), for: .normal)
        button.addTarget(self, action: #selector(addDependencyTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 12
        
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "arrow.triangle.branch")
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        let titleLabel = UILabel()
        titleLabel.text = "No Dependencies"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .systemGray
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "This task doesn't depend on any other tasks"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .systemGray2
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
        
        return view
    }()
    
    // Init
    
    init(task: TaskEntity, pendingDependencies: [TaskEntity] = []) {
        self.viewModel = DependencyViewModel(task: task, pendingDependencies: pendingDependencies)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigation()
        bindViewModel()
        updateUI()
    }
    
    // Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(headerView)
        headerView.addSubview(rootTaskCard)
        rootTaskCard.addSubview(rootTaskColorDot)
        rootTaskCard.addSubview(rootTaskLabel)
        rootTaskCard.addSubview(statusLabel)
        
        view.addSubview(addButton)
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            rootTaskCard.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            rootTaskCard.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            rootTaskCard.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            rootTaskCard.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
            
            rootTaskColorDot.topAnchor.constraint(equalTo: rootTaskCard.topAnchor, constant: 16),
            rootTaskColorDot.leadingAnchor.constraint(equalTo: rootTaskCard.leadingAnchor, constant: 16),
            rootTaskColorDot.widthAnchor.constraint(equalToConstant: 12),
            rootTaskColorDot.heightAnchor.constraint(equalToConstant: 12),
            
            rootTaskLabel.topAnchor.constraint(equalTo: rootTaskCard.topAnchor, constant: 14),
            rootTaskLabel.leadingAnchor.constraint(equalTo: rootTaskColorDot.trailingAnchor, constant: 12),
            rootTaskLabel.trailingAnchor.constraint(equalTo: rootTaskCard.trailingAnchor, constant: -16),
            
            statusLabel.topAnchor.constraint(equalTo: rootTaskLabel.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: rootTaskLabel.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: rootTaskLabel.trailingAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: rootTaskCard.bottomAnchor, constant: -14),
            
            addButton.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addButton.heightAnchor.constraint(equalToConstant: 44),
            
            tableView.topAnchor.constraint(equalTo: addButton.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateView.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: 40),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    private func setupNavigation() {
        title = "Dependencies"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
    }
    
    private func bindViewModel() {
        viewModel.onDataUpdated = { [weak self] in
            self?.updateUI()
        }
        
        viewModel.onError = { [weak self] message in
            self?.showAlert(title: "Error", message: message)
        }
        
        viewModel.onDependencyCompleted = { [weak self] task in
            self?.showCompletionFeedback(for: task)
        }
        
        viewModel.onDependenciesChanged = { [weak self] dependencies in
            self?.onDependenciesChanged?(dependencies)
        }
    }
    
    // UI Updates
    
    private func updateUI() {
        // Root task info
        rootTaskLabel.text = viewModel.rootTaskName
        
        if let colorHex = viewModel.rootTaskCategoryColorHex {
            rootTaskColorDot.backgroundColor = UIColor(hex: colorHex)
        }
        
        // Status
        if viewModel.canCompleteRootTask {
            statusLabel.text = "✓ Ready to complete"
            statusLabel.textColor = .systemGreen
        } else {
            statusLabel.text = "⏳ \(viewModel.blockingDependencies) blocking task\(viewModel.blockingDependencies == 1 ? "" : "s")"
            statusLabel.textColor = .systemOrange
        }
        
        // Table / Empty state
        let isEmpty = !viewModel.hasDependencies && !viewModel.hasDependents
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        
        tableView.reloadData()
    }
    
    private func showCompletionFeedback(for task: TaskEntity) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // Actions
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func addDependencyTapped() {
        let availableTasks = viewModel.getAvailableTasksForDependency()
        
        if availableTasks.isEmpty {
            showAlert(title: "No Tasks Available", message: "There are no other tasks that can be added as dependencies")
            return
        }
        
        let alert = UIAlertController(title: "Add Dependency", message: "Select a task that must be completed first", preferredStyle: .actionSheet)
        
        for task in availableTasks.prefix(10) {
            let title = task.name ?? "Untitled"
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.viewModel.addDependency(task)
            })
        }
        
        if availableTasks.count > 10 {
            alert.addAction(UIAlertAction(title: "Show All...", style: .default) { [weak self] _ in
                self?.showAllTasksPicker(availableTasks)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = addButton
        }
        
        present(alert, animated: true)
    }
    
    private func showAllTasksPicker(_ tasks: [TaskEntity]) {
        let pickerVC = DependencyPickerViewController(tasks: tasks)
        pickerVC.onTaskSelected = { [weak self] task in
            self?.viewModel.addDependency(task)
        }
        let navController = UINavigationController(rootViewController: pickerVC)
        present(navController, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// UITableViewDataSource

extension DependencyChainViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(in: section)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.sectionTitle(for: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DependencyCell.identifier, for: indexPath) as? DependencyCell,
              let node = viewModel.node(at: indexPath.section, row: indexPath.row) else {
            return UITableViewCell()
        }
        
        let isDependencySection = viewModel.isDependencySection(indexPath.section)
        cell.configure(with: node, showCompleteButton: isDependencySection && !node.isCompleted)
        
        cell.onCompleteTapped = { [weak self] in
            self?.viewModel.completeDependency(at: indexPath.row)
        }
        
        return cell
    }
}

// UITableViewDelegate

extension DependencyChainViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let node = viewModel.node(at: indexPath.section, row: indexPath.row) else { return }
        
        // Show dependency chain for selected task
        let chainVC = DependencyChainViewController(task: node.task)
        let navController = UINavigationController(rootViewController: chainVC)
        present(navController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Only allow removing direct dependencies
        guard viewModel.isDependencySection(indexPath.section),
              let node = viewModel.node(at: indexPath.section, row: indexPath.row),
              node.level == 1 else {
            return nil
        }
        
        let removeAction = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, completion in
            self?.viewModel.removeDependency(at: indexPath.row)
            completion(true)
        }
        removeAction.image = UIImage(systemName: "minus.circle")
        
        return UISwipeActionsConfiguration(actions: [removeAction])
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard viewModel.isDependencySection(indexPath.section),
              let node = viewModel.node(at: indexPath.section, row: indexPath.row),
              !node.isCompleted else {
            return nil
        }
        
        let completeAction = UIContextualAction(style: .normal, title: "Complete") { [weak self] _, _, completion in
            self?.viewModel.completeDependency(at: indexPath.row)
            completion(true)
        }
        completeAction.backgroundColor = .systemGreen
        completeAction.image = UIImage(systemName: "checkmark")
        
        return UISwipeActionsConfiguration(actions: [completeAction])
    }
}

// DependencyCell

final class DependencyCell: UITableViewCell {
    
    static let identifier = "DependencyCell"
    
    var onCompleteTapped: (() -> Void)?
    
    // UI Elements
    
    private let levelIndicatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let colorDot: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let statusIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var completeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "checkmark.circle", withConfiguration: config), for: .normal)
        button.tintColor = .systemGreen
        button.addTarget(self, action: #selector(completeTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    private var levelIndicatorWidthConstraint: NSLayoutConstraint?
    
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
        titleLabel.text = nil
        titleLabel.textColor = .label
        colorDot.backgroundColor = .systemGray4
        statusIcon.image = nil
        completeButton.isHidden = true
        onCompleteTapped = nil
        levelIndicatorWidthConstraint?.constant = 0
    }
    
    // Setup
    
    private func setupUI() {
        contentView.addSubview(levelIndicatorView)
        contentView.addSubview(colorDot)
        contentView.addSubview(titleLabel)
        contentView.addSubview(statusIcon)
        contentView.addSubview(completeButton)
        
        levelIndicatorWidthConstraint = levelIndicatorView.widthAnchor.constraint(equalToConstant: 0)
        levelIndicatorWidthConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            levelIndicatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            levelIndicatorView.topAnchor.constraint(equalTo: contentView.topAnchor),
            levelIndicatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            colorDot.leadingAnchor.constraint(equalTo: levelIndicatorView.trailingAnchor, constant: 16),
            colorDot.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorDot.widthAnchor.constraint(equalToConstant: 10),
            colorDot.heightAnchor.constraint(equalToConstant: 10),
            
            titleLabel.leadingAnchor.constraint(equalTo: colorDot.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: statusIcon.leadingAnchor, constant: -8),
            
            statusIcon.trailingAnchor.constraint(equalTo: completeButton.leadingAnchor, constant: -8),
            statusIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusIcon.widthAnchor.constraint(equalToConstant: 20),
            statusIcon.heightAnchor.constraint(equalToConstant: 20),
            
            completeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            completeButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            completeButton.widthAnchor.constraint(equalToConstant: 44),
            completeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    // Configure
    
    func configure(with node: DependencyNode, showCompleteButton: Bool) {
        titleLabel.text = node.name
        
        // Level indentation (16pt per level)
        let indentation = CGFloat((node.level - 1) * 16)
        levelIndicatorWidthConstraint?.constant = indentation
        
        // Category color
        if let colorHex = node.categoryColorHex {
            colorDot.backgroundColor = UIColor(hex: colorHex)
        } else {
            colorDot.backgroundColor = .systemGray4
        }
        
        // Status
        if node.isCompleted {
            titleLabel.textColor = .systemGray
            let attributedString = NSMutableAttributedString(string: node.name)
            attributedString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: node.name.count))
            titleLabel.attributedText = attributedString
            
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            statusIcon.image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: config)
            statusIcon.tintColor = .systemGreen
        } else if node.isBlocking {
            titleLabel.textColor = .label
            
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            statusIcon.image = UIImage(systemName: "exclamationmark.circle.fill", withConfiguration: config)
            statusIcon.tintColor = .systemOrange
        } else {
            titleLabel.textColor = .label
            statusIcon.image = nil
        }
        
        completeButton.isHidden = !showCompleteButton
    }
    
    @objc private func completeTapped() {
        onCompleteTapped?()
    }
}

// DependencyPickerViewController

final class DependencyPickerViewController: UIViewController {
    
    private let tasks: [TaskEntity]
    var onTaskSelected: ((TaskEntity) -> Void)?
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "TaskCell")
        return table
    }()
    
    init(tasks: [TaskEntity]) {
        self.tasks = tasks
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Select Task"
        view.backgroundColor = .systemGroupedBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}

extension DependencyPickerViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        let task = tasks[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = task.name ?? "Untitled"
        config.secondaryText = task.category
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let task = tasks[indexPath.row]
        onTaskSelected?(task)
        dismiss(animated: true)
    }
}
