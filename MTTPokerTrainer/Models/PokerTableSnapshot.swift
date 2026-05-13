import Foundation

/// One seat on a rendered poker table diagram.
struct PokerTableSeat: Hashable, Identifiable {
    var id: TablePosition { position }
    let position: TablePosition
    let stackBB: Double
    let isHero: Bool
    let hasButton: Bool
    let isFolded: Bool
    /// Blind posted from this seat's stack. nil if not SB/BB.
    let postedBlindBB: Double?
}

/// Pure-data snapshot describing a single training spot as a renderable table.
/// Built from a `TrainingSpot` so the view stays dumb.
struct PokerTableSnapshot: Hashable {
    let seats: [PokerTableSeat]
    let potBB: Double
    let heroPosition: TablePosition
}

extension PokerTableSnapshot {
    /// Build the snapshot from a `TrainingSpot`. All non-hero stacks are
    /// assumed equal to hero (a fair approximation for the start of a level).
    /// The pot includes posted blinds, antes, and any chips put in by the
    /// "action ahead" implied by `facingAction`.
    static func from(spot: TrainingSpot) -> PokerTableSnapshot {
        let positions = TablePosition.nineMaxOrder
        let stack = Double(spot.stackDepthBB)

        let seats: [PokerTableSeat] = positions.map { pos in
            let postedBlind: Double? = {
                switch pos {
                case .sb: return 0.5
                case .bb: return 1.0
                default:  return nil
                }
            }()
            return PokerTableSeat(
                position: pos,
                stackBB: stack - (postedBlind ?? 0),
                isHero: pos == spot.position,
                hasButton: pos == .btn,
                isFolded: foldedBeforeHero(position: pos, spot: spot),
                postedBlindBB: postedBlind
            )
        }

        return PokerTableSnapshot(
            seats: seats,
            potBB: potForSpot(spot: spot),
            heroPosition: spot.position
        )
    }

    /// Heuristic: for a "facing an open" spot, mark the seats earlier than
    /// hero — except the assumed opener — as folded; the opener stays in.
    /// Keeps the table visually honest without overclaiming a specific story.
    private static func foldedBeforeHero(position: TablePosition, spot: TrainingSpot) -> Bool {
        guard let heroIdx = TablePosition.nineMaxOrder.firstIndex(of: spot.position),
              let posIdx  = TablePosition.nineMaxOrder.firstIndex(of: position) else {
            return false
        }
        // Hero never folded. Anything after hero is yet to act.
        if posIdx >= heroIdx { return false }
        // For unopened first-in spots, no one has acted before hero.
        if spot.facingAction == .unopened || spot.facingAction == .pushFold {
            return false
        }
        return true
    }

    private static func potForSpot(spot: TrainingSpot) -> Double {
        let blinds = 1.5 // SB + BB
        let antes: Double = {
            switch spot.anteType {
            case .none, .unknown: return 0
            case .bigBlindAnte:   return 1.0
            case .classic:        return Double(spot.tableSize) * 0.125
            }
        }()
        let actionAhead: Double = {
            switch spot.facingAction {
            case .unopened, .pushFold:    return 0
            case .vsOpen, .blindDefense:  return 2.5     // single open
            case .squeeze:                return 2.5 + 2.5 // open + caller
            case .vs3Bet:                 return 2.5 + 8.0 // open + 3-bet
            }
        }()
        return blinds + antes + actionAhead
    }
}
