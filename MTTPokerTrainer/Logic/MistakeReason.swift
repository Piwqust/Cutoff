import Foundation

/// Direction-of-error label for a single answer. Used by `MistakeExplainer` to
/// pick a teaching template and by `ReviewAnalyzer` to aggregate the kinds of
/// mistakes the user makes most often.
enum MistakeReason: String, CaseIterable, Hashable, Identifiable {
    case correct        // user nailed it (≥80% chart freq for chosen action)
    case missedMix      // mixed spot, user picked the minority leg
    case tooTight       // user folded, chart wanted to play
    case tooLoose       // user played, chart wanted to fold
    case wrongLine      // both folded out — user picked the wrong non-fold line
    case overcommit     // user jammed/3-bet, chart wanted call/raise
    case undercommit    // user called/raised, chart wanted jam/3-bet

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .correct:      return "Correct"
        case .missedMix:    return "Missed mix"
        case .tooTight:     return "Too tight"
        case .tooLoose:     return "Too loose"
        case .wrongLine:    return "Wrong line"
        case .overcommit:   return "Over-committed"
        case .undercommit:  return "Under-committed"
        }
    }

    var shortLabel: String {
        switch self {
        case .correct:      return "Correct"
        case .missedMix:    return "Mix"
        case .tooTight:     return "Tight"
        case .tooLoose:     return "Loose"
        case .wrongLine:    return "Wrong line"
        case .overcommit:   return "Over"
        case .undercommit:  return "Under"
        }
    }

    /// Classify a single answer given the chart's coarse-action frequencies for
    /// the played combo. `frequencies` should sum to ~1.0 across RangeAction
    /// values (fold/call/raise/threeBet/jam — `.mixed` is never an output).
    static func classify(
        userAction: RangeAction,
        frequencies: [RangeAction: Double]
    ) -> MistakeReason {
        let userFreq = frequencies[userAction] ?? 0
        if userFreq >= 0.8 { return .correct }
        if userFreq >= 0.2 { return .missedMix }

        let foldFreq = frequencies[.fold] ?? 0
        let chartFolds = foldFreq >= 0.5
        let userFolds = userAction == .fold

        if userFolds && !chartFolds { return .tooTight }
        if !userFolds && chartFolds { return .tooLoose }

        // Both played (or both folded but folded freq < 0.8 — already returned).
        // The error is choosing the wrong non-fold line. Distinguish over vs under
        // commitment by aggression-tier distance from the dominant play action.
        let dominantPlay = dominantNonFold(in: frequencies) ?? userAction
        let userTier = userAction.aggressionTier
        let chartTier = dominantPlay.aggressionTier
        if userTier > chartTier { return .overcommit }
        if userTier < chartTier { return .undercommit }
        return .wrongLine
    }

    private static func dominantNonFold(in freqs: [RangeAction: Double]) -> RangeAction? {
        freqs
            .filter { $0.key != .fold && $0.value > 0 }
            .max(by: { $0.value < $1.value })?
            .key
    }
}

/// Helper that collapses the fine-grained `HandFrequencies` (PreflopAction-keyed)
/// into the coarse `RangeAction` vocabulary used by the trainer UI and stored
/// in `QuizResult`. Mirrors `RangeAction.init(_ preflop:)`.
enum FrequencyCollapser {
    static func coarse(_ fine: HandFrequencies) -> [RangeAction: Double] {
        var out: [RangeAction: Double] = [:]
        for action in PreflopAction.allCases {
            let f = fine[action]
            guard f > 0 else { continue }
            let coarse = RangeAction(action)
            out[coarse, default: 0] += f
        }
        return out
    }
}
