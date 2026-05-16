import Foundation
import SwiftData

@MainActor
@Observable
final class DrillTrainerViewModel {
    private(set) var charts: [RangeChart] = []
    private(set) var current: DrillEngine.Question?
    private(set) var lastOutcome: AnswerOutcome?
    private(set) var lastExplanation: String = ""
    private(set) var lastDeepDive: FeedbackSheet.DeepDive?
    private(set) var hasAnswered: Bool = false

    private var rng = SystemRandomNumberGenerator()
    private let loader: RangeLoader
    private var category: DrillCategory = .mixed

    var modelContext: ModelContext?
    var progress: ProgressStore?

    init(loader: RangeLoader = .init()) {
        self.loader = loader
    }

    func load(category: DrillCategory) {
        self.category = category
        if charts.isEmpty {
            charts = (try? loader.loadAll()) ?? []
        }
        next()
    }

    func next() {
        let engine = DrillEngine(charts: charts, category: category)
        current = engine.next(rng: &rng)
        lastOutcome = nil
        lastExplanation = ""
        lastDeepDive = nil
        hasAnswered = false
    }

    func submit(_ userAction: RangeAction) {
        guard !hasAnswered, let question = current else { return }
        let outcome = Scorer.evaluate(user: userAction, correct: question.correctAction)
        let explanation = DrillExplanation.explain(question: question, category: category)
        lastOutcome = outcome
        lastExplanation = explanation
        lastDeepDive = buildDeepDive(question: question, userAction: userAction)
        hasAnswered = true

        progress?.record(outcome: outcome, in: category)

        if let modelContext {
            let row = QuizResult(
                combo: question.combo.notation,
                position: question.spot.position,
                stackDepthBB: question.spot.stackDepthBB,
                facingAction: question.spot.facingAction,
                anteType: question.spot.anteType,
                rangeChartID: question.chart.id,
                userAction: userAction,
                correctAction: question.correctAction,
                outcome: outcome,
                category: category,
                villain: question.villain,
                explanation: explanation
            )
            modelContext.insert(row)
            try? modelContext.save()
        }
    }

    private func buildDeepDive(
        question: DrillEngine.Question,
        userAction: RangeAction
    ) -> FeedbackSheet.DeepDive {
        let chart = question.chart
        let combo = question.combo
        let frequencies = FrequencyCollapser.coarse(chart.frequencies(for: combo))
        let explanation = MistakeExplainer.explain(
            combo: combo,
            position: question.spot.position,
            depthBB: question.spot.stackDepthBB,
            facing: question.spot.facingAction,
            userAction: userAction,
            chart: chart
        )

        let focusClass = HandClass.of(combo)
        let siblings: [String] = HandCombo.allInMatrixOrder
            .filter { $0 != combo }
            .filter { HandClass.of($0) == focusClass }
            .filter { chart.action(for: $0) == question.correctAction }
            .sorted { a, b in
                let da = abs(a.highRank.sortValue - combo.highRank.sortValue) + abs(a.lowRank.sortValue - combo.lowRank.sortValue)
                let db = abs(b.highRank.sortValue - combo.highRank.sortValue) + abs(b.lowRank.sortValue - combo.lowRank.sortValue)
                return da < db
            }
            .prefix(5)
            .map(\.notation)

        return FeedbackSheet.DeepDive(
            frequencies: frequencies,
            userAction: userAction,
            paragraphs: explanation.paragraphs,
            mistakeReason: explanation.mistakeReason,
            siblingHands: siblings
        )
    }
}
