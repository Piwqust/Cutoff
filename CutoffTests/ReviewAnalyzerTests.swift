import XCTest
@testable import Cutoff

final class ReviewAnalyzerTests: XCTestCase {

    private func make(
        combo: String = "AKs",
        position: TablePosition = .btn,
        depth: Int = 100,
        facing: FacingAction = .unopened,
        user: RangeAction,
        correct: RangeAction,
        outcome: AnswerOutcome,
        rangeChartID: String = "X"
    ) -> QuizResult {
        QuizResult(
            combo: combo,
            position: position,
            stackDepthBB: depth,
            facingAction: facing,
            anteType: .bigBlindAnte,
            rangeChartID: rangeChartID,
            userAction: user,
            correctAction: correct,
            outcome: outcome
        )
    }

    func test_snapshot_empty() {
        let s = ReviewAnalyzer.snapshot([])
        XCTAssertEqual(s.total, 0)
        XCTAssertEqual(s.accuracy, 0)
    }

    func test_snapshot_aggregates() {
        let rows = [
            make(user: .raise, correct: .raise, outcome: .correct),
            make(user: .fold,  correct: .raise, outcome: .mistake),
            make(user: .call,  correct: .raise, outcome: .close),
            make(user: .jam,   correct: .fold,  outcome: .punt),
        ]
        let s = ReviewAnalyzer.snapshot(rows)
        XCTAssertEqual(s.total, 4)
        XCTAssertEqual(s.correct, 1)
        XCTAssertEqual(s.close, 1)
        XCTAssertEqual(s.mistakes, 2)
        // average score = (100 + 30 + 70 + 0) / 4 = 50
        XCTAssertEqual(s.accuracy, 50)
    }

    func test_byHandClass_groups() {
        let rows = [
            make(combo: "AKs", user: .raise, correct: .raise, outcome: .correct),
            make(combo: "A2s", user: .raise, correct: .raise, outcome: .correct),
            make(combo: "72o", user: .raise, correct: .fold,  outcome: .mistake),
        ]
        let buckets = ReviewAnalyzer.byHandClass(rows)
        XCTAssertEqual(buckets.first(where: { $0.id == HandClass.suitedAce.rawValue })?.total, 2)
        XCTAssertEqual(buckets.first(where: { $0.id == HandClass.offsuitJunk.rawValue })?.total, 1)
    }

    func test_topLeakSpots_thresholdedAndSorted() {
        var rows: [QuizResult] = []
        for _ in 0..<5 {
            rows.append(make(position: .utg, depth: 100, facing: .unopened,
                             user: .raise, correct: .fold, outcome: .mistake))
        }
        for _ in 0..<5 {
            rows.append(make(position: .btn, depth: 100, facing: .unopened,
                             user: .raise, correct: .raise, outcome: .correct))
        }
        let spots = ReviewAnalyzer.topLeakSpots(rows, minSample: 4)
        XCTAssertEqual(spots.count, 1)
        XCTAssertEqual(spots.first?.position, .utg)
        XCTAssertEqual(spots.first?.mistakeRate ?? 0, 1.0, accuracy: 0.01)
    }

    func test_scope_filtersByDate() {
        let now = Date()
        let cal = Calendar.current
        let oldRow = make(user: .raise, correct: .raise, outcome: .correct)
        oldRow.createdAt = cal.date(byAdding: .day, value: -10, to: now)!
        let newRow = make(user: .raise, correct: .raise, outcome: .correct)
        newRow.createdAt = now

        let scoped = ReviewAnalyzer.apply(scope: .last7, to: [oldRow, newRow], now: now)
        XCTAssertEqual(scoped.count, 1)

        let scoped30 = ReviewAnalyzer.apply(scope: .last30, to: [oldRow, newRow], now: now)
        XCTAssertEqual(scoped30.count, 2)
    }

    func test_heatmap_excludesEmptyBuckets() {
        let rows = [
            make(position: .btn, depth: 100, user: .raise, correct: .raise, outcome: .correct),
            make(position: .btn, depth: 100, user: .raise, correct: .raise, outcome: .correct),
            make(position: .utg, depth: 30,  user: .fold,  correct: .raise, outcome: .mistake),
        ]
        let cells = ReviewAnalyzer.heatmap(rows)
        XCTAssertEqual(cells.count, 2)
        XCTAssertEqual(cells.first(where: { $0.position == .btn })?.total, 2)
    }
}
