//
//  TemplateEditorViewController.swift
//  Comrade
//
//  Created by Bohdan Hupalo on 15.12.2025.
//


import UIKit
import SnapKit

final class TemplateEditorViewController: UIViewController {
    
    private let viewModel = TemplateEditorViewModel()
    
    // MARK: - UI Elements
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private lazy var cancelButton: UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
    }()
    
    private lazy var saveButton: UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
    }()
    
    
    private let nameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Template Name"
        tf.font = .systemFont(ofSize: 22, weight: .bold)
        tf.borderStyle = .none
        return tf
    }()
    
    private lazy var emojiCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 44, height: 44)
        layout.minimumLineSpacing = 8
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.delegate = self
        cv.dataSource = self
        cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "EmojiCell")
        return cv
    }()
    
    private let formStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .fill
        return stack
    }()
    
    // Sliders
    private lazy var workSlider = SliderRowView(title: "Work Duration", min: 5, max: 90, current: viewModel.workDuration, step: 5)
    private lazy var shortBreakSlider = SliderRowView(title: "Short Break", min: 1, max: 30, current: viewModel.shortBreakDuration, step: 1)
    private lazy var longBreakSlider = SliderRowView(title: "Long Break", min: 5, max: 60, current: viewModel.longBreakDuration, step: 5)
    
    private let cyclesContainer = UIView()
    private let cyclesLabel = UILabel()
    private let cyclesStepper = UIStepper()
    

    private let previewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let previewLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        
        viewModel.updatePattern()
        
        let defaultIndex = IndexPath(item: 0, section: 0)
        emojiCollectionView.selectItem(at: defaultIndex, animated: false, scrollPosition: .left)
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "New Template"
        
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(nameField)
        contentView.addSubview(emojiCollectionView)
        contentView.addSubview(formStack)
        contentView.addSubview(previewContainer)
        previewContainer.addSubview(previewLabel)
        
        setupCyclesView()
        
        formStack.addArrangedSubview(workSlider)
        formStack.addArrangedSubview(shortBreakSlider)
        formStack.addArrangedSubview(longBreakSlider)
        formStack.addArrangedSubview(cyclesContainer)
        
        // MARK: - Constraints
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        nameField.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(40)
        }
        
        emojiCollectionView.snp.makeConstraints { make in
            make.top.equalTo(nameField.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
        
        formStack.snp.makeConstraints { make in
            make.top.equalTo(emojiCollectionView.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        previewContainer.snp.makeConstraints { make in
            make.top.equalTo(formStack.snp.bottom).offset(40)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-40)
        }
        
        previewLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }
    
    private func setupCyclesView() {
        cyclesLabel.text = "Cycles before long break: \(viewModel.cycles)"
        cyclesLabel.font = .systemFont(ofSize: 15, weight: .medium)
        
        cyclesStepper.minimumValue = 2
        cyclesStepper.maximumValue = 6
        cyclesStepper.value = Double(viewModel.cycles)
        cyclesStepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)
        
        cyclesContainer.addSubview(cyclesLabel)
        cyclesContainer.addSubview(cyclesStepper)
        
        cyclesLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        
        cyclesStepper.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(4)
        }
        
        cyclesContainer.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
    }
    
    private func setupBindings() {
        nameField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)
        
        workSlider.onValueChange = { [weak self] val in
            self?.viewModel.workDuration = val
            self?.viewModel.updatePattern()
        }
        
        shortBreakSlider.onValueChange = { [weak self] val in
            self?.viewModel.shortBreakDuration = val
            self?.viewModel.updatePattern()
        }
        
        longBreakSlider.onValueChange = { [weak self] val in
            self?.viewModel.longBreakDuration = val
            self?.viewModel.updatePattern()
        }
        
        viewModel.onPatternUpdate = { [weak self] text in
            self?.previewLabel.text = "Pattern Preview:\n" + text
        }
        
        viewModel.onError = { [weak self] message in
            self?.showAlert(message)
        }
        
        viewModel.onSaveSuccess = { [weak self] in
            self?.dismiss(animated: true)
        }
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        viewModel.save()
    }
    
    @objc private func nameChanged() {
        viewModel.name = nameField.text ?? ""
    }
    
    @objc private func stepperChanged() {
        let val = Int(cyclesStepper.value)
        viewModel.cycles = val
        cyclesLabel.text = "Cycles before long break: \(val)"
        viewModel.updatePattern()
    }
    
    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Validation Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - CollectionView (Emoji Picker)

extension TemplateEditorViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.availableEmojis.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath)
        
        let label: UILabel
        if let existingLabel = cell.contentView.subviews.first as? UILabel {
            label = existingLabel
        } else {
            label = UILabel()
            label.font = .systemFont(ofSize: 30)
            label.textAlignment = .center
            cell.contentView.addSubview(label)
            label.snp.makeConstraints { make in make.edges.equalToSuperview() }
        }
        
        label.text = viewModel.availableEmojis[indexPath.item]
        
        let isSelected = indexPath == collectionView.indexPathsForSelectedItems?.first
        cell.backgroundColor = isSelected
            ? UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 0.2)
            : .secondarySystemBackground
        cell.layer.cornerRadius = 22
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.icon = viewModel.availableEmojis[indexPath.item]
        
        collectionView.visibleCells.forEach { cell in
            cell.backgroundColor = .secondarySystemBackground
        }
        
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.backgroundColor = UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 0.2)
        }
    }
}
