import XCTest

@testable import MTTPokerTrainer

final class RangeLoaderTests: XCTestCase {

    /// Resolve the host-app bundle (where the JSON resources live).
    private var appBundle: Bundle {
        Bundle(for: QuizResult.self)
    }

    func test_bundledRanges_loadFullSpotMatrix() throws {
        let loader = RangeLoader(bundle: appBundle)
        let charts = try loader.loadAll()

        XCTAssertEqual(charts.count, SpotMatrix.all.count,
                       "Range count (\(charts.count)) does not match SpotMatrix count (\(SpotMatrix.all.count)).")

        let chartTriples = Set(charts.map {
            SpotMatrix.Triple(position: $0.spot.position, depth: $0.spot.stackDepthBB, facing: $0.spot.facingAction)
        })

        for spot in SpotMatrix.all {
            let triple = SpotMatrix.Triple(position: spot.position, depth: spot.stackDepthBB, facing: spot.facingAction)
            XCTAssertTrue(chartTriples.contains(triple),
                          "Missing chart for \(spot.position.displayName) \(spot.stackDepthBB) BB \(spot.facingAction.displayName)")
        }
    }

    func test_bundledRanges_haveValidSourceKinds() throws {
        let loader = RangeLoader(bundle: appBundle)
        let charts = try loader.loadAll()

        let allowed: Set<RangeChart.SourcePayload.Kind> = [.nashComputed, .solverDump, .demoHandAuthored, .userImported]
        for chart in charts {
            XCTAssertTrue(allowed.contains(chart.source.type),
                          "Chart \(chart.id) has unexpected source.type")
            XCTAssertEqual(chart.format, "NLHE_MTT_9MAX")
        }
    }

    func test_pushfoldSpots_areNashComputed() throws {
        let loader = RangeLoader(bundle: appBundle)
        let charts = try loader.loadAll()
        let pushFold = charts.filter { $0.spot.facingAction == .pushFold }
        XCTAssertFalse(pushFold.isEmpty)
        for chart in pushFold {
            XCTAssertEqual(chart.source.type, .nashComputed,
                           "Push/fold chart \(chart.id) should be nashComputed.")
        }
    }
}
