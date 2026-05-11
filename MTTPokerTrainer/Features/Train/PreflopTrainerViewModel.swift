import Foundation
import SwiftData

@MainActor
@Observable
final class PreflopTrainerViewModel {
    private(set) var charts: [RangeChart] = []
    private(set) var currentChart: RangeChart?
    private(set) var currentCombo: HandCombo?
    private(set) var correctAction: RangeAction = .fold
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

    func next() {
        guard let chart = charts.randomElement(using: &rng) else { return }
        currentChart = chart
        let pick = SpotGenerator(chart: chart).next(rng: &rng)
        currentCombo = pick.combo
        correctAction = pick.correctAction
        lastOutcome = nil
        lastExplanation = ""
        hasAnswered = false
    }

    func submit(_ userAction: RangeAction) {
        guard !hasAnswered,
              let chart = currentChart,
              let combo = currentCombo else { return }
        let outcome = Scorer.evaluate(user: userAction, correct: correctAction)
        let explanation = ExplanationBuilder.explain(spot: chart.trainingSpot, combo: combo, correct: correctAction)
        lastOutcome = outcome
        lastExplanation = explanation
        hasAnswered = true

        // Persist a QuizResult — best effort.
        if let modelContext {
            let row = QuizResult(
                combo: combo.notation,
                position: chart.spot.position,
                stackDepthBB: chart.spot.stackDepthBB,
                facingAction: chart.spot.facingAction,
                anteType: chart.spot.anteType,
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
