import XCTest

@testable import Cutoff

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

    // MARK: - Hand-class accuracy leaks

    func test_detectsHandClassLeak_smallPairs() {
        // 6 small-pair spots all answered wrong (.punt) → accuracy 0% for
        // the smallPair class, well below the 55% floor.
        var rows: [QuizResult] = (0..<6).map { _ in
            row(combo: "44", position: .co, depth: 30, facing: .unopened,
                user: .fold, correct: .raise, outcome: .punt)
        }
        // Pad with unrelated correct rows so the 8-row analyzer floor passes
        // without pushing other classes below 55%.
        rows += (0..<6).map { _ in
            row(combo: "AKs", position: .co, depth: 30, facing: .unopened,
                user: .raise, correct: .raise, outcome: .correct)
        }
        let leaks = LeakAnalyzer.leaks(from: rows)
        XCTAssertTrue(
            leaks.contains(where: { $0.id == "handclass_\(HandClass.smallPair.rawValue)" }),
            "Expected a handclass_smallPair leak; got \(leaks.map(\.id))"
        )
    }

    func test_noHandClassLeak_whenAccuracyAboveFloor() {
        // 5 correct + 1 wrong on small pairs = ~83% accuracy → no leak.
        var rows: [QuizResult] = (0..<5).map { _ in
            row(combo: "44", position: .co, depth: 30, facing: .unopened,
                user: .raise, correct: .raise, outcome: .correct)
        }
        rows.append(row(combo: "44", position: .co, depth: 30, facing: .unopened,
                        user: .fold, correct: .raise, outcome: .mistake))
        // Pad to clear the 8-row analyzer floor.
        rows += (0..<5).map { _ in
            row(combo: "AKs", position: .co, depth: 30, facing: .unopened,
                user: .raise, correct: .raise, outcome: .correct)
        }
        let leaks = LeakAnalyzer.leaks(from: rows)
        XCTAssertFalse(
            leaks.contains(where: { $0.id.hasPrefix("handclass_") }),
            "Did not expect a hand-class leak above the accuracy floor; got \(leaks.map(\.id))"
        )
    }

    func test_noHandClassLeak_belowSampleFloor() {
        // 4 small-pair spots all wrong, but the analyzer requires >= 5 in a
        // class before flagging. Pad with unrelated correct rows for the
        // overall 8-row floor.
        var rows: [QuizResult] = (0..<4).map { _ in
            row(combo: "44", position: .co, depth: 30, facing: .unopened,
                user: .fold, correct: .raise, outcome: .punt)
        }
        rows += (0..<6).map { _ in
            row(combo: "AKs", position: .co, depth: 30, facing: .unopened,
                user: .raise, correct: .raise, outcome: .correct)
        }
        let leaks = LeakAnalyzer.leaks(from: rows)
        XCTAssertFalse(
            leaks.contains(where: { $0.id == "handclass_\(HandClass.smallPair.rawValue)" }),
            "Below the 5-row class floor — should not flag. Got \(leaks.map(\.id))"
        )
    }

    // MARK: - Direction-of-error leak

    func test_directionLeak_tooTight() {
        // 8 mistakes where the user folded but the chart wanted to raise.
        // Without a chart resolver the analyzer falls back to action-distance
        // inference (LeakAnalyzer.swift / ReviewAnalyzer.classify) — fold vs
        // non-fold correct = .tooTight. Share = 1.0, over the 0.45 threshold.
        let rows: [QuizResult] = (0..<8).map { _ in
            row(combo: "K9s", position: .co, depth: 30, facing: .unopened,
                user: .fold, correct: .raise, outcome: .mistake)
        }
        let leaks = LeakAnalyzer.leaks(from: rows)
        XCTAssertTrue(
            leaks.contains(where: { $0.id == "direction_\(MistakeReason.tooTight.rawValue)" }),
            "Expected a direction_tooTight leak; got \(leaks.map(\.id))"
        )
    }

    func test_directionLeak_tooLoose() {
        // 8 mistakes where the user raised but the chart wanted to fold.
        // Inferred reason for every row is .tooLoose.
        let rows: [QuizResult] = (0..<8).map { _ in
            row(combo: "T7o", position: .co, depth: 30, facing: .unopened,
                user: .raise, correct: .fold, outcome: .mistake)
        }
        let leaks = LeakAnalyzer.leaks(from: rows)
        XCTAssertTrue(
            leaks.contains(where: { $0.id == "direction_\(MistakeReason.tooLoose.rawValue)" }),
            "Expected a direction_tooLoose leak; got \(leaks.map(\.id))"
        )
    }

    func test_noDirectionLeak_belowMistakeFloor() {
        // The direction branch only runs at >= 6 mistakes. Five tooTight
        // mistakes plus padding correct rows should not surface one.
        var rows: [QuizResult] = (0..<5).map { _ in
            row(combo: "K9s", position: .co, depth: 30, facing: .unopened,
                user: .fold, correct: .raise, outcome: .mistake)
        }
        rows += (0..<5).map { _ in
            row(combo: "AKs", position: .co, depth: 30, facing: .unopened,
                user: .raise, correct: .raise, outcome: .correct)
        }
        let leaks = LeakAnalyzer.leaks(from: rows)
        XCTAssertFalse(
            leaks.contains(where: { $0.id.hasPrefix("direction_") }),
            "Direction branch requires >= 6 mistakes — should not surface. Got \(leaks.map(\.id))"
        )
    }
}
