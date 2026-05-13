import Foundation

/// Preflop scenario that led to a postflop street. Coarse on purpose: the
/// trainer drills strategic concepts, not exhaustive runouts.
enum PreflopScenario: String, CaseIterable, Codable, Identifiable {
    case srpIP   = "srp_ip"      // single-raised pot, hero in position
    case srpOOP  = "srp_oop"     // single-raised pot, hero out of position
    case threeBP_IP  = "3bp_ip"  // 3-bet pot, hero in position
    case threeBP_OOP = "3bp_oop" // 3-bet pot, hero out of position
    case limpedPot   = "limped_pot"
    case fourBP      = "4bp"     // 4-bet pot

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .srpIP:        return "SRP, in position"
        case .srpOOP:       return "SRP, out of position"
        case .threeBP_IP:   return "3-bet pot, in position"
        case .threeBP_OOP:  return "3-bet pot, out of position"
        case .limpedPot:    return "Limped pot"
        case .fourBP:       return "4-bet pot"
        }
    }
}

/// Postflop action a player can take on a given street.
enum PostflopAction: String, CaseIterable, Codable, Hashable {
    case check
    case bet33    // ~1/3 pot
    case bet66    // ~2/3 pot
    case bet100   // pot-sized
    case overbet  // 1.5x pot+
    case call
    case fold
    case raise    // any raise size
    case jam      // all-in

    var displayName: String {
        switch self {
        case .check:    return "Check"
        case .bet33:    return "Bet 33%"
        case .bet66:    return "Bet 66%"
        case .bet100:   return "Bet pot"
        case .overbet:  return "Overbet"
        case .call:     return "Call"
        case .fold:     return "Fold"
        case .raise:    return "Raise"
        case .jam:      return "Jam"
        }
    }

    var systemImage: String {
        switch self {
        case .check:    return "hand.raised"
        case .bet33,
             .bet66,
             .bet100,
             .overbet:  return "arrow.up.right"
        case .call:     return "equal"
        case .fold:     return "xmark"
        case .raise:    return "arrow.up.right.circle.fill"
        case .jam:      return "flame.fill"
        }
    }
}

/// One postflop spot the user can drill. Self-describing so a quiz can
/// render it with no extra lookups.
struct PostflopSpot: Codable, Hashable, Identifiable {
    let id: String
    let scenario: PreflopScenario
    let stackDepthBB: Int
    let textureClass: BoardTextureClass
    /// Example board the spot uses for rendering (one canonical board per
    /// texture class). Not necessarily the only valid board for the class.
    let sampleBoard: String
    /// Action history up to this decision point, as plain English.
    let history: [String]
    /// The decision the hero must make: what actions are available.
    let availableActions: [PostflopAction]
    /// Frequency-weighted "correct" answer mix. Sum = 1.0 (within rounding).
    /// e.g. ["bet33": 0.85, "check": 0.15].
    let solution: [String: Double]
    let coachingNote: String
}

/// A "deck" of postflop training spots — what FlopTrainerLoader returns.
struct PostflopChartPack: Codable {
    let format: String
    let version: String
    let generatedAt: String
    let source: SourcePayload
    let spots: [PostflopSpot]

    struct SourcePayload: Codable {
        let type: String        // "solverDump" / "heuristic"
        let solverName: String?
        let assumptions: String?
        let description: String
    }
}
