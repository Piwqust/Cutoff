import XCTest

@testable import MTTPokerTrainer

final class RangeLoaderTests: XCTestCase {

    /// Resolve the host-app bundle (where the JSON resources live), regardless
    /// of whether the test target runs inside the app or standalone.
    private var appBundle: Bundle {
        // A class declared in the app module — `Bundle(for:)` returns the app bundle.
        Bundle(for: QuizResult.self)
    }

    func test_bundledRanges_allDecodeWithKnownSourceTypeAndDisclaimer() throws {
        let loader = RangeLoader(bundle: appBundle)
        let charts = (try? loader.loadAll()) ?? []

        // Expect at least the original 6 demo files OR the generated Nash/GTO replacements.
        XCTAssertGreaterThanOrEqual(
            charts.count, 6, "Expected at least six bundled ranges, found \(charts.count)")
        let allowedKinds: Set<RangeChart.SourcePayload.Kind> = [.demo, .userDefined]
        for chart in charts {
            XCTAssertTrue(
                allowedKinds.contains(chart.source.type),
                "Range \(chart.id) has unexpected source type '\(chart.source.type.rawValue)'"
            )
            XCTAssertTrue(
                chart.source.description.lowercased().contains("not solver-verified"),
                "Range \(chart.id) is missing the 'not solver-verified' caveat"
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
}
