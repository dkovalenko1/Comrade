import Foundation
import UIKit

final class TimerViewModel {

    // MARK: - Dependencies
    private let sessionService = SessionService.shared
    private let templateService = TemplateService.shared
    private let creditService = SocialCreditService.shared

    // MARK: - State
    var selectedMode: FocusMode = .casual
    private(set) var selectedTemplate: PomodoroTemplateModel?
    private let gracePeriod: TimeInterval = 9
    private var graceTimer: Timer?
    private var sessionStartDate: Date?
    private var graceExpired: Bool = false

    // MARK: - Outputs
    var onTimeUpdate: ((TimeInterval) -> Void)?
    var onProgressUpdate: ((CGFloat) -> Void)?
    var onPhaseUpdate: ((SessionPhase, Int, Int) -> Void)?
    var onStateChange: ((TimerState) -> Void)?
    var onTemplateUpdate: ((PomodoroTemplateModel?) -> Void)?
    var onCreditUpdate: ((SocialCredit) -> Void)?
    var onSessionComplete: (() -> Void)?
    var onSessionFail: ((String) -> Void)?
    var onGraceUpdate: ((TimeInterval) -> Void)?

    // MARK: - Init
    init() {
        setupCallbacks()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(creditChanged(_:)),
            name: .socialCreditChanged,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        graceTimer?.invalidate()
    }

    // MARK: - Public API

    func loadDefaultTemplate() {
        if let first = templateService.getPresetTemplates().first {
            selectedTemplate = first
            onTemplateUpdate?(first)
        } else {
            onTemplateUpdate?(nil)
        }
    }

    func applyTemplate(_ template: PomodoroTemplateModel) {
        selectedTemplate = template
        onTemplateUpdate?(template)
    }

    func startSession() {
        guard sessionService.state == .idle else { return }
        startGraceTimer()
        if let template = selectedTemplate {
            sessionService.startSession(template: template, mode: selectedMode)
        } else {
            let duration: TimeInterval = selectedMode == .hardcore ? 25 * 60 : 25 * 60
            sessionService.startSession(duration: duration, mode: selectedMode)
        }
    }

    func stopSession() {
        sessionService.stopSession()
        stopGraceTimer()
    }

    var currentDuration: TimeInterval {
        if sessionService.totalDuration > 0 {
            return sessionService.totalDuration
        }
        return selectedTemplate?.workDuration ?? 25 * 60
    }

    var isAfterGrace: Bool {
        if graceExpired { return true }
        guard let start = sessionStartDate else { return false }
        return Date().timeIntervalSince(start) >= gracePeriod
    }

    // MARK: - Private

    private func setupCallbacks() {
        sessionService.onTick = { [weak self] remaining in
            self?.onTimeUpdate?(remaining)
            self?.updateProgress()
        }

        sessionService.onSessionComplete = { [weak self] in
            self?.stopGraceTimer()
            self?.onSessionComplete?()
            self?.emitCredit()
        }

        sessionService.onSessionFail = { [weak self] reason in
            self?.stopGraceTimer()
            self?.onSessionFail?(reason)
            self?.emitCredit()
        }

        sessionService.onStateChange = { [weak self] state in
            self?.onStateChange?(state)
            if state == .idle {
                self?.stopGraceTimer()
            }
        }

        sessionService.onPhaseChange = { [weak self] phase in
            guard let self = self else { return }
            self.onPhaseUpdate?(phase, self.sessionService.currentCycle, self.sessionService.totalCycles)
        }
    }

    private func updateProgress() {
        guard sessionService.totalDuration > 0 else { return }
        let elapsed = sessionService.totalDuration - sessionService.remainingTime
        let progress = CGFloat(elapsed / sessionService.totalDuration)
        onProgressUpdate?(progress)
    }

    private func startGraceTimer() {
        stopGraceTimer()
        sessionStartDate = Date()
        graceExpired = false
        onGraceUpdate?(gracePeriod)
        graceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.sessionStartDate else { return }
            let remaining = self.gracePeriod - Date().timeIntervalSince(start)
            if remaining > 0 {
                self.onGraceUpdate?(remaining)
            } else {
                self.onGraceUpdate?(0)
                self.graceExpired = true
                self.stopGraceTimer(clearSessionStart: false)
            }
        }
    }

    private func stopGraceTimer(clearSessionStart: Bool = true) {
        graceTimer?.invalidate()
        graceTimer = nil
        if clearSessionStart {
            sessionStartDate = nil
            graceExpired = false
        }
        onGraceUpdate?(0)
    }

    private func emitCredit() {
        onCreditUpdate?(creditService.current)
    }

    func refreshCredit() {
        emitCredit()
    }

    @objc private func creditChanged(_ notification: Notification) {
        emitCredit()
    }
}
