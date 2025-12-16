import UIKit
import SnapKit

class TimerViewController: UIViewController {

    // MARK: - UI Components

    // Mode Toggle
    private let modesLabel = UILabel()
    private let infoButton = UIButton(type: .system)
    private let templatesLabel = UILabel()
    private let modeToggleButton = UIButton(type: .system)
    private let templateButton = UIButton(type: .system)
    private let resetCreditsButton = UIButton(type: .system)

    // Social Credit
    private let creditContainer = UIView()
    private let tierDot = UIView()
    private let tierLabel = UILabel()
    private let scoreLabel = UILabel()
    private let progressView = UIProgressView(progressViewStyle: .bar)

    // Timer
    private let circularProgressView = CircularProgressView()
    private let timeLabel = UILabel()

    // Phase Indicators
    private let phaseStackView = UIStackView()
    private let phaseContainer = UIView()
    private let totalCycleLabel = UILabel()
    private let phaseDescriptionLabel = UILabel()

    // Control Buttons
    private let playButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)

    // MARK: - Properties

    private let viewModel = TimerViewModel()
    private var isRunning = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupViewModelBindings()
        updateModeButtons()
        viewModel.loadDefaultTemplate()
        updateCreditUI(with: SocialCreditService.shared.current)
        NotificationCenter.default.addObserver(self, selector: #selector(onCreditNotification(_:)), name: .socialCreditChanged, object: nil)
        SocialCreditService.shared.logCurrentBalance()
    }

    // MARK: - Setup UI

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.98, green: 0.97, blue: 0.96, alpha: 1.0)

        setupModeToggle()
        setupCreditIndicator()
        setupTimer()
        setupPhaseIndicators()
        setupControlButtons()
    }

    private func setupModeToggle() {
        // Modes label
        modesLabel.text = "Modes"
        modesLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        modesLabel.textColor = .gray
        view.addSubview(modesLabel)

        infoButton.setImage(UIImage(systemName: "info.circle"), for: .normal)
        infoButton.tintColor = .gray
        infoButton.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        infoButton.addTarget(self, action: #selector(infoTapped), for: .touchUpInside)
        view.addSubview(infoButton)

        // Templates label
        templatesLabel.text = "Templates"
        templatesLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        templatesLabel.textColor = .gray
        view.addSubview(templatesLabel)

        // Mode toggle button
        modeToggleButton.setTitle("Casual", for: .normal)
        modeToggleButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        modeToggleButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.2)
        modeToggleButton.setTitleColor(.systemRed, for: .normal)
        modeToggleButton.layer.cornerRadius = 20
        modeToggleButton.accessibilityIdentifier = "modeToggleButton"
        modeToggleButton.addTarget(self, action: #selector(modeToggleTapped), for: .touchUpInside)
        view.addSubview(modeToggleButton)

        // Template button (uses slot of old hardcore button)
        templateButton.setTitle("Select template", for: .normal)
        templateButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        templateButton.backgroundColor = .systemRed
        templateButton.setTitleColor(.white, for: .normal)
        templateButton.layer.cornerRadius = 20
        templateButton.accessibilityIdentifier = "templateButton"
        templateButton.addTarget(self, action: #selector(templateTapped), for: .touchUpInside)
        view.addSubview(templateButton)

        // Reset credits button
        resetCreditsButton.setTitle("Reset credits", for: .normal)
        resetCreditsButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        resetCreditsButton.setTitleColor(.systemRed, for: .normal)
        resetCreditsButton.addTarget(self, action: #selector(resetCreditsTapped), for: .touchUpInside)
        view.addSubview(resetCreditsButton)
    }

    private func setupCreditIndicator() {
        creditContainer.backgroundColor = .white
        creditContainer.layer.cornerRadius = 14
        creditContainer.layer.shadowColor = UIColor.black.cgColor
        creditContainer.layer.shadowOpacity = 0.05
        creditContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        creditContainer.layer.shadowRadius = 6

        tierDot.layer.cornerRadius = 6
        tierDot.clipsToBounds = true

        tierLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        tierLabel.textColor = .darkGray

        scoreLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        scoreLabel.textColor = .gray

        progressView.trackTintColor = UIColor.systemGray5
        progressView.progressTintColor = .systemRed
        progressView.layer.cornerRadius = 1.5
        progressView.clipsToBounds = true

        let labelsStack = UIStackView(arrangedSubviews: [tierLabel, scoreLabel, progressView])
        labelsStack.axis = .vertical
        labelsStack.spacing = 2

        let contentStack = UIStackView(arrangedSubviews: [tierDot, labelsStack])
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = 10

        creditContainer.addSubview(contentStack)
        view.addSubview(creditContainer)

        tierDot.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 12, height: 12))
        }
        
        contentStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(10)
        }
        
        progressView.snp.makeConstraints { make in
            make.height.equalTo(3)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(creditTapped))
        creditContainer.addGestureRecognizer(tap)
        creditContainer.isUserInteractionEnabled = true
    }


    private func setupTimer() {
        // Circular progress
        view.addSubview(circularProgressView)

        // Time label
        timeLabel.text = "25:00"
        timeLabel.font = UIFont.systemFont(ofSize: 60, weight: .light)
        timeLabel.textColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        timeLabel.textAlignment = .center
        view.addSubview(timeLabel)
    }

    private func setupPhaseIndicators() {
        // Phase stack (dots)
        phaseStackView.axis = .horizontal
        phaseStackView.alignment = .center
        phaseStackView.spacing = 24
        phaseContainer.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        phaseContainer.layer.cornerRadius = 14
        phaseContainer.layer.shadowColor = UIColor.black.cgColor
        phaseContainer.layer.shadowOpacity = 0.05
        phaseContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        phaseContainer.layer.shadowRadius = 6
        phaseContainer.addSubview(phaseStackView)
        view.addSubview(phaseContainer)

        totalCycleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        totalCycleLabel.textColor = .darkGray
        totalCycleLabel.textAlignment = .center
        totalCycleLabel.text = ""
        view.addSubview(totalCycleLabel)

        // Description
        phaseDescriptionLabel.text = "Select a template to start"
        phaseDescriptionLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        phaseDescriptionLabel.textColor = .gray
        phaseDescriptionLabel.textAlignment = .center
        view.addSubview(phaseDescriptionLabel)
    }

    private func createPhaseDot(filled: Bool, color: UIColor = .systemRed, symbol: String = "🧠") -> UIView {
        let container = UIView()

        if filled {
            let dot = UIView()
            dot.backgroundColor = color
            dot.layer.cornerRadius = 6
            container.addSubview(dot)

            dot.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 12, height: 12))
                make.center.equalToSuperview()
            }
        } else {
            let label = UILabel()
            label.text = symbol
            label.font = UIFont.systemFont(ofSize: 16)
            label.textAlignment = .center
            container.addSubview(label)

            label.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
        }

        return container
    }

    private func setupControlButtons() {
        // Play button
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = .white
        playButton.backgroundColor = .systemRed
        playButton.layer.cornerRadius = 40
        playButton.layer.shadowColor = UIColor.systemRed.cgColor
        playButton.layer.shadowOpacity = 0.3
        playButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        playButton.layer.shadowRadius = 8
        playButton.accessibilityIdentifier = "playButton"
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        view.addSubview(playButton)

        // Stop button
        stopButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
        stopButton.tintColor = .gray
        stopButton.backgroundColor = .white
        stopButton.layer.cornerRadius = 30
        stopButton.layer.shadowColor = UIColor.black.cgColor
        stopButton.layer.shadowOpacity = 0.1
        stopButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        stopButton.layer.shadowRadius = 4
        stopButton.accessibilityIdentifier = "stopButton"
        stopButton.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)
        stopButton.isEnabled = false
        stopButton.alpha = 0.4
        view.addSubview(stopButton)
    }

    // MARK: - Constraints

    private func setupConstraints() {
        // Mode Toggle
        modesLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(-29)
            make.leading.equalToSuperview().offset(20)
        }
        
        infoButton.snp.makeConstraints { make in
            make.centerY.equalTo(modesLabel)
            make.leading.equalTo(modesLabel.snp.trailing).offset(6)
            make.size.equalTo(CGSize(width: 18, height: 18))
        }
        
        templatesLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(-29)
            make.trailing.equalToSuperview().inset(20)
        }
        
        modeToggleButton.snp.makeConstraints { make in
            make.top.equalTo(modesLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(20)
            make.size.equalTo(CGSize(width: 110, height: 40))
        }
        
        templateButton.snp.makeConstraints { make in
            make.top.equalTo(templatesLabel.snp.bottom).offset(8)
            make.trailing.equalToSuperview().inset(20)
            make.width.greaterThanOrEqualTo(140)
            make.height.equalTo(40)
        }
        
        creditContainer.snp.makeConstraints { make in
            make.top.equalTo(modeToggleButton.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().inset(20)
        }
        
        // Circular Progress
        circularProgressView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(creditContainer.snp.bottom).offset(24)
            make.size.equalTo(CGSize(width: 280, height: 280))
        }
        
        // Time Label
        timeLabel.snp.makeConstraints { make in
            make.center.equalTo(circularProgressView)
        }
        
        // Phase Indicators + total
        totalCycleLabel.snp.makeConstraints { make in
            make.top.equalTo(circularProgressView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }
        
        phaseContainer.snp.makeConstraints { make in
            make.top.equalTo(totalCycleLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.height.equalTo(32)
            make.leading.greaterThanOrEqualToSuperview().offset(40)
            make.trailing.lessThanOrEqualToSuperview().inset(40)
        }
        
        phaseStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
        }
        
        phaseDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(phaseContainer.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
        
        // Control Buttons
        playButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(phaseDescriptionLabel.snp.bottom).offset(40)
            make.size.equalTo(CGSize(width: 80, height: 80))
        }
        
        stopButton.snp.makeConstraints { make in
            make.leading.equalTo(playButton.snp.trailing).offset(32)
            make.centerY.equalTo(playButton)
            make.size.equalTo(CGSize(width: 60, height: 60))
        }
        
        resetCreditsButton.snp.makeConstraints { make in
            make.top.equalTo(stopButton.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
        }
    }

    // MARK: - SessionService Callbacks

    private func setupViewModelBindings() {
        viewModel.onTimeUpdate = { [weak self] remainingTime in
            self?.updateTimeLabel(remainingTime)
        }

        viewModel.onProgressUpdate = { [weak self] progress in
            self?.circularProgressView.setProgress(progress, animated: false)
        }

        viewModel.onPhaseUpdate = { [weak self] phase, currentCycle, _ in
            guard let self = self else { return }
            if let template = self.viewModel.selectedTemplate {
                self.updatePhaseIndicators(for: template, currentPhase: phase, currentCycle: currentCycle)
                switch phase {
                case .work:
                    self.phaseDescriptionLabel.text = "Now: Focus for \(Int(template.workDuration / 60)) minutes"
                case .shortBreak:
                    self.phaseDescriptionLabel.text = "Now: Short break \(Int(template.shortBreakDuration / 60)) min"
                case .longBreak:
                    self.phaseDescriptionLabel.text = "Now: Long break \(Int(template.longBreakDuration / 60)) min"
                }
            } else {
                self.updatePhaseIndicators(for: nil, currentPhase: phase, currentCycle: currentCycle)
            }
        }

        viewModel.onStateChange = { [weak self] state in
            self?.updateUIForState(state)
        }

        viewModel.onSessionComplete = { [weak self] in
            self?.handleSessionComplete()
        }

        viewModel.onSessionFail = { [weak self] reason in
            self?.handleSessionFail(reason)
        }

        viewModel.onTemplateUpdate = { [weak self] template in
            guard let self = self else { return }
            if let template = template {
                self.applyTemplateToUI(template)
            } else {
                self.templateButton.setTitle("Select template", for: .normal)
                self.updatePhaseIndicators(for: nil, currentPhase: .work)
                self.phaseDescriptionLabel.text = "Now: Focus for 25 minutes"
                self.timeLabel.text = self.formatTime(25 * 60)
            }
        }

        viewModel.onGraceUpdate = { [weak self] remaining in
            guard let self = self else { return }
            if remaining > 0 {
                self.stopButton.setTitle("\(Int(ceil(remaining)))s", for: .normal)
            } else {
                self.stopButton.setTitle(nil, for: .normal)
            }
        }
    }

    // MARK: - Actions

    @objc private func modeToggleTapped() {
        viewModel.selectedMode = viewModel.selectedMode == .casual ? .hardcore : .casual
        updateModeButtons()
    }

    @objc private func playTapped() {
        guard viewModelIsIdle else { return }
        isRunning = true
        stopButton.isEnabled = true
        stopButton.alpha = 1.0
        viewModel.startSession()
        timeLabel.text = formatTime(viewModel.currentDuration)
    }

    @objc private func stopTapped() {
        guard !viewModelIsIdle else { return }

        let afterGrace = viewModel.isAfterGrace

        let proceedStop: () -> Void = { [weak self] in
            self?.viewModel.stopSession()
            self?.resetUI()
        }

        if afterGrace {
            let alert = UIAlertController(
                title: "Do you want to give up?",
                message: "You will be penalized for stopping this session.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Give up", style: .destructive) { _ in
                proceedStop()
            })
            present(alert, animated: true)
        } else {
            proceedStop()
        }
    }

    // MARK: - Helper Methods

    private func updateModeButtons() {
        let isHardcore = viewModel.selectedMode == .hardcore
        modeToggleButton.setTitle(isHardcore ? "Hardcore" : "Casual", for: .normal)
        if isHardcore {
            modeToggleButton.backgroundColor = .systemRed
            modeToggleButton.setTitleColor(.white, for: .normal)
        } else {
            modeToggleButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.2)
            modeToggleButton.setTitleColor(.systemRed, for: .normal)
        }
    }

    @objc private func infoTapped() {
        let message = """
Casual: the timer keeps running in the background, default rewards

Hardcore: If you close the app, you fail, but you will receive double rewards if you pass it; penalties are also higher.

You can stop the timer without any credit loss within the first 9 seconds.
"""
        let alert = UIAlertController(title: "Mode", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Accept", style: .default))
        present(alert, animated: true)
    }

    @objc private func resetCreditsTapped() {
        let alert = UIAlertController(
            title: "Reset Credits?",
            message: "Set social credit back to the baseline (100 points). This action cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { _ in
            SocialCreditService.shared.resetToBaseline()
            SocialCreditService.shared.logCurrentBalance()
        })
        present(alert, animated: true)
    }

    private func updateTimeLabel(_ time: TimeInterval) {
        timeLabel.text = formatTime(time)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func handleSessionComplete() {
        let alert = UIAlertController(
            title: "Session Complete!",
            message: "Great job! You've completed your focus session.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.resetUI()
        })
        present(alert, animated: true)
    }

    private func handleSessionFail(_ reason: String) {
        // If user gave up (stop after grace), silently reset without alert
        if reason == "Session aborted" {
            resetUI()
            return
        }

        let alert = UIAlertController(
            title: "Session Failed",
            message: reason,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.resetUI()
        })
        present(alert, animated: true)
    }

    private func updateUIForState(_ state: TimerState) {
        switch state {
        case .idle:
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            stopButton.isEnabled = false
            stopButton.alpha = 0.4
            templateButton.isEnabled = true
            templateButton.alpha = 1.0
            isRunning = false
        case .running:
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            stopButton.isEnabled = true
            stopButton.alpha = 1.0
            templateButton.isEnabled = false
            templateButton.alpha = 0.5
        case .completed, .failed:
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            stopButton.isEnabled = false
            stopButton.alpha = 0.4
            templateButton.isEnabled = true
            templateButton.alpha = 1.0
            isRunning = false
        }
    }

    private var viewModelIsIdle: Bool {
        return SessionService.shared.state == .idle
    }

    private func updatePhaseIndicators(for template: PomodoroTemplateModel?, currentPhase: SessionPhase, currentCycle: Int = 1) {
        phaseStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        guard let template = template else {
            let dot = createPhaseDot(filled: true)
            phaseStackView.addArrangedSubview(dot)
            return
        }

        let cycles = max(1, template.cyclesBeforeLongBreak)
        let currentCycleIndex = currentCycle
        for index in 1...cycles {
            let isCurrentWork = currentPhase == .work && currentCycleIndex == index
            let workDot = createPhaseDot(filled: isCurrentWork)
            phaseStackView.addArrangedSubview(workDot)

            if index < cycles {
                let isCurrentBreak = currentPhase == .shortBreak && currentCycleIndex == index
                let breakDot = createPhaseDot(filled: isCurrentBreak, color: UIColor.systemGray3, symbol: "☕️")
                phaseStackView.addArrangedSubview(breakDot)
            }
        }

        // Long break indicator
        if template.longBreakDuration > 0 {
            let isLongBreak = currentPhase == .longBreak
            let longBreakDot = createPhaseDot(filled: isLongBreak, color: UIColor.systemGray2, symbol: "🧘🏼")
            phaseStackView.addArrangedSubview(longBreakDot)
        }
    }

    @objc private func templateTapped() {
        guard viewModelIsIdle else { return }

        let picker = TemplatePickerViewController()
        picker.modalPresentationStyle = .pageSheet
        picker.onSelect = { [weak self] template in
            self?.viewModel.applyTemplate(template)
        }
        present(picker, animated: true)
    }

    private func resetUI() {
        circularProgressView.reset()
        viewModel.stopSession()
        if let template = viewModel.selectedTemplate {
            timeLabel.text = formatTime(template.workDuration)
            updatePhaseIndicators(for: template, currentPhase: .work, currentCycle: 1)
            phaseDescriptionLabel.text = "Now: Focus for \(Int(template.workDuration / 60)) minutes"
            totalCycleLabel.text = totalCycleText(for: template)
        } else {
            timeLabel.text = formatTime(viewModel.currentDuration)
            updatePhaseIndicators(for: nil, currentPhase: .work, currentCycle: 1)
            phaseDescriptionLabel.text = "Now: Focus for \(Int(viewModel.currentDuration / 60)) minutes"
            totalCycleLabel.text = ""
        }
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        stopButton.isEnabled = false
        stopButton.alpha = 0.4
        stopButton.setTitle(nil, for: .normal)
        stopButton.layer.borderWidth = 0
        isRunning = false
    }

    private func applyTemplateToUI(_ template: PomodoroTemplateModel) {
        templateButton.setTitle("\(template.icon) \(template.name)", for: .normal)
        timeLabel.text = formatTime(template.workDuration)
        updatePhaseIndicators(for: template, currentPhase: .work, currentCycle: 1)
        phaseDescriptionLabel.text = "Now: Focus for \(Int(template.workDuration / 60)) minutes"
        totalCycleLabel.text = totalCycleText(for: template)
    }

    private func updateCreditUI(with credit: SocialCredit) {
        tierLabel.text = credit.tier.displayName
        scoreLabel.text = "\(credit.currentScore) pts"
        tierDot.backgroundColor = color(for: credit.tier)

        let nextTierMin = SocialCreditTier.allCases
            .sorted { $0.minScore < $1.minScore }
            .first(where: { $0.minScore > credit.tier.minScore })?.minScore

        if let next = nextTierMin {
            let span = max(1, next - credit.tier.minScore)
            let progress = Float(credit.currentScore - credit.tier.minScore) / Float(span)
            progressView.setProgress(max(0, min(progress, 1)), animated: true)
        } else {
            progressView.setProgress(1, animated: false)
        }
    }

    private func color(for tier: SocialCreditTier) -> UIColor {
        switch tier {
        case .bronze: return UIColor(red: 0.8, green: 0.54, blue: 0.33, alpha: 1)
        case .silver: return UIColor(red: 0.65, green: 0.72, blue: 0.78, alpha: 1)
        case .gold: return UIColor(red: 0.95, green: 0.73, blue: 0.2, alpha: 1)
        case .platinum: return UIColor(red: 0.6, green: 0.62, blue: 0.9, alpha: 1)
        }
    }

    @objc private func creditTapped() {
        let message = """
Base balance: 100 points.
Earn: +\(Int(viewModel.currentDuration / 60)) per session (x2 in Hardcore).
Penalty: -15 if you fail. Score can't be less than 0.
"""
        let alert = UIAlertController(title: "Social Credit", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func onCreditNotification(_ notification: Notification) {
        updateCreditUI(with: SocialCreditService.shared.current)
    }

    private func totalCycleText(for template: PomodoroTemplateModel) -> String {
        let work = template.workDuration * Double(template.cyclesBeforeLongBreak)
        let short = template.shortBreakDuration * Double(max(0, template.cyclesBeforeLongBreak - 1))
        let long = template.longBreakDuration
        let totalSeconds = work + short + long
        return "Total cycle: \(formatDurationVerbose(totalSeconds))"
    }

    private func formatDurationVerbose(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        var parts: [String] = []
        if hours > 0 { parts.append("\(hours)h") }
        if minutes > 0 { parts.append("\(minutes)m") }
        if hours == 0 && minutes == 0 {
            parts.append("\(secs)s")
        }

        return parts.joined(separator: " ")
    }
}
