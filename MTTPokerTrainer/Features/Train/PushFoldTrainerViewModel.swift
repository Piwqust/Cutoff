import Foundation
import SwiftData

@MainActor
@Observable
final class PushFoldTrainerViewModel {
    private(set) var charts: [RangeChart] = []
    private(set) var currentChart: RangeChart?
    private(set) var currentCombo: HandCombo?
    private(set) var correctAction: RangeAction = .fold
    private(set) var lastOutcome: AnswerOutcome?
    private(set) var lastExplanation: String = ""
    private(set) var hasAnswered: Bool = false

    private var rng = SystemRandomNumberGenerator()
    var modelContext: ModelContext?

    func load(using service: RangeService) {
        service.ensureLoaded()
        if charts.isEmpty {
            charts = service.charts.filter { $0.spot.facingAction == .pushFold }
        }
        next()
    }

    func next() {
        guard let chart = charts.randomElement(using: &rng) else { return }
        currentChart = chart
        let pick = SpotGenerator(chart: chart).next(rng: &rng)
        currentCombo = pick.combo
        // Map any non-fold to .jam since we only show Jam / Fold for this trainer.
        correctAction = (pick.correctAction == .fold) ? .fold : .jam
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
