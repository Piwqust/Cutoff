import Foundation

/// Pure function from a flop to a `BoardTextureClass`. The classifier is
/// deliberately coarse — we want 9 buckets so the postflop chart count stays
/// manageable, not 1755 (the full canonical flop count).
enum BoardClassifier {
    static func classify(_ board: Board) -> BoardTextureClass {
        // Use the first three cards (flop). Turn/river adjustments are
        // beyond v1 scope.
        let cards = Array(board.cards.prefix(3))
        guard cards.count == 3 else { return .middleMixed }

        let ranks = cards.map(\.rank.sortValue).sorted(by: >)
        let suits = cards.map(\.suit)
        let suitCounts = Dictionary(grouping: suits, by: { $0 }).mapValues(\.count)
        let maxSuit = suitCounts.values.max() ?? 1
        let isPaired = ranks[0] == ranks[1] || ranks[1] == ranks[2]
        let isMonotone = maxSuit == 3
        let isTwoTone  = maxSuit == 2
        let highest = ranks[0]
        let middle = ranks[1]
        let lowest = ranks[2]

        // Paired textures
        if isPaired {
            let pairRank = ranks[0] == ranks[1] ? ranks[0] : ranks[1]
            return pairRank >= rankValue(.ten) ? .pairedHigh : .pairedLow
        }

        // Monotone
        if isMonotone { return .monotone }

        // Broadway-heavy: all three ten+
        if lowest >= rankValue(.ten) { return .broadwayHeavy }

        // Wet & connected: span ≤ 4 across all three cards, ignoring suits
        let span = highest - lowest
        let twoConnected = (highest - middle <= 2) && (middle - lowest <= 2)
        if span <= 4 && twoConnected { return .wetConnected }

        // Dry high: one big card (T+), rest dry, rainbow or two-tone but span > 4
        if highest >= rankValue(.ten) && span > 5 && !isTwoTone {
            return .dryHigh
        }
        if highest >= rankValue(.ten) && span > 5 {
            return .dryHigh
        }

        // Dry low: top card ≤ 9, span > 4
        if highest < rankValue(.ten) && span > 4 {
            return .dryLow
        }

        // Two-tone: not yet matched anything else but has flush draw
        if isTwoTone { return .twoTone }

        return .middleMixed
    }

    private static func rankValue(_ r: HandCombo.Rank) -> Int { r.sortValue }
}
