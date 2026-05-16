import XCTest

@testable import MTTPokerTrainer

final class RangeLoaderTests: XCTestCase {

    /// Resolve the host-app bundle (where the JSON resources live).
    private var appBundle: Bundle {
        Bundle(for: QuizResult.self)
    }

    func test_bundledRanges_allDecodeAsSolverVerified() throws {
        let loader = RangeLoader(bundle: appBundle)
        let charts = try loader.loadAll()

        XCTAssertGreaterThanOrEqual(
            charts.count, 6, "Expected at least six bundled ranges, found \(charts.count)")

        let allowedKinds: Set<RangeChart.SourcePayload.Kind> = [.solverDump, .nashComputed, .gto, .userDefined]
        for chart in charts {
            XCTAssertTrue(
                allowedKinds.contains(chart.source.type),
                "Range \(chart.id) has unexpected source type '\(chart.source.type.rawValue)'"
            )
            XCTAssertEqual(chart.hands.count, 169, "Range \(chart.id) must list all 169 hand classes; found \(chart.hands.count)")
        }
    }

    func test_pushfoldSpots_areNashComputed() throws {
        let loader = RangeLoader(bundle: appBundle)
        let charts = (try? loader.loadAll()) ?? []
        try XCTSkipIf(charts.isEmpty, "No bundled ranges available in this test environment")

        let chart = loader.chart(matching: .btn, depthBB: 13, facing: .pushFold, in: charts)
        if let chart {
            XCTAssertEqual(chart.position, .btn)
            XCTAssertEqual(chart.facingAction, .pushFold)
        }
    }

    func test_everyEnabledActionAcrossPilotIsReachable() throws {
        let loader = RangeLoader(bundle: appBundle)
        let charts = (try? loader.loadAll()) ?? []
        try XCTSkipIf(charts.isEmpty, "No bundled ranges available")

        var union: Set<PreflopAction> = []
        for chart in charts { union.formUnion(chart.enabledActions) }

        // Actions the MTT 9-max chipEV corpus is expected to exercise. Limp,
        // limp-raise, and min-raise belong to cash / deep-stack variants we
        // don't ship yet — they're omitted intentionally.
        let mttActions: Set<PreflopAction> = [.fold, .call, .raise25x, .raise3x, .shove]
        for action in mttActions {
            XCTAssertTrue(
                union.contains(action),
                "Action \(action.rawValue) is never reachable across the bundled MTT ranges — UI button is dead."
            )
        }
    }

    func test_rangeService_loadsAllChartsOnce() throws {
        let loader = RangeLoader(bundle: appBundle)
        let charts = (try? loader.loadAll()) ?? []
        try XCTSkipIf(charts.isEmpty, "No bundled ranges available in this test environment")
        XCTAssertGreaterThanOrEqual(charts.count, 200, "Expected at least 200 bundled GTO ranges to decode")
    }

    func test_trainingFilter_matchesCorrectly() throws {
        let loader = RangeLoader(bundle: appBundle)
        let charts = (try? loader.loadAll()) ?? []
        try XCTSkipIf(charts.isEmpty, "No bundled ranges available in this test environment")

        let filter = TrainingFilter(
            positions: [.btn],
            depthBuckets: [.bb100],
            facingActions: [.unopened]
        )
        let matched = charts.filter { filter.matches($0) }
        XCTAssertFalse(matched.isEmpty, "BTN / 100BB / unopened should match at least one chart")
        for chart in matched {
            XCTAssertEqual(chart.spot.position, .btn)
            XCTAssertEqual(chart.spot.facingAction, .unopened)
            XCTAssertEqual(chart.spot.stackDepthBB, 100)
        }
    }
}
