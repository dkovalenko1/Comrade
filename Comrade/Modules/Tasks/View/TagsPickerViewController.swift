import UIKit

protocol TagsPickerDelegate: AnyObject {
    func tagsPicker(_ picker: TagsPickerViewController, didSelectTags tags: [TagEntity])
}

final class TagsPickerViewController: UIViewController {
    
    // Properties
    
    weak var delegate: TagsPickerDelegate?
    
    private let tagService = TagService.shared
    private var allTags: [TagEntity] = []
    private var selectedTags: Set<TagEntity> = []
    
    // UI Elements
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(TagPickerCell.self, forCellReuseIdentifier: TagPickerCell.identifier)
        table.allowsMultipleSelection = true
        return table
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("+ Add New Tag", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0), for: .normal)
        button.addTarget(self, action: #selector(addNewTag), for: .touchUpInside)
        return button
    }()
    
    // Init
    
    init(selectedTags: [TagEntity] = []) {
        super.init(nibName: nil, bundle: nil)
        self.selectedTags = Set(selectedTags)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigation()
        loadTags()
    }
    
    // Setup
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(tableView)
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addButton.heightAnchor.constraint(equalToConstant: 44),
            
            tableView.topAnchor.constraint(equalTo: addButton.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavigation() {
        title = "Tags"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
    }
    
    private func loadTags() {
        allTags = tagService.fetchAllTags()
        tableView.reloadData()
        
        // Restore selection
        for (index, tag) in allTags.enumerated() {
            if selectedTags.contains(tag) {
                let indexPath = IndexPath(row: index, section: 0)
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
        }
    }
    
    // Actions
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func doneTapped() {
        delegate?.tagsPicker(self, didSelectTags: Array(selectedTags))
        dismiss(animated: true)
    }
    
    @objc private func addNewTag() {
        let alert = UIAlertController(title: "New Tag", message: "Enter tag name", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Tag name"
            textField.autocapitalizationType = .words
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let self = self,
                  let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else {
                return
            }
            
            let colorHex = self.tagService.randomColorHex()
            if let newTag = self.tagService.createTag(name: name, colorHex: colorHex) {
                self.selectedTags.insert(newTag)
                self.loadTags()
            } else {
                self.showAlert(title: "Error", message: "Tag with this name already exists")
            }
        })
        
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// UITableViewDataSource

extension TagsPickerViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allTags.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TagPickerCell.identifier, for: indexPath) as? TagPickerCell else {
            return UITableViewCell()
        }
        
        let tag = allTags[indexPath.row]
        let isSelected = selectedTags.contains(tag)
        cell.configure(with: tag, isSelected: isSelected)
        
        return cell
    }
}

// UITableViewDelegate

extension TagsPickerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tag = allTags[indexPath.row]
        selectedTags.insert(tag)
        
        if let cell = tableView.cellForRow(at: indexPath) as? TagPickerCell {
            cell.setSelected(true)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let tag = allTags[indexPath.row]
        selectedTags.remove(tag)
        
        if let cell = tableView.cellForRow(at: indexPath) as? TagPickerCell {
            cell.setSelected(false)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let tag = allTags[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.confirmDeleteTag(tag, at: indexPath)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, completion in
            self?.editTag(tag)
            completion(true)
        }
        editAction.backgroundColor = .systemBlue
        editAction.image = UIImage(systemName: "pencil")
        
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
    
    private func confirmDeleteTag(_ tag: TagEntity, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: "Delete Tag",
            message: "Are you sure you want to delete \"\(tag.name ?? "this tag")\"?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.selectedTags.remove(tag)
            self?.tagService.deleteTag(tag)
            self?.loadTags()
        })
        
        present(alert, animated: true)
    }
    
    private func editTag(_ tag: TagEntity) {
        let alert = UIAlertController(title: "Edit Tag", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.text = tag.name
            textField.placeholder = "Tag name"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else {
                return
            }
            
            self?.tagService.updateTag(tag, name: name)
            self?.loadTags()
        })
        
        present(alert, animated: true)
    }
}

// TagPickerCell

final class TagPickerCell: UITableViewCell {
    
    static let identifier = "TagPickerCell"
    
    // UI Elements
    
    private let colorDot: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 6
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        imageView.image = UIImage(systemName: "checkmark", withConfiguration: config)
        imageView.tintColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        imageView.isHidden = true
        return imageView
    }()
    
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
        colorDot.backgroundColor = .systemGray
        nameLabel.text = nil
        checkmarkImageView.isHidden = true
    }
    
    // Setup
    
    private func setupUI() {
        selectionStyle = .none
        
        contentView.addSubview(colorDot)
        contentView.addSubview(nameLabel)
        contentView.addSubview(checkmarkImageView)
        
        NSLayoutConstraint.activate([
            colorDot.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            colorDot.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorDot.widthAnchor.constraint(equalToConstant: 12),
            colorDot.heightAnchor.constraint(equalToConstant: 12),
            
            nameLabel.leadingAnchor.constraint(equalTo: colorDot.trailingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: checkmarkImageView.leadingAnchor, constant: -8),
            
            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    // Configuration
    
    func configure(with tag: TagEntity, isSelected: Bool) {
        nameLabel.text = tag.name
        colorDot.backgroundColor = UIColor(hex: tag.colorHex ?? "#888888")
        checkmarkImageView.isHidden = !isSelected
    }
    
    func setSelected(_ selected: Bool) {
        checkmarkImageView.isHidden = !selected
    }
}
