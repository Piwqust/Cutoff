import Foundation

/// Monte Carlo equity calculator. Pure Swift, no third-party dependency.
/// Designed for educational display ("you have ~62% vs a 30% range"), not
/// for solver-grade precision. Default 2 000 iterations gives ±~1% accuracy.
enum EquityCalculator {

    /// Equity of a specific hand vs a *range* of possible opponent hands,
    /// on a (possibly partial) board. Returns hero's win+tie/2 fraction.
    ///
    /// - Parameters:
    ///   - heroHand: hero's hole cards (exactly 2).
    ///   - villainCombos: villain's possible hole-card pairs (each pair = 2 cards).
    ///   - board: 0..5 cards already dealt.
    ///   - iterations: Monte Carlo samples.
    static func equity(
        heroHand: [Card],
        villainCombos: [[Card]],
        board: [Card],
        iterations: Int = 2_000
    ) -> Double {
        guard heroHand.count == 2, !villainCombos.isEmpty else { return 0 }
        let knownDead = Set(heroHand.map(\.index52) + board.map(\.index52))

        // Pre-filter villain combos that don't collide with hero/board.
        let validVillain = villainCombos.filter { combo in
            combo.count == 2
                && !knownDead.contains(combo[0].index52)
                && !knownDead.contains(combo[1].index52)
                && combo[0].index52 != combo[1].index52
        }
        guard !validVillain.isEmpty else { return 0 }

        var wins = 0.0
        var rng = SystemRandomNumberGenerator()

        for _ in 0..<iterations {
            let villain = validVillain.randomElement(using: &rng)!
            var dead = knownDead
            dead.insert(villain[0].index52)
            dead.insert(villain[1].index52)

            var runout = board
            var attempts = 0
            while runout.count < 5 && attempts < 100 {
                let idx = Int.random(in: 0..<52, using: &rng)
                if !dead.contains(idx) {
                    dead.insert(idx)
                    runout.append(Card.deck[idx])
                }
                attempts += 1
            }
            guard runout.count == 5 else { continue }

            let heroScore   = HandEvaluator.bestFive(of: heroHand + runout)
            let villainScore = HandEvaluator.bestFive(of: villain + runout)
            if heroScore > villainScore      { wins += 1 }
            else if heroScore == villainScore { wins += 0.5 }
        }
        return wins / Double(iterations)
    }
}

// ---------------------------------------------------------------------------
// 7-card poker hand evaluator
// ---------------------------------------------------------------------------

/// Compact integer hand ranking. Higher value = stronger hand.
struct HandRank: Comparable, Hashable {
    let value: UInt64
    static func < (l: HandRank, r: HandRank) -> Bool { l.value < r.value }
}

enum HandEvaluator {
    /// Best 5-card rank out of 5..7 cards.
    static func bestFive(of cards: [Card]) -> HandRank {
        if cards.count == 5 { return rank5(cards) }
        var best = HandRank(value: 0)
        let indices = combinationsOfFive(from: cards.count)
        for combo in indices {
            let five = combo.map { cards[$0] }
            let r = rank5(five)
            if r > best { best = r }
        }
        return best
    }

    // MARK: - Internal

    /// All C(n, 5) index combinations for n in 5..<8. Pre-computed lookup.
    private static let combos5_6: [[Int]] = makeCombinations(6, 5)
    private static let combos5_7: [[Int]] = makeCombinations(7, 5)
    private static let combos5_5: [[Int]] = [[0,1,2,3,4]]

    private static func combinationsOfFive(from n: Int) -> [[Int]] {
        switch n {
        case 5: return combos5_5
        case 6: return combos5_6
        case 7: return combos5_7
        default:
            return makeCombinations(n, 5)
        }
    }

    private static func makeCombinations(_ n: Int, _ k: Int) -> [[Int]] {
        var result: [[Int]] = []
        var current: [Int] = []
        func backtrack(_ start: Int) {
            if current.count == k {
                result.append(current)
                return
            }
            for i in start..<n {
                current.append(i)
                backtrack(i + 1)
                current.removeLast()
            }
        }
        backtrack(0)
        return result
    }

    /// Categorize a 5-card hand and pack it into a single comparable integer.
    ///
    /// Layout (high → low bits): `category(4) | k1(4) | k2(4) | k3(4) | k4(4) | k5(4)`
    /// where category is 0..8 and kickers are rank.sortValue 0..12.
    private static func rank5(_ cards: [Card]) -> HandRank {
        let ranks = cards.map(\.rank.sortValue).sorted(by: >)
        let suits = cards.map(\.suit)
        let isFlush = Set(suits).count == 1
        let isStraight = makeStraight(ranks)
        let counts = countByRank(ranks)            // [(rank, count)] sorted by count desc then rank desc
        let countsOnly = counts.map(\.1)

        // 8: straight flush
        if isFlush, let top = isStraight {
            return pack(category: 8, kickers: [top])
        }
        // 7: quads
        if countsOnly.first == 4 {
            let quad = counts[0].0
            let kicker = counts[1].0
            return pack(category: 7, kickers: [quad, kicker])
        }
        // 6: full house
        if countsOnly[0] == 3 && countsOnly.count > 1 && countsOnly[1] == 2 {
            return pack(category: 6, kickers: [counts[0].0, counts[1].0])
        }
        // 5: flush
        if isFlush {
            return pack(category: 5, kickers: ranks)
        }
        // 4: straight
        if let top = isStraight {
            return pack(category: 4, kickers: [top])
        }
        // 3: trips
        if countsOnly.first == 3 {
            let trip = counts[0].0
            let kickers = counts.dropFirst().map(\.0).prefix(2)
            return pack(category: 3, kickers: [trip] + Array(kickers))
        }
        // 2: two pair
        if countsOnly.prefix(2).allSatisfy({ $0 == 2 }) {
            let highPair = counts[0].0
            let lowPair = counts[1].0
            let kicker = counts[2].0
            return pack(category: 2, kickers: [highPair, lowPair, kicker])
        }
        // 1: pair
        if countsOnly.first == 2 {
            let pair = counts[0].0
            let kickers = counts.dropFirst().map(\.0).prefix(3)
            return pack(category: 1, kickers: [pair] + Array(kickers))
        }
        // 0: high card
        return pack(category: 0, kickers: ranks)
    }

    private static func countByRank(_ ranks: [Int]) -> [(Int, Int)] {
        let grouped = Dictionary(grouping: ranks, by: { $0 })
            .mapValues(\.count)
        return grouped.sorted { l, r in
            if l.value != r.value { return l.value > r.value }
            return l.key > r.key
        }.map { ($0.key, $0.value) }
    }

    /// If `ranks` (sorted desc) is a straight, return the top card's value.
    /// Handles wheel (A-2-3-4-5) by returning 3 (the 5).
    private static func makeStraight(_ ranks: [Int]) -> Int? {
        let unique = Array(Set(ranks)).sorted(by: >)
        guard unique.count >= 5 else { return nil }
        // Standard straight
        for i in 0...(unique.count - 5) {
            if unique[i] - unique[i + 4] == 4 {
                return unique[i]
            }
        }
        // Wheel: A,5,4,3,2
        if Set([12, 3, 2, 1, 0]).isSubset(of: Set(unique)) {
            return 3
        }
        return nil
    }

    private static func pack(category: Int, kickers: [Int]) -> HandRank {
        var v: UInt64 = UInt64(category) << 32
        var shift: UInt64 = 28
        for k in kickers.prefix(5) {
            v |= UInt64(k & 0xF) << shift
            if shift >= 4 { shift -= 4 }
        }
        return HandRank(value: v)
    }
}
