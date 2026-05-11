import Foundation

/// Positions for a 9-max table, in early-to-late order.
enum TablePosition: String, Codable, CaseIterable, Identifiable, Hashable {
    case utg   = "UTG"
    case utg1  = "UTG+1"
    case lj    = "LJ"
    case hj    = "HJ"
    case co    = "CO"
    case btn   = "BTN"
    case sb    = "SB"
    case bb    = "BB"

    var id: String { rawValue }
    var displayName: String { rawValue }

    /// Ordered list used by the UI for filter chips.
    static let nineMaxOrder: [TablePosition] = [.utg, .utg1, .lj, .hj, .co, .btn, .sb, .bb]
}
