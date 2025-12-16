import UIKit
import SnapKit

final class CategoryManagerViewController: UIViewController {
    
    // Properties
    
    private let categoryService = CategoryService.shared
    
    // UI Elements
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.delegate = self
        table.dataSource = self
        table.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.identifier)
        table.backgroundColor = .systemGroupedBackground
        return table
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        
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
    
    // Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigation()
    }
    
    // Setup
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(tableView)
        view.addSubview(addButton)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        addButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 56, height: 56))
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
        }
    }
    
    private func setupNavigation() {
        title = "Categories"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        closeButton.tintColor = .systemGray
        navigationItem.leftBarButtonItem = closeButton
        
        let resetButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.counterclockwise"),
            style: .plain,
            target: self,
            action: #selector(resetTapped)
        )
        resetButton.tintColor = .systemGray
        
        let editButton = UIBarButtonItem(
            title: tableView.isEditing ? "Done" : "Edit",
            style: .plain,
            target: self,
            action: #selector(editTapped)
        )
        editButton.tintColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        
        navigationItem.rightBarButtonItems = [editButton, resetButton]
    }
    
    // Actions
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func editTapped() {
        tableView.setEditing(!tableView.isEditing, animated: true)
        navigationItem.rightBarButtonItems?.first?.title = tableView.isEditing ? "Done" : "Edit"
    }
    
    @objc private func resetTapped() {
        let alert = UIAlertController(
            title: "Reset Categories",
            message: "This will restore default categories (Personal, Work, Studies) and remove all custom categories. Are you sure?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            self?.categoryService.resetToDefaults()
            self?.tableView.reloadData()
        })
        
        present(alert, animated: true)
    }
    
    @objc private func addButtonTapped() {
        showCategoryEditor(category: nil)
    }
    
    private func showCategoryEditor(category: Category?) {
        let isEditing = category != nil
        let title = isEditing ? "Edit Category" : "New Category"
        
        let alert = UIAlertController(title: title, message: "Choose a color after entering the name", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Category name"
            textField.text = category?.name
            textField.autocapitalizationType = .words
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Next", style: .default) { [weak self] _ in
            guard let self = self,
                  let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else { return }
            
            self.showColorPicker(for: name, existingCategory: category)
        })
        
        present(alert, animated: true)
    }
    
    private func showColorPicker(for name: String, existingCategory: Category?) {
        let alert = UIAlertController(title: "Choose Color", message: "Select a color for \"\(name)\"", preferredStyle: .actionSheet)
        
        let colors: [(title: String, hex: String)] = [
            ("🔵 Blue", "#007AFF"),
            ("🟢 Green", "#34C759"),
            ("🔴 Red", "#FF6B6B"),
            ("🟠 Orange", "#FF9500"),
            ("🟣 Purple", "#AF52DE"),
            ("🩷 Pink", "#FF2D55"),
            ("🩵 Cyan", "#5AC8FA"),
            ("🟤 Brown", "#A2845E")
        ]
        
        for color in colors {
            alert.addAction(UIAlertAction(title: color.title, style: .default) { [weak self] _ in
                guard let self = self else { return }
                
                if let category = existingCategory {
                    self.categoryService.updateCategory(category, name: name, colorHex: color.hex)
                } else {
                    self.categoryService.createCategory(name: name, colorHex: color.hex)
                }
                
                self.tableView.reloadData()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(alert, animated: true)
    }
    
    private func getColorIndex(for hex: String) -> Int {
        switch hex.uppercased() {
        case "#007AFF": return 0
        case "#34C759": return 1
        case "#FF6B6B", "#FF3B30": return 2
        case "#FF9500": return 3
        case "#AF52DE": return 4
        default: return 0
        }
    }
    
    private func getColorHex(for index: Int) -> String {
        switch index {
        case 0: return "#007AFF"
        case 1: return "#34C759"
        case 2: return "#FF6B6B"
        case 3: return "#FF9500"
        case 4: return "#AF52DE"
        default: return "#007AFF"
        }
    }
}

// UITableViewDataSource

extension CategoryManagerViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categoryService.categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CategoryCell.identifier, for: indexPath) as? CategoryCell else {
            return UITableViewCell()
        }
        
        let category = categoryService.categories[indexPath.row]
        cell.configure(with: category)
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Manage your task categories"
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "Default categories (Personal, Work, Studies) cannot be deleted."
    }
}

// UITableViewDelegate

extension CategoryManagerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let category = categoryService.categories[indexPath.row]
        
        // Don't allow editing default categories
        if category.isDefault {
            let alert = UIAlertController(
                title: "Default Category",
                message: "Default categories cannot be edited.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        showCategoryEditor(category: category)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let category = categoryService.categories[indexPath.row]
        return !category.isDefault
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let category = categoryService.categories[indexPath.row]
            
            let alert = UIAlertController(
                title: "Delete Category",
                message: "Are you sure you want to delete \"\(category.name)\"? Tasks in this category will keep their category name.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                self?.categoryService.deleteCategory(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            })
            
            present(alert, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        categoryService.moveCategory(from: sourceIndexPath.row, to: destinationIndexPath.row)
    }
}

// CategoryCell

final class CategoryCell: UITableViewCell {
    
    static let identifier = "CategoryCell"
    
    private let colorDot: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17)
        return label
    }()
    
    private let defaultBadge: UILabel = {
        let label = UILabel()
        label.text = "Default"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.isHidden = true
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(colorDot)
        contentView.addSubview(nameLabel)
        contentView.addSubview(defaultBadge)
        
        colorDot.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 16, height: 16))
        }
        
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(colorDot.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }
        
        defaultBadge.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
    }
    
    func configure(with category: Category) {
        nameLabel.text = category.name
        colorDot.backgroundColor = UIColor(hex: category.colorHex)
        defaultBadge.isHidden = !category.isDefault
        
        // Don't show disclosure indicator for default categories
        accessoryType = category.isDefault ? .none : .disclosureIndicator
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        colorDot.backgroundColor = nil
        defaultBadge.isHidden = true
        accessoryType = .none
    }
}
