import Foundation

enum SocialCreditTier: String, CaseIterable {
    case bronze
    case silver
    case gold
    case platinum

    var minScore: Int {
        switch self {
        case .bronze: return 0
        case .silver: return 200
        case .gold: return 500
        case .platinum: return 900
        }
    }

    var displayName: String {
        switch self {
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        case .platinum: return "Platinum"
        }
    }
}

struct SocialCredit {
    var id: UUID
    var currentScore: Int
    var totalEarned: Int
    var totalLost: Int
    var tier: SocialCreditTier
    var lastUpdate: Date

    init(
        id: UUID = UUID(),
        currentScore: Int = 100,
        totalEarned: Int = 100,
        totalLost: Int = 0,
        tier: SocialCreditTier = .bronze,
        lastUpdate: Date = Date()
    ) {
        self.id = id
        self.currentScore = currentScore
        self.totalEarned = totalEarned
        self.totalLost = totalLost
        self.tier = tier
        self.lastUpdate = lastUpdate
    }

    static func tier(for score: Int) -> SocialCreditTier {
        return SocialCreditTier.allCases
            .sorted { $0.minScore < $1.minScore }
            .last(where: { score >= $0.minScore }) ?? .bronze
    }
}
