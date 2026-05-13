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
        XCTAssertEqual(Scorer.evaluate(user: .fold, frequencies: f), .mistake)
    }

    func test_shoveWhenDominantIsFoldIsPunt() {
        // Shove tier 6 vs fold tier 0 = distance 6, far.
        let f = freqs((.fold, 1.0))
        XCTAssertEqual(Scorer.evaluate(user: .shove, frequencies: f), .punt)
    }

    func test_callWhenDominantIsShoveIsPunt() {
        // call tier 1 vs shove tier 6 = distance 5, far.
        let f = freqs((.shove, 1.0))
        XCTAssertEqual(Scorer.evaluate(user: .call, frequencies: f), .punt)
    }

    func test_legacySingleActionOverloadStillWorks() {
        XCTAssertEqual(Scorer.evaluate(user: .fold, correct: .fold), .correct)
        XCTAssertEqual(Scorer.evaluate(user: .minRaise, correct: .minRaise), .correct)
        XCTAssertEqual(Scorer.evaluate(user: .shove, correct: .fold), .punt)
    }
}
