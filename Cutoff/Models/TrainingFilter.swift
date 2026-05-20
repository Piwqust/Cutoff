import Foundation

/// A value type that narrows which `RangeChart` entries are used for a drill.
/// `nil` for a dimension means "all values accepted".
struct TrainingFilter: Hashable {
    var positions: Set<TablePosition>?
    var depthBuckets: Set<StackDepthBucket>?
    var facingActions: Set<FacingAction>?

    /// No constraints — every loaded chart qualifies.
    static let all = TrainingFilter()

    var isEmpty: Bool {
        positions == nil && depthBuckets == nil && facingActions == nil
    }

    func matches(_ chart: RangeChart) -> Bool {
        if let positions, !positions.contains(chart.spot.position) { return false }
        if let facingActions, !facingActions.contains(chart.spot.facingAction) { return false }
        if let depthBuckets {
            let bucket = StackDepthBucket.nearest(to: chart.spot.stackDepthBB)
            if !depthBuckets.contains(bucket) { return false }
        }
        return true
    }

    /// Short human-readable description of active constraints, or nil if unconstrained.
    var summary: String? { localizedSummary(in: .english) }

    /// Language-aware summary. Position and depth labels are universal poker
    /// tokens (UTG, 100 BB) — only the facing-action chunk needs translation.
    func localizedSummary(in lang: AppLanguage) -> String? {
        var parts: [String] = []
        if let positions {
            let names = TablePosition.nineMaxOrder.filter { positions.contains($0) }.map(\.displayName)
            parts.append(names.joined(separator: "/"))
        }
        if let depthBuckets {
            let labels = StackDepthBucket.allCases.filter { depthBuckets.contains($0) }.map(\.label)
            parts.append(labels.joined(separator: "/"))
        }
        if let facingActions {
            let names = FacingAction.allCases.filter { facingActions.contains($0) }.map { $0.displayName(in: lang) }
            parts.append(names.joined(separator: "/"))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
