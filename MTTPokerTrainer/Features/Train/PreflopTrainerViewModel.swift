import Foundation
import SwiftData

@MainActor
@Observable
final class PreflopTrainerViewModel {
    private(set) var charts: [RangeChart] = []
    private(set) var currentChart: RangeChart?
    private(set) var currentCombo: HandCombo?
    private(set) var currentFrequencies: HandFrequencies = HandFrequencies()
    private(set) var lastOutcome: AnswerOutcome?
    private(set) var lastExplanation: String = ""
    private(set) var hasAnswered: Bool = false

    private var rng = SystemRandomNumberGenerator()
    private let loader: RangeLoader
    var modelContext: ModelContext?

    init(loader: RangeLoader = .init()) {
        self.loader = loader
    }

    func load() {
        if charts.isEmpty {
            charts = (try? loader.loadAll()) ?? []
        }
        next()
    }

    /// Test-only seam: bypass the bundle loader and inject a fixed chart set.
    func injectChartsForTesting(_ replacement: [RangeChart]) {
        charts = replacement
        if let chart = replacement.first {
            currentChart = chart
            let combo = HandCombo.allInMatrixOrder.first!
            currentCombo = combo
            currentFrequencies = chart.frequencies(for: combo)
        }
    }

    func next() {
        guard let chart = charts.randomElement(using: &rng) else { return }
        currentChart = chart
        let pick = SpotGenerator(chart: chart).next(rng: &rng)
        currentCombo = pick.combo
        currentFrequencies = pick.frequencies
        lastOutcome = nil
        lastExplanation = ""
        hasAnswered = false
    }

    /// Best-answer action for the current combo (highest-frequency).
    var correctAction: PreflopAction { currentFrequencies.dominantAction }

    /// Whether a given preflop action is reachable in the current spot.
    /// The trainer UI uses this to disable buttons that have no weight here.
    func isActionEnabled(_ action: PreflopAction) -> Bool {
        guard let chart = currentChart else { return false }
        return chart.enabledActions.contains(action)
    }

    /// Positions that have already acted in the current spot. Drives the
    /// `TableMinimapView` highlighting.
    var actedPositions: [TablePosition] {
        guard let chart = currentChart else { return [] }
        let hero = chart.position
        let order = TablePosition.nineMaxOrder
        guard let heroIdx = order.firstIndex(of: hero) else { return [] }
        switch chart.facingAction {
        case .rfi:
            // Hero is first in. No one upstream has acted yet.
            return []
        case .vsOpenCall:
            // Someone upstream opened. Highlight the upstream opener nearest hero.
            if heroIdx == 0 { return [] }
            return [order[max(0, heroIdx - 1)]]
        case .vs3Bet:
            // Hero opened, someone downstream 3-bet. Highlight hero's prior raise
            // plus the 3-bettor sitting between hero and the blinds.
            let threeBettor = order.indices.contains(heroIdx + 1) ? order[heroIdx + 1] : order.last ?? hero
            return [threeBettor]
        case .pushFold:
            // Short-stack open-shove scenarios; usually no one has acted yet.
            return []
        }
    }

    func submit(_ userAction: PreflopAction) {
        guard !hasAnswered,
              let chart = currentChart,
              let combo = currentCombo else { return }
        let outcome = Scorer.evaluate(user: userAction, frequencies: currentFrequencies)
        let explanation = ExplanationBuilder.explain(spot: chart.trainingSpot, combo: combo, frequencies: currentFrequencies)
        lastOutcome = outcome
        lastExplanation = explanation
        hasAnswered = true

        if let modelContext {
            let row = QuizResult(
                combo: combo.notation,
                position: chart.position,
                stackDepthBB: chart.stackDepth,
                facingAction: chart.facingAction,
                anteType: .bigBlindAnte,
                rangeChartID: chart.id,
                userAction: userAction,
                correctAction: correctAction,
                outcome: outcome
            )
            modelContext.insert(row)
            try? modelContext.save()
        }
    }
}
