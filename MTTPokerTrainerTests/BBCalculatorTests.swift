import XCTest
@testable import MTTPokerTrainer

final class BBCalculatorTests: XCTestCase {
    func test_defaultProfile_gives125BB() {
        XCTAssertEqual(BBCalculator.bb(stack: 25_000, bigBlind: 200), 125)
    }

    func test_zeroBigBlind_returnsZero() {
        XCTAssertEqual(BBCalculator.bb(stack: 25_000, bigBlind: 0), 0)
    }

    func test_truncatesTowardZero() {
        XCTAssertEqual(BBCalculator.bb(stack: 12_500, bigBlind: 200), 62)
    }
}
