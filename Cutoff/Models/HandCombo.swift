import Foundation

/// Canonical preflop hand notation:
///   - pairs: "AA", "TT", "22"
///   - suited: "AKs", "T9s"
///   - offsuit: "AKo", "T9o"
struct HandCombo: Hashable, Codable {
    enum Category: String, Codable { case pair, suited, offsuit }

    let highRank: Rank
    let lowRank: Rank
    let category: Category

    enum Rank: String, Codable, CaseIterable, Hashable, Comparable {
        case two = "2", three = "3", four = "4", five = "5",
             six = "6", seven = "7", eight = "8", nine = "9",
             ten = "T", jack = "J", queen = "Q", king = "K", ace = "A"

        var sortValue: Int { Rank.allCases.firstIndex(of: self) ?? 0 }
        static func < (lhs: Rank, rhs: Rank) -> Bool { lhs.sortValue < rhs.sortValue }

        /// All ranks high → low for matrix display (A first).
        static let highToLow: [Rank] = allCases.reversed()
    }

    /// Notation string the user (and the JSON files) write.
    var notation: String {
        switch category {
        case .pair:    return "\(highRank.rawValue)\(highRank.rawValue)"
        case .suited:  return "\(highRank.rawValue)\(lowRank.rawValue)s"
        case .offsuit: return "\(highRank.rawValue)\(lowRank.rawValue)o"
        }
    }

    /// Parse a notation string. Returns `nil` on malformed input.
    static func parse(_ s: String) -> HandCombo? {
        let raw = s.trimmingCharacters(in: .whitespaces)
        guard raw.count == 2 || raw.count == 3 else { return nil }

        let chars = Array(raw)
        guard let r1 = Rank(rawValue: String(chars[0])),
              let r2 = Rank(rawValue: String(chars[1])) else { return nil }

        if raw.count == 2 {
            guard r1 == r2 else { return nil }
            return HandCombo(highRank: r1, lowRank: r2, category: .pair)
        }
        // 3-char form
        let suffix = String(chars[2]).lowercased()
        guard suffix == "s" || suffix == "o" else { return nil }
        guard r1 != r2 else { return nil }
        let (high, low) = r1 > r2 ? (r1, r2) : (r2, r1)
        return HandCombo(highRank: high, lowRank: low, category: suffix == "s" ? .suited : .offsuit)
    }

    /// Canonical 13×13 matrix in row=high rank (A first), col=low rank (A first) order.
    /// Diagonal = pair. Upper triangle (col > row in display terms) = suited. Lower = offsuit.
    /// We use the visual convention: upper-right triangle = suited, lower-left = offsuit.
    static func combo(forRow row: Int, column col: Int) -> HandCombo {
        let r1 = Rank.highToLow[row]
        let r2 = Rank.highToLow[col]
        if r1 == r2 { return HandCombo(highRank: r1, lowRank: r2, category: .pair) }
        let high = r1 > r2 ? r1 : r2
        let low  = r1 > r2 ? r2 : r1
        // upper-right (column index > row index) = suited
        let category: Category = (col > row) ? .suited : .offsuit
        return HandCombo(highRank: high, lowRank: low, category: category)
    }

    /// All 169 canonical combos in row-major matrix order.
    static let allInMatrixOrder: [HandCombo] = {
        var out: [HandCombo] = []
        for r in 0..<13 {
            for c in 0..<13 {
                out.append(combo(forRow: r, column: c))
            }
        }
        return out
    }()
}
