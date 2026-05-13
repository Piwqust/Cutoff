import SwiftUI

/// Postflop action set used by the postflop drill.
///
/// The button row shown to the user is filtered to the actions valid for the
/// spot (e.g. `check` only when hero is the actor and no bet is in front).
enum PostflopAction: String, Codable, CaseIterable, Identifiable, Hashable {
    case check
    case bet33
    case bet67
    case bet100
    case raise
    case fold
    case call
    case shove

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .check:  return "Check"
        case .bet33:  return "Bet 33%"
        case .bet67:  return "Bet 67%"
        case .bet100: return "Bet pot"
        case .raise:  return "Raise"
        case .fold:   return "Fold"
        case .call:   return "Call"
        case .shove:  return "Shove"
        }
    }

    var systemImage: String {
        switch self {
        case .check:  return "hand.raised.fill"
        case .bet33:  return "arrow.up.circle"
        case .bet67:  return "arrow.up.right.circle"
        case .bet100: return "arrow.up.right.circle.fill"
        case .raise:  return "arrow.up.forward.circle.fill"
        case .fold:   return "xmark"
        case .call:   return "equal"
        case .shove:  return "flame.fill"
        }
    }

    var tint: Color {
        switch self {
        case .check:  return AppColors.actionCall
        case .bet33:  return AppColors.actionRaise
        case .bet67:  return AppColors.actionRaise
        case .bet100: return AppColors.actionThreeBet
        case .raise:  return AppColors.actionThreeBet
        case .fold:   return AppColors.actionFold
        case .call:   return AppColors.actionCall
        case .shove:  return AppColors.actionJam
        }
    }

    var prefersDarkForeground: Bool {
        switch self {
        case .fold: return false
        default:    return true
        }
    }

    /// Aggression tier used for "neighbor" scoring (lower = more passive).
    var aggressionTier: Int {
        switch self {
        case .fold:   return 0
        case .check:  return 1
        case .call:   return 2
        case .bet33:  return 3
        case .bet67:  return 4
        case .bet100: return 5
        case .raise:  return 6
        case .shove:  return 7
        }
    }
}
