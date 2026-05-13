import Foundation

/// Loads bundled charts and exposes queries used across the Ranges drill-down.
@MainActor
@Observable
final class RangesViewModel {
    var charts: [RangeChart] = []
    var didLoad = false

    private let loader: RangeLoader

    init(loader: RangeLoader = .init()) {
        self.loader = loader
    }

    func load() {
        guard !didLoad else { return }
        charts = (try? loader.loadAll()) ?? []
        didLoad = true
    }

    // MARK: - Lookups

    func chart(for spot: SpotMatrix.Triple) -> RangeChart? {
        charts.first { c in
            c.spot.position == spot.position
                && c.spot.stackDepthBB == spot.depth
                && c.spot.facingAction == spot.facing
        }
    }

    func chart(id: String) -> RangeChart? {
        charts.first { $0.id == id }
    }

    func charts(for position: TablePosition) -> [RangeChart] {
        charts.filter { $0.spot.position == position }
            .sorted { lhs, rhs in
                if lhs.spot.stackDepthBB != rhs.spot.stackDepthBB {
                    return lhs.spot.stackDepthBB > rhs.spot.stackDepthBB
                }
                return lhs.spot.facingAction.rawValue < rhs.spot.facingAction.rawValue
            }
    }

    func charts(forDepth depth: Int) -> [RangeChart] {
        charts.filter { $0.spot.stackDepthBB == depth }
    }

    func charts(forFacing facing: FacingAction) -> [RangeChart] {
        charts.filter { $0.spot.facingAction == facing }
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

    private func chartSearchHaystack(_ chart: RangeChart) -> String {
        let pos = chart.spot.position.displayName.lowercased()
        let depth = "\(chart.spot.stackDepthBB)bb \(chart.spot.stackDepthBB) bb"
        let facing = chart.spot.facingAction.displayName.lowercased()
        let facingRaw = chart.spot.facingAction.rawValue.lowercased()
        return "\(pos) \(depth) \(facing) \(facingRaw)"
    }
}
