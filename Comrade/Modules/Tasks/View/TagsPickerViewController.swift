import UIKit
import SnapKit

protocol TagsPickerDelegate: AnyObject {
    func tagsPicker(_ picker: TagsPickerViewController, didSelectTags tags: [TagEntity])
}

final class TagsPickerViewController: UIViewController {
    
    // Properties
    
    weak var delegate: TagsPickerDelegate?
    private let viewModel: TagsPickerViewModel
    
    // UI Elements
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.delegate = self
        table.dataSource = self
        table.register(TagPickerCell.self, forCellReuseIdentifier: TagPickerCell.identifier)
        table.allowsMultipleSelection = true
        return table
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("+ Add New Tag", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.appRed, for: .normal)
        button.addTarget(self, action: #selector(addNewTag), for: .touchUpInside)
        return button
    }()
    
    // Init
    
    init(selectedTags: [TagEntity] = []) {
        self.viewModel = TagsPickerViewModel(selectedTags: selectedTags)
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
        viewModel.loadTags()
    }
    
    // Setup
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(tableView)
        view.addSubview(addButton)
        
        addButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(44)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(addButton.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
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
        navigationItem.rightBarButtonItem?.tintColor = .appRed
    }
    
    private func bindViewModel() {
        viewModel.onTagsUpdated = { [weak self] in
            self?.tableView.reloadData()
            
            // Restore selection
            guard let self = self else { return }
            for (index, tag) in self.viewModel.allTags.enumerated() {
                if self.viewModel.isTagSelected(tag) {
                    let indexPath = IndexPath(row: index, section: 0)
                    self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
            }
        }
        
        viewModel.onError = { [weak self] message in
            self?.showAlert(title: "Error", message: message)
        }
    }
    
    // Actions
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func doneTapped() {
        delegate?.tagsPicker(self, didSelectTags: viewModel.selectedTagsArray)
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
                  let name = alert.textFields?.first?.text else {
                return
            }
            
            self.viewModel.createTag(named: name)
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
        return viewModel.allTags.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TagPickerCell.identifier, for: indexPath) as? TagPickerCell else {
            return UITableViewCell()
        }
        
        guard let tag = viewModel.tag(at: indexPath.row) else { return cell }
        let isSelected = viewModel.isTagSelected(tag)
        cell.configure(with: tag, isSelected: isSelected)
        
        return cell
    }
}

// UITableViewDelegate

extension TagsPickerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectTag(at: indexPath.row)
        
        if let cell = tableView.cellForRow(at: indexPath) as? TagPickerCell {
            cell.setSelected(true)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        viewModel.deselectTag(at: indexPath.row)
        
        if let cell = tableView.cellForRow(at: indexPath) as? TagPickerCell {
            cell.setSelected(false)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let tag = viewModel.tag(at: indexPath.row) else { return nil }
        
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
            guard let index = self?.viewModel.allTags.firstIndex(of: tag) else { return }
            self?.viewModel.deleteTag(at: index)
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
            guard let name = alert.textFields?.first?.text else { return }
            guard let index = self?.viewModel.allTags.firstIndex(of: tag) else { return }
            self?.viewModel.updateTag(at: index, name: name)
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
        view.layer.cornerRadius = 6
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        imageView.image = UIImage(systemName: "checkmark", withConfiguration: config)
        imageView.tintColor = .appRed
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
        
        colorDot.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 12, height: 12))
        }
        
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(colorDot.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(checkmarkImageView.snp.leading).offset(-8)
        }
        
        checkmarkImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
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
