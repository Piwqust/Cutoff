import Foundation

enum Scorer {
    /// Grade the user's action against the full frequency distribution for the
    /// combo.
    ///
    ///   freq[user] ≥ 0.8             → `.correct` (100)
    ///   0.2 ≤ freq[user] < 0.8       → `.close`   (70)   — mixed-strategy neighbor
    ///   0.0 < freq[user] < 0.2       → `.mistake` (30)   — present but rare
    ///   freq[user] == 0 and far from dominant → `.punt`  (0)
    ///   freq[user] == 0 and adjacent to dominant → `.mistake` (30)
    ///
    /// "Far" = aggression-tier distance ≥ 3 from the dominant action.
    static func evaluate(user: PreflopAction, frequencies: HandFrequencies) -> AnswerOutcome {
        let f = frequencies[user]
        if f >= 0.8 { return .correct }
        if f >= 0.2 { return .close }
        if f > 0    { return .mistake }
        // freq[user] == 0 — judge by distance to the dominant action.
        let dominant = frequencies.dominantAction
        let dist = abs(user.aggressionTier - dominant.aggressionTier)
        return dist >= 3 ? .punt : .mistake
    }

    /// Convenience overload kept for legacy single-action callsites (e.g. the
    /// push/fold trainer that collapses every spot to fold-or-shove).
    static func evaluate(user: PreflopAction, correct: PreflopAction) -> AnswerOutcome {
        var f = HandFrequencies()
        f[correct] = 1
        return evaluate(user: user, frequencies: f)
    }
}
