import Foundation

/// Preflop street action that hero is facing when the spot begins.
///
/// Raw values match the JSON contract used by the bundled range files:
///   - "RFI"          → hero acts first (no one has opened)
///   - "vs-open-call" → hero is closing the action vs an opener (BB defense)
///   - "vs-3bet"      → hero opened and is now facing a 3-bet
///   - "push/fold"    → short-stack jam-or-fold spot
enum FacingAction: String, Codable, CaseIterable, Identifiable, Hashable {
    case unopened
    case vsOpen
    case vs3Bet
    case blindDefense
    case squeeze
    case pushFold

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .unopened:     return "RFI"
        case .vsOpen:       return "vs Open"
        case .vs3Bet:       return "vs 3-bet"
        case .blindDefense: return "Blind defense"
        case .squeeze:      return "Squeeze"
        case .pushFold:     return "Push/Fold"
        }
    }

    /// Short, sentence-style label used as a headline above the cards.
    var headline: String {
        switch self {
        case .unopened:     return "First in"
        case .vsOpen:       return "Facing an open"
        case .vs3Bet:       return "Facing a 3-bet"
        case .blindDefense: return "Defending the blinds"
        case .squeeze:      return "Squeeze spot"
        case .pushFold:     return "Push or fold"
        }
    }

    var systemImage: String {
        switch self {
        case .unopened:     return "play.fill"
        case .vsOpen:       return "person.fill"
        case .vs3Bet:       return "arrow.up.right.circle.fill"
        case .blindDefense: return "shield.fill"
        case .squeeze:      return "rectangle.compress.vertical"
        case .pushFold:     return "flame.fill"
        }
    }

    /// Accept legacy raw-value spellings ("RFI", "vs-open-call", "vs-3bet",
    /// "push/fold") in addition to the canonical camelCase ones.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case "unopened", "RFI", "rfi":                self = .unopened
        case "vsOpen", "vs-open", "vs-open-call":     self = .vsOpen
        case "vs3Bet", "vs-3bet":                     self = .vs3Bet
        case "blindDefense", "blind-defense":         self = .blindDefense
        case "squeeze":                               self = .squeeze
        case "pushFold", "push/fold", "push-fold":    self = .pushFold
        default:
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Unknown FacingAction raw value: \(raw)"
            )
        }
    }
}

struct TrainingSpot: Hashable, Codable, Identifiable {
    var id: String { "\(position.rawValue)_\(stackDepthBB)_\(facingAction.rawValue)" }
    let position: TablePosition
    let stackDepthBB: Int
    let facingAction: FacingAction
    let anteType: AnteType
    let tableSize: Int

    var summary: String {
        "\(position.displayName) · \(stackDepthBB) BB · \(facingAction.displayName)"
    }
}
