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
        // Canonical raw value is "UTG+1"; legacy "UTG1" still decodes via the
        // custom Codable bridge.
        let data = try JSONEncoder().encode(TablePosition.utg1)
        let decoded = try JSONDecoder().decode(TablePosition.self, from: data)
        XCTAssertEqual(decoded, .utg1)
        XCTAssertEqual(TablePosition.utg1.rawValue, "UTG+1")
        XCTAssertEqual(TablePosition.utg1.displayName, "UTG+1")

        // Legacy form ("UTG1") still decodes.
        let legacyData = "\"UTG1\"".data(using: .utf8)!
        XCTAssertEqual(try JSONDecoder().decode(TablePosition.self, from: legacyData), .utg1)
    }
}
