import Foundation

/// Coarse classification of a flop's strategic character. Used as both a
/// filter axis in the flop library and as the lookup key for bundled flop
/// solver outputs (we don't store a chart per specific board — one per class).
enum BoardTextureClass: String, CaseIterable, Codable, Identifiable {
    case dryHigh           = "dry_high"           // K72r, A82r — dry, ace/king-high
    case dryLow            = "dry_low"            // 832r, 742r — dry, low cards
    case wetConnected      = "wet_connected"      // T98ss, 765r — straight-heavy
    case monotone          = "monotone"           // KsTs5s
    case twoTone           = "two_tone"           // K72 two-tone, common
    case pairedHigh        = "paired_high"        // KK7, AA4
    case pairedLow         = "paired_low"         // 552, 663
    case broadwayHeavy     = "broadway_heavy"     // KQJ, AKT
    case middleMixed       = "middle_mixed"       // T87, J96 mid-range mix

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dryHigh:        return "Dry high"
        case .dryLow:         return "Dry low"
        case .wetConnected:   return "Wet, connected"
        case .monotone:       return "Monotone"
        case .twoTone:        return "Two-tone"
        case .pairedHigh:     return "Paired (high)"
        case .pairedLow:      return "Paired (low)"
        case .broadwayHeavy:  return "Broadway-heavy"
        case .middleMixed:    return "Middle / mixed"
        }
    }

    var summary: String {
        switch self {
        case .dryHigh:        return "An overcard + two low cards, all different suits. Range advantage flops for the preflop raiser."
        case .dryLow:         return "Three low, disconnected, rainbow cards. Caller's range improves more here."
        case .wetConnected:   return "Coordinated, draw-heavy boards. Bet smaller, check more, range matters."
        case .monotone:       return "Three of a suit. Connectors and made flushes shape the strategy."
        case .twoTone:        return "Two suited cards. Draws are live but flush completion needs a third suited card."
        case .pairedHigh:     return "High pair already on board. Most ranges miss; check more, bet small for thin value."
        case .pairedLow:      return "Low pair on board. Overpairs and overcards dominate."
        case .broadwayHeavy:  return "Three broadway cards (T+). Hits the preflop raiser's range hard."
        case .middleMixed:    return "Middle cards with playable connectivity. Most-balanced texture."
        }
    }
}
