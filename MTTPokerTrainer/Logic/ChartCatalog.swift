import Foundation

/// Thin index over a loaded `[RangeChart]` for answering "is this filter
/// combination valid?" questions. Driven entirely by the data — no hardcoded
/// poker rules — so adding new bundled charts automatically expands the
/// filter UI without code changes.
struct ChartCatalog {
    private let triples: Set<Triple>
    private let positions: Set<TablePosition>
    private let depths: Set<Int>
    private let facings: Set<FacingAction>

    init(charts: [RangeChart]) {
        var triples: Set<Triple> = []
        var positions: Set<TablePosition> = []
        var depths: Set<Int> = []
        var facings: Set<FacingAction> = []
        for c in charts {
            let s = c.spot
            triples.insert(Triple(s.position, s.stackDepthBB, s.facingAction))
            positions.insert(s.position)
            depths.insert(s.stackDepthBB)
            facings.insert(s.facingAction)
        }
        self.triples = triples
        self.positions = positions
        self.depths = depths
        self.facings = facings
    }

    /// Is the fully-specified spot in the catalog?
    func contains(position: TablePosition, depthBB: Int, facing: FacingAction) -> Bool {
        triples.contains(Triple(position, depthBB, facing))
    }

    /// Is this position selectable, given the other two filters?
    func isPositionAvailable(_ position: TablePosition, depthBB: Int, facing: FacingAction) -> Bool {
        contains(position: position, depthBB: depthBB, facing: facing)
    }

    /// Is this facing selectable, given the other two filters?
    func isFacingAvailable(_ facing: FacingAction, position: TablePosition, depthBB: Int) -> Bool {
        contains(position: position, depthBB: depthBB, facing: facing)
    }

    /// Is this depth selectable, given the other two filters?
    func isDepthAvailable(_ depthBB: Int, position: TablePosition, facing: FacingAction) -> Bool {
        contains(position: position, depthBB: depthBB, facing: facing)
    }

    /// All facings that have at least one chart for the given position (any depth).
    /// Used as a fallback when an impossible combination is selected on launch.
    func anyFacing(for position: TablePosition) -> FacingAction? {
        FacingAction.allCases.first { facing in
            triples.contains { $0.position == position && $0.facing == facing }
        }
    }

    /// All depths that have at least one chart for the given (position, facing).
    func depths(position: TablePosition, facing: FacingAction) -> [Int] {
        triples
            .filter { $0.position == position && $0.facing == facing }
            .map { $0.depth }
            .sorted()
    }

    private struct Triple: Hashable {
        let position: TablePosition
        let depth: Int
        let facing: FacingAction
        init(_ p: TablePosition, _ d: Int, _ f: FacingAction) {
            position = p; depth = d; facing = f
        }
    }
}
