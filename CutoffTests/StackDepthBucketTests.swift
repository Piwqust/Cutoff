import XCTest

@testable import Cutoff

final class StackDepthBucketTests: XCTestCase {

    func test_nearest_snapsToExactBucket() {
        XCTAssertEqual(StackDepthBucket.nearest(to: 25), .bb25)
        XCTAssertEqual(StackDepthBucket.nearest(to: 35), .bb35)
        XCTAssertEqual(StackDepthBucket.nearest(to: 70), .bb70)
        XCTAssertEqual(StackDepthBucket.nearest(to: 100), .bb100)
    }

    func test_nearest_picksClosestBucket() {
        XCTAssertEqual(StackDepthBucket.nearest(to: 26), .bb25)
        XCTAssertEqual(StackDepthBucket.nearest(to: 36), .bb35)
        XCTAssertEqual(StackDepthBucket.nearest(to: 58), .bb60)
        XCTAssertEqual(StackDepthBucket.nearest(to: 92), .bb100)
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
        // 45 (between 40 and 50) snaps to 40.
        XCTAssertEqual(StackDepthBucket.nearest(to: 45), .bb40)
    }

    func test_nearest_clampsBelowMinimum() {
        XCTAssertEqual(StackDepthBucket.nearest(to: 5), .bb10)
        XCTAssertEqual(StackDepthBucket.nearest(to: -1), .bb10)
    }

    func test_nearest_clampsAboveMaximum() {
        XCTAssertEqual(StackDepthBucket.nearest(to: 200), .bb100)
    }
}
