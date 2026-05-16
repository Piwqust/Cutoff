import XCTest
@testable import MTTPokerTrainer

/// Pushfold spots are jam-or-fold (or call-or-fold for the defender). If a
/// chart tagged `facingAction == .pushFold` lists a hand as `raise` or
/// `minRaise`, the chart is broken — the action vocabulary leaked from a
/// non-pushfold spot. This catches the regression we saw in the pre-Nash
/// corpus where pushfold files contained "call" actions for the jammer.
final class PushfoldSemanticTests: XCTestCase {
    private var appBundle: Bundle { Bundle(for: QuizResult.self) }

    func test_pushfoldCharts_onlyUseJamCallOrFold() throws {
        let charts = try RangeLoader(bundle: appBundle).loadAll()
        try XCTSkipIf(charts.isEmpty)

        let allowed: Set<PreflopAction> = [.fold, .shove, .call]
        for chart in charts where chart.facingAction == .pushFold {
            for (notation, freq) in chart.hands {
                let used = PreflopAction.allCases.filter { freq[$0] > 0 }
                for action in used {
                    XCTAssertTrue(
                        allowed.contains(action),
                        "Pushfold chart \(chart.id) uses disallowed action \(action.rawValue) on \(notation)"
                    )
                }
            }
        }
    }

    /// The jammer's chart (any non-BB position) must not list any hand as
    /// `call` — open-jams are pure jam-or-fold for the jammer.
    func test_pushfoldChartsForJammer_haveNoCalls() throws {
        let charts = try RangeLoader(bundle: appBundle).loadAll()
        try XCTSkipIf(charts.isEmpty)

        for chart in charts where chart.facingAction == .pushFold && chart.position != .bb {
            for (notation, freq) in chart.hands where freq[.call] > 0 {
                XCTFail("Pushfold jammer chart \(chart.id) lists \(notation) as call — should be jam or fold")
            }
        }
    }

    /// BB facing an open-jam can only call or fold — never re-jam (Hero is
    /// already all-in). SB pushfold spots are open-jam ranges (SB as jammer
    /// vs BB), so SB is treated like any other jammer.
    func test_pushfoldDefender_onlyCallsOrFolds() throws {
        let charts = try RangeLoader(bundle: appBundle).loadAll()
        try XCTSkipIf(charts.isEmpty)

        for chart in charts where chart.facingAction == .pushFold && chart.position == .bb {
            for (notation, freq) in chart.hands where freq[.shove] > 0 {
                XCTFail("BB pushfold chart \(chart.id) lists \(notation) as shove — facing an all-in, can only call or fold")
            }
        }
    }
}
