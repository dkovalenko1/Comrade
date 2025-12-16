import UIKit
import SnapKit

final class AchievementsViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let viewModel = AchievementsViewModel()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Achievements"
        view.backgroundColor = .appBackground
        setupTable()
        setupNavigation()
        bind()
        setupObservers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.load()
    }

    private func setupTable() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AchievementCell.self, forCellReuseIdentifier: "AchievementCell")
        tableView.backgroundColor = .appBackground
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        view.addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    private func setupNavigation() {
        let resetItem = UIBarButtonItem(
            title: "Reset",
            style: .plain,
            target: self,
            action: #selector(resetAchievementsTapped)
        )
        resetItem.tintColor = .systemRed
        navigationItem.rightBarButtonItem = resetItem
    }

    private func bind() {
        viewModel.onUpdate = { [weak self] in
            self?.tableView.reloadData()
        }
    }
}

extension AchievementsViewController {
    @objc private func resetAchievementsTapped() {
        let alert = UIAlertController(
            title: "Reset achievements?",
            message: "Удалить все ачивки и пересоздать при следующей загрузке.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            AchievementsService.shared.resetAllAchievements { _ in
                DispatchQueue.main.async {
                    self?.viewModel.load()
                }
            }
        })
        present(alert, animated: true)
    }
}

extension AchievementsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.achievements.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: "AchievementCell", for: indexPath) as? AchievementCell,
            let achievement = viewModel.achievement(at: indexPath.row)
        else { return UITableViewCell() }

        let progressText = viewModel.progressText(for: achievement)
        let progressValue = viewModel.progressValue(for: achievement)
        cell.configure(with: achievement, progressText: progressText, progressValue: progressValue)
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let achievement = viewModel.achievement(at: indexPath.row) else { return }

        let message = achievement.detail + "\nProgress: " + viewModel.progressText(for: achievement)
        let alert = UIAlertController(title: achievement.title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}


private extension AchievementsViewController {
    func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAchievementUnlocked),
            name: .achievementUnlocked,
            object: nil
        )
    }

    @objc func handleAchievementUnlocked() {
        viewModel.load()
    }
}
