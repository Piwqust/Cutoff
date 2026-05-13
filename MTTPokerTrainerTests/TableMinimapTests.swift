import XCTest
import CoreGraphics
@testable import MTTPokerTrainer

@MainActor
final class TableMinimapTests: XCTestCase {
    func test_seatAngle_startsAtTopAndStepsClockwise() {
        let total = 8
        // Index 0 = top (-π/2)
        XCTAssertEqual(TableMinimapView.seatAngle(forIndex: 0, total: total), -.pi / 2, accuracy: 0.0001)
        // Index 2 = quarter clockwise from top = 0 (right side)
        XCTAssertEqual(TableMinimapView.seatAngle(forIndex: 2, total: total), 0, accuracy: 0.0001)
        // Index 4 = bottom (π/2)
        XCTAssertEqual(TableMinimapView.seatAngle(forIndex: 4, total: total), .pi / 2, accuracy: 0.0001)
    }

    func test_pointAtAngle_putsSeat0AtTopOfOval() {
        let center = CGPoint(x: 100, y: 60)
        let p = TableMinimapView.point(at: TableMinimapView.seatAngle(forIndex: 0, total: 8), center: center, radiusX: 80, radiusY: 40)
        XCTAssertEqual(p.x, 100, accuracy: 0.5)
        XCTAssertEqual(p.y, 20, accuracy: 0.5)
    }

    func test_preflopViewModelDerivesActedPositions_forRFI_isEmpty() {
        // Synthesise a chart via the JSON decoder for type safety
        let chart = makeChart(facing: .rfi, position: .utg)
        let vm = makePreflopVM(with: [chart])
        vm.load()
        XCTAssertEqual(vm.actedPositions, [], "RFI should have no acted positions upstream")
    }

    func test_preflopViewModelDerivesActedPositions_forVsOpenCall_marksUpstream() {
        let chart = makeChart(facing: .vsOpenCall, position: .bb)
        let vm = makePreflopVM(with: [chart])
        vm.load()
        XCTAssertFalse(vm.actedPositions.isEmpty, "vs-open-call should highlight at least one upstream opener")
        XCTAssertFalse(vm.actedPositions.contains(.bb), "Hero seat should not be in acted positions")
    }

    // MARK: helpers

    private func makeChart(facing: FacingAction, position: TablePosition) -> RangeChart {
        let json = """
        {
          "id": "test_\(position.rawValue)_\(facing.rawValue)",
          "stackDepth": 100,
          "position": "\(position.rawValue)",
          "tableSize": 8,
          "antePercent": 12.5,
          "facingAction": "\(facing.rawValue)",
          "isICM": false,
          "source": {"type": "demo", "description": "Approximate demo training range. Not solver-verified."},
          "hands": {"AA": {"fold": 0.0, "call": 0.0, "minRaise": 0.0, "raise25x": 1.0, "raise3x": 0.0, "shove": 0.0, "limp": 0.0, "limpRaise": 0.0}}
        }
        """.data(using: .utf8)!
        return try! JSONDecoder().decode(RangeChart.self, from: json)
    }

    private func makePreflopVM(with charts: [RangeChart]) -> PreflopTrainerViewModel {
        let vm = PreflopTrainerViewModel()
        // Inject via reflection isn't pretty — but the VM only reads `charts`
        // via `load()` so we instead write a tiny seam: rely on currentChart
        // being set via `next()` after manual injection. Easiest: drive via
        // KVC-style mirror — but the VM uses @Observable without setters.
        // Workaround: encode charts as JSON files in a temp bundle. Too heavy.
        // Practical approach: just set charts via a dedicated test seam below.
        vm.injectChartsForTesting(charts)
        return vm
    }
}
