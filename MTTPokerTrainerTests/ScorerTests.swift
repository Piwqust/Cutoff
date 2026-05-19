import XCTest
@testable import MTTPokerTrainer

final class ScorerTests: XCTestCase {
    private func freqs(_ entries: (PreflopAction, Double)...) -> HandFrequencies {
        var dict: [PreflopAction: Double] = [:]
        for (k, v) in entries { dict[k] = v }
        return HandFrequencies(dict)
    }

    func test_dominantAnswerIsCorrect() {
        let f = freqs((.minRaise, 1.0))
        XCTAssertEqual(Scorer.evaluate(user: .minRaise, frequencies: f), .correct)
        XCTAssertEqual(AnswerOutcome.correct.score, 100)
    }

    func test_neighborMixIsClose() {
        // 60% raise25x / 40% raise3x — answering either way should be at least close.
        let f = freqs((.raise25x, 0.6), (.raise3x, 0.4))
        XCTAssertEqual(Scorer.evaluate(user: .raise25x, frequencies: f), .close)
        XCTAssertEqual(Scorer.evaluate(user: .raise3x,  frequencies: f), .close)
        XCTAssertEqual(AnswerOutcome.close.score, 70)
    }

    func test_dominantAtThresholdIsCorrect() {
        // Dominant action with freq exactly 0.8 should still count as correct.
        let f = freqs((.minRaise, 0.8), (.raise25x, 0.2))
        XCTAssertEqual(Scorer.evaluate(user: .minRaise, frequencies: f), .correct)
    }

    func test_rareButPresentIsMistake() {
        // 5% sprinkle is a mistake (not catastrophic).
        let f = freqs((.fold, 0.95), (.shove, 0.05))
        XCTAssertEqual(Scorer.evaluate(user: .shove, frequencies: f), .mistake)
    }

    func test_foldWhenDominantIsRaiseIsMistakeNotPunt() {
        // Fold vs minRaise dominant — passive direction, adjacent tiers (2→0 = 2).
        let f = freqs((.minRaise, 1.0))
        XCTAssertEqual(Scorer.evaluate(user: PreflopAction.fold, frequencies: f), .mistake)
    }

    func test_shoveWhenDominantIsFoldIsPunt() {
        // Shove tier 6 vs fold tier 0 = distance 6, far.
        let f = freqs((.fold, 1.0))
        XCTAssertEqual(Scorer.evaluate(user: PreflopAction.shove, frequencies: f), .punt)
    }

    func test_callWhenDominantIsShoveIsPunt() {
        // call tier 1 vs shove tier 6 = distance 5, far.
        let f = freqs((.shove, 1.0))
        XCTAssertEqual(Scorer.evaluate(user: PreflopAction.call, frequencies: f), .punt)
    }

    func test_legacySingleActionOverloadStillWorks() {
        XCTAssertEqual(Scorer.evaluate(user: PreflopAction.fold,     correct: PreflopAction.fold), .correct)
        XCTAssertEqual(Scorer.evaluate(user: PreflopAction.minRaise, correct: PreflopAction.minRaise), .correct)
        XCTAssertEqual(Scorer.evaluate(user: PreflopAction.shove,    correct: PreflopAction.fold), .punt)
    }

    // MARK: - RangeAction (coarse) overload — frequency-aware

    func test_rangeAction_neighborMixIsClose() {
        // 60% raise25x / 40% call should grade either coarse choice as .close
        // — the same as the PreflopAction overload on the same distribution.
        let f = freqs((.raise25x, 0.6), (.call, 0.4))
        XCTAssertEqual(Scorer.evaluate(user: RangeAction.raise, frequencies: f), .close)
        XCTAssertEqual(Scorer.evaluate(user: RangeAction.call,  frequencies: f), .close)
    }

    func test_rangeAction_dominantIsCorrect() {
        let f = freqs((.shove, 1.0))
        XCTAssertEqual(Scorer.evaluate(user: RangeAction.jam, frequencies: f), .correct)
    }

    func test_rangeAction_farAggressionDistanceIsPunt() {
        // jam vs fold-dominated chart — distance 4, far.
        let f = freqs((.fold, 1.0))
        XCTAssertEqual(Scorer.evaluate(user: RangeAction.jam, frequencies: f), .punt)
    }

    func test_rangeAction_collapsesMixedRaiseSizings() {
        // 50% minRaise / 50% raise25x → both collapse to .raise. The
        // collapsed bucket has freq 1.0 → .correct.
        let f = freqs((.minRaise, 0.5), (.raise25x, 0.5))
        XCTAssertEqual(Scorer.evaluate(user: RangeAction.raise, frequencies: f), .correct)
    }

    func test_constrainedDrill_projectsRaiseOntoJam_andGradesCorrect() {
        // Regression test for the firstInJam bug: chart says 100% raise but
        // the drill only offers Fold/Jam. The projection routes the raise
        // mass into the jam bucket — picking Jam must grade .correct.
        let coarse: [RangeAction: Double] = [.raise: 1.0]
        let projected = DrillEngine.project(
            coarse: coarse,
            available: [.fold, .jam],
            villain: .standard
        )
        XCTAssertEqual(projected[.jam], 1.0)
        XCTAssertEqual(
            Scorer.evaluate(user: RangeAction.jam, coarseFrequencies: projected),
            .correct
        )
        XCTAssertEqual(
            Scorer.evaluate(user: RangeAction.fold, coarseFrequencies: projected),
            .punt
        )
    }

    func test_constrainedDrill_mixedRaiseJamProjectsAndGradesClose() {
        // Chart: 60% raise / 40% jam, firstInJam-style buttons. Raise routes
        // into jam → all mass on jam → both Jam picks are .correct and Fold
        // is .punt.
        let coarse: [RangeAction: Double] = [.raise: 0.6, .jam: 0.4]
        let projected = DrillEngine.project(
            coarse: coarse,
            available: [.fold, .jam],
            villain: .standard
        )
        XCTAssertEqual(projected[.jam], 1.0)
        XCTAssertEqual(
            Scorer.evaluate(user: RangeAction.jam, coarseFrequencies: projected),
            .correct
        )
    }

    func test_legacyAndFrequencyAwareAgreeOnPureSpot() {
        // A 100%-shove spot should grade the same whether you go through
        // (user, correct) or (user, frequencies). This is the regression
        // bar for the two-overloads consolidation.
        let f = freqs((.shove, 1.0))
        for user in RangeAction.allCases {
            let viaFreq = Scorer.evaluate(user: user, frequencies: f)
            let viaCorrect = Scorer.evaluate(user: user, correct: .jam)
            XCTAssertEqual(viaFreq, viaCorrect,
                           "Disagreement on \(user): freq=\(viaFreq), correct=\(viaCorrect)")
        }
    }
}
