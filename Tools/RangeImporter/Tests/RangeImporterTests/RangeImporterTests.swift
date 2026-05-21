import XCTest
@testable import RangeImporter

final class RangeImporterTests: XCTestCase {

    // MARK: - HandClasses

    func test_handClasses_has169Notations() {
        XCTAssertEqual(HandClasses.all.count, 169)
        XCTAssertEqual(HandClasses.all.first, "AA")
        XCTAssertEqual(HandClasses.all.last, "22")
        XCTAssertTrue(HandClasses.all.contains("AKs"))
        XCTAssertTrue(HandClasses.all.contains("AKo"))
    }

    // MARK: - CribSheet parsing

    func test_cribSheet_parsesPureAndMixed() throws {
        let csv = """
        notation,action,freq
        AA,raise,1.0
        A5s,raise,0.5
        A5s,fold,0.5
        # comment
        72o,fold,1.0
        """
        let sheet = try CribSheet.parse(csv)
        XCTAssertEqual(sheet.entries["AA"]?["raise"], 1.0)
        XCTAssertEqual(sheet.entries["A5s"]?["raise"], 0.5)
        XCTAssertEqual(sheet.entries["A5s"]?["fold"], 0.5)
    }

    func test_cribSheet_rejectsBadNotation() {
        let csv = """
        notation,action,freq
        XX,raise,1.0
        """
        XCTAssertThrowsError(try CribSheet.parse(csv))
    }

    func test_cribSheet_rejectsBadAction() {
        let csv = """
        notation,action,freq
        AA,donk,1.0
        """
        XCTAssertThrowsError(try CribSheet.parse(csv))
    }

    func test_cribSheet_rejectsFrequenciesThatDontSum() {
        let csv = """
        notation,action,freq
        AA,raise,0.5
        AA,call,0.3
        """
        XCTAssertThrowsError(try CribSheet.parse(csv))
    }

    // MARK: - ChartSlug

    func test_chartSlug_roundTrips() {
        let slug = ChartSlug.parse("mtt_8max_100bb_co_unopened")
        XCTAssertEqual(slug?.tableSize, 8)
        XCTAssertEqual(slug?.depthBB, 100)
        XCTAssertEqual(slug?.position, .co)
        XCTAssertEqual(slug?.facing, .unopened)
        XCTAssertEqual(slug?.id, "mtt_8max_100bb_co_unopened")
        XCTAssertEqual(slug?.format, "NLHE_MTT_8MAX")
    }

    func test_chartSlug_rejectsMalformed() {
        XCTAssertNil(ChartSlug.parse("totally_not_a_slug"))
        XCTAssertNil(ChartSlug.parse("mtt_8max_100bb_co"))
    }

    // MARK: - Emitter

    func test_emitter_writesPureAndMixed() throws {
        let csv = """
        notation,action,freq
        AA,raise,1.0
        A5s,raise,0.5
        A5s,fold,0.5
        """
        let sheet = try CribSheet.parse(csv)
        let slug = ChartSlug(tableSize: 8, depthBB: 100, position: .co, facing: .unopened)
        let emitter = Emitter(publisher: .rangeConverter8maxMTT)
        let data = try emitter.emit(slug: slug, sheet: sheet)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let hands = obj?["hands"] as? [String: Any]

        // Pure action emits as string.
        XCTAssertEqual(hands?["AA"] as? String, "raise")
        // Mixed action emits as dict keyed by PreflopAction rawValues.
        let mixed = hands?["A5s"] as? [String: Double]
        XCTAssertEqual(mixed?["raise25x"], 0.5)
        XCTAssertEqual(mixed?["fold"], 0.5)

        // Source metadata is `published`.
        let source = obj?["source"] as? [String: Any]
        XCTAssertEqual(source?["type"] as? String, "published")
        XCTAssertNotNil(source?["publisher"])
        XCTAssertEqual(obj?["format"] as? String, "NLHE_MTT_8MAX")
    }

    // MARK: - 9-max adapter

    func test_nineMaxAdapter_tightensUTG() {
        let entries: [String: [String: Double]] = [
            "AA": ["raise": 1.0],
            "KK": ["raise": 1.0],
            "A5s": ["raise": 1.0],          // mid-strength suited ace, kept
            "A2s": ["raise": 1.0],          // weakest, demoted
            "K7s": ["raise": 1.0],          // demoted
            "98s": ["raise": 1.0],          // suited connector, demoted
            "AKo": ["raise": 1.0],
        ]
        let sheet = CribSheet(entries: entries)
        let (adapted, note) = NineMaxAdapter.adapt(eightMax: sheet, sourcePosition: .utg, targetPosition: .utg)
        XCTAssertNotNil(adapted.entries["AA"])
        XCTAssertNotNil(adapted.entries["AKo"])
        XCTAssertNil(adapted.entries["A2s"], "weakest suited ace should be demoted")
        XCTAssertNil(adapted.entries["K7s"], "weak suited K should be demoted")
        XCTAssertNil(adapted.entries["98s"], "suited connector should be demoted")
        XCTAssertTrue(note.contains("demoted"))
    }

    func test_nineMaxAdapter_utg1CopiesEightMaxUTG() {
        let sheet = CribSheet(entries: ["AA": ["raise": 1.0], "A5s": ["raise": 1.0]])
        let (adapted, note) = NineMaxAdapter.adapt(eightMax: sheet, sourcePosition: .utg, targetPosition: .utg1)
        XCTAssertEqual(adapted.entries.count, 2)
        XCTAssertNotNil(adapted.entries["A5s"], "9-max UTG+1 keeps the same range as 8-max UTG")
        XCTAssertTrue(note.contains("UTG+1") || note.contains("same role"))
    }

    func test_nineMaxAdapter_othersCopyVerbatim() {
        let sheet = CribSheet(entries: ["AA": ["raise": 1.0], "76s": ["raise": 1.0]])
        let (adapted, _) = NineMaxAdapter.adapt(eightMax: sheet, sourcePosition: .btn, targetPosition: .btn)
        XCTAssertEqual(adapted.entries.count, 2)
        XCTAssertNotNil(adapted.entries["76s"])
    }
}
