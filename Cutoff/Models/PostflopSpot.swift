import Foundation
import SwiftData

/// One bundled postflop training spot.
struct PostflopSpot: Codable, Hashable, Identifiable {
    let id: String
    let boardTexture: BoardTexture
    let board: [Card]
    let heroPosition: TablePosition
    let heroHand: HoleCards
    let potSizeBB: Double
    let effectiveStackBB: Double
    let stackDepth: Int
    /// True when hero is in position relative to villain (acts last).
    let isInPosition: Bool
    /// True when hero is the actor (no bet to call). When false, the spot is
    /// "facing a bet" and Check is unavailable.
    let isHeroToAct: Bool
    /// 1–3 actions with frequency weights summing to 1.0. Other actions
    /// implicitly have frequency 0.
    let correctActions: [String: Double]
    let explanation: String
    let source: RangeChart.SourcePayload

    /// Strongly-typed frequency lookup.
    func frequency(for action: PostflopAction) -> Double {
        correctActions[action.rawValue] ?? 0
    }

    /// Action with the highest weight; ties break by passive-first.
    var dominantAction: PostflopAction {
        let scored = PostflopAction.allCases.map { ($0, frequency(for: $0)) }
        return scored.max { lhs, rhs in
            if lhs.1 != rhs.1 { return lhs.1 < rhs.1 }
            return lhs.0.aggressionTier > rhs.0.aggressionTier
        }?.0 ?? .fold
    }

    /// Set of actions valid to render as buttons for this spot.
    var validActions: [PostflopAction] {
        var actions: [PostflopAction] = []
        if isHeroToAct {
            actions = [.check, .bet33, .bet67, .bet100]
            // Short-stack ⇒ allow shove as an open
            if effectiveStackBB <= 25 { actions.append(.shove) }
        } else {
            actions = [.fold, .call, .raise]
            if effectiveStackBB <= 25 { actions.append(.shove) }
        }
        return actions
    }
}

/// SwiftData record for an aggregate postflop drill session.
@Model
final class PostflopDrillSession {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var correct: Int
    var close: Int
    var mistake: Int
    var punt: Int

    init() {
        self.id = UUID()
        self.startedAt = .now
        self.endedAt = nil
        self.correct = 0
        self.close = 0
        self.mistake = 0
        self.punt = 0
    }

    var total: Int { correct + close + mistake + punt }
    var accuracy: Int {
        guard total > 0 else { return 0 }
        let weighted = correct * 100 + close * 70 + mistake * 30
        return Int((Double(weighted) / Double(total)).rounded())
    }
}

/// SwiftData record for one postflop attempt.
@Model
final class PostflopResult {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var spotID: String
    var userActionRaw: String
    var outcomeRaw: String
    var score: Int

    init(spotID: String, userAction: PostflopAction, outcome: AnswerOutcome) {
        self.id = UUID()
        self.createdAt = .now
        self.spotID = spotID
        self.userActionRaw = userAction.rawValue
        self.outcomeRaw = outcome.rawValue
        self.score = outcome.score
    }

    var userAction: PostflopAction { PostflopAction(rawValue: userActionRaw) ?? .fold }
    var outcome: AnswerOutcome { AnswerOutcome(rawValue: outcomeRaw) ?? .mistake }
}
