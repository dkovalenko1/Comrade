//
//  TasksViewController.swift
//  Comrade
//
//  Created by Savelii Kozlov on 11.12.2025.
//

import UIKit

final class TasksViewController: UIViewController {
    
    // Properties
    
    private let viewModel = TasksViewModel()
    
    // UI Elements
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(TaskCell.self, forCellReuseIdentifier: TaskCell.identifier)
        table.register(TaskSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: TaskSectionHeaderView.identifier)
        table.separatorStyle = .none
        table.backgroundColor = .systemGroupedBackground
        table.showsVerticalScrollIndicator = false
        return table
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let image = UIImage(systemName: "plus", withConfiguration: config)
        button.setImage(image, for: .normal)
        
        button.tintColor = .white
        button.backgroundColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0) // Coral/Red color
        button.layer.cornerRadius = 28
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.layer.shadowOpacity = 0.2
        
        button.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var searchController: UISearchController = {
        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search tasks"
        return search
    }()
    
    private lazy var filterButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            style: .plain,
            target: self,
            action: #selector(filterButtonTapped)
        )
        button.tintColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
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
        stackView.spacing = 16
        
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark.circle")
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
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
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
    }()
    
    // Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        bindViewModel()
        viewModel.loadTasks()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadTasks()
    }
    
    // Setup
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            addButton.widthAnchor.constraint(equalToConstant: 56),
            addButton.heightAnchor.constraint(equalToConstant: 56),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupNavigationBar() {
        title = "Tasks"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Title color
        let appearance = UINavigationBarAppearance()
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        ]
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        navigationItem.rightBarButtonItem = filterButton
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true
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
        print("Add task tapped")
        
        // Placeholder: Create a test task
        let categories = ["Personal", "Work", "Studies"]
        let randomCategory = categories.randomElement() ?? "Personal"
        
        TaskService.shared.createTask(
            name: "New Task \(Int.random(in: 1...100))",
            category: randomCategory,
            priority: .medium
        )
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
        
        // For iPad
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = filterButton
        }
        
        present(alert, animated: true)
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
        
        cell.configure(with: task)
        cell.onCheckboxTapped = { [weak self] in
            self?.viewModel.toggleTaskCompletion(at: indexPath.section, row: indexPath.row)
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 56
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let task = viewModel.task(at: indexPath.section, row: indexPath.row) else { return }
        
        // TODO: Navigate to TaskEditorViewController for editing
        print("Selected task: \(task.name ?? "Unknown")")
    }
    
    // Swipe actions
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        // Delete action
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
            self?.confirmDelete(at: indexPath)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = .systemRed
        
        // Edit action
        let editAction = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completion in
            self?.editTask(at: indexPath)
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
    
    private func editTask(at indexPath: IndexPath) {
        guard let task = viewModel.task(at: indexPath.section, row: indexPath.row) else { return }
        // TODO: Navigate to TaskEditorViewController
        print("Edit task: \(task.name ?? "Unknown")")
    }
}

// UISearchResultsUpdating

extension TasksViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text ?? ""
        viewModel.search(query)
    }
}
