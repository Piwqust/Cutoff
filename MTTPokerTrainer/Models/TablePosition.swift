import Foundation

/// Positions for a 9-max table, in early-to-late order.
enum TablePosition: String, CaseIterable, Identifiable, Hashable {
    case utg   = "UTG"
    case utg1  = "UTG1"   // JSON files use "UTG1"; display as "UTG+1"
    case lj    = "LJ"
    case hj    = "HJ"
    case co    = "CO"
    case btn   = "BTN"
    case sb    = "SB"
    case bb    = "BB"

    var id: String { rawValue }

    var displayName: String {
        self == .utg1 ? "UTG+1" : rawValue
    }

    /// Ordered list used by the UI for filter chips.
    static let nineMaxOrder: [TablePosition] = [.utg, .utg1, .lj, .hj, .co, .btn, .sb, .bb]
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
