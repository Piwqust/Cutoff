import Foundation

/// Positions for a 9-max table, in early-to-late order.
enum TablePosition: String, CaseIterable, Identifiable, Hashable {
    case utg   = "UTG"
    case utg1  = "UTG+1"  // canonical raw; legacy "UTG1" accepted in decoder
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

    /// Seats present at a table of the given size, ordered early-to-late.
    /// 6-max drops UTG+1 and LJ; 8/9-max use the canonical 8-seat order.
    static func ordered(for tableSize: Int) -> [TablePosition] {
        switch tableSize {
        case ...6: return [.utg, .hj, .co, .btn, .sb, .bb]
        default:   return nineMaxOrder
        }
    }
}

extension TablePosition: Codable {
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        // Accept both the canonical "UTG+1" form and the legacy "UTG1" form
        // used in the bundled range JSON files.
        let normalized = (raw == "UTG1") ? "UTG+1" : raw
        guard let value = TablePosition(rawValue: normalized) else {
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Unknown TablePosition '\(raw)'"
            )
        }
        self = value
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(rawValue)
    }
}
