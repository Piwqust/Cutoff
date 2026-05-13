import Foundation

@MainActor
@Observable
final class RangesViewModel {
    var charts: [RangeChart] = []
    private(set) var catalog = ChartCatalog(charts: [])

    var selectedPosition: TablePosition = .btn
    var selectedDepthBucket: StackDepthBucket = .bb100
    var selectedFacing: FacingAction = .unopened

    private let loader: RangeLoader

    init(loader: RangeLoader = .init()) {
        self.loader = loader
    }

    func load() {
        if charts.isEmpty {
            charts = (try? loader.loadAll()) ?? []
            catalog = ChartCatalog(charts: charts)
            // Seed from the first chart so we land on a valid combination.
            if let first = charts.first {
                selectedPosition = first.spot.position
                selectedDepthBucket = StackDepthBucket.nearest(to: first.spot.stackDepthBB)
                selectedFacing = first.spot.facingAction
            }
        }
    }

    // MARK: - Selection

    /// Selecting a chip only commits if a chart exists for the resulting
    /// triple. The view layer asks `isPositionEnabled(_:)` etc. before
    /// offering a tap, so this is mainly a defense in depth.

    func selectPosition(_ pos: TablePosition) {
        guard catalog.isPositionAvailable(pos, depthBB: selectedDepthBucket.bb, facing: selectedFacing) else { return }
        selectedPosition = pos
    }

    func selectFacing(_ facing: FacingAction) {
        guard catalog.isFacingAvailable(facing, position: selectedPosition, depthBB: selectedDepthBucket.bb) else { return }
        selectedFacing = facing
    }

    func selectDepth(_ bucket: StackDepthBucket) {
        guard catalog.isDepthAvailable(bucket.bb, position: selectedPosition, facing: selectedFacing) else { return }
        selectedDepthBucket = bucket
    }

    // MARK: - Chip enablement (driven by the catalog)

    func isPositionEnabled(_ pos: TablePosition) -> Bool {
        catalog.isPositionAvailable(pos, depthBB: selectedDepthBucket.bb, facing: selectedFacing)
    }

    func isDepthEnabled(_ bucket: StackDepthBucket) -> Bool {
        catalog.isDepthAvailable(bucket.bb, position: selectedPosition, facing: selectedFacing)
    }

    func isFacingEnabled(_ facing: FacingAction) -> Bool {
        catalog.isFacingAvailable(facing, position: selectedPosition, depthBB: selectedDepthBucket.bb)
    }

    /// Exact chart for the current triple, if one exists.
    var activeChart: RangeChart? {
        charts.first {
            $0.spot.position == selectedPosition
                && $0.spot.stackDepthBB == selectedDepthBucket.bb
                && $0.spot.facingAction == selectedFacing
        }
    }
}
