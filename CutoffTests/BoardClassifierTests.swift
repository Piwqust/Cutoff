import XCTest

@testable import Cutoff

final class BoardClassifierTests: XCTestCase {
    private func classify(_ s: String) -> BoardTextureClass? {
        guard let b = Board(s) else { return nil }
        return BoardClassifier.classify(b)
    }

    func test_dryHigh() {
        XCTAssertEqual(classify("Ks7d2c"), .dryHigh)
    }

    func test_monotone() {
        XCTAssertEqual(classify("KsTs5s"), .monotone)
    }

    func test_wetConnected() {
        XCTAssertEqual(classify("Th9s8d"), .wetConnected)
    }

    func test_pairedHigh() {
        XCTAssertEqual(classify("KhKd5c"), .pairedHigh)
    }

    func test_pairedLow() {
        XCTAssertEqual(classify("5h5s2d"), .pairedLow)
    }

    func test_broadwayHeavy() {
        XCTAssertEqual(classify("AhKsJc"), .broadwayHeavy)
    }
}
