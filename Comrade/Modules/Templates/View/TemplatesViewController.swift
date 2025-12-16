import UIKit
import SnapKit

final class TemplatesViewController: UIViewController {
    
    private let viewModel = TemplatesViewModel()
    
    // MARK: - UI Elements
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Templates"
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.textColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1.0)
        return label
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .systemBackground
        collection.delegate = self
        collection.dataSource = self
        collection.register(TemplateCell.self, forCellWithReuseIdentifier: TemplateCell.identifier)
        return collection
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        view.addSubview(titleLabel)
        view.addSubview(collectionView)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.equalToSuperview().offset(20)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func bindViewModel() {
        viewModel.onDataUpdated = { [weak self] in
            self?.collectionView.reloadData()
        }
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(80)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(80)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 16
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
}

// MARK: - DataSource & Delegate

extension TemplatesViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TemplateCell.identifier, for: indexPath) as? TemplateCell else {
            return UICollectionViewCell()
        }
        
        let item = viewModel.items[indexPath.row]
        let data = viewModel.getDetails(for: item)
        let isExpanded = viewModel.isExpanded(item)
        
        cell.configure(
            title: data.title,
            subtitle: data.subtitle,
            details: data.details,
            iconName: data.icon,
            buttonTitle: data.button,
            isExpanded: isExpanded
        )
        
        cell.onMainButtonTapped = { [weak self] in
            if case .createCustom = item {
                let editorVC = TemplateEditorViewController()
                let nav = UINavigationController(rootViewController: editorVC)

                self?.present(nav, animated: true)
            } else {
                print("Use template: \(data.title)")
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = viewModel.items[indexPath.row]
        let willExpand = !viewModel.isExpanded(item)

        
        viewModel.toggleExpansion(for: item)
        
        if let cell = collectionView.cellForItem(at: indexPath) as? TemplateCell {
            cell.setExpandedState(willExpand, animated: true)
        }
        
        collectionView.performBatchUpdates(nil, completion: nil)
        
        if willExpand {
            collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
        }
    }
}
