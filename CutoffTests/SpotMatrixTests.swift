import XCTest

@testable import Cutoff

final class SpotMatrixTests: XCTestCase {

    func test_all_isNonEmptyAndUnique() {
        let all = SpotMatrix.all
        XCTAssertFalse(all.isEmpty)
        let triples = all.map { SpotMatrix.Triple(position: $0.position, depth: $0.stackDepthBB, facing: $0.facingAction) }
        XCTAssertEqual(triples.count, Set(triples).count,
                       "SpotMatrix.all should not contain duplicate triples")
    }

    func test_BB_neverOpensUnopened() {
        for depth in StackDepthBucket.allCases.map(\.bb) {
            XCTAssertFalse(SpotMatrix.isValid(position: .bb, depth: depth, facing: .unopened),
                           "BB is never first-in unopened at \(depth) BB")
        }
    }

    func test_UTG_neverFacesOpen() {
        for depth in StackDepthBucket.allCases.map(\.bb) {
            XCTAssertFalse(SpotMatrix.isValid(position: .utg, depth: depth, facing: .vsOpen),
                           "UTG acts first; cannot face an open at \(depth) BB")
        }
    }

    func test_pushFold_onlyAtShortStacks() {
        let pushFoldDepths = SpotMatrix.all.filter { $0.facingAction == .pushFold }
            .map(\.stackDepthBB)
        XCTAssertFalse(pushFoldDepths.isEmpty, "Push/fold spots should exist for short stacks")
        XCTAssertTrue(pushFoldDepths.allSatisfy { $0 <= 25 },
                      "Push/fold spots beyond 25 BB shouldn't appear in the matrix")
    }

    func test_blindDefense_onlyForBlinds() {
        let defenders = SpotMatrix.all.filter { $0.facingAction == .blindDefense }
            .map(\.position)
        XCTAssertTrue(defenders.allSatisfy { $0 == .sb || $0 == .bb },
                      "Only SB / BB defend; got \(Set(defenders))")
    }

    func test_squeeze_requiresLateOrLaterPosition() {
        let squeezers = Set(SpotMatrix.all.filter { $0.facingAction == .squeeze }.map(\.position))
        // UTG, UTG+1 have no two earlier seats acting — they can't squeeze.
        XCTAssertFalse(squeezers.contains(.utg))
        XCTAssertFalse(squeezers.contains(.utg1))
    }

    func test_validTriples_matchesAll() {
        XCTAssertEqual(SpotMatrix.validTriples.count, SpotMatrix.all.count)
    }
}
