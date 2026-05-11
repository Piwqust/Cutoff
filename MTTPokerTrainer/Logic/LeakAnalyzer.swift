import Foundation

struct Leak: Identifiable, Hashable {
    let id: String          // stable id for the leak category
    let title: String       // plain-English ("Too loose UTG")
    let detail: String      // 1-line explanation
    let severity: Double    // 0...1
    let suggestedSpot: (position: TablePosition, depthBB: Int, facingAction: FacingAction)?

    static func == (lhs: Leak, rhs: Leak) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Pure post-hoc analysis of a flat array of `QuizResult` rows. Computes a
/// handful of named, friendly leaks. Intentionally simple — this is not a
/// solver, it's a study cue.
enum LeakAnalyzer {
    static func leaks(from results: [QuizResult]) -> [Leak] {
        guard results.count >= 8 else { return [] }

        var leaks: [Leak] = []

        // 1) Loose UTG opens — opening hands from UTG that are folds in chart.
        let utg = results.filter { $0.position == .utg }
        if utg.count >= 5 {
            let looseOpens = utg.filter { $0.userAction == .raise && $0.correctAction == .fold }.count
            let ratio = Double(looseOpens) / Double(utg.count)
            if ratio > 0.18 {
                leaks.append(Leak(
                    id: "too_loose_utg",
                    title: "Too loose UTG",
                    detail: "You're opening hands from early position that play badly out of position at 9-max.",
                    severity: min(1, ratio * 2),
                    suggestedSpot: (.utg, 100, .unopened)
                ))
            }
        }

        // 2) Overfolding BB — folding hands from BB that the chart wants to defend.
        let bbDefense = results.filter { $0.position == .bb && $0.facingAction == .vsOpen }
        if bbDefense.count >= 5 {
            let overFolds = bbDefense.filter { $0.userAction == .fold && $0.correctAction != .fold }.count
            let ratio = Double(overFolds) / Double(bbDefense.count)
            if ratio > 0.25 {
                leaks.append(Leak(
                    id: "overfolding_bb",
                    title: "Overfolding the Big Blind",
                    detail: "You're folding to opens too often. The blinds are already in — defend wider.",
                    severity: min(1, ratio * 1.6),
                    suggestedSpot: (.bb, 50, .blindDefense)
                ))
            }
        }

        // 3) Calling too much vs 3-bet — calling when chart wants fold or 4-bet.
        let vs3 = results.filter { $0.facingAction == .vs3Bet }
        if vs3.count >= 4 {
            let badCalls = vs3.filter { $0.userAction == .call && $0.correctAction == .fold }.count
            let ratio = Double(badCalls) / Double(vs3.count)
            if ratio > 0.3 {
                leaks.append(Leak(
                    id: "loose_call_vs3",
                    title: "Calling too much vs 3-bet",
                    detail: "Flatting 3-bets out of position with marginal hands loses chips.",
                    severity: min(1, ratio * 1.4),
                    suggestedSpot: (.btn, 50, .vs3Bet)
                ))
            }
        }

        // 4) Missing reshove spots — folding when chart wants jam at short stack.
        let shortJamSpots = results.filter { $0.stackDepthBB <= 20 && $0.correctAction == .jam }
        if shortJamSpots.count >= 4 {
            let missed = shortJamSpots.filter { $0.userAction == .fold }.count
            let ratio = Double(missed) / Double(shortJamSpots.count)
            if ratio > 0.3 {
                leaks.append(Leak(
                    id: "missed_reshoves",
                    title: "Missing reshove spots",
                    detail: "You're folding short-stack hands that have enough fold equity to jam.",
                    severity: min(1, ratio * 1.3),
                    suggestedSpot: (.co, 15, .pushFold)
                ))
            }
        }

        return leaks.sorted { $0.severity > $1.severity }
    }
}
