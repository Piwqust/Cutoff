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

    /// Coarse-action overload, frequency-aware. Collapses the chart's
    /// fine-grained `HandFrequencies` into `RangeAction` buckets (via
    /// `FrequencyCollapser.coarse`) and applies the same threshold ladder as
    /// the `PreflopAction` overload — so a 60/40 raise/call spot grades the
    /// same on both surfaces.
    static func evaluate(user: RangeAction, frequencies: HandFrequencies) -> AnswerOutcome {
        let coarse = FrequencyCollapser.coarse(frequencies)
        let f = coarse[user] ?? 0
        if f >= 0.8 { return .correct }
        if f >= 0.2 { return .close }
        if f > 0    { return .mistake }
        let dominantCoarse = coarse.max(by: { $0.value < $1.value })?.key ?? .fold
        let dist = abs(user.aggressionTier - dominantCoarse.aggressionTier)
        return dist >= 3 ? .punt : .mistake
    }

    /// Legacy overload that grades against a single dominant `RangeAction`.
    /// Routes through the frequency-aware path with a synthetic 100% weight
    /// on `correct`, so call-sites without a chart still get verdicts that
    /// line up with the `PreflopAction`/`HandFrequencies` ladder.
    static func evaluate(user: RangeAction, correct: RangeAction) -> AnswerOutcome {
        let representative: PreflopAction
        switch correct {
        case .fold:     representative = .fold
        case .call:     representative = .call
        case .raise:    representative = .raise25x
        case .threeBet: representative = .raise3x
        case .jam:      representative = .shove
        case .mixed:    representative = .raise25x // never the dominant output
        }
        var f = HandFrequencies()
        f[representative] = 1
        return evaluate(user: user, frequencies: f)
    }
}
