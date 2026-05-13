import Foundation

/// Preflop street action that hero is facing when the spot begins.
///
/// Raw values match the JSON contract used by the bundled range files:
///   - "RFI"          → hero acts first (no one has opened)
///   - "vs-open-call" → hero is closing the action vs an opener (BB defense)
///   - "vs-3bet"      → hero opened and is now facing a 3-bet
///   - "push/fold"    → short-stack jam-or-fold spot
enum FacingAction: String, Codable, CaseIterable, Identifiable, Hashable {
    case rfi          = "RFI"
    case vsOpenCall   = "vs-open-call"
    case vs3Bet       = "vs-3bet"
    case pushFold     = "push/fold"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rfi:         return "RFI"
        case .vsOpenCall:  return "vs Open"
        case .vs3Bet:      return "vs 3-bet"
        case .pushFold:    return "Push/Fold"
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
