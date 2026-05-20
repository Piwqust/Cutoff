import XCTest

@testable import Cutoff

@MainActor
final class ChartCatalogTests: XCTestCase {

    private var appBundle: Bundle { Bundle(for: QuizResult.self) }

    private func loadCatalog() -> ChartCatalog {
        let charts = (try? RangeLoader(bundle: appBundle).loadAll()) ?? []
        return ChartCatalog(charts: charts)
    }

    func test_utgPlus1_chartsDecode() {
        // Regression: the bundled JSONs use "UTG1" while the canonical raw
        // value is "UTG+1". TablePosition's custom Decodable bridges them.
        let charts = (try? RangeLoader(bundle: appBundle).loadAll()) ?? []
        let utg1Charts = charts.filter { $0.spot.position == .utg1 }
        XCTAssertGreaterThan(utg1Charts.count, 0, "UTG+1 charts should decode")
    }

    func test_semanticImpossibilities_areCorrectlyAbsent() {
        let cat = loadCatalog()
        // Blind defense is BB-only at a 9-max
        for p in TablePosition.allCases where p != .bb {
            for d in StackDepthBucket.allCases {
                XCTAssertFalse(cat.contains(position: p, depthBB: d.bb, facing: .blindDefense),
                               "\(p.rawValue) blindDefense should not exist")
            }
        }
        // Squeeze requires open + caller — impossible from first two seats
        for p: TablePosition in [.utg, .utg1] {
            XCTAssertFalse(cat.contains(position: p, depthBB: 100, facing: .squeeze))
        }
        // UTG can't face an open (UTG is the first to act)
        XCTAssertFalse(cat.contains(position: .utg, depthBB: 100, facing: .vsOpen))
        // BB never has an "unopened" decision
        XCTAssertFalse(cat.contains(position: .bb, depthBB: 100, facing: .unopened))
    }

    func test_validCombinations_arePresent() {
        let cat = loadCatalog()
        // Every depth bucket should be populated for the easy positions.
        for d in StackDepthBucket.allCases {
            XCTAssertTrue(cat.contains(position: .btn, depthBB: d.bb, facing: .unopened),
                          "BTN unopened at \(d.bb) BB should exist")
            XCTAssertTrue(cat.contains(position: .bb, depthBB: d.bb, facing: .blindDefense),
                          "BB blind defense at \(d.bb) BB should exist")
        }
    }

}
