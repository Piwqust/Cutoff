import XCTest
@testable import MTTPokerTrainer

/// Enforces the "every quiz button must be reachable" invariant on the pilot
/// range set. If a future range edit removes the last spot that uses a
/// particular action with non-zero frequency, this test fails so the dead
/// button is caught before shipping.
final class RangeCoverageTests: XCTestCase {
    private var appBundle: Bundle { Bundle(for: QuizResult.self) }

    func test_pilotRangesCoverEveryPreflopAction() throws {
        let charts = try RangeLoader(bundle: appBundle).loadAll()
        try XCTSkipIf(charts.isEmpty)

        var seen: Set<PreflopAction> = []
        for chart in charts {
            for (_, freqs) in chart.hands {
                for action in PreflopAction.allCases where freqs[action] > 0 {
                    seen.insert(action)
                }
            }
        }

        for action in PreflopAction.allCases {
            XCTAssertTrue(
                seen.contains(action),
                "PreflopAction.\(action.rawValue) is unreachable in any pilot range — the UI button has no spot that triggers it."
            )
        }
    }

    func test_pilotRangesAllDeclareDemoCompliance() throws {
        let charts = try RangeLoader(bundle: appBundle).loadAll()
        for chart in charts {
            XCTAssertEqual(chart.source.type, .demo)
            XCTAssertTrue(chart.source.description.lowercased().contains("not solver-verified"))
        }
    }

    func test_pilotCoversAllEightPositionsOrAtLeastFour() throws {
        let charts = try RangeLoader(bundle: appBundle).loadAll()
        let positions = Set(charts.map(\.position))
        XCTAssertGreaterThanOrEqual(positions.count, 4, "Pilot should at least exercise 4 positions")
    }

    func test_pilotCoversEveryFacingActionWeShipUiFor() throws {
        let charts = try RangeLoader(bundle: appBundle).loadAll()
        let facings = Set(charts.map(\.facingAction))
        XCTAssertTrue(facings.contains(.rfi))
        XCTAssertTrue(facings.contains(.pushFold))
        XCTAssertTrue(facings.contains(.vsOpenCall))
        XCTAssertTrue(facings.contains(.vs3Bet))
    }
}
