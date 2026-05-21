import Foundation

/// Shared, loaded-once range library. Inject via `.environment(rangeService)` at
/// the app root so every ViewModel draws from the same chart pool instead of
/// loading all 370+ JSON files independently.
@MainActor
@Observable
final class RangeService {
    private(set) var charts: [RangeChart] = []
    private(set) var isLoaded = false

    private let loader: RangeLoader

    init(loader: RangeLoader = .init()) {
        self.loader = loader
    }

    /// Loads all bundled charts exactly once. Safe to call repeatedly.
    func ensureLoaded() {
        guard !isLoaded else { return }
        charts = (try? loader.loadAll()) ?? []
        isLoaded = true
    }

    // MARK: - Queries

    /// All charts that satisfy a filter. Returns the full list when filter is unconstrained.
    func charts(matching filter: TrainingFilter) -> [RangeChart] {
        filter.isEmpty ? charts : charts.filter { filter.matches($0) }
    }

    /// Best chart for a specific spot — exact match or nearest stack depth.
    /// Pass `tableSize` to prefer 8-max or 9-max charts; falls back to any
    /// table size with a logged warning if no exact match exists.
    func bestChart(position: TablePosition, depthBB: Int, facing: FacingAction, tableSize: Int? = nil) -> RangeChart? {
        loader.chart(matching: position, depthBB: depthBB, facing: facing, tableSize: tableSize, in: charts)
    }

    /// Lookup by the stable chart id stored on `QuizResult.rangeChartID`. Used
    /// by the Review tab to reconstruct the frequency distribution for a past
    /// answer without paying for a fuzzy spot match.
    func chart(byID id: String) -> RangeChart? {
        charts.first { $0.id == id }
    }

    // MARK: - Available dimensions (for building filter UIs)

    var availablePositions: [TablePosition] {
        let present = Set(charts.map(\.spot.position))
        return TablePosition.nineMaxOrder.filter { present.contains($0) }
    }

    var availableDepthBuckets: [StackDepthBucket] {
        let present = Set(charts.map { StackDepthBucket.nearest(to: $0.spot.stackDepthBB) })
        return StackDepthBucket.allCases.filter { present.contains($0) }
    }

    var availableFacingActions: [FacingAction] {
        let present = Set(charts.map(\.spot.facingAction))
        return FacingAction.allCases.filter { present.contains($0) }
    }
}
