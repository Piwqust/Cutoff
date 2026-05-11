import Foundation

enum Scorer {
    /// Score a user's action against the "correct" action for the spot.
    ///
    /// - exact match     → `.correct` (100)
    /// - close action    → `.close`   (70)   — e.g. raise vs 3-bet on a marginal hand
    /// - strategic miss  → `.mistake` (30)
    /// - punt            → `.punt`    (0)    — e.g. jamming a fold-only hand
    static func evaluate(user: RangeAction, correct: RangeAction) -> AnswerOutcome {
        if user == correct { return .correct }
        if correct == .mixed { return .close }  // any non-punt response is at least close vs mixed

        switch (user, correct) {
        // Raise vs 3-bet / jam — same direction, different aggression
        case (.raise, .threeBet), (.threeBet, .raise),
             (.raise, .jam),      (.jam, .raise),
             (.threeBet, .jam),   (.jam, .threeBet):
            return .close

        // Call vs raise — passive vs aggressive but same direction
        case (.call, .raise), (.raise, .call):
            return .close

        // Folding when correct line is to play, or playing when correct line is to fold
        // — that's a genuine mistake but not a punt.
        case (.fold, _), (_, .fold):
            return .mistake

        // Jamming when the correct action is .call — that's a punt.
        case (.jam, .call), (.call, .jam):
            return .punt

        default:
            return .mistake
        }
    }
}
