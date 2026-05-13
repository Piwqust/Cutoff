import Foundation

/// Coarse board-texture classes used to bucket postflop training spots.
enum BoardTexture: String, Codable, CaseIterable, Identifiable, Hashable {
    case dryRainbow     // 3 ranks, 3 suits, no straight/flush potential
    case wetMonotone    // single-suited or two-tone with strong straight potential
    case paired         // contains a pair
    case connected      // three connectors or one-gappers
    case broadway       // all cards T+
    case lowScatter     // three low cards, no pair/draws

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dryRainbow:  return "Dry / rainbow"
        case .wetMonotone: return "Wet / monotone"
        case .paired:      return "Paired"
        case .connected:   return "Connected"
        case .broadway:    return "Broadway"
        case .lowScatter:  return "Low scatter"
        }
    }
}
