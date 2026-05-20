import XCTest

@testable import Cutoff

final class SpotGeneratorTests: XCTestCase {

    /// Build a chart by encoding a JSON payload and decoding it through
    /// `RangeChart`'s custom decoder — the model doesn't expose a
    /// memberwise init.
    private func makeChart(decisionHands: Set<String>) throws -> RangeChart {
        let mixed: [String: Double] = ["raise25x": 0.6, "call": 0.4]
        let foldOnly: [String: Double] = ["fold": 1.0]

        var hands: [String: [String: Double]] = [:]
        for combo in HandCombo.allInMatrixOrder {
            hands[combo.notation] = decisionHands.contains(combo.notation) ? mixed : foldOnly
        }

        let payload: [String: Any] = [
            "id": "test_chart",
            "stackDepth": 30,
            "position": "CO",
            "tableSize": 9,
            "antePercent": 12.5,
            "facingAction": "RFI",
            "isICM": false,
            "source": ["type": "gto", "description": "Test"],
            "hands": hands
        ]
        let data = try JSONSerialization.data(withJSONObject: payload, options: [])
        return try JSONDecoder().decode(RangeChart.self, from: data)
    }

    func test_generatorAlwaysReturnsAValidCombo() throws {
        let gen = SpotGenerator(chart: try makeChart(decisionHands: ["AKo", "KQs", "T9s", "55"]))
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<200 {
            let (combo, freqs) = gen.next(rng: &rng)
            XCTAssertNotNil(HandCombo.parse(combo.notation),
                            "Generator returned an unparseable combo: \(combo.notation)")
            XCTAssertEqual(freqs.total, 1.0, accuracy: 0.001,
                           "Frequencies should sum to ~1 for any returned hand")
        }
    }

    /// The generator should skew toward decision hands at ~70% (the
    /// 7-in-10 branch in `next`). With 1 000 samples across 4 decision
    /// hands out of 169 total, uniform sampling would land near 2% — so
    /// > 50% decision-hits is a strong signal the bias works.
    func test_generatorPrefersDecisionHands() throws {
        let decisionSet: Set<String> = ["AKo", "KQs", "T9s", "55"]
        let gen = SpotGenerator(chart: try makeChart(decisionHands: decisionSet))
        var rng = SystemRandomNumberGenerator()

        var decisionHits = 0
        let trials = 1_000
        for _ in 0..<trials {
            let (combo, _) = gen.next(rng: &rng)
            if decisionSet.contains(combo.notation) { decisionHits += 1 }
        }
        let rate = Double(decisionHits) / Double(trials)
        XCTAssertGreaterThan(rate, 0.5,
                             "Generator should hit decision hands well above uniform; got \(rate)")
    }

    func test_generatorFallsBackToUniform_whenNoDecisionHands() throws {
        // Pure-fold chart: every hand is clean fold, no decision hands.
        let chart = try makeChart(decisionHands: [])
        let gen = SpotGenerator(chart: chart)
        var rng = SystemRandomNumberGenerator()

        // Should not crash and should keep covering many distinct combos.
        var seen: Set<String> = []
        for _ in 0..<200 {
            let (combo, _) = gen.next(rng: &rng)
            seen.insert(combo.notation)
        }
        XCTAssertGreaterThan(seen.count, 30,
                             "Uniform fallback should cover many distinct combos; got \(seen.count)")
    }
}
