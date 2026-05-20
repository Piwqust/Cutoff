import Foundation

/// Coarse villain archetypes used to color the live spot the user is being shown.
/// This is *flavor* + a small action-weight nudge — not a solver-grade opponent model.
enum VillainType: String, Codable, CaseIterable, Identifiable, Hashable {
    case standard
    case loose      // calls too wide
    case maniac     // 3-bets / jams too wide
    case nit        // folds too much

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: return "Standard reg"
        case .loose:    return "Loose caller"
        case .maniac:   return "Maniac"
        case .nit:      return "Nit"
        }
    }

    var shortNote: String {
        switch self {
        case .standard: return "Plays close to a sensible default."
        case .loose:    return "Calls wide — value-bet bigger, bluff less."
        case .maniac:   return "Opens / 3-bets light — fold less, jam more."
        case .nit:      return "Tight ranges — believe their pressure."
        }
    }

    var systemImage: String {
        switch self {
        case .standard: return "person.fill"
        case .loose:    return "person.fill.questionmark"
        case .maniac:   return "bolt.fill"
        case .nit:      return "lock.fill"
        }
    }
}
