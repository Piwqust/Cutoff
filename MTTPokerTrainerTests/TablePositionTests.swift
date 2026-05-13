import XCTest
@testable import MTTPokerTrainer

final class TablePositionTests: XCTestCase {
    func test_nineMaxOrder_isEightSeatsEarlyToLate() {
        let order = TablePosition.nineMaxOrder
        XCTAssertEqual(order.count, 8)
        XCTAssertEqual(order.first, .utg)
        XCTAssertEqual(order.last, .bb)
        XCTAssertEqual(order, [.utg, .utg1, .lj, .hj, .co, .btn, .sb, .bb])
    }

    func test_utg1_decodesFromJSONRawValue() throws {
        // JSON files use "UTG1" (no plus sign). Make sure it round-trips.
        let data = try JSONEncoder().encode(TablePosition.utg1)
        let decoded = try JSONDecoder().decode(TablePosition.self, from: data)
        XCTAssertEqual(decoded, .utg1)
        XCTAssertEqual(TablePosition.utg1.rawValue, "UTG1")
        XCTAssertEqual(TablePosition.utg1.displayName, "UTG+1")
    }
}
