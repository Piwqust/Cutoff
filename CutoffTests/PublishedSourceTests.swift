import XCTest

@testable import Cutoff

/// Verifies the additions made when 8-max became the canonical baseline:
/// - `RangeChart.SourcePayload.Kind.published` decodes correctly.
/// - `RangeChart.Publisher` round-trips through Codable.
/// - `NLHE_MTT_8MAX` format token resolves `tableSize` to 8.
/// - Mixed-frequency hand entries (`"A5s": {"raise": 0.5, "fold": 0.5}`)
///   are accepted by the rich-shape decoder and scored as ambiguous.
/// - `TrainingFilter.tableSizes` narrows charts to the requested format.
final class PublishedSourceTests: XCTestCase {

    private func decode(_ json: String) throws -> RangeChart {
        try JSONDecoder().decode(RangeChart.self, from: Data(json.utf8))
    }

    func test_published_source_kind_decodes() throws {
        let json = """
        {
          "id": "mtt_8max_100bb_co_unopened",
          "format": "NLHE_MTT_8MAX",
          "spot": { "position": "CO", "stackDepthBB": 100, "facingAction": "unopened", "anteType": "bigBlindAnte" },
          "source": {
            "type": "published",
            "description": "RangeConverter free PDF — 8-max 100bb 1bb ante.",
            "publisher": {
              "name": "RangeConverter",
              "product": "Free Poker Charts — 8 max 100bb 1bb ante MTT GTO Ranges",
              "url": "https://rangeconverter.com/free-poker-charts",
              "accessedDate": "2026-05-21",
              "treeParams": "2.5x open"
            }
          },
          "hands": { "AA": "raise" }
        }
        """
        let chart = try decode(json)
        XCTAssertEqual(chart.source.type, .published)
        XCTAssertEqual(chart.source.humanLabel, "Published chart")
        XCTAssertEqual(chart.source.publisher?.name, "RangeConverter")
        XCTAssertEqual(chart.source.publisher?.accessedDate, "2026-05-21")
        XCTAssertEqual(chart.source.publisher?.url, "https://rangeconverter.com/free-poker-charts")
        XCTAssertEqual(chart.tableSize, 8, "NLHE_MTT_8MAX format token must resolve to tableSize == 8")
    }

    func test_unknown_kind_falls_back_to_demo() throws {
        // Defensive guarantee: malformed kind doesn't crash decode.
        let json = """
        {
          "id": "x",
          "format": "NLHE_MTT_8MAX",
          "spot": { "position": "CO", "stackDepthBB": 100, "facingAction": "unopened", "anteType": "bigBlindAnte" },
          "source": { "type": "totallyMadeUp", "description": "" },
          "hands": {}
        }
        """
        let chart = try decode(json)
        XCTAssertEqual(chart.source.type, .demo)
    }

    func test_publisher_is_optional_for_legacy_files() throws {
        let json = """
        {
          "id": "legacy",
          "format": "NLHE_MTT_9MAX",
          "spot": { "position": "BTN", "stackDepthBB": 25, "facingAction": "pushFold", "anteType": "bigBlindAnte" },
          "source": { "type": "nashComputed", "description": "Nash chart." },
          "hands": { "AA": "jam" }
        }
        """
        let chart = try decode(json)
        XCTAssertNil(chart.source.publisher)
        XCTAssertEqual(chart.source.type, .nashComputed)
    }

    func test_mixed_frequency_hand_entry_decodes_and_scores_ambiguous() throws {
        // 50/50 raise/fold — Scorer should accept either action as "close enough".
        let json = """
        {
          "id": "mtt_8max_100bb_co_unopened",
          "format": "NLHE_MTT_8MAX",
          "spot": { "position": "CO", "stackDepthBB": 100, "facingAction": "unopened", "anteType": "bigBlindAnte" },
          "source": { "type": "published", "description": "test" },
          "hands": { "A5s": { "raise25x": 0.5, "fold": 0.5 } }
        }
        """
        let chart = try decode(json)
        let combo = HandCombo.parse("A5s")!
        let freq = chart.frequencies(for: combo)
        XCTAssertEqual(freq[PreflopAction.fold], 0.5, accuracy: 0.001)
        XCTAssertEqual(freq[PreflopAction.raise25x], 0.5, accuracy: 0.001)

        // Scorer's ≥0.2 threshold means both raise and fold are acceptable.
        let foldOutcome: AnswerOutcome = Scorer.evaluate(user: PreflopAction.fold, frequencies: freq)
        let raiseOutcome: AnswerOutcome = Scorer.evaluate(user: PreflopAction.raise25x, frequencies: freq)
        XCTAssertNotEqual(foldOutcome, AnswerOutcome.punt, "50% fold should not score as punt")
        XCTAssertNotEqual(raiseOutcome, AnswerOutcome.punt, "50% raise should not score as punt")
    }

    func test_trainingFilter_tableSizes_narrows() {
        let make: (Int) -> RangeChart = { size in
            let json = """
            {
              "id": "x\(size)",
              "format": "NLHE_MTT_\(size)MAX",
              "spot": { "position": "CO", "stackDepthBB": 100, "facingAction": "unopened", "anteType": "bigBlindAnte" },
              "source": { "type": "published", "description": "" },
              "hands": {}
            }
            """
            return try! JSONDecoder().decode(RangeChart.self, from: Data(json.utf8))
        }
        let charts = [make(8), make(9)]
        let filter = TrainingFilter(tableSizes: [8])
        let matched = charts.filter { filter.matches($0) }
        XCTAssertEqual(matched.count, 1)
        XCTAssertEqual(matched.first?.tableSize, 8)
    }
}
