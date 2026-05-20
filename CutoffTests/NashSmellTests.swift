import XCTest
@testable import Cutoff

/// Sanity-check the shape of canonical Nash chipEV ranges. Tolerant bands —
/// different public solvers disagree by a few % on edge hands. If a chart
/// falls *outside* the band, it's almost certainly placeholder data.
final class NashSmellTests: XCTestCase {
    private var appBundle: Bundle { Bundle(for: QuizResult.self) }
    private var allCharts: [RangeChart] = []

    override func setUpWithError() throws {
        allCharts = try RangeLoader(bundle: appBundle).loadAll()
        try XCTSkipIf(allCharts.isEmpty)
    }

    /// Fraction of the 1326 concrete combos for which `predicate` returns
    /// true. Each hand class (e.g. "AA") expands to a different number of
    /// real combos (pairs=6, suited=4, offsuit=12), and canonical Nash
    /// charts publish combo-weighted percentages — so we must weight by
    /// `combos` here, not just count classes.
    private func concreteCombos(_ c: HandCombo) -> Int {
        switch c.category {
        case .pair:    return 6
        case .suited:  return 4
        case .offsuit: return 12
        }
    }

    private func comboFraction(in chart: RangeChart, where predicate: (HandFrequencies) -> Bool) -> Double {
        var hits = 0
        var total = 0
        for c in HandCombo.allInMatrixOrder {
            let n = concreteCombos(c)
            total += n
            if predicate(chart.frequencies(for: c)) { hits += n }
        }
        return Double(hits) / Double(total)
    }

    private func chart(_ pos: TablePosition, _ depth: Int, _ facing: FacingAction) -> RangeChart? {
        allCharts.first { $0.position == pos && $0.stackDepth == depth && $0.facingAction == facing }
    }

    // MARK: - 10 BB push-fold

    func test_10bb_utg_jam_within_4_to_20_percent() {
        guard let c = chart(.utg, 10, .pushFold) else { return XCTFail("Missing UTG 10bb pushfold") }
        let jam = comboFraction(in: c, where: { $0[.shove] > 0 })
        XCTAssertGreaterThanOrEqual(jam, 0.04, "UTG 10bb jam too tight (\(Int(jam*100))%)")
        XCTAssertLessThanOrEqual(jam, 0.22, "UTG 10bb jam too wide (\(Int(jam*100))%)")
    }

    func test_10bb_btn_jam_within_30_to_65_percent() {
        guard let c = chart(.btn, 10, .pushFold) else { return XCTFail("Missing BTN 10bb pushfold") }
        let jam = comboFraction(in: c, where: { $0[.shove] > 0 })
        XCTAssertGreaterThanOrEqual(jam, 0.30, "BTN 10bb jam too tight (\(Int(jam*100))%)")
        XCTAssertLessThanOrEqual(jam, 0.65, "BTN 10bb jam too wide (\(Int(jam*100))%)")
    }

    func test_10bb_sb_jam_within_40_to_75_percent() {
        guard let c = chart(.sb, 10, .pushFold) else { return XCTFail("Missing SB 10bb pushfold") }
        let jam = comboFraction(in: c, where: { $0[.shove] > 0 })
        XCTAssertGreaterThanOrEqual(jam, 0.40, "SB 10bb jam too tight (\(Int(jam*100))%)")
        XCTAssertLessThanOrEqual(jam, 0.80, "SB 10bb jam too wide (\(Int(jam*100))%)")
    }

    // MARK: - 15 BB push-fold

    func test_15bb_utg_jam_within_4_to_20_percent() {
        guard let c = chart(.utg, 15, .pushFold) else { return XCTFail("Missing UTG 15bb pushfold") }
        let jam = comboFraction(in: c, where: { $0[.shove] > 0 })
        XCTAssertGreaterThanOrEqual(jam, 0.04, "UTG 15bb jam too tight (\(Int(jam*100))%)")
        XCTAssertLessThanOrEqual(jam, 0.20, "UTG 15bb jam too wide (\(Int(jam*100))%)")
    }

    func test_15bb_btn_jam_within_20_to_50_percent() {
        guard let c = chart(.btn, 15, .pushFold) else { return XCTFail("Missing BTN 15bb pushfold") }
        let jam = comboFraction(in: c, where: { $0[.shove] > 0 })
        XCTAssertGreaterThanOrEqual(jam, 0.20, "BTN 15bb jam too tight (\(Int(jam*100))%)")
        XCTAssertLessThanOrEqual(jam, 0.55, "BTN 15bb jam too wide (\(Int(jam*100))%)")
    }

    // MARK: - BB defense

    func test_10bb_bb_call_vs_jam_within_25_to_60_percent() {
        guard let c = chart(.bb, 10, .pushFold) else { return XCTFail("Missing BB 10bb pushfold") }
        let call = comboFraction(in: c, where: { $0[.call] > 0 })
        // BB calling range vs SB jam is wide at 10bb — typically 35-55%.
        XCTAssertGreaterThanOrEqual(call, 0.25, "BB 10bb call vs SB jam too tight (\(Int(call*100))%)")
        XCTAssertLessThanOrEqual(call, 0.65, "BB 10bb call vs SB jam too wide (\(Int(call*100))%)")
    }

    /// Cross-position monotonicity: jam% should be non-decreasing as we move
    /// from UTG to BTN (later position can jam wider with fewer players left).
    func test_jamWidens_fromUtgToBtn_at_10bb() {
        let positions: [TablePosition] = [.utg, .utg1, .lj, .hj, .co, .btn]
        var prev: Double = 0
        for p in positions {
            guard let c = chart(p, 10, .pushFold) else { continue }
            let jam = comboFraction(in: c, where: { $0[.shove] > 0 })
            XCTAssertGreaterThanOrEqual(
                jam, prev - 0.01,
                "Jam% should not shrink from one position to the next: \(p.rawValue) = \(jam) < previous \(prev)"
            )
            prev = jam
        }
    }
}
