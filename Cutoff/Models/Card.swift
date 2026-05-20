import Foundation
import SwiftUI

/// One playing card. Stored as compact strings ("As", "Td", "9h") so JSON
/// authoring stays trivial.
struct Card: Codable, Hashable, Identifiable {
    enum Suit: String, Codable, CaseIterable, Hashable {
        case spades   = "s"
        case hearts   = "h"
        case diamonds = "d"
        case clubs    = "c"

        var sfSymbol: String {
            switch self {
            case .spades:   return "suit.spade.fill"
            case .hearts:   return "suit.heart.fill"
            case .diamonds: return "suit.diamond.fill"
            case .clubs:    return "suit.club.fill"
            }
        }

        var isRed: Bool { self == .hearts || self == .diamonds }
    }

    let rank: HandCombo.Rank
    let suit: Suit

    var id: String { "\(rank.rawValue)\(suit.rawValue)" }
    var notation: String { id }

    init(rank: HandCombo.Rank, suit: Suit) {
        self.rank = rank
        self.suit = suit
    }

    init?(notation: String) {
        guard notation.count == 2 else { return nil }
        let chars = Array(notation)
        guard let r = HandCombo.Rank(rawValue: String(chars[0])),
              let s = Suit(rawValue: String(chars[1]).lowercased()) else { return nil }
        self.rank = r
        self.suit = s
    }

    // MARK: - Codable (encode as a single string)

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        guard let card = Card(notation: raw) else {
            throw DecodingError.dataCorruptedError(in: try decoder.singleValueContainer(),
                                                   debugDescription: "Invalid card notation: \(raw)")
        }
        self = card
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(notation)
    }

    /// Unique [0, 52) index used by Monte Carlo equity sampling for fast
    /// "is this card already dead?" set lookups.
    var index52: Int { rank.sortValue * 4 + Suit.allCases.firstIndex(of: suit)! }

    /// Full 52-card deck, indexed so `deck[card.index52] == card`.
    static let deck: [Card] = {
        var cards: [Card] = []
        cards.reserveCapacity(52)
        for rank in HandCombo.Rank.allCases {
            for suit in Suit.allCases {
                cards.append(Card(rank: rank, suit: suit))
            }
        }
        return cards
    }()
}

/// Two-card hand (hero's hole cards) — distinct from the abstract HandCombo.
struct HoleCards: Codable, Hashable {
    let first: Card
    let second: Card

    init(first: Card, second: Card) {
        self.first = first
        self.second = second
    }

    /// Convenience: notation-style class ("AKs", "TT", "T9o").
    var comboNotation: String {
        if first.rank == second.rank {
            return "\(first.rank.rawValue)\(second.rank.rawValue)"
        }
        let (hi, lo): (HandCombo.Rank, HandCombo.Rank) = first.rank > second.rank ? (first.rank, second.rank) : (second.rank, first.rank)
        let suffix = first.suit == second.suit ? "s" : "o"
        return "\(hi.rawValue)\(lo.rawValue)\(suffix)"
    }

    // MARK: - Codable (encode as a single string like "AsKh")

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        guard raw.count == 4,
              let first = Card(notation: String(raw.prefix(2))),
              let second = Card(notation: String(raw.suffix(2))) else {
            throw DecodingError.dataCorruptedError(in: try decoder.singleValueContainer(),
                                                   debugDescription: "Invalid hole cards: \(raw)")
        }
        self.first = first
        self.second = second
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(first.notation + second.notation)
    }
}
