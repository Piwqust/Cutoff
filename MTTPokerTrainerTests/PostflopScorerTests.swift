import XCTest
@testable import MTTPokerTrainer

final class PostflopScorerTests: XCTestCase {
    private func makeSpot(actions: [PostflopAction: Double], isHeroToAct: Bool = true) -> PostflopSpot {
        let dict = Dictionary(uniqueKeysWithValues: actions.map { ($0.key.rawValue, $0.value) })
        return PostflopSpot(
            id: "TEST",
            boardTexture: .dryRainbow,
            board: [Card(notation: "Kc")!, Card(notation: "7d")!, Card(notation: "2s")!],
            heroPosition: .btn,
            heroHand: HoleCards(first: Card(notation: "Ah")!, second: Card(notation: "Kd")!),
            potSizeBB: 6,
            effectiveStackBB: 100,
            stackDepth: 100,
            isInPosition: true,
            isHeroToAct: isHeroToAct,
            correctActions: dict,
            explanation: "test",
            source: RangeChart.SourcePayload(type: .demo, description: "Approximate demo training range. Not solver-verified.")
        )
    }

    func test_dominantBetIsCorrect() {
        let spot = makeSpot(actions: [.bet33: 1.0])
        XCTAssertEqual(PostflopScorer.evaluate(user: .bet33, spot: spot), .correct)
    }

    func test_mixedNeighborIsClose() {
        let spot = makeSpot(actions: [.bet33: 0.6, .check: 0.4])
        XCTAssertEqual(PostflopScorer.evaluate(user: .bet33, spot: spot), .close)
        XCTAssertEqual(PostflopScorer.evaluate(user: .check, spot: spot), .close)
    }

    func test_distantActionIsPunt() {
        let spot = makeSpot(actions: [.fold: 1.0])
        XCTAssertEqual(PostflopScorer.evaluate(user: .shove, spot: spot), .punt)
    }

    func test_adjacentZeroFreqIsMistake() {
        // Dominant bet33 (tier 3); call (tier 2) is adjacent → mistake, not punt.
        let spot = makeSpot(actions: [.bet33: 1.0], isHeroToAct: false)
        XCTAssertEqual(PostflopScorer.evaluate(user: .call, spot: spot), .mistake)
    }
}
