import UIKit
import SnapKit

final class TemplatePickerViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let addButton = UIButton(type: .system)

    private var templates: [PomodoroTemplateModel] = []
    var onSelect: ((PomodoroTemplateModel) -> Void)?

    private let service = TemplateService.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Templates"

        setupTableView()
        setupAddButton()
        loadTemplates()
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TemplateCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(70)
        }
    }

    private func setupAddButton() {
        addButton.setTitle("Create Custom", for: .normal)
        addButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        addButton.backgroundColor = .systemRed
        addButton.setTitleColor(.white, for: .normal)
        addButton.layer.cornerRadius = 12
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        view.addSubview(addButton)

        addButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(12)
            make.height.equalTo(50)
        }
    }

    private func loadTemplates() {
        templates = service.getAllTemplates()
        tableView.reloadData()
    }

    @objc private func addTapped() {
        let editor = TemplateEditorViewController(template: nil)
        editor.onSave = { [weak self] saved in
            self?.loadTemplates()
            self?.onSelect?(saved)
            self?.dismiss(animated: true)
        }
        let nav = UINavigationController(rootViewController: editor)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }
}

extension TemplatePickerViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return templates.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let template = templates[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? TemplateCell else {
            return UITableViewCell()
        }
        cell.configure(with: template)
        cell.onEdit = { [weak self] in
            self?.presentEdit(for: template)
        }
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let template = templates[indexPath.row]
        onSelect?(template)
        dismiss(animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let template = templates[indexPath.row]
        guard template.isPreset == false else { return nil }

        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.service.delete(id: template.id)
            self?.loadTemplates()
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }

    private func presentEdit(for template: PomodoroTemplateModel) {
        let editor = TemplateEditorViewController(template: template)
        editor.onSave = { [weak self] saved in
            self?.loadTemplates()
            self?.onSelect?(saved)
        }
        let nav = UINavigationController(rootViewController: editor)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }
}
