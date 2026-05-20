import SwiftUI

/// Coarse action vocabulary used by the legacy drill/UI surfaces (DrillEngine,
/// FeedbackSheet, ReviewView, action chips). Distinct from the fine-grained
/// `PreflopAction` (which knows about sizings like 2.5x vs 3x); this enum
/// groups everything raise-like into one bucket the user-facing copy uses.
enum RangeAction: String, Codable, CaseIterable, Identifiable, Hashable {
    case fold
    case call
    case raise
    case threeBet
    case jam
    case mixed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fold:     return "Fold"
        case .call:     return "Call"
        case .raise:    return "Raise"
        case .threeBet: return "3-bet"
        case .jam:      return "Jam"
        case .mixed:    return "Mixed"
        }
    }

    var systemImage: String {
        switch self {
        case .fold:     return "xmark"
        case .call:     return "equal"
        case .raise:    return "arrow.up.right"
        case .threeBet: return "arrow.up.right.circle.fill"
        case .jam:      return "flame.fill"
        case .mixed:    return "shuffle"
        }
    }

    var tint: Color {
        switch self {
        case .fold:     return AppColors.actionFold
        case .call:     return AppColors.actionCall
        case .raise:    return AppColors.actionRaise
        case .threeBet: return AppColors.actionThreeBet
        case .jam:      return AppColors.actionJam
        case .mixed:    return AppColors.actionCall
        }
    }

    var prefersDarkForeground: Bool {
        switch self {
        case .fold: return false
        default:    return true
        }
    }

    var aggressionTier: Int {
        switch self {
        case .fold:     return 0
        case .call:     return 1
        case .raise:    return 2
        case .threeBet: return 3
        case .jam:      return 4
        case .mixed:    return 2
        }
    }

    /// Derive the coarse action bucket from a fine-grained preflop action.
    init(_ preflop: PreflopAction) {
        switch preflop {
        case .fold:                       self = .fold
        case .call, .limp:                self = .call
        case .minRaise, .raise25x:        self = .raise
        case .raise3x, .limpRaise:        self = .threeBet
        case .shove:                      self = .jam
        }
    }
}
