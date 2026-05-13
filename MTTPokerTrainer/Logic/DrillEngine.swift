import Foundation

/// Builds the spot pool and picks the next training question for a given
/// `DrillCategory`. This is the practical replacement for the old "random
/// chart" picker — the chart pool is filtered to depths and facing actions
/// that match the user's real games.
struct DrillEngine {
    let charts: [RangeChart]
    let category: DrillCategory

    /// Charts that match this category's depth + facing + position filters.
    var pool: [RangeChart] {
        charts.filter { chart in
            category.depthRange.contains(chart.spot.stackDepthBB)
                && category.facingActions.contains(chart.spot.facingAction)
                && category.positions.contains(chart.spot.position)
        }
    }

    /// Generate the next training question. Falls back to the full chart list
    /// if the curated pool is empty (defensive — should not happen with the
    /// bundled set, but keeps the trainer functional under partial data).
    func next(rng: inout SystemRandomNumberGenerator) -> Question? {
        let basePool = pool.isEmpty ? charts : pool
        guard let chart = basePool.randomElement(using: &rng) else { return nil }

        let pick = SpotGenerator(chart: chart).next(rng: &rng)
        let villain = category.defaultVillain
        let baseCoarse = RangeAction(pick.frequencies.dominantAction)
        let mappedCorrect = mapCorrectAction(
            base: baseCoarse,
            available: category.availableActions,
            villain: villain
        )

        return Question(
            chart: chart,
            combo: pick.combo,
            correctAction: mappedCorrect,
            availableActions: category.availableActions,
            villain: villain
        )
    }

    /// The chart's underlying action might be e.g. ".raise" but the drill only
    /// offers Fold/Jam (push-fold drill). Collapse the action to the closest
    /// allowed option so the user always has a sensible button to press.
    private func mapCorrectAction(
        base: RangeAction,
        available: [RangeAction],
        villain: VillainType
    ) -> RangeAction {
        if available.contains(base) { return base }
        switch base {
        case .threeBet, .raise:
            // No raise option → prefer jam if allowed, else call, else fold.
            if available.contains(.jam)  { return .jam  }
            if available.contains(.call) { return .call }
            return .fold
        case .jam:
            if available.contains(.jam)  { return .jam }
            if available.contains(.call) { return .call }
            return .fold
        case .call:
            if available.contains(.call) { return .call }
            if available.contains(.jam)  { return villain == .maniac ? .jam : .fold }
            return .fold
        case .mixed:
            return available.first(where: { $0 != .fold }) ?? .fold
        case .fold:
            return .fold
        }
    }

    struct Question {
        let chart: RangeChart
        let combo: HandCombo
        let correctAction: RangeAction
        let availableActions: [RangeAction]
        let villain: VillainType

        var spot: TrainingSpot { chart.trainingSpot }
    }
}

/// Plain-English explanation tuned to the drill category and villain.
enum DrillExplanation {
    static func explain(question: DrillEngine.Question, category: DrillCategory) -> String {
        let pos = question.spot.position.displayName
        let bb = question.spot.stackDepthBB
        let action = question.correctAction
        let combo = question.combo.notation

        switch (category, action) {
        case (.firstInJam, .jam):
            return "Jam. \(combo) from \(pos) at \(bb) BB has enough fold equity + showdown to shove first-in."
        case (.firstInJam, .fold):
            return "Fold. Too weak to open-jam \(bb) BB from \(pos)."

        case (.reJam, .jam):
            return "Re-jam. \(bb) BB is in the sweet spot — denying equity beats flatting out of position."
        case (.reJam, .call):
            return "Call. Strong enough to play in position, not big enough to commit yet."
        case (.reJam, .fold):
            return "Fold. Not enough to call profitably and not enough fold equity to jam."

        case (.callJam, .call):
            return "Call. Price + equity say snap. At \(bb) BB this hand is ahead of the shoving range."
        case (.callJam, .fold):
            return "Fold. You'd be calling off too light; live, players aren't shoving wide enough here."

        case (.stealBlinds, .raise):
            return "Steal. \(pos) at \(bb) BB can open this — pressure the blinds when they fold too much."
        case (.stealBlinds, .fold):
            return "Fold. Even with light blinds, this hand bleeds chips out of \(pos)."

        case (.vsManiac, .jam):
            return "Jam. The maniac 3-bets too wide — flip back the pressure with \(combo)."
        case (.vsManiac, .call):
            return "Call. Don't fold to a wide 3-bet; play the pot in position."
        case (.vsManiac, .fold):
            return "Fold. Even vs a maniac this is too weak to continue."

        case (_, .raise):
            return "Open. \(pos) at \(bb) BB plays this hand for a raise."
        case (_, .call):
            return "Call. The right speed at \(bb) BB — folding is too tight, jamming overcommits."
        case (_, .jam):
            return "Jam. At \(bb) BB this hand has the right mix of fold equity and showdown."
        case (_, .fold):
            return "Fold. Not strong enough at this depth from \(pos)."
        case (_, .threeBet):
            return "3-bet. Apply pressure — flatting is too passive at \(bb) BB."
        case (_, .mixed):
            return "Mixed spot. Both lines are defensible."
        }
    }
}
