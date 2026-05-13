import XCTest

@testable import MTTPokerTrainer

final class HandEvaluatorTests: XCTestCase {
    private func cards(_ notations: String...) -> [Card] {
        notations.compactMap { Card(notation: $0) }
    }

    func test_straightFlushBeatsQuads() {
        let sf = HandEvaluator.bestFive(of: cards("As","Ks","Qs","Js","Ts"))
        let quads = HandEvaluator.bestFive(of: cards("Ah","Ad","Ac","As","Kd"))
        XCTAssertGreaterThan(sf, quads)
    }

    func test_flushBeatsStraight() {
        let flush = HandEvaluator.bestFive(of: cards("Kh","Th","7h","5h","2h"))
        let straight = HandEvaluator.bestFive(of: cards("Th","9c","8d","7s","6h"))
        XCTAssertGreaterThan(flush, straight)
    }

    func test_pairBeatsHighCard() {
        let pair = HandEvaluator.bestFive(of: cards("Ks","Kc","9d","5h","2c"))
        let high = HandEvaluator.bestFive(of: cards("As","Qc","9d","5h","2c"))
        XCTAssertGreaterThan(pair, high)
    }

    func test_evaluatesSevenCards() {
        // AKQJT + extra rags = ace-high straight
        let score = HandEvaluator.bestFive(of: cards("Ah","Kc","Qd","Jh","Ts","2c","3d"))
        let pair = HandEvaluator.bestFive(of: cards("As","Ac","9d","5h","2c"))
        XCTAssertGreaterThan(score, pair)
    }
}
