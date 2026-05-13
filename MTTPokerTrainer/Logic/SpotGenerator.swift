import Foundation

/// Picks a random combo from a chart, weighted toward "decision" hands — i.e.
/// avoid asking the user 70% trivial folds (72o) or 5% obvious raises (AA).
///
/// "Decision" = a hand where no single action has frequency ≥ 0.9 (i.e. the
/// spot is genuinely mixed). We pick from those 70% of the time; otherwise
/// sample uniformly across all 169 combos.
struct SpotGenerator {
    let chart: RangeChart

    func next(rng: inout SystemRandomNumberGenerator) -> (combo: HandCombo, frequencies: HandFrequencies) {
        let decisionKeys: [String] = chart.hands.filter { _, freqs in
            !PreflopAction.allCases.contains(where: { freqs[$0] >= 0.9 })
        }.map { $0.key }

        if !decisionKeys.isEmpty && Int.random(in: 0..<10, using: &rng) < 7,
           let pick = decisionKeys.randomElement(using: &rng),
           let combo = HandCombo.parse(pick) {
            return (combo, chart.frequencies(for: combo))
        }
        let combo = HandCombo.allInMatrixOrder.randomElement(using: &rng) ?? HandCombo.allInMatrixOrder[0]
        return (combo, chart.frequencies(for: combo))
    }
}

/// Human-friendly explanation that respects the "no solver jargon" rule.
enum ExplanationBuilder {
    static func explain(spot: TrainingSpot, combo: HandCombo, frequencies: HandFrequencies) -> String {
        let pos = spot.position.displayName
        let bb = spot.stackDepthBB
        let dominant = frequencies.dominantAction
        let dominantPct = Int(round((frequencies[dominant]) * 100))

        if frequencies.isMixed {
            return "Mixed at \(pos) · \(bb) BB. \(dominant.displayName) ~\(dominantPct)% of the time; other actions have non-trivial weight."
        }

        switch (dominant, spot.facingAction) {
        case (.minRaise, .unopened), (.raise25x, .unopened), (.raise3x, .unopened):
            return "Open. \(pos) at \(bb) BB opens this hand."
        case (.fold, .unopened):
            return "Fold. Too weak from \(pos) at \(bb) BB."
        case (.raise3x, .vsOpen):
            return "3-bet. Strong enough to put pressure on the opener at \(bb) BB."
        case (.call, .vsOpen):
            return "Call. Defends well from \(pos) at \(bb) BB."
        case (.fold, .vsOpen):
            return "Fold. Dominated too often to defend profitably."
        case (.shove, _):
            return "Jam. At \(bb) BB this hand has the right mix of fold equity and showdown."
        case (.fold, .pushFold):
            return "Fold. Not enough equity to shove at \(bb) BB."
        case (.limp, _):
            return "Limp. At \(bb) BB you can complete the small blind here."
        case (.limpRaise, _):
            return "Limp/3-bet. Strong enough to limp/3-bet for value."
        case (.raise3x, .vs3Bet):
            return "4-bet. Continue with strength vs the 3-bet."
        case (.call, .vs3Bet):
            return "Call. Realises equity vs the 3-bet without inflating the pot."
        case (.fold, .vs3Bet):
            return "Fold. Not strong enough to continue."
        default:
            return "\(dominant.displayName) at \(pos) · \(bb) BB."
        }
    }

    static func explain(spot: TrainingSpot, combo: HandCombo, correct: PreflopAction) -> String {
        var freqs = HandFrequencies()
        freqs[correct] = 1
        return explain(spot: spot, combo: combo, frequencies: freqs)
    }
}
