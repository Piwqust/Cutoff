import Foundation

enum PostflopScorer {
    /// Mirror the preflop scorer banding for postflop. Frequencies are read
    /// from `PostflopSpot.correctActions`.
    static func evaluate(user: PostflopAction, spot: PostflopSpot) -> AnswerOutcome {
        let f = spot.frequency(for: user)
        if f >= 0.8 { return .correct }
        if f >= 0.2 { return .close }
        if f > 0    { return .mistake }
        let dominant = spot.dominantAction
        let dist = abs(user.aggressionTier - dominant.aggressionTier)
        return dist >= 3 ? .punt : .mistake
    }
}
