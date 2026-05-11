import XCTest
@testable import MTTPokerTrainer

final class TablePositionTests: XCTestCase {
    func test_nineMaxOrder_isEightSeatsEarlyToLate() {
        let order = TablePosition.nineMaxOrder
        XCTAssertEqual(order.count, 8) // UTG..BB at 9-max
        XCTAssertEqual(order.first, .utg)
        XCTAssertEqual(order.last, .bb)
        XCTAssertEqual(order, [.utg, .utg1, .lj, .hj, .co, .btn, .sb, .bb])
    }
}
