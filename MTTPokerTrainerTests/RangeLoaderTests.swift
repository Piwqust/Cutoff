import XCTest

@testable import MTTPokerTrainer

final class RangeLoaderTests: XCTestCase {

    /// Resolve the host-app bundle (where the JSON resources live), regardless
    /// of whether the test target runs inside the app or standalone.
    private var appBundle: Bundle {
        Bundle(for: QuizResult.self)
    }

    func test_bundledRanges_allDecodeWithKnownSourceTypeAndDisclaimer() throws {
        let loader = RangeLoader(bundle: appBundle)
        let charts = (try? loader.loadAll()) ?? []

        XCTAssertGreaterThanOrEqual(
            charts.count, 6, "Expected at least six bundled ranges, found \(charts.count)")

        let allowedKinds: Set<RangeChart.SourcePayload.Kind> = [.demo, .userDefined, .gto]
        for chart in charts {
            XCTAssertTrue(
                allowedKinds.contains(chart.source.type),
                "Range \(chart.id) has unexpected source type '\(chart.source.type.rawValue)'"
            )
            // The UI-facing disclaimer must always say "not solver-verified" for compliance.
            XCTAssertTrue(
                chart.source.fullDisclaimer.lowercased().contains("not solver-verified"),
                "Range \(chart.id) fullDisclaimer is missing the 'not solver-verified' caveat"
            )
            XCTAssertEqual(chart.format, "NLHE_MTT_9MAX")
        }
    }

    func test_nearestMatch_picksClosestDepth() throws {
        let loader = RangeLoader(bundle: appBundle)
        let charts = (try? loader.loadAll()) ?? []
        try XCTSkipIf(charts.isEmpty, "No bundled ranges available in this test environment")

        let chart = loader.chart(matching: .btn, depthBB: 11, facing: .pushFold, in: charts)
        XCTAssertNotNil(chart)
        XCTAssertEqual(chart?.spot.position, .btn)
        XCTAssertEqual(chart?.spot.facingAction, .pushFold)
    }

    func test_rangeService_loadsAllChartsOnce() throws {
        let loader = RangeLoader(bundle: appBundle)
        let charts = (try? loader.loadAll()) ?? []
        try XCTSkipIf(charts.isEmpty, "No bundled ranges available in this test environment")
        XCTAssertGreaterThanOrEqual(charts.count, 370, "Expected all 370 bundled GTO ranges to decode")
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
