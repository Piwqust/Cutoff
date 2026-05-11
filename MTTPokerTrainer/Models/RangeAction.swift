import SwiftUI

enum RangeAction: String, Codable, CaseIterable, Identifiable, Hashable {
    case fold, call, raise, threeBet, jam, mixed

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
        case .mixed:    return "circle.lefthalf.filled"
        }
    }

    var tint: Color {
        switch self {
        case .fold:     return AppColors.actionFold
        case .call:     return AppColors.actionCall
        case .raise:    return AppColors.actionRaise
        case .threeBet: return AppColors.actionThreeBet
        case .jam:      return AppColors.actionJam
        case .mixed:    return AppColors.accentGreen
        }
    }

    /// Whether the action requires a *dark* foreground for contrast.
    var prefersDarkForeground: Bool {
        switch self {
        case .fold: return false  // dark fill, light text
        default:    return true   // bright fill, dark text
        }
    }
}
