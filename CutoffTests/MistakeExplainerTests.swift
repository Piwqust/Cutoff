import XCTest
@testable import Cutoff

final class MistakeExplainerTests: XCTestCase {

    private func chart(
        id: String = "TEST",
        position: TablePosition = .btn,
        depth: Int = 100,
        facing: FacingAction = .unopened,
        hands: [String: HandFrequencies]
    ) -> RangeChart {
        // Pad missing hands with fold so the chart looks valid.
        var padded = hands
        for combo in HandCombo.allInMatrixOrder where padded[combo.notation] == nil {
            padded[combo.notation] = HandFrequencies([.fold: 1.0])
        }
        return RangeChartFixture(
            id: id,
            stackDepth: depth,
            position: position,
            tableSize: 9,
            antePercent: 12.5,
            facingAction: facing,
            isICM: false,
            source: .init(type: .gto, description: "test"),
            hands: padded
        ).asChart
    }

    func test_tooTight_suitedAce_returnsReasonReferencingEquity() {
        let c = chart(hands: [
            "AKs": HandFrequencies([.raise25x: 1.0])
        ])
        let result = QuizResult(
            combo: "AKs",
            position: .btn,
            stackDepthBB: 100,
            facingAction: .unopened,
            anteType: .bigBlindAnte,
            rangeChartID: c.id,
            userAction: .fold,
            correctAction: .raise,
            outcome: .mistake
        )
        let exp = MistakeExplainer.explain(result: result, chart: c)
        XCTAssertEqual(exp.mistakeReason, .tooTight)
        XCTAssertFalse(exp.verdict.isEmpty)
        XCTAssertFalse(exp.reason.isEmpty)
        XCTAssertFalse(exp.context.isEmpty)
    }

    func test_tooLoose_offsuitJunk_reasonMentionsBleed() {
        let c = chart(hands: [
            "72o": HandFrequencies([.fold: 1.0])
        ])
        let result = QuizResult(
            combo: "72o",
            position: .utg,
            stackDepthBB: 100,
            facingAction: .unopened,
            anteType: .bigBlindAnte,
            rangeChartID: c.id,
            userAction: .raise,
            correctAction: .fold,
            outcome: .punt
        )
        let exp = MistakeExplainer.explain(result: result, chart: c)
        XCTAssertEqual(exp.mistakeReason, .tooLoose)
        XCTAssertTrue(exp.joined.lowercased().contains("fold") || exp.joined.lowercased().contains("bleed"))
    }

    func test_missedMix_returnsMinorityLegMessage() {
        let c = chart(hands: [
            "AJs": HandFrequencies([.raise25x: 0.6, .raise3x: 0.4])
        ])
        let result = QuizResult(
            combo: "AJs",
            position: .btn,
            stackDepthBB: 100,
            facingAction: .unopened,
            anteType: .bigBlindAnte,
            rangeChartID: c.id,
            userAction: .threeBet,
            correctAction: .raise,
            outcome: .close
        )
        let exp = MistakeExplainer.explain(result: result, chart: c)
        XCTAssertEqual(exp.mistakeReason, .missedMix)
        XCTAssertTrue(exp.reason.lowercased().contains("mix"))
    }

    func test_verdictMentionsFrequenciesForMixedSpot() {
        let c = chart(hands: [
            "JTs": HandFrequencies([.raise25x: 0.7, .call: 0.3])
        ])
        let result = QuizResult(
            combo: "JTs",
            position: .btn,
            stackDepthBB: 100,
            facingAction: .unopened,
            anteType: .bigBlindAnte,
            rangeChartID: c.id,
            userAction: .fold,
            correctAction: .raise,
            outcome: .mistake
        )
        let exp = MistakeExplainer.explain(result: result, chart: c)
        XCTAssertTrue(exp.verdict.contains("%"))
    }
}

/// Small builder that materialises a RangeChart without going through JSON decoding,
/// so unit tests don't need bundled resources.
private struct RangeChartFixture {
    let id: String
    let stackDepth: Int
    let position: TablePosition
    let tableSize: Int
    let antePercent: Double
    let facingAction: FacingAction
    let isICM: Bool
    let source: RangeChart.SourcePayload
    let hands: [String: HandFrequencies]

    var asChart: RangeChart {
        // Encode → decode round trip gives us a clean RangeChart instance via Codable.
        let payload: [String: Any] = [
            "id": id,
            "stackDepth": stackDepth,
            "position": position.rawValue,
            "tableSize": tableSize,
            "antePercent": antePercent,
            "facingAction": facingAction.rawValue,
            "isICM": isICM,
            "source": ["type": source.type.rawValue, "description": source.description] as [String: Any],
            "hands": handsAsJSON
        ]
        let data = try! JSONSerialization.data(withJSONObject: payload, options: [])
        return try! JSONDecoder().decode(RangeChart.self, from: data)
    }

    private var handsAsJSON: [String: [String: Double]] {
        var out: [String: [String: Double]] = [:]
        for (k, f) in hands {
            var inner: [String: Double] = [:]
            for action in PreflopAction.allCases {
                inner[action.rawValue] = f[action]
            }
            out[k] = inner
        }
        return out
    }
}
