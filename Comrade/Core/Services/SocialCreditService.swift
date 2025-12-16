import Foundation
import CoreData

final class SocialCreditService {

    static let shared = SocialCreditService()
    private let coreData = CoreDataStack.shared

    private let initialScore: Int = 100
    private var cache: SocialCredit?

    private init() {
        cache = loadOrCreate()
    }

    var current: SocialCredit {
        cache ?? loadOrCreate()
    }

    func addPoints(_ amount: Int, reason: String) {
        guard amount > 0 else { return }
        updateScore(by: amount, reason: reason)
    }

    func removePoints(_ amount: Int, reason: String) {
        guard amount > 0 else { return }
        updateScore(by: -amount, reason: reason)
    }

    func getCurrentTier() -> SocialCreditTier {
        SocialCredit.tier(for: current.currentScore)
    }
    
    func logCurrentBalance() {
        let credit = current
        print("SocialCredit current: score=\(credit.currentScore), tier=\(credit.tier.rawValue), earned=\(credit.totalEarned), lost=\(credit.totalLost)")
    }

    func resetToBaseline() {
        if let existing = coreData.fetchFirst(SocialCreditEntity.self, predicate: NSPredicate(value: true)) {
            coreData.delete(existing)
        }

        let baseline = baselineModel()
        let entity = coreData.create(SocialCreditEntity.self)
        apply(model: baseline, to: entity)
        coreData.save()
        cache = baseline

        print("SocialCredit reset to baseline: score=\(baseline.currentScore), tier=\(baseline.tier.rawValue)")
        NotificationCenter.default.post(name: .socialCreditChanged, object: nil, userInfo: ["score": baseline.currentScore, "tier": baseline.tier.rawValue, "reason": "reset"])
    }


    @discardableResult
    private func loadOrCreate() -> SocialCredit {
        if let existing = coreData.fetchFirst(SocialCreditEntity.self, predicate: NSPredicate(value: true)) {
            if var model = map(entity: existing) {
                if isEmpty(model: model) {
                    model = baselineModel()
                    apply(model: model, to: existing)
                    coreData.save()
                }
                cache = model
                return model
            }
        }

        let entity = coreData.create(SocialCreditEntity.self)
        entity.id = UUID()
        entity.currentScore = Int32(initialScore)
        entity.totalEarned = Int32(initialScore)
        entity.totalLost = 0
        entity.tier = SocialCredit.tier(for: initialScore).rawValue
        entity.lastUpdate = Date()

        coreData.save()

        let model = map(entity: entity) ?? SocialCredit()
        cache = model
        return model
    }

    private func updateScore(by delta: Int, reason: String) {
        guard let entity = coreData.fetchFirst(SocialCreditEntity.self, predicate: NSPredicate(value: true)) else {
            cache = loadOrCreate()
            return updateScore(by: delta, reason: reason)
        }

        guard var model = map(entity: entity) else {
            cache = loadOrCreate()
            return
        }

        if isEmpty(model: model) {
            model = baselineModel()
        }

        let newScore = max(0, model.currentScore + delta)

        model.currentScore = newScore
        if delta > 0 {
            model.totalEarned += delta
        } else {
            model.totalLost += abs(delta)
        }
        model.tier = SocialCredit.tier(for: newScore)
        model.lastUpdate = Date()

        apply(model: model, to: entity)
        coreData.save()

        cache = model

        let deltaDesc = delta > 0 ? "+\(delta)" : "\(delta)"
        print("SocialCredit updated: \(deltaDesc), score=\(model.currentScore), tier=\(model.tier.rawValue), reason=\(reason)")

        NotificationCenter.default.post(
            name: .socialCreditChanged,
            object: nil,
            userInfo: [
                "score": model.currentScore,
                "tier": model.tier.rawValue,
                "reason": reason
            ]
        )
    }

    private func map(entity: SocialCreditEntity) -> SocialCredit? {
        guard let id = entity.id else { return nil }
        let tier = SocialCreditTier(rawValue: entity.tier ?? "") ?? .bronze
        return SocialCredit(
            id: id,
            currentScore: Int(entity.currentScore),
            totalEarned: Int(entity.totalEarned),
            totalLost: Int(entity.totalLost),
            tier: tier,
            lastUpdate: entity.lastUpdate ?? Date()
        )
    }

    private func apply(model: SocialCredit, to entity: SocialCreditEntity) {
        entity.id = model.id
        entity.currentScore = Int32(model.currentScore)
        entity.totalEarned = Int32(model.totalEarned)
        entity.totalLost = Int32(model.totalLost)
        entity.tier = model.tier.rawValue
        entity.lastUpdate = model.lastUpdate
    }

    private func isEmpty(model: SocialCredit) -> Bool {
        return model.currentScore == 0 && model.totalEarned == 0 && model.totalLost == 0
    }

    private func baselineModel() -> SocialCredit {
        return SocialCredit(
            currentScore: initialScore,
            totalEarned: initialScore,
            totalLost: 0,
            tier: SocialCredit.tier(for: initialScore),
            lastUpdate: Date()
        )
    }
}
