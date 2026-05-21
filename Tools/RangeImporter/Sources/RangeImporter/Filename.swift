import Foundation

/// Filename convention for crib sheets and emitted JSON ranges:
///
/// `mtt_{tableSize}max_{depth}bb_{position}_{facing}`
///
/// Examples:
///   mtt_8max_100bb_co_unopened.csv  →  mtt_8max_100bb_co_unopened.json
///   mtt_9max_25bb_btn_pushfold.csv  →  mtt_9max_25bb_btn_pushfold.json
struct ChartSlug {
    let tableSize: Int
    let depthBB: Int
    let position: Position
    let facing: Facing

    enum Position: String, CaseIterable {
        case utg, utg1, lj, hj, co, btn, sb, bb

        /// JSON `TablePosition` rawValue.
        var jsonValue: String {
            switch self {
            case .utg:  return "UTG"
            case .utg1: return "UTG1"
            case .lj:   return "LJ"
            case .hj:   return "HJ"
            case .co:   return "CO"
            case .btn:  return "BTN"
            case .sb:   return "SB"
            case .bb:   return "BB"
            }
        }
    }

    enum Facing: String, CaseIterable {
        case unopened, vsopen, vs3bet, squeeze, blinddefense, pushfold

        /// JSON `FacingAction` rawValue. Matches the enum in
        /// Cutoff/Models/PokerTableSnapshot.swift via TablePosition / FacingAction.
        var jsonValue: String {
            switch self {
            case .unopened:     return "unopened"
            case .vsopen:       return "vsOpen"
            case .vs3bet:       return "vs3Bet"
            case .squeeze:      return "squeeze"
            case .blinddefense: return "blindDefense"
            case .pushfold:     return "pushFold"
            }
        }
    }

    var id: String {
        "mtt_\(tableSize)max_\(depthBB)bb_\(position.rawValue)_\(facing.rawValue)"
    }

    var format: String { "NLHE_MTT_\(tableSize)MAX" }

    /// Parse a filename (without extension) into a slug. Returns nil if the
    /// pattern doesn't match.
    static func parse(_ stem: String) -> ChartSlug? {
        // Expect: mtt_<size>max_<depth>bb_<position>_<facing>
        let parts = stem.split(separator: "_").map(String.init)
        guard parts.count == 5, parts[0] == "mtt" else { return nil }
        guard parts[1].hasSuffix("max"), let size = Int(parts[1].dropLast(3)) else { return nil }
        guard parts[2].hasSuffix("bb"), let depth = Int(parts[2].dropLast(2)) else { return nil }
        guard let position = Position(rawValue: parts[3]) else { return nil }
        guard let facing = Facing(rawValue: parts[4]) else { return nil }
        return ChartSlug(tableSize: size, depthBB: depth, position: position, facing: facing)
    }
}
