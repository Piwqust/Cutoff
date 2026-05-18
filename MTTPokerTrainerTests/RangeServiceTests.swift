import XCTest

@testable import MTTPokerTrainer

@MainActor
final class RangeServiceTests: XCTestCase {

    /// Loaded once for the whole suite — `ensureLoaded` is idempotent so
    /// sharing is safe.
    private static let service: RangeService = {
        let s = RangeService()
        s.ensureLoaded()
        return s
    }()

    private var service: RangeService { Self.service }

    func test_ensureLoaded_isIdempotent() {
        let countBefore = service.charts.count
        service.ensureLoaded()
        service.ensureLoaded()
        XCTAssertEqual(service.charts.count, countBefore,
                       "Repeated ensureLoaded() calls should not reload")
        XCTAssertTrue(service.isLoaded)
    }

    func test_loadsAllBundledRanges() {
        XCTAssertGreaterThanOrEqual(service.charts.count, 300,
                                    "Bundle ships ~330 charts; got \(service.charts.count)")
    }

    func test_chartsMatching_emptyFilter_returnsAll() {
        let matches = service.charts(matching: .all)
        XCTAssertEqual(matches.count, service.charts.count)
    }

    func test_chartsMatching_byPosition_filters() {
        let filter = TrainingFilter(positions: [.btn])
        let matches = service.charts(matching: filter)
        XCTAssertFalse(matches.isEmpty, "BTN should have bundled charts")
        XCTAssertTrue(matches.allSatisfy { $0.position == .btn },
                      "Filter should only return BTN charts")
    }

    func test_chartsMatching_byFacing_filters() {
        let filter = TrainingFilter(facingActions: [.pushFold])
        let matches = service.charts(matching: filter)
        XCTAssertFalse(matches.isEmpty)
        XCTAssertTrue(matches.allSatisfy { $0.facingAction == .pushFold })
    }

    func test_bestChart_exactMatch() {
        guard let chart = service.bestChart(position: .btn, depthBB: 100, facing: .unopened) else {
            XCTFail("Expected a BTN 100 BB unopened chart")
            return
        }
        XCTAssertEqual(chart.position, .btn)
        XCTAssertEqual(chart.facingAction, .unopened)
    }

    func test_bestChart_snapsToNearestDepth() {
        // 90 BB isn't a canonical bucket. The loader should snap to nearest.
        guard let chart = service.bestChart(position: .co, depthBB: 90, facing: .unopened) else {
            XCTFail("Should match some chart by nearest depth")
            return
        }
        XCTAssertEqual(chart.position, .co)
        XCTAssertEqual(chart.facingAction, .unopened)
    }

    func test_chartByID_findsByExactID() {
        guard let firstID = service.charts.first?.id else {
            XCTFail("Bundle empty")
            return
        }
        let lookedUp = service.chart(byID: firstID)
        XCTAssertEqual(lookedUp?.id, firstID)
    }

    func test_chartByID_returnsNilOnUnknownID() {
        XCTAssertNil(service.chart(byID: "not_a_real_chart_id_xyz"))
    }

    func test_availableDimensions_areNonEmpty() {
        XCTAssertFalse(service.availablePositions.isEmpty)
        XCTAssertFalse(service.availableDepthBuckets.isEmpty)
        XCTAssertFalse(service.availableFacingActions.isEmpty)
    }
}
