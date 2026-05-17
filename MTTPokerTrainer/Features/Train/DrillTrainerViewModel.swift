import Foundation
import SwiftData

@MainActor
@Observable
final class DrillTrainerViewModel {
    private(set) var charts: [RangeChart] = []
    private(set) var current: DrillEngine.Question?
    private(set) var lastOutcome: AnswerOutcome?
    private(set) var lastPayload: FeedbackPayload?
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
        lastPayload = nil
        hasAnswered = false
    }

    func submit(_ userAction: RangeAction) {
        guard !hasAnswered, let question = current else { return }
        let outcome = Scorer.evaluate(user: userAction, correct: question.correctAction)
        let explanation = MistakeExplainer.explain(
            combo: question.combo,
            position: question.spot.position,
            depthBB: question.spot.stackDepthBB,
            facing: question.spot.facingAction,
            userAction: userAction,
            chart: question.chart
        )
        let payload = buildPayload(
            question: question,
            userAction: userAction,
            outcome: outcome,
            explanation: explanation
        )

        lastOutcome = outcome
        lastPayload = payload
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
                // Continue persisting the joined explanation for Review's
                // historical detail sheets — the overlay no longer reads it.
                explanation: explanation.joined
            )
            modelContext.insert(row)
            try? modelContext.save()
        }
    }

    private func buildPayload(
        question: DrillEngine.Question,
        userAction: RangeAction,
        outcome: AnswerOutcome,
        explanation: MistakeExplainer.Explanation
    ) -> FeedbackPayload {
        let chart = question.chart
        let combo = question.combo
        let focusClass = HandClass.of(combo)
        let siblings: [HandCombo] = HandCombo.allInMatrixOrder
            .filter { $0 != combo }
            .filter { HandClass.of($0) == focusClass }
            .filter { chart.action(for: $0) == question.correctAction }
            .sorted { a, b in
                let da = abs(a.highRank.sortValue - combo.highRank.sortValue) + abs(a.lowRank.sortValue - combo.lowRank.sortValue)
                let db = abs(b.highRank.sortValue - combo.highRank.sortValue) + abs(b.lowRank.sortValue - combo.lowRank.sortValue)
                return da < db
            }
            .prefix(5)
            .map { $0 }

        // The verdict is the one-liner; reason + context become body paragraphs.
        let body = [explanation.reason, explanation.context].filter { !$0.isEmpty }

        return FeedbackPayload(
            outcome: outcome,
            userAction: ActionDescriptor(userAction),
            correctAction: ActionDescriptor(question.correctAction),
            verdict: explanation.verdict,
            paragraphs: body,
            mistakeReason: explanation.mistakeReason,
            siblingHands: siblings
        )
    }
}
