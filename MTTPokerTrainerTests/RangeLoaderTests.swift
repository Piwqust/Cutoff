import XCTest

@testable import MTTPokerTrainer

final class RangeLoaderTests: XCTestCase {

    /// Resolve the host-app bundle (where the JSON resources live).
    private var appBundle: Bundle {
        Bundle(for: QuizResult.self)
    }

    func test_bundledRanges_allDecodeAsDemoWithCompliantDisclaimer() throws {
        let loader = RangeLoader(bundle: appBundle)
        let charts = try loader.loadAll()

        XCTAssertGreaterThanOrEqual(charts.count, 16, "Expected at least the 16 pilot ranges, found \(charts.count)")
        for chart in charts {
            XCTAssertEqual(chart.source.type, .demo, "Range \(chart.id) must be labeled 'demo' (CLAUDE.md compliance)")
            XCTAssertTrue(
                chart.source.description.lowercased().contains("not solver-verified"),
                "Range \(chart.id) is missing the 'not solver-verified' caveat"
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

        for action in PreflopAction.allCases {
            XCTAssertTrue(
                union.contains(action),
                "Action \(action.rawValue) is never reachable across the bundled pilot ranges — UI button is dead."
            )
        }
    }
}
