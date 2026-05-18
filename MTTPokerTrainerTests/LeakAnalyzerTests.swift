import XCTest

@testable import MTTPokerTrainer

final class LeakAnalyzerTests: XCTestCase {

    private func row(
        combo: String = "T9o",
        position: TablePosition,
        depth: Int = 100,
        facing: FacingAction,
        user: RangeAction,
        correct: RangeAction,
        outcome: AnswerOutcome = .mistake
    ) -> QuizResult {
        QuizResult(
            combo: combo,
            position: position,
            stackDepthBB: depth,
            facingAction: facing,
            anteType: .bigBlindAnte,
            rangeChartID: "test",
            userAction: user,
            correctAction: correct,
            outcome: outcome
        )
    }

    func test_emptyResults_returnsNoLeaks() {
        XCTAssertTrue(LeakAnalyzer.leaks(from: []).isEmpty)
    }

    func test_smallSample_returnsNoLeaks() {
        // < 8 rows → analyzer bails early.
        let rows = (0..<5).map { _ in
            row(position: .utg, facing: .unopened, user: .raise, correct: .fold)
        }
        XCTAssertTrue(LeakAnalyzer.leaks(from: rows).isEmpty)
    }

    func test_detectsLooseUTG() {
        // 10 UTG opens where chart wants fold → loose UTG ratio = 1.0.
        var rows: [QuizResult] = (0..<10).map { _ in
            row(combo: "K8o", position: .utg, facing: .unopened, user: .raise, correct: .fold)
        }
        // Pad with some neutral rows so the 8-row floor passes.
        for _ in 0..<3 {
            rows.append(row(position: .btn, facing: .unopened, user: .fold, correct: .fold, outcome: .correct))
        }
        let leaks = LeakAnalyzer.leaks(from: rows)
        XCTAssertTrue(leaks.contains(where: { $0.id == "too_loose_utg" }),
                      "Expected a too_loose_utg leak; got \(leaks.map(\.id))")
    }

    func test_detectsOverfoldingBB() {
        // 10 BB-vs-open spots where user folds and chart wants call.
        var rows: [QuizResult] = (0..<10).map { _ in
            row(combo: "65s", position: .bb, depth: 30, facing: .vsOpen, user: .fold, correct: .call)
        }
        rows += (0..<3).map { _ in
            row(position: .btn, facing: .unopened, user: .fold, correct: .fold, outcome: .correct)
        }
        let leaks = LeakAnalyzer.leaks(from: rows)
        XCTAssertTrue(leaks.contains(where: { $0.id == "overfolding_bb" }))
    }

    func test_detectsMissedReshoves() {
        // 6 short-stack reshove spots; user folds them all.
        var rows: [QuizResult] = (0..<6).map { _ in
            row(combo: "A8s", position: .btn, depth: 15, facing: .pushFold, user: .fold, correct: .jam)
        }
        rows += (0..<3).map { _ in
            row(position: .co, facing: .unopened, user: .fold, correct: .fold, outcome: .correct)
        }
        let leaks = LeakAnalyzer.leaks(from: rows)
        XCTAssertTrue(leaks.contains(where: { $0.id == "missed_reshoves" }))
    }

    func test_leaksSortedBySeverityDescending() {
        // Build two leaks of differing severity by stacking many UTG opens
        // (severity ~1.0) and a milder BB overfold (severity ~0.4-0.5).
        var rows: [QuizResult] = []
        rows += (0..<20).map { _ in
            row(combo: "K8o", position: .utg, facing: .unopened, user: .raise, correct: .fold)
        }
        rows += (0..<5).map { _ in
            row(combo: "65s", position: .bb, depth: 30, facing: .vsOpen, user: .fold, correct: .call)
        }
        let leaks = LeakAnalyzer.leaks(from: rows)
        let severities = leaks.map(\.severity)
        XCTAssertEqual(severities, severities.sorted(by: >),
                       "Leaks should be returned sorted by severity desc")
    }

    func test_severityClampedToOne() {
        let rows = (0..<10).map { _ in
            row(combo: "K8o", position: .utg, facing: .unopened, user: .raise, correct: .fold)
        } + (0..<3).map { _ in
            row(position: .btn, facing: .unopened, user: .fold, correct: .fold, outcome: .correct)
        }
        let leaks = LeakAnalyzer.leaks(from: rows)
        XCTAssertTrue(leaks.allSatisfy { $0.severity <= 1.0 && $0.severity >= 0.0 })
    }
}
