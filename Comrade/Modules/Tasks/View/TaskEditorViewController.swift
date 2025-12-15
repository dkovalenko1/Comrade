import UIKit

final class TaskEditorViewController: UIViewController {
    
    // Properties
    
    private let viewModel: TaskEditorViewModel
    
    // UI Elements
    
    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = false
        scroll.keyboardDismissMode = .onDrag
        return scroll
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal)
        button.tintColor = .systemGray
        button.backgroundColor = .systemGray5
        button.layer.cornerRadius = 15
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        button.accessibilityIdentifier = "close_task_button"
        return button
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        button.setImage(UIImage(systemName: "checkmark", withConfiguration: config), for: .normal)
        button.tintColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        button.backgroundColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 0.15)
        button.layer.cornerRadius = 15
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        button.accessibilityIdentifier = "save_task_button"
        return button
    }()
    
    private lazy var nameTextField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = "Name"
        field.font = .systemFont(ofSize: 28, weight: .bold)
        field.textColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        field.delegate = self
        field.returnKeyType = .next
        field.accessibilityIdentifier = "task_name_field"
        return field
    }()
    
    private lazy var colorDot: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(hex: "#FF6B6B")
        view.layer.cornerRadius = 10
        return view
    }()
    
    private lazy var descriptionTextField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.placeholder = "Add description"
        field.font = .systemFont(ofSize: 16)
        field.textColor = .label
        field.delegate = self
        field.returnKeyType = .done
        return field
    }()
    
    private lazy var categoryRow: SettingsRowView = {
        let row = SettingsRowView(title: "Category", value: "Personal")
        row.translatesAutoresizingMaskIntoConstraints = false
        row.onTap = { [weak self] in self?.showCategoryPicker() }
        return row
    }()
    
    private lazy var tagsRow: SettingsRowView = {
        let row = SettingsRowView(title: "Tags", value: "")
        row.translatesAutoresizingMaskIntoConstraints = false
        row.onTap = { [weak self] in self?.showTagsPicker() }
        return row
    }()
    
    private lazy var priorityRow: ToggleRowView = {
        let row = ToggleRowView(title: "Priority")
        row.translatesAutoresizingMaskIntoConstraints = false
        row.isOn = false
        row.onToggle = { [weak self] isOn in
            self?.viewModel.priority = isOn ? .high : .medium
        }
        return row
    }()
    
    // Deadline Section
    private lazy var deadlineSectionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Deadline"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        return label
    }()
    
    private lazy var dateRow: SettingsRowView = {
        let row = SettingsRowView(title: "Date", value: "")
        row.translatesAutoresizingMaskIntoConstraints = false
        row.onTap = { [weak self] in self?.showDatePicker() }
        return row
    }()
    
    private lazy var timeRow: SettingsRowView = {
        let row = SettingsRowView(title: "Time", value: "")
        row.translatesAutoresizingMaskIntoConstraints = false
        row.onTap = { [weak self] in self?.showTimePicker() }
        return row
    }()
    
    private lazy var allDayRow: ToggleRowView = {
        let row = ToggleRowView(title: "All day")
        row.translatesAutoresizingMaskIntoConstraints = false
        row.isOn = true
        row.onToggle = { [weak self] isOn in
            self?.viewModel.deadlineIsAllDay = isOn
            self?.timeRow.isHidden = isOn
        }
        return row
    }()
    
    // Reminder Section
    private lazy var reminderSectionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Reminder"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        return label
    }()
    
    private lazy var reminderRow: SettingsRowView = {
        let row = SettingsRowView(title: "Multiple reminder", value: "")
        row.translatesAutoresizingMaskIntoConstraints = false
        row.onTap = { [weak self] in self?.showReminderPicker() }
        return row
    }()
    
    private lazy var relativeReminderRow: SettingsRowView = {
        let row = SettingsRowView(title: "Relative", value: "")
        row.translatesAutoresizingMaskIntoConstraints = false
        row.onTap = { [weak self] in self?.showRelativeReminderPicker() }
        return row
    }()
    
    private lazy var absoluteReminderRow: ToggleRowView = {
        let row = ToggleRowView(title: "Absolute")
        row.translatesAutoresizingMaskIntoConstraints = false
        row.isOn = true
        return row
    }()
    
    private lazy var dependenciesRow: SettingsRowView = {
        let row = SettingsRowView(title: "Dependencies", value: "")
        row.translatesAutoresizingMaskIntoConstraints = false
        row.onTap = { [weak self] in self?.showDependenciesPicker() }
        return row
    }()
    
    private lazy var addPhotoRow: SettingsRowView = {
        let row = SettingsRowView(title: "Add photo", value: "")
        row.translatesAutoresizingMaskIntoConstraints = false
        row.onTap = { [weak self] in self?.showPhotoPicker() }
        return row
    }()
    
    // Container views for grouping
    private lazy var mainFieldsContainer: UIView = createContainer()
    private lazy var deadlineContainer: UIView = createContainer()
    private lazy var reminderContainer: UIView = createContainer()
    private lazy var otherContainer: UIView = createContainer()
    
    // Init
    
    init(mode: TaskEditorMode) {
        self.viewModel = TaskEditorViewModel(mode: mode)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        loadData()
    }
    
    // Setup
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(closeButton)
        view.addSubview(saveButton)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        setupMainFieldsContainer()
        setupDeadlineContainer()
        setupReminderContainer()
        setupOtherContainer()
        
        contentView.addSubview(mainFieldsContainer)
        contentView.addSubview(deadlineContainer)
        contentView.addSubview(reminderContainer)
        contentView.addSubview(otherContainer)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            saveButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            saveButton.widthAnchor.constraint(equalToConstant: 30),
            saveButton.heightAnchor.constraint(equalToConstant: 30),
            
            scrollView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            mainFieldsContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            mainFieldsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainFieldsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            deadlineContainer.topAnchor.constraint(equalTo: mainFieldsContainer.bottomAnchor, constant: 24),
            deadlineContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            deadlineContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            reminderContainer.topAnchor.constraint(equalTo: deadlineContainer.bottomAnchor, constant: 24),
            reminderContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            reminderContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            otherContainer.topAnchor.constraint(equalTo: reminderContainer.bottomAnchor, constant: 16),
            otherContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            otherContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            otherContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
        ])
    }
    
    private func createContainer() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        return view
    }
    
    private func setupMainFieldsContainer() {
        mainFieldsContainer.addSubview(nameTextField)
        mainFieldsContainer.addSubview(colorDot)
        mainFieldsContainer.addSubview(descriptionTextField)
        mainFieldsContainer.addSubview(categoryRow)
        mainFieldsContainer.addSubview(tagsRow)
        mainFieldsContainer.addSubview(priorityRow)
        
        let divider1 = createDivider()
        let divider2 = createDivider()
        let divider3 = createDivider()
        let divider4 = createDivider()
        
        mainFieldsContainer.addSubview(divider1)
        mainFieldsContainer.addSubview(divider2)
        mainFieldsContainer.addSubview(divider3)
        mainFieldsContainer.addSubview(divider4)
        
        NSLayoutConstraint.activate([
            nameTextField.topAnchor.constraint(equalTo: mainFieldsContainer.topAnchor, constant: 16),
            nameTextField.leadingAnchor.constraint(equalTo: mainFieldsContainer.leadingAnchor, constant: 16),
            nameTextField.trailingAnchor.constraint(equalTo: colorDot.leadingAnchor, constant: -12),
            
            colorDot.centerYAnchor.constraint(equalTo: nameTextField.centerYAnchor),
            colorDot.trailingAnchor.constraint(equalTo: mainFieldsContainer.trailingAnchor, constant: -16),
            colorDot.widthAnchor.constraint(equalToConstant: 20),
            colorDot.heightAnchor.constraint(equalToConstant: 20),
            
            descriptionTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 8),
            descriptionTextField.leadingAnchor.constraint(equalTo: mainFieldsContainer.leadingAnchor, constant: 16),
            descriptionTextField.trailingAnchor.constraint(equalTo: mainFieldsContainer.trailingAnchor, constant: -16),
            
            divider1.topAnchor.constraint(equalTo: descriptionTextField.bottomAnchor, constant: 16),
            divider1.leadingAnchor.constraint(equalTo: mainFieldsContainer.leadingAnchor, constant: 16),
            divider1.trailingAnchor.constraint(equalTo: mainFieldsContainer.trailingAnchor),
            divider1.heightAnchor.constraint(equalToConstant: 1),
            
            categoryRow.topAnchor.constraint(equalTo: divider1.bottomAnchor),
            categoryRow.leadingAnchor.constraint(equalTo: mainFieldsContainer.leadingAnchor),
            categoryRow.trailingAnchor.constraint(equalTo: mainFieldsContainer.trailingAnchor),
            categoryRow.heightAnchor.constraint(equalToConstant: 48),
            
            divider2.topAnchor.constraint(equalTo: categoryRow.bottomAnchor),
            divider2.leadingAnchor.constraint(equalTo: mainFieldsContainer.leadingAnchor, constant: 16),
            divider2.trailingAnchor.constraint(equalTo: mainFieldsContainer.trailingAnchor),
            divider2.heightAnchor.constraint(equalToConstant: 1),
            
            tagsRow.topAnchor.constraint(equalTo: divider2.bottomAnchor),
            tagsRow.leadingAnchor.constraint(equalTo: mainFieldsContainer.leadingAnchor),
            tagsRow.trailingAnchor.constraint(equalTo: mainFieldsContainer.trailingAnchor),
            tagsRow.heightAnchor.constraint(equalToConstant: 48),
            
            divider3.topAnchor.constraint(equalTo: tagsRow.bottomAnchor),
            divider3.leadingAnchor.constraint(equalTo: mainFieldsContainer.leadingAnchor, constant: 16),
            divider3.trailingAnchor.constraint(equalTo: mainFieldsContainer.trailingAnchor),
            divider3.heightAnchor.constraint(equalToConstant: 1),
            
            priorityRow.topAnchor.constraint(equalTo: divider3.bottomAnchor),
            priorityRow.leadingAnchor.constraint(equalTo: mainFieldsContainer.leadingAnchor),
            priorityRow.trailingAnchor.constraint(equalTo: mainFieldsContainer.trailingAnchor),
            priorityRow.heightAnchor.constraint(equalToConstant: 48),
            priorityRow.bottomAnchor.constraint(equalTo: mainFieldsContainer.bottomAnchor),
        ])
    }
    
    private func setupDeadlineContainer() {
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(deadlineSectionLabel)
        
        deadlineContainer.addSubview(headerView)
        deadlineContainer.addSubview(dateRow)
        deadlineContainer.addSubview(timeRow)
        deadlineContainer.addSubview(allDayRow)
        
        let divider1 = createDivider()
        let divider2 = createDivider()
        deadlineContainer.addSubview(divider1)
        deadlineContainer.addSubview(divider2)
        
        NSLayoutConstraint.activate([
            deadlineSectionLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            deadlineSectionLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            headerView.topAnchor.constraint(equalTo: deadlineContainer.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: deadlineContainer.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: deadlineContainer.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 44),
            
            dateRow.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            dateRow.leadingAnchor.constraint(equalTo: deadlineContainer.leadingAnchor),
            dateRow.trailingAnchor.constraint(equalTo: deadlineContainer.trailingAnchor),
            dateRow.heightAnchor.constraint(equalToConstant: 48),
            
            divider1.topAnchor.constraint(equalTo: dateRow.bottomAnchor),
            divider1.leadingAnchor.constraint(equalTo: deadlineContainer.leadingAnchor, constant: 16),
            divider1.trailingAnchor.constraint(equalTo: deadlineContainer.trailingAnchor),
            divider1.heightAnchor.constraint(equalToConstant: 1),
            
            timeRow.topAnchor.constraint(equalTo: divider1.bottomAnchor),
            timeRow.leadingAnchor.constraint(equalTo: deadlineContainer.leadingAnchor),
            timeRow.trailingAnchor.constraint(equalTo: deadlineContainer.trailingAnchor),
            timeRow.heightAnchor.constraint(equalToConstant: 48),
            
            divider2.topAnchor.constraint(equalTo: timeRow.bottomAnchor),
            divider2.leadingAnchor.constraint(equalTo: deadlineContainer.leadingAnchor, constant: 16),
            divider2.trailingAnchor.constraint(equalTo: deadlineContainer.trailingAnchor),
            divider2.heightAnchor.constraint(equalToConstant: 1),
            
            allDayRow.topAnchor.constraint(equalTo: divider2.bottomAnchor),
            allDayRow.leadingAnchor.constraint(equalTo: deadlineContainer.leadingAnchor),
            allDayRow.trailingAnchor.constraint(equalTo: deadlineContainer.trailingAnchor),
            allDayRow.heightAnchor.constraint(equalToConstant: 48),
            allDayRow.bottomAnchor.constraint(equalTo: deadlineContainer.bottomAnchor),
        ])
        
        timeRow.isHidden = true
    }
    
    private func setupReminderContainer() {
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(reminderSectionLabel)
        
        reminderContainer.addSubview(headerView)
        reminderContainer.addSubview(reminderRow)
        reminderContainer.addSubview(relativeReminderRow)
        reminderContainer.addSubview(absoluteReminderRow)
        
        let divider1 = createDivider()
        let divider2 = createDivider()
        reminderContainer.addSubview(divider1)
        reminderContainer.addSubview(divider2)
        
        NSLayoutConstraint.activate([
            reminderSectionLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            reminderSectionLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            headerView.topAnchor.constraint(equalTo: reminderContainer.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: reminderContainer.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: reminderContainer.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 44),
            
            reminderRow.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            reminderRow.leadingAnchor.constraint(equalTo: reminderContainer.leadingAnchor),
            reminderRow.trailingAnchor.constraint(equalTo: reminderContainer.trailingAnchor),
            reminderRow.heightAnchor.constraint(equalToConstant: 48),
            
            divider1.topAnchor.constraint(equalTo: reminderRow.bottomAnchor),
            divider1.leadingAnchor.constraint(equalTo: reminderContainer.leadingAnchor, constant: 16),
            divider1.trailingAnchor.constraint(equalTo: reminderContainer.trailingAnchor),
            divider1.heightAnchor.constraint(equalToConstant: 1),
            
            relativeReminderRow.topAnchor.constraint(equalTo: divider1.bottomAnchor),
            relativeReminderRow.leadingAnchor.constraint(equalTo: reminderContainer.leadingAnchor),
            relativeReminderRow.trailingAnchor.constraint(equalTo: reminderContainer.trailingAnchor),
            relativeReminderRow.heightAnchor.constraint(equalToConstant: 48),
            
            divider2.topAnchor.constraint(equalTo: relativeReminderRow.bottomAnchor),
            divider2.leadingAnchor.constraint(equalTo: reminderContainer.leadingAnchor, constant: 16),
            divider2.trailingAnchor.constraint(equalTo: reminderContainer.trailingAnchor),
            divider2.heightAnchor.constraint(equalToConstant: 1),
            
            absoluteReminderRow.topAnchor.constraint(equalTo: divider2.bottomAnchor),
            absoluteReminderRow.leadingAnchor.constraint(equalTo: reminderContainer.leadingAnchor),
            absoluteReminderRow.trailingAnchor.constraint(equalTo: reminderContainer.trailingAnchor),
            absoluteReminderRow.heightAnchor.constraint(equalToConstant: 48),
            absoluteReminderRow.bottomAnchor.constraint(equalTo: reminderContainer.bottomAnchor),
        ])
    }
    
    private func setupOtherContainer() {
        otherContainer.addSubview(dependenciesRow)
        otherContainer.addSubview(addPhotoRow)
        
        let divider = createDivider()
        otherContainer.addSubview(divider)
        
        NSLayoutConstraint.activate([
            dependenciesRow.topAnchor.constraint(equalTo: otherContainer.topAnchor),
            dependenciesRow.leadingAnchor.constraint(equalTo: otherContainer.leadingAnchor),
            dependenciesRow.trailingAnchor.constraint(equalTo: otherContainer.trailingAnchor),
            dependenciesRow.heightAnchor.constraint(equalToConstant: 48),
            
            divider.topAnchor.constraint(equalTo: dependenciesRow.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: otherContainer.leadingAnchor, constant: 16),
            divider.trailingAnchor.constraint(equalTo: otherContainer.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),
            
            addPhotoRow.topAnchor.constraint(equalTo: divider.bottomAnchor),
            addPhotoRow.leadingAnchor.constraint(equalTo: otherContainer.leadingAnchor),
            addPhotoRow.trailingAnchor.constraint(equalTo: otherContainer.trailingAnchor),
            addPhotoRow.heightAnchor.constraint(equalToConstant: 48),
            addPhotoRow.bottomAnchor.constraint(equalTo: otherContainer.bottomAnchor),
        ])
    }
    
    private func createDivider() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray5
        return view
    }
    
    private func bindViewModel() {
        viewModel.onValidationError = { [weak self] message in
            self?.showAlert(title: "Error", message: message)
        }
        
        viewModel.onSaveSuccess = { [weak self] _ in
            self?.dismiss(animated: true)
        }
        
        viewModel.onSaveError = { [weak self] message in
            self?.showAlert(title: "Error", message: message)
        }
    }
    
    private func loadData() {
        nameTextField.text = viewModel.name
        descriptionTextField.text = viewModel.taskDescription
        categoryRow.setValue(viewModel.category)
        colorDot.backgroundColor = UIColor(hex: viewModel.categoryColorHex)
        priorityRow.isOn = viewModel.priority == .high
        
        if let deadline = viewModel.deadline {
            updateDeadlineDisplay(deadline)
        }
        
        allDayRow.isOn = viewModel.deadlineIsAllDay
        timeRow.isHidden = viewModel.deadlineIsAllDay
        
        updateTagsDisplay()
        updateRemindersDisplay()
        updateDependenciesDisplay()
    }
    
    // Actions
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        viewModel.name = nameTextField.text ?? ""
        viewModel.taskDescription = descriptionTextField.text ?? ""
        viewModel.save()
    }
    
    // Pickers
    
    private func showCategoryPicker() {
        let alert = UIAlertController(title: "Select Category", message: nil, preferredStyle: .actionSheet)
        
        for category in viewModel.availableCategories {
            alert.addAction(UIAlertAction(title: category.name, style: .default) { [weak self] _ in
                self?.viewModel.setCategory(category.name)
                self?.categoryRow.setValue(category.name)
                self?.colorDot.backgroundColor = UIColor(hex: category.colorHex)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Manage Categories", style: .default) { [weak self] _ in
            self?.showCategoryManager()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = categoryRow
        }
        
        present(alert, animated: true)
    }
    
    private func showCategoryManager() {
        let categoryVC = CategoryManagerViewController()
        let navController = UINavigationController(rootViewController: categoryVC)
        present(navController, animated: true)
    }
    
    // Tags Picker
    
    private func showTagsPicker() {
        let tagsPickerVC = TagsPickerViewController(selectedTags: viewModel.selectedTags)
        tagsPickerVC.delegate = self
        let navController = UINavigationController(rootViewController: tagsPickerVC)
        present(navController, animated: true)
    }
    
    private func updateTagsDisplay() {
        let count = viewModel.selectedTags.count
        if count == 0 {
            tagsRow.setValue("")
        } else if count == 1 {
            tagsRow.setValue(viewModel.selectedTags.first?.name ?? "")
        } else {
            tagsRow.setValue("\(count) tags")
        }
    }
    
    private func showDatePicker() {
        let alert = UIAlertController(title: "Select Date", message: "\n\n\n\n\n\n\n\n\n", preferredStyle: .actionSheet)
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.date = viewModel.deadline ?? Date()
        datePicker.frame = CGRect(x: 0, y: 50, width: alert.view.bounds.width - 20, height: 200)
        
        alert.view.addSubview(datePicker)
        
        alert.addAction(UIAlertAction(title: "Done", style: .default) { [weak self] _ in
            self?.viewModel.deadline = datePicker.date
            self?.updateDeadlineDisplay(datePicker.date)
        })
        
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            self?.viewModel.deadline = nil
            self?.dateRow.setValue("")
            self?.timeRow.setValue("")
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = dateRow
        }
        
        present(alert, animated: true)
    }
    
    private func showTimePicker() {
        let alert = UIAlertController(title: "Select Time", message: "\n\n\n\n\n\n\n\n\n", preferredStyle: .actionSheet)
        
        let timePicker = UIDatePicker()
        timePicker.datePickerMode = .time
        timePicker.preferredDatePickerStyle = .wheels
        timePicker.date = viewModel.deadline ?? Date()
        timePicker.frame = CGRect(x: 0, y: 50, width: alert.view.bounds.width - 20, height: 200)
        
        alert.view.addSubview(timePicker)
        
        alert.addAction(UIAlertAction(title: "Done", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: timePicker.date)
            
            if var deadline = self.viewModel.deadline {
                deadline = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                        minute: timeComponents.minute ?? 0,
                                        second: 0,
                                        of: deadline) ?? deadline
                self.viewModel.deadline = deadline
                self.updateDeadlineDisplay(deadline)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = timeRow
        }
        
        present(alert, animated: true)
    }
    
    private func showReminderPicker() {
        showRelativeReminderPicker()
    }
    
    private func showRelativeReminderPicker() {
        let alert = UIAlertController(title: "Add Reminder", message: nil, preferredStyle: .actionSheet)
        
        for reminder in viewModel.availableRelativeReminders {
            alert.addAction(UIAlertAction(title: reminder.title, style: .default) { [weak self] _ in
                self?.viewModel.addRelativeReminder(minutes: reminder.minutes)
                self?.updateRemindersDisplay()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = relativeReminderRow
        }
        
        present(alert, animated: true)
    }
    
    private func showDependenciesPicker() {
        let alert = UIAlertController(title: "Dependencies", message: nil, preferredStyle: .actionSheet)
        
        // View dependency chain (only in edit mode)
        if case .edit(let task) = viewModel.mode {
            alert.addAction(UIAlertAction(title: "View Dependency Chain", style: .default) { [weak self] _ in
                self?.showDependencyChain(for: task)
            })
        }
        
        // Add new dependency
        alert.addAction(UIAlertAction(title: "Add Dependency", style: .default) { [weak self] _ in
            self?.showAddDependencyPicker()
        })
        
        // Remove dependency (if any exist)
        if !viewModel.dependencies.isEmpty {
            alert.addAction(UIAlertAction(title: "Remove Dependency", style: .destructive) { [weak self] _ in
                self?.showRemoveDependencyPicker()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = dependenciesRow
        }
        
        present(alert, animated: true)
    }
    
    private func showDependencyChain(for task: TaskEntity) {
        let chainVC = DependencyChainViewController(
            task: task,
            pendingDependencies: viewModel.dependencies
        )
        
        // Handle changes made in dependency chain
        chainVC.onDependenciesChanged = { [weak self] updatedDependencies in
            self?.viewModel.dependencies = updatedDependencies
            self?.updateDependenciesDisplay()
        }
        
        let navController = UINavigationController(rootViewController: chainVC)
        present(navController, animated: true)
    }
    
    private func showAddDependencyPicker() {
        let availableTasks = viewModel.getAvailableTasksForDependency()
        
        if availableTasks.isEmpty {
            showAlert(title: "No Tasks", message: "There are no other tasks to add as dependencies")
            return
        }
        
        let alert = UIAlertController(title: "Add Dependency", message: "Select a task that must be completed first", preferredStyle: .actionSheet)
        
        for task in availableTasks.prefix(10) {
            alert.addAction(UIAlertAction(title: task.name ?? "Untitled", style: .default) { [weak self] _ in
                self?.viewModel.addDependency(task)
                self?.updateDependenciesDisplay()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = dependenciesRow
        }
        
        present(alert, animated: true)
    }
    
    private func showRemoveDependencyPicker() {
        let alert = UIAlertController(title: "Remove Dependency", message: nil, preferredStyle: .actionSheet)
        
        for (index, task) in viewModel.dependencies.enumerated() {
            alert.addAction(UIAlertAction(title: task.name ?? "Untitled", style: .destructive) { [weak self] _ in
                self?.viewModel.removeDependency(at: index)
                self?.updateDependenciesDisplay()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = dependenciesRow
        }
        
        present(alert, animated: true)
    }
    
    private func showPhotoPicker() {
        let alert = UIAlertController(title: "Add Photo", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
                self?.presentImagePicker(sourceType: .camera)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Choose from Library", style: .default) { [weak self] _ in
            self?.presentImagePicker(sourceType: .photoLibrary)
        })
        
        if viewModel.photoData != nil {
            alert.addAction(UIAlertAction(title: "Remove Photo", style: .destructive) { [weak self] _ in
                self?.viewModel.removePhoto()
                self?.addPhotoRow.setValue("")
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = addPhotoRow
        }
        
        present(alert, animated: true)
    }
    
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    // Helpers
    
    private func updateDeadlineDisplay(_ date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        dateRow.setValue(dateFormatter.string(from: date))
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeRow.setValue(timeFormatter.string(from: date))
    }
    
    private func updateRemindersDisplay() {
        let count = viewModel.reminders.count
        if count == 0 {
            reminderRow.setValue("")
        } else {
            reminderRow.setValue("\(count) reminder\(count == 1 ? "" : "s")")
        }
    }
    
    private func updateDependenciesDisplay() {
        let count = viewModel.dependencies.count
        if count == 0 {
            dependenciesRow.setValue("")
        } else {
            dependenciesRow.setValue("\(count) task\(count == 1 ? "" : "s")")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// UITextFieldDelegate

extension TaskEditorViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            descriptionTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}

// UIImagePickerControllerDelegate

extension TaskEditorViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            if let data = image.jpegData(compressionQuality: 0.8) {
                viewModel.setPhoto(data)
                addPhotoRow.setValue("Photo added")
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// TagsPickerDelegate

extension TaskEditorViewController: TagsPickerDelegate {
    func tagsPicker(_ picker: TagsPickerViewController, didSelectTags tags: [TagEntity]) {
        viewModel.selectedTags = tags
        updateTagsDisplay()
    }
}
