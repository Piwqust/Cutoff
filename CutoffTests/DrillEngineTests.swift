import XCTest

@testable import Cutoff

@MainActor
final class DrillEngineTests: XCTestCase {

    private var appBundle: Bundle { Bundle(for: QuizResult.self) }

    private func loadCharts() -> [RangeChart] {
        (try? RangeLoader(bundle: appBundle).loadAll()) ?? []
    }

    func test_bundledCharts_loadInLargeNumber() {
        let charts = loadCharts()
        XCTAssertGreaterThan(
            charts.count, 100,
            "Expected the bundled GTO charts to all decode; got \(charts.count). " +
            "If this regressed, check SourcePayload.Kind covers every type in JSON."
        )
    }

    func test_eachDrillCategory_hasNonEmptyPool() {
        let charts = loadCharts()
        guard !charts.isEmpty else {
            XCTFail("No charts decoded — decoding regression.")
            return
        }
        for cat in DrillCategory.allCases {
            let engine = DrillEngine(charts: charts, category: cat)
            XCTAssertFalse(engine.pool.isEmpty, "\(cat.rawValue) has no matching charts")
        }
    }

    func test_drillRespectsDepthAndFacingFilters() {
        let charts = loadCharts()
        for cat in DrillCategory.allCases where cat != .mixed {
            let engine = DrillEngine(charts: charts, category: cat)
            for chart in engine.pool {
                XCTAssertTrue(cat.depthRange.contains(chart.spot.stackDepthBB),
                              "\(cat.rawValue) leaked a \(chart.spot.stackDepthBB) BB chart")
                XCTAssertTrue(cat.facingActions.contains(chart.spot.facingAction),
                              "\(cat.rawValue) leaked a \(chart.spot.facingAction.rawValue) chart")
            }
        }
    }

    func test_next_returnsCorrectActionFromAvailableSet() {
        let charts = loadCharts()
        var rng = SystemRandomNumberGenerator()
        for cat in DrillCategory.allCases {
            let engine = DrillEngine(charts: charts, category: cat)
            for _ in 0..<20 {
                guard let q = engine.next(rng: &rng) else {
                    XCTFail("\(cat.rawValue) returned nil question")
                    continue
                }
                XCTAssertTrue(cat.availableActions.contains(q.correctAction),
                              "\(cat.rawValue): correctAction \(q.correctAction) not in available set \(cat.availableActions)")
            }
        }
    }

    func test_progressStore_recordsRatingAndStreak() {
        let suite = UserDefaults(suiteName: "DrillEngineTests-\(UUID().uuidString)")!
        let store = ProgressStore(defaults: suite)

        XCTAssertEqual(store.rating(for: .firstInJam), 1000)
        XCTAssertEqual(store.totalXP, 0)
        XCTAssertEqual(store.streakDays, 0)

        store.record(outcome: .correct, in: .firstInJam)
        XCTAssertEqual(store.rating(for: .firstInJam), 1016)
        XCTAssertEqual(store.totalXP, 10)
        XCTAssertEqual(store.streakDays, 1)

        store.record(outcome: .punt, in: .firstInJam)
        XCTAssertEqual(store.rating(for: .firstInJam), 994)
        XCTAssertEqual(store.totalXP, 11)
        // Same calendar day → streak unchanged
        XCTAssertEqual(store.streakDays, 1)
    }
}
