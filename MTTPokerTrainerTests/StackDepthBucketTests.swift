import XCTest

@testable import MTTPokerTrainer

final class StackDepthBucketTests: XCTestCase {

    func test_nearest_snapsToExactBucket() {
        XCTAssertEqual(StackDepthBucket.nearest(to: 25), .bb25)
        XCTAssertEqual(StackDepthBucket.nearest(to: 100), .bb100)
    }

    func test_nearest_picksClosestBucket() {
        XCTAssertEqual(StackDepthBucket.nearest(to: 26), .bb25)
        XCTAssertEqual(StackDepthBucket.nearest(to: 35), .bb30)
        XCTAssertEqual(StackDepthBucket.nearest(to: 60), .bb50)
        XCTAssertEqual(StackDepthBucket.nearest(to: 90), .bb100)
    }

    /// On a midway input the smaller bucket wins — the conservative choice
    /// for a trainer (train the shorter chart, higher cost-of-error). If
    /// this test fails the doc comment on `StackDepthBucket.nearest` needs
    /// to change with it.
    func test_nearest_midpointTie_prefersSmallerBucket() {
        // 17 is equidistant from 15 and 20.
        XCTAssertEqual(StackDepthBucket.nearest(to: 17), .bb15)
        // 22 is equidistant from 20 and 25.
        XCTAssertEqual(StackDepthBucket.nearest(to: 22), .bb20)
        // 35 (between 30 and 40) snaps to 30.
        XCTAssertEqual(StackDepthBucket.nearest(to: 35), .bb30)
    }

    func test_nearest_clampsBelowMinimum() {
        XCTAssertEqual(StackDepthBucket.nearest(to: 5), .bb10)
        XCTAssertEqual(StackDepthBucket.nearest(to: -1), .bb10)
    }

    func test_nearest_clampsAboveMaximum() {
        XCTAssertEqual(StackDepthBucket.nearest(to: 200), .bb125)
    }
}
