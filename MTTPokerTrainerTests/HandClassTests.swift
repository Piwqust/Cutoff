import XCTest
@testable import MTTPokerTrainer

final class HandClassTests: XCTestCase {
    private func cls(_ s: String) -> HandClass {
        HandClass.of(HandCombo.parse(s)!)
    }

    func test_pairs() {
        XCTAssertEqual(cls("AA"), .premiumPair)
        XCTAssertEqual(cls("KK"), .premiumPair)
        XCTAssertEqual(cls("QQ"), .premiumPair)
        XCTAssertEqual(cls("JJ"), .midPair)
        XCTAssertEqual(cls("99"), .midPair)
        XCTAssertEqual(cls("88"), .midPair)
        XCTAssertEqual(cls("77"), .smallPair)
        XCTAssertEqual(cls("22"), .smallPair)
    }

    func test_aces() {
        XCTAssertEqual(cls("AKs"), .suitedAce)
        XCTAssertEqual(cls("A2s"), .suitedAce)
        XCTAssertEqual(cls("AKo"), .offsuitAce)
        XCTAssertEqual(cls("A2o"), .offsuitAce)
    }

    func test_broadway() {
        XCTAssertEqual(cls("KQs"), .suitedBroadway)
        XCTAssertEqual(cls("JTs"), .suitedBroadway)
        XCTAssertEqual(cls("KQo"), .offsuitBroadway)
        XCTAssertEqual(cls("JTo"), .offsuitBroadway)
    }

    func test_suitedConnectors() {
        XCTAssertEqual(cls("T9s"), .suitedConnector)
        XCTAssertEqual(cls("54s"), .suitedConnector)
        XCTAssertEqual(cls("76s"), .suitedConnector)
    }

    func test_suitedGappers() {
        XCTAssertEqual(cls("86s"), .suitedGapper)
        XCTAssertEqual(cls("J9s"), .suitedGapper)
    }

    func test_suitedKingsAndQueens() {
        XCTAssertEqual(cls("K7s"), .suitedKing)
        XCTAssertEqual(cls("K2s"), .suitedKing)
        XCTAssertEqual(cls("Q7s"), .suitedQueen)
        XCTAssertEqual(cls("Q2s"), .suitedQueen)
    }

    func test_offsuitJunk() {
        XCTAssertEqual(cls("72o"), .offsuitJunk)
        XCTAssertEqual(cls("85o"), .offsuitJunk)
        XCTAssertEqual(cls("K7o"), .offsuitJunk)
    }

    func test_familyAxis() {
        XCTAssertEqual(HandClass.smallPair.family, .pair)
        XCTAssertEqual(HandClass.suitedAce.family, .ace)
        XCTAssertEqual(HandClass.suitedBroadway.family, .broadway)
        XCTAssertEqual(HandClass.suitedConnector.family, .suitedConnector)
        XCTAssertEqual(HandClass.suitedQueen.family, .suitedOther)
        XCTAssertEqual(HandClass.offsuitJunk.family, .junk)
    }
}
