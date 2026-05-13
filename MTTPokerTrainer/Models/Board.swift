import Foundation

/// A flop / turn / river board (3-5 cards).
struct Board: Hashable, Codable {
    let cards: [Card]

    init(cards: [Card]) {
        self.cards = cards
    }

    /// Parse compact notation: "Ks7d2c" or "Ks 7d 2c".
    init?(_ notation: String) {
        let cleaned = notation.replacingOccurrences(of: " ", with: "")
        var cards: [Card] = []
        var i = cleaned.startIndex
        while i < cleaned.endIndex {
            let next = cleaned.index(i, offsetBy: 2, limitedBy: cleaned.endIndex) ?? cleaned.endIndex
            guard let card = Card(notation: String(cleaned[i..<next])) else { return nil }
            cards.append(card)
            i = next
        }
        guard (3...5).contains(cards.count) else { return nil }
        self.cards = cards
    }

    var notation: String { cards.map(\.notation).joined() }
    var display: String { cards.map(\.notation).joined(separator: " ") }
    var street: Street {
        switch cards.count {
        case 3: return .flop
        case 4: return .turn
        case 5: return .river
        default: return .flop
        }
    }

    enum Street: String, Codable { case flop, turn, river }
}
