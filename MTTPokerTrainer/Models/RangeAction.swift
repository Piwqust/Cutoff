import SwiftUI

/// Preflop action vocabulary used by the frequency-based range schema.
///
/// Replaces the old single-action `RangeAction` enum. Every spot stores a
/// frequency in `[0...1]` for every case so the UI can always render the full
/// 8-button grid (disabled when the frequency is 0).
enum PreflopAction: String, Codable, CaseIterable, Identifiable, Hashable {
    case fold
    case call
    case minRaise   // 2bb open
    case raise25x   // 2.5bb open
    case raise3x    // 3bb open
    case shove      // all-in
    case limp       // SB only — flat the small blind
    case limpRaise  // SB only — limp/3-bet line

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fold:      return "Fold"
        case .call:      return "Call"
        case .minRaise:  return "Min-raise"
        case .raise25x:  return "Raise 2.5x"
        case .raise3x:   return "Raise 3x"
        case .shove:     return "Shove"
        case .limp:      return "Limp"
        case .limpRaise: return "Limp-raise"
        }
    }

    /// Short label used in compact UI / minimap legends.
    var shortLabel: String {
        switch self {
        case .fold:      return "Fold"
        case .call:      return "Call"
        case .minRaise:  return "2bb"
        case .raise25x:  return "2.5x"
        case .raise3x:   return "3x"
        case .shove:     return "Jam"
        case .limp:      return "Limp"
        case .limpRaise: return "L-Rz"
        }
    }

    var systemImage: String {
        switch self {
        case .fold:      return "xmark"
        case .call:      return "equal"
        case .minRaise:  return "arrow.up.right"
        case .raise25x:  return "arrow.up.right.circle"
        case .raise3x:   return "arrow.up.right.circle.fill"
        case .shove:     return "flame.fill"
        case .limp:      return "circle.dashed"
        case .limpRaise: return "arrow.up.forward.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .fold:      return AppColors.actionFold
        case .call:      return AppColors.actionCall
        case .minRaise:  return AppColors.actionRaise
        case .raise25x:  return AppColors.actionRaise
        case .raise3x:   return AppColors.actionThreeBet
        case .shove:     return AppColors.actionJam
        case .limp:      return AppColors.actionCall
        case .limpRaise: return AppColors.actionThreeBet
        }
    }

    /// When true, the action button uses a dark foreground for contrast on a
    /// bright tint. Fold is the only muted/dark tint that prefers light text.
    var prefersDarkForeground: Bool {
        switch self {
        case .fold: return false
        default:    return true
        }
    }

    /// "Aggression tier" — used by the scorer to decide whether a wrong answer
    /// is a neighbor (close) or far away (mistake/punt). Lower = more passive.
    var aggressionTier: Int {
        switch self {
        case .fold:      return 0
        case .call:      return 1
        case .limp:      return 1
        case .minRaise:  return 2
        case .raise25x:  return 3
        case .raise3x:   return 4
        case .limpRaise: return 5
        case .shove:     return 6
        }
    }
}
