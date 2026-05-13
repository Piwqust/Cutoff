import Foundation

enum Suit: String, CaseIterable, Codable, Hashable {
    case clubs = "c", diamonds = "d", hearts = "h", spades = "s"

    var symbol: String {
        switch self {
        case .clubs:    return "♣"
        case .diamonds: return "♦"
        case .hearts:   return "♥"
        case .spades:   return "♠"
        }
    }

    var isRed: Bool { self == .hearts || self == .diamonds }
}

struct Card: Hashable, Codable {
    let rank: HandCombo.Rank
    let suit: Suit

    init(rank: HandCombo.Rank, suit: Suit) {
        self.rank = rank
        self.suit = suit
    }

    /// Parse compact notation, e.g. "Ks" → King of spades, "Th" → Ten of hearts.
    init?(_ notation: String) {
        guard notation.count == 2 else { return nil }
        let chars = Array(notation)
        guard let r = HandCombo.Rank(rawValue: String(chars[0])),
              let s = Suit(rawValue: String(chars[1]).lowercased()) else { return nil }
        self.rank = r
        self.suit = s
    }

    var notation: String { "\(rank.rawValue)\(suit.rawValue)" }
    var display: String { "\(rank.rawValue)\(suit.symbol)" }

    /// 52-card index 0..51, useful for fast bitmap math.
    var index52: Int { rank.sortValue * 4 + Suit.allCases.firstIndex(of: suit)! }

    static let deck: [Card] = HandCombo.Rank.allCases.flatMap { r in
        Suit.allCases.map { Card(rank: r, suit: $0) }
    }
}
