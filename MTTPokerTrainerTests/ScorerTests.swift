import XCTest
@testable import MTTPokerTrainer

final class ScorerTests: XCTestCase {
    func test_exactMatchIsCorrect() {
        XCTAssertEqual(Scorer.evaluate(user: .raise, correct: .raise), .correct)
        XCTAssertEqual(Scorer.evaluate(user: .fold,  correct: .fold),  .correct)
        XCTAssertEqual(Scorer.evaluate(user: .jam,   correct: .jam),   .correct)
        XCTAssertEqual(AnswerOutcome.correct.score, 100)
    }

    func test_raiseVsThreeBetIsClose() {
        XCTAssertEqual(Scorer.evaluate(user: .raise, correct: .threeBet), .close)
        XCTAssertEqual(Scorer.evaluate(user: .threeBet, correct: .raise), .close)
        XCTAssertEqual(AnswerOutcome.close.score, 70)
    }

    func test_foldingWhenShouldPlayIsMistake() {
        XCTAssertEqual(Scorer.evaluate(user: .fold, correct: .raise), .mistake)
        XCTAssertEqual(Scorer.evaluate(user: .fold, correct: .call),  .mistake)
        XCTAssertEqual(AnswerOutcome.mistake.score, 30)
    }

    func test_jammingWhenShouldCallIsPunt() {
        XCTAssertEqual(Scorer.evaluate(user: .jam, correct: .call), .punt)
        XCTAssertEqual(Scorer.evaluate(user: .call, correct: .jam), .punt)
        XCTAssertEqual(AnswerOutcome.punt.score, 0)
    }

    func test_anyResponseVsMixedIsClose() {
        XCTAssertEqual(Scorer.evaluate(user: .raise, correct: .mixed), .close)
        XCTAssertEqual(Scorer.evaluate(user: .call,  correct: .mixed), .close)
    }
}
