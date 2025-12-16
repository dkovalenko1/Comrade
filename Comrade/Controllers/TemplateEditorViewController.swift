import UIKit
import SnapKit

final class TemplateEditorViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let nameField = UITextField()
    private let iconField = UITextField()

    private let workSlider = UISlider()
    private let workValueLabel = UILabel()
    private let shortBreakSlider = UISlider()
    private let shortBreakValueLabel = UILabel()
    private let longBreakSlider = UISlider()
    private let longBreakValueLabel = UILabel()

    private let cyclesValueLabel = UILabel()
    private let cyclesMinusButton = UIButton(type: .system)
    private let cyclesPlusButton = UIButton(type: .system)

    private let saveButton = UIButton(type: .system)

    private let service = TemplateService.shared
    private let template: PomodoroTemplateModel?

    private var workMinutes: Int = 25
    private var shortBreakMinutes: Int = 5
    private var longBreakMinutes: Int = 15
    private var cycles: Int = 4

    var onSave: ((PomodoroTemplateModel) -> Void)?

    init(template: PomodoroTemplateModel?) {
        self.template = template
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.template = nil
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = template == nil ? "New Template" : "Edit Template"

        setupNav()
        setupForm()
        populate()
    }

    private func setupNav() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = nil
    }

    private func setupForm() {
        // Setup save button first (at the bottom)
        saveButton.setTitle("Save", for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        saveButton.backgroundColor = .systemRed
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 12
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        view.addSubview(saveButton)

        saveButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12)
            make.height.equalTo(50)
        }

        view.addSubview(scrollView)

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(saveButton.snp.top).offset(-12)
        }

        stackView.axis = .vertical
        stackView.spacing = 20
        scrollView.addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-20)
            make.width.equalTo(scrollView).offset(-32)
        }

        nameField.borderStyle = .roundedRect
        nameField.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        addLabeledTextField(title: "Name", field: nameField, placeholder: "Enter the name you want")

        iconField.borderStyle = .roundedRect
        iconField.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
        addLabeledTextField(title: "Icon (1-2 emoji)", field: iconField, placeholder: "Enter the best emoji for this task")

        setupSlider(
            slider: workSlider,
            valueLabel: workValueLabel,
            title: "Work (minutes)",
            minValue: 1,
            maxValue: 120,
            initialValue: Float(workMinutes)
        )

        setupSlider(
            slider: shortBreakSlider,
            valueLabel: shortBreakValueLabel,
            title: "Short break (minutes)",
            minValue: 1,
            maxValue: 30,
            initialValue: Float(shortBreakMinutes)
        )

        setupSlider(
            slider: longBreakSlider,
            valueLabel: longBreakValueLabel,
            title: "Long break (minutes)",
            minValue: 5,
            maxValue: 60,
            initialValue: Float(longBreakMinutes)
        )

        setupCyclesStepper()
    }

    private func addLabeledTextField(title: String, field: UITextField, placeholder: String) {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .secondaryLabel
        titleLabel.text = title

        field.placeholder = placeholder

        let container = UIStackView(arrangedSubviews: [titleLabel, field])
        container.axis = .vertical
        container.spacing = 6

        stackView.addArrangedSubview(container)
    }

    private func setupSlider(slider: UISlider, valueLabel: UILabel, title: String, minValue: Float, maxValue: Float, initialValue: Float) {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .secondaryLabel
        titleLabel.text = title

        slider.minimumValue = minValue
        slider.maximumValue = maxValue
        slider.value = initialValue
        slider.tintColor = .systemRed
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)

        valueLabel.text = "\(Int(initialValue)) min"
        valueLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        valueLabel.textAlignment = .right
        valueLabel.textColor = .label

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        headerStack.axis = .horizontal
        headerStack.distribution = .equalSpacing

        let container = UIStackView(arrangedSubviews: [headerStack, slider])
        container.axis = .vertical
        container.spacing = 8

        stackView.addArrangedSubview(container)
    }

    private func setupCyclesStepper() {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .secondaryLabel
        titleLabel.text = "Cycles before long break (max 6)"

        cyclesValueLabel.text = "\(cycles)"
        cyclesValueLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        cyclesValueLabel.textAlignment = .center
        cyclesValueLabel.textColor = .label
        cyclesValueLabel.snp.makeConstraints { make in
            make.width.equalTo(50)
        }

        cyclesMinusButton.setTitle("−", for: .normal)
        cyclesMinusButton.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .regular)
        cyclesMinusButton.setTitleColor(.white, for: .normal)
        cyclesMinusButton.backgroundColor = .systemRed
        cyclesMinusButton.layer.cornerRadius = 25
        cyclesMinusButton.snp.makeConstraints { make in
            make.width.height.equalTo(50)
        }
        cyclesMinusButton.addTarget(self, action: #selector(cyclesMinusTapped), for: .touchUpInside)

        cyclesPlusButton.setTitle("+", for: .normal)
        cyclesPlusButton.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .regular)
        cyclesPlusButton.setTitleColor(.white, for: .normal)
        cyclesPlusButton.backgroundColor = .systemRed
        cyclesPlusButton.layer.cornerRadius = 25
        cyclesPlusButton.snp.makeConstraints { make in
            make.width.height.equalTo(50)
        }
        cyclesPlusButton.addTarget(self, action: #selector(cyclesPlusTapped), for: .touchUpInside)

        let buttonsStack = UIStackView(arrangedSubviews: [cyclesMinusButton, cyclesValueLabel, cyclesPlusButton])
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 20
        buttonsStack.alignment = .center
        buttonsStack.distribution = .equalCentering

        let container = UIStackView(arrangedSubviews: [titleLabel, buttonsStack])
        container.axis = .vertical
        container.spacing = 12
        container.alignment = .center

        stackView.addArrangedSubview(container)
    }

    private func populate() {
        if let template = template {
            nameField.text = template.name
            iconField.text = template.icon

            workMinutes = Int(template.workDuration / 60)
            shortBreakMinutes = Int(template.shortBreakDuration / 60)
            longBreakMinutes = Int(template.longBreakDuration / 60)
            cycles = template.cyclesBeforeLongBreak

            workSlider.value = Float(workMinutes)
            shortBreakSlider.value = Float(shortBreakMinutes)
            longBreakSlider.value = Float(longBreakMinutes)

            workValueLabel.text = "\(workMinutes) min"
            shortBreakValueLabel.text = "\(shortBreakMinutes) min"
            longBreakValueLabel.text = "\(longBreakMinutes) min"
            cyclesValueLabel.text = "\(cycles)"
        }
    }

    @objc private func sliderValueChanged(_ slider: UISlider) {
        let value = Int(slider.value)

        if slider == workSlider {
            workMinutes = value
            workValueLabel.text = "\(value) min"
        } else if slider == shortBreakSlider {
            shortBreakMinutes = value
            shortBreakValueLabel.text = "\(value) min"
        } else if slider == longBreakSlider {
            longBreakMinutes = value
            longBreakValueLabel.text = "\(value) min"
        }
    }

    @objc private func cyclesMinusTapped() {
        if cycles > 1 {
            cycles -= 1
            cyclesValueLabel.text = "\(cycles)"
        }
    }

    @objc private func cyclesPlusTapped() {
        if cycles < 6 {
            cycles += 1
            cyclesValueLabel.text = "\(cycles)"
        }
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        let nameInput = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let iconInput = iconField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let work = TimeInterval(workMinutes * 60)
        let short = TimeInterval(shortBreakMinutes * 60)
        let long = TimeInterval(longBreakMinutes * 60)

        let validation = validate(nameInput: nameInput, iconInput: iconInput, work: work, short: short, long: long, cycles: cycles)
        guard validation.isValid else {
            showError(message: validation.message)
            return
        }

        let model = PomodoroTemplateModel(
            id: template?.id ?? UUID(),
            name: validation.name,
            icon: validation.icon,
            workDuration: work,
            shortBreakDuration: short,
            longBreakDuration: long,
            cyclesBeforeLongBreak: cycles,
            isPreset: template?.isPreset ?? false,
            createdAt: template?.createdAt ?? Date(),
            updatedAt: Date()
        )

        let saved = service.upsert(model)
        onSave?(saved)
        dismiss(animated: true)
    }

    private func validate(nameInput: String, iconInput: String, work: TimeInterval, short: TimeInterval, long: TimeInterval, cycles: Int) -> (isValid: Bool, name: String, icon: String, message: String) {
        let iconCount = iconInput.count
        if iconCount == 0 {
            return (false, nameInput, iconInput, "Enter 1-2 emoji's as an icon.")
        }
        if iconCount > 2 {
            return (false, nameInput, iconInput, "Icon can be at most 2 characters long.")
        }

        let maxNameLength = iconCount == 1 ? 12 : 8
        if nameInput.count > maxNameLength {
            return (false, nameInput, iconInput, "Maximum length for the set of icons is \(maxNameLength) symbols.")
        }
        if nameInput.isEmpty {
            return (false, nameInput, iconInput, "Enter template name.")
        }
        if cycles > 6 || cycles < 1 {
            return (false, nameInput, iconInput, "Cycles must be between 1 and 6.")
        }
        if work <= 0 || short < 0 || long < 0 {
            return (false, nameInput, iconInput, "Enter valid time values.")
        }
        return (true, nameInput, iconInput, "")
    }

    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
