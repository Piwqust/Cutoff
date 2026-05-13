import Foundation
import SwiftData

@MainActor
@Observable
final class PushFoldTrainerViewModel {
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
            let all = (try? loader.loadAll()) ?? []
            charts = all.filter { $0.facingAction == .pushFold }
        }
        next()
    }

    /// Collapsed correct action — push/fold trainer only shows two buttons.
    var correctAction: PreflopAction {
        currentFrequencies.dominantAction == .fold ? .fold : .shove
    }

    func next() {
        guard let chart = charts.randomElement(using: &rng) else { return }
        currentChart = chart
        let pick = SpotGenerator(chart: chart).next(rng: &rng)
        currentCombo = pick.combo
        // Collapse the full distribution to fold / shove only.
        var collapsed = HandFrequencies()
        let foldWeight = pick.frequencies[.fold]
        collapsed[.fold] = foldWeight
        collapsed[.shove] = max(0, 1.0 - foldWeight)
        currentFrequencies = collapsed
        lastOutcome = nil
        lastExplanation = ""
        hasAnswered = false
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
