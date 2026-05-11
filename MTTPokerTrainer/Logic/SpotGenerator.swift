import Foundation

/// Picks a random combo from a chart, weighted toward "decision" hands — i.e.
/// avoid asking the user 70% trivial folds (72o) or 5% obvious raises (AA).
///
/// The MVP weighting is simple: 70% of the time pick a non-fold hand if any
/// exists; otherwise random over the (sparse) chart. Fully-unlisted (implicit
/// fold) hands are deprioritised.
struct SpotGenerator {
    let chart: RangeChart

    func next(rng: inout SystemRandomNumberGenerator) -> (combo: HandCombo, correctAction: RangeAction) {
        let nonFold = chart.hands.filter { $0.value != .fold }
        if !nonFold.isEmpty && Int.random(in: 0..<10, using: &rng) < 7 {
            let pick = nonFold.randomElement(using: &rng)!
            let combo = HandCombo.parse(pick.key) ?? HandCombo.allInMatrixOrder.first!
            return (combo, pick.value)
        }
        // 30% chance to sample any 169 hand (including explicit folds)
        let combo = HandCombo.allInMatrixOrder.randomElement(using: &rng)!
        return (combo, chart.action(for: combo))
    }
}

/// Human-friendly explanation that respects the "no solver jargon" rule.
enum ExplanationBuilder {
    static func explain(spot: TrainingSpot, combo: HandCombo, correct: RangeAction) -> String {
        let pos = spot.position.displayName
        let bb = spot.stackDepthBB
        switch (correct, spot.facingAction) {
        case (.raise, .unopened):
            return "Open. \(pos) at \(bb) BB can lead with this hand."
        case (.fold, .unopened):
            return "Fold. Too weak from \(pos) at \(bb) BB in a 9-max field."
        case (.threeBet, .vsOpen):
            return "3-bet. Strong enough to put pressure on the opener at \(bb) BB."
        case (.call, .vsOpen):
            return "Call. Plays well in position; folding is too tight here."
        case (.fold, .vsOpen):
            return "Fold. Dominated too often to call profitably."
        case (.jam, _):
            return "Jam. At \(bb) BB this hand has the right mix of fold equity and showdown."
        case (.fold, .pushFold):
            return "Fold. Not enough equity to shove at \(bb) BB."
        case (.fold, .blindDefense):
            return "Fold. Defending too wide from the blinds bleeds chips."
        case (.call, .blindDefense):
            return "Defend. Good price and reasonable playability."
        case (.threeBet, .blindDefense):
            return "3-bet. The opener is too wide; punish from the blinds."
        case (.mixed, _):
            return "Mixed. The correct play is split — either action is defensible."
        default:
            return "Best answer for \(pos) at \(bb) BB."
        }
    }
}
