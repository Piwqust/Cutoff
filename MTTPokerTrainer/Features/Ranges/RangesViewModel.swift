import Foundation

@MainActor
@Observable
final class RangesViewModel {
    var charts: [RangeChart] = []
    var selectedPosition: TablePosition? = nil
    var selectedDepthBucket: StackDepthBucket? = nil
    var selectedFacing: FacingAction? = nil

    private let loader: RangeLoader

    init(loader: RangeLoader = .init()) {
        self.loader = loader
    }

    func load() {
        if charts.isEmpty {
            charts = (try? loader.loadAll()) ?? []
            if let first = charts.first {
                selectedPosition = first.position
                selectedDepthBucket = StackDepthBucket.nearest(to: first.stackDepth)
                selectedFacing = first.facingAction
            }
        }
    }

    // MARK: - Filter selection
    //
    // Selecting a filter pivots to the chart that best matches it. The other
    // two filters auto-adjust to that chart so the grid always changes when
    // the user taps a chip — even if no chart matches all three filters.

    func selectPosition(_ pos: TablePosition) {
        selectedPosition = pos
        syncOtherFiltersTo(activeChart)
    }

    func selectFacing(_ facing: FacingAction) {
        selectedFacing = facing
        syncOtherFiltersTo(activeChart)
    }

    func selectDepth(_ bucket: StackDepthBucket) {
        selectedDepthBucket = bucket
        syncOtherFiltersTo(activeChart)
    }

    private func syncOtherFiltersTo(_ chart: RangeChart?) {
        guard let chart else { return }
        selectedPosition = chart.position
        selectedDepthBucket = StackDepthBucket.nearest(to: chart.stackDepth)
        selectedFacing = chart.facingAction
    }

    /// Best-match chart for the current filters. Prefers an exact triple
    /// match, then falls back by relaxing constraints in priority order:
    /// position > facing > depth.
    var activeChart: RangeChart? {
        guard !charts.isEmpty else { return nil }
        let pos = selectedPosition
        let facing = selectedFacing
        let depthBB = selectedDepthBucket?.bb

        let scored = charts.map { chart -> (chart: RangeChart, score: Int, depthDelta: Int) in
            var score = 0
            if let pos, chart.position == pos { score += 4 }
            if let facing, chart.facingAction == facing { score += 2 }
            let delta = depthBB.map { abs(chart.stackDepth - $0) } ?? .max
            if let depthBB, chart.stackDepth == depthBB { score += 1 }
            return (chart, score, delta)
        }
        return scored.max {
            if $0.score != $1.score { return $0.score < $1.score }
            return $0.depthDelta > $1.depthDelta
        }?.chart
    }
}
