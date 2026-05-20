import XCTest

@testable import Cutoff

/// Sanity checks against well-known hot/cold and coinflip equities.
/// Monte Carlo, so each test uses 5 000 iterations and a ±3% tolerance to
/// keep flakiness low. We're not certifying solver-grade accuracy — we're
/// catching regressions that would shift equities by tens of points.
final class EquityCalculatorTests: XCTestCase {

    private let iterations = 5_000
    private let tolerance  = 0.03

    private func card(_ s: String) -> Card { Card(notation: s)! }
    private func hand(_ a: String, _ b: String) -> [Card] { [card(a), card(b)] }

    func test_AAvsKK_isAroundEightyOne() throws {
        let hero = hand("As", "Ad")
        let villain = [hand("Kh", "Kc")]
        let eq = EquityCalculator.equity(
            heroHand: hero, villainCombos: villain, board: [], iterations: iterations
        )
        XCTAssertEqual(eq, 0.817, accuracy: tolerance,
                       "AA vs KK preflop ~81.7%; got \(eq)")
    }

    func test_AKs_vs_22_isCoinflip() throws {
        let hero = hand("As", "Ks")
        let villain = [hand("2h", "2c")]
        let eq = EquityCalculator.equity(
            heroHand: hero, villainCombos: villain, board: [], iterations: iterations
        )
        // AKs vs 22 sits just over 50% for the pair preflop. Hero (AKs)
        // therefore lands just under 50.
        XCTAssertEqual(eq, 0.495, accuracy: tolerance + 0.01,
                       "AKs vs 22 ~49.5%; got \(eq)")
    }

    func test_AAvsKK_onKKxBoard_villainHasTrips() throws {
        let hero = hand("As", "Ad")
        let villain = [hand("Kh", "Kc")]
        // Villain flops trip kings; hero has overpair. Trips vs overpair on
        // a dry board lands hero at ~7-8%.
        let board = [card("Ks"), card("7d"), card("2c")]
        let eq = EquityCalculator.equity(
            heroHand: hero, villainCombos: villain, board: board, iterations: iterations
        )
        XCTAssertEqual(eq, 0.08, accuracy: tolerance,
                       "AA vs flopped trip KK ~7-8%; got \(eq)")
    }

    func test_emptyVillainRange_returnsZero() {
        let eq = EquityCalculator.equity(
            heroHand: hand("As", "Kh"), villainCombos: [], board: [], iterations: 100
        )
        XCTAssertEqual(eq, 0)
    }

    func test_blockedVillainCombo_excludedFromSample() {
        // Hero has As; villain combo containing As must be filtered out.
        // We pass *only* a colliding combo so a correct filter yields 0
        // (no valid villain) instead of crashing or counting it.
        let hero = hand("As", "Ad")
        let villain = [hand("As", "Ks")]
        let eq = EquityCalculator.equity(
            heroHand: hero, villainCombos: villain, board: [], iterations: 200
        )
        XCTAssertEqual(eq, 0,
                       "All villain combos blocked → 0; got \(eq)")
    }
}
