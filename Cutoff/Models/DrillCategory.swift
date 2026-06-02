import Foundation

/// Practical decision categories tuned for live 9-max MTTs with 15–40 BB stacks.
/// Each category corresponds to a curated slice of bundled range charts.
enum DrillCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case standardRoutine  // full-coverage warmup: any position, any stack, any scenario
    case firstInJam       // open-jamming 12–25 BB
    case reJam            // 3-bet jam vs an opener at 15–30 BB
    case callJam          // calling an all-in (price-based)
    case stealBlinds      // late-position opens at 20–40 BB
    case vsManiac         // facing a 3-bet from a wide aggressor
    case mixed            // pulls from all of the above, weighted to 15–40 BB

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standardRoutine: return "Standard routine"
        case .firstInJam:  return "First-in jam"
        case .reJam:       return "Re-jam over an open"
        case .callJam:     return "Call an all-in"
        case .stealBlinds: return "Steal the blinds"
        case .vsManiac:    return "Play vs a maniac"
        case .mixed:       return "Mixed live drill"
        }
    }

    var subtitle: String {
        switch self {
        case .standardRoutine: return "Random preflop — any position, stack, or scenario."
        case .firstInJam:  return "12–25 BB · find the jam, don't min-raise yourself broke."
        case .reJam:       return "15–30 BB · when someone opens, can you shove?"
        case .callJam:     return "Snap, call, or fold the all-in based on price."
        case .stealBlinds: return "Late position, 20–40 BB · open wider when nobody fights back."
        case .vsManiac:    return "25–40 BB · they 3-bet light — fold less, jam more."
        case .mixed:       return "A live MTT mix biased to 15–40 BB."
        }
    }

    var systemImage: String {
        switch self {
        case .standardRoutine: return "shuffle.circle.fill"
        case .firstInJam:  return "flame.fill"
        case .reJam:       return "arrow.uturn.up"
        case .callJam:     return "hand.raised.fill"
        case .stealBlinds: return "scissors"
        case .vsManiac:    return "bolt.fill"
        case .mixed:       return "shuffle"
        }
    }

    /// BB depths the spot pool will draw from, inclusive.
    var depthRange: ClosedRange<Int> {
        switch self {
        case .standardRoutine: return 10...125
        case .firstInJam:  return 10...25
        case .reJam:       return 15...30
        case .callJam:     return 10...40
        case .stealBlinds: return 20...40
        case .vsManiac:    return 20...50
        case .mixed:       return 12...50
        }
    }

    /// Facing actions that count toward this drill.
    var facingActions: Set<FacingAction> {
        switch self {
        case .standardRoutine: return Set(FacingAction.allCases)
        case .firstInJam:  return [.pushFold, .unopened]
        case .reJam:       return [.vsOpen, .squeeze]
        case .callJam:     return [.pushFold, .vs3Bet, .vs3BetJam]
        case .stealBlinds: return [.unopened]
        case .vsManiac:    return [.vs3Bet, .vs3BetJam, .vsOpen]
        case .mixed:       return Set(FacingAction.allCases)
        }
    }

    /// Positions that count toward this drill.
    var positions: Set<TablePosition> {
        switch self {
        case .standardRoutine: return Set(TablePosition.nineMaxOrder)
        case .firstInJam:  return Set(TablePosition.nineMaxOrder)
        case .reJam:       return Set(TablePosition.nineMaxOrder)
        case .callJam:     return Set(TablePosition.nineMaxOrder)
        case .stealBlinds: return [.co, .btn, .sb]
        case .vsManiac:    return Set(TablePosition.nineMaxOrder)
        case .mixed:       return Set(TablePosition.nineMaxOrder)
        }
    }

    /// What actions the trainer offers as buttons for this drill. Fold is always
    /// allowed — the other slots are tuned to the decision the user is being
    /// asked to make.
    var availableActions: [RangeAction] {
        switch self {
        case .standardRoutine: return [.fold, .call, .raise, .threeBet, .jam]
        case .firstInJam:  return [.fold, .jam]
        case .reJam:       return [.fold, .call, .jam]
        case .callJam:     return [.fold, .call]
        case .stealBlinds: return [.fold, .raise]
        case .vsManiac:    return [.fold, .call, .jam]
        case .mixed:       return [.fold, .call, .raise, .threeBet, .jam]
        }
    }

    /// Most categories ignore villain typing; the maniac drill always uses .maniac.
    var defaultVillain: VillainType {
        switch self {
        case .vsManiac: return .maniac
        default:        return .standard
        }
    }
}
