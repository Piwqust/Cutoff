import Foundation

/// The static catalog of (position × stackDepth × facingAction) combinations
/// the Ranges tab considers *valid*. Combinations outside this set are not
/// rendered in the UI — they don't make poker sense (e.g. UTG can't face an
/// open in 9-max; pushFold is only meaningful for short stacks).
///
/// This is the single source of truth for "does this button have a real
/// table?". The loader is expected to find a chart for every entry here; any
/// gap is a build-time bug, surfaced by `RangeLoaderTests`.
enum SpotMatrix {
    /// All valid spots, in stable iteration order (position × depth × facing).
    static let all: [TrainingSpot] = {
        var spots: [TrainingSpot] = []
        for pos in TablePosition.nineMaxOrder {
            for depth in StackDepthBucket.allCases.map(\.bb) {
                for facing in FacingAction.allCases where isValid(position: pos, depth: depth, facing: facing) {
                    let opps = validOpponents(for: pos, facing: facing)
                    if opps.isEmpty {
                        spots.append(TrainingSpot(
                            position: pos,
                            stackDepthBB: depth,
                            facingAction: facing,
                            opponentPosition: nil,
                            anteType: .bigBlindAnte,
                            tableSize: 9
                        ))
                    } else {
                        for opp in opps {
                            spots.append(TrainingSpot(
                                position: pos,
                                stackDepthBB: depth,
                                facingAction: facing,
                                opponentPosition: opp,
                                anteType: .bigBlindAnte,
                                tableSize: 9
                            ))
                        }
                    }
                }
            }
        }
        return spots
    }()

    /// Returns true if a 9-max preflop spot of this shape makes poker sense.
    static func isValid(position: TablePosition, depth: Int, facing: FacingAction) -> Bool {
        switch facing {
        case .unopened:
            // Every seat that acts before the BB can be "first in." BB never is.
            return position != .bb

        case .vsOpen:
            // Need at least one position earlier than us that could have opened.
            // UTG is first to act, so can't face an open.
            return position != .utg

        case .vs3Bet:
            // We opened and got 3-bet. Anyone who can open can get 3-bet — except
            // BB (no one acts after BB to 3-bet preflop).
            return position != .bb

        case .vs3BetJam:
            // Same validity surface as .vs3Bet — only the size differs.
            return position != .bb

        case .squeeze:
            // Squeeze = open + caller, action on us. Requires two seats before
            // us to act. Earliest position that can squeeze is LJ.
            return [.lj, .hj, .co, .btn, .sb, .bb].contains(position)

        case .blindDefense:
            // Only SB and BB defend.
            return position == .sb || position == .bb

        case .pushFold:
            // Short-stack jam/fold makes sense at ≤25 BB only.
            return depth <= 25
        }
    }

    static func validOpponents(for position: TablePosition, facing: FacingAction) -> [TablePosition] {
        let order = TablePosition.nineMaxOrder
        guard let heroIdx = order.firstIndex(of: position) else { return [] }
        
        switch facing {
        case .vsOpen, .blindDefense:
            return Array(order.prefix(heroIdx))
        case .vs3Bet, .vs3BetJam:
            if heroIdx + 1 < order.count {
                return Array(order.suffix(from: heroIdx + 1))
            }
            return []
        default:
            return []
        }
    }

    /// Convenience set of all (position, depth, facing) triples for lookup.
    static let validTriples: Set<Triple> = Set(all.map { Triple(position: $0.position, depth: $0.stackDepthBB, facing: $0.facingAction, opponent: $0.opponentPosition) })

    struct Triple: Hashable {
        let position: TablePosition
        let depth: Int
        let facing: FacingAction
        let opponent: TablePosition?
    }

    static func isValid(_ position: TablePosition, _ depth: Int, _ facing: FacingAction, _ opponent: TablePosition? = nil) -> Bool {
        validTriples.contains(Triple(position: position, depth: depth, facing: facing, opponent: opponent))
    }
}
