import XCTest
@testable import MTTPokerTrainer

final class HandComboTests: XCTestCase {
    func test_parsesPair() {
        let h = HandCombo.parse("AA")
        XCTAssertEqual(h?.category, .pair)
        XCTAssertEqual(h?.highRank, .ace)
        XCTAssertEqual(h?.notation, "AA")
    }

    func test_parsesSuited() {
        let h = HandCombo.parse("AKs")
        XCTAssertEqual(h?.category, .suited)
        XCTAssertEqual(h?.highRank, .ace)
        XCTAssertEqual(h?.lowRank, .king)
        XCTAssertEqual(h?.notation, "AKs")
    }

    func test_parsesOffsuit_normalizesHighRankFirst() {
        let h = HandCombo.parse("KAo")
        XCTAssertEqual(h?.category, .offsuit)
        XCTAssertEqual(h?.highRank, .ace)
        XCTAssertEqual(h?.lowRank, .king)
        XCTAssertEqual(h?.notation, "AKo")
    }

    func test_rejectsMalformed() {
        XCTAssertNil(HandCombo.parse(""))
        XCTAssertNil(HandCombo.parse("AKx"))
        XCTAssertNil(HandCombo.parse("A"))
        XCTAssertNil(HandCombo.parse("AAs"))   // pair can't be suited
        XCTAssertNil(HandCombo.parse("BB"))    // invalid rank
    }

    func test_matrixHasAll169Combos() {
        let combos = HandCombo.allInMatrixOrder
        XCTAssertEqual(combos.count, 169)
        let pairs   = combos.filter { $0.category == .pair }.count
        let suited  = combos.filter { $0.category == .suited }.count
        let offsuit = combos.filter { $0.category == .offsuit }.count
        XCTAssertEqual(pairs,   13)
        XCTAssertEqual(suited,  78)
        XCTAssertEqual(offsuit, 78)
    }

    func test_topLeftCellIsAcesPocket() {
        let combo = HandCombo.combo(forRow: 0, column: 0)
        XCTAssertEqual(combo.notation, "AA")
    }
}
