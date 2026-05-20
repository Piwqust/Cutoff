import Foundation

/// Loads bundled charts and exposes queries used across the Ranges drill-down.
@MainActor
@Observable
final class RangesViewModel {
    var charts: [RangeChart] = []
    var didLoad = false

    var selectedPosition: TablePosition?
    var selectedDepthBucket: StackDepthBucket?
    var selectedFacing: FacingAction?

    func load(using service: RangeService) {
        service.ensureLoaded()
        if charts.isEmpty {
            charts = Self.normalize(service.charts)
            if let first = charts.first {
                selectedPosition = first.position
                selectedDepthBucket = StackDepthBucket.nearest(to: first.stackDepth)
                selectedFacing = first.facingAction
            }
        }
    }

    /// Drop semantically-impossible placeholder spots (UTG squeeze, SB
    /// blindDefense, etc.) and dedup by (position, depth, facing) — preferring
    /// the 9-max bundled chart when both 8-max and 9-max files exist for the
    /// same spot.
    private static func normalize(_ source: [RangeChart]) -> [RangeChart] {
        var byKey: [String: RangeChart] = [:]
        for c in source where TrainingSpot.isValid(position: c.position, facing: c.facingAction) {
            let key = "\(c.position.rawValue)_\(c.stackDepth)_\(c.facingAction.rawValue)"
            if let existing = byKey[key] {
                if c.tableSize == 9 && existing.tableSize != 9 { byKey[key] = c }
            } else {
                byKey[key] = c
            }
        }
        return byKey.values.sorted { $0.id < $1.id }
    }

    func charts(forDepth depth: Int) -> [RangeChart] {
        charts.filter { $0.spot.stackDepthBB == depth }
    }

    func charts(forFacing facing: FacingAction) -> [RangeChart] {
        charts.filter { $0.spot.facingAction == facing }
    }

    func charts(for position: TablePosition) -> [RangeChart] {
        charts.filter { $0.position == position }
    }

    func chart(id: String) -> RangeChart? {
        charts.first { $0.id == id }
    }

    private func chartSearchHaystack(_ chart: RangeChart) -> String {
        [
            chart.position.displayName,
            chart.position.rawValue,
            "\(chart.stackDepth)",
            "\(chart.stackDepth)bb",
            chart.facingAction.displayName,
            chart.facingAction.rawValue,
            chart.facingAction.headline
        ].joined(separator: " ").lowercased()
    }

    // MARK: - Search

    /// Free-text search: matches against position names, depth, and facing
    /// keywords. e.g. "btn 100" → all BTN charts at 100 BB; "vs open" → all
    /// vsOpen charts; "squeeze 40" → squeeze at 40 BB.
    func search(_ query: String) -> [RangeChart] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        let tokens = q.split(whereSeparator: { $0.isWhitespace || $0 == "," }).map(String.init)
        return charts.filter { chart in
            let hay = chartSearchHaystack(chart)
            return tokens.allSatisfy { hay.contains($0) }
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
