import Foundation

/// Builds the rich, multi-sentence "why" explanation shown in the Review
/// mistake-detail sheet and in the Train flow's expandable "Why?" disclosure.
///
/// Composed of three lines:
///   1. **Verdict** — what the chart wants, with frequencies if mixed.
///   2. **Reason** — keyed on (MistakeReason × HandClass.Family), explains the
///      specific kind of error the user made for this hand class.
///   3. **Context** — depth/position strategic note for the hand class.
///
/// Templates are deterministic and offline; no API calls.
enum MistakeExplainer {

    struct Explanation: Hashable {
        let verdict: String
        let reason: String
        let context: String
        let mistakeReason: MistakeReason

        var paragraphs: [String] {
            [verdict, reason, context].filter { !$0.isEmpty }
        }

        var joined: String {
            paragraphs.joined(separator: " ")
        }
    }

    /// Build an Explanation for a past answer using the bundled chart that was
    /// drilled. If the chart can't be found, returns a generic fallback so the
    /// UI still renders something useful.
    static func explain(
        result: QuizResult,
        chart: RangeChart?
    ) -> Explanation {
        let combo = HandCombo.parse(result.combo)
        let handClass = combo.map(HandClass.of) ?? .offsuitJunk
        let frequencies: [RangeAction: Double]
        if let chart, let combo {
            frequencies = FrequencyCollapser.coarse(chart.frequencies(for: combo))
        } else {
            frequencies = [result.correctAction: 1.0]
        }

        let reason = MistakeReason.classify(userAction: result.userAction, frequencies: frequencies)
        return build(
            combo: result.combo,
            position: result.position,
            depthBB: result.stackDepthBB,
            facing: result.facingAction,
            userAction: result.userAction,
            chartAction: result.correctAction,
            frequencies: frequencies,
            handClass: handClass,
            reason: reason
        )
    }

    /// Live-trainer variant — same logic but takes the in-flight chart and combo
    /// directly so we don't have to round-trip through QuizResult.
    static func explain(
        combo: HandCombo,
        position: TablePosition,
        depthBB: Int,
        facing: FacingAction,
        userAction: RangeAction,
        chart: RangeChart
    ) -> Explanation {
        let frequencies = FrequencyCollapser.coarse(chart.frequencies(for: combo))
        let handClass = HandClass.of(combo)
        let chartAction = chart.action(for: combo)
        let reason = MistakeReason.classify(userAction: userAction, frequencies: frequencies)
        return build(
            combo: combo.notation,
            position: position,
            depthBB: depthBB,
            facing: facing,
            userAction: userAction,
            chartAction: chartAction,
            frequencies: frequencies,
            handClass: handClass,
            reason: reason
        )
    }

    // MARK: - Internal composition

    private static func build(
        combo: String,
        position: TablePosition,
        depthBB: Int,
        facing: FacingAction,
        userAction: RangeAction,
        chartAction: RangeAction,
        frequencies: [RangeAction: Double],
        handClass: HandClass,
        reason: MistakeReason
    ) -> Explanation {
        let verdict = verdictLine(
            combo: combo,
            frequencies: frequencies,
            chartAction: chartAction
        )
        let reasonLine = reasonTemplate(
            reason: reason,
            family: handClass.family,
            handClass: handClass,
            combo: combo,
            position: position,
            depthBB: depthBB,
            facing: facing,
            userAction: userAction,
            chartAction: chartAction
        )
        let contextLine = contextTemplate(
            handClass: handClass,
            position: position,
            depthBB: depthBB,
            facing: facing
        )
        return Explanation(
            verdict: verdict,
            reason: reasonLine,
            context: contextLine,
            mistakeReason: reason
        )
    }

    private static func verdictLine(
        combo: String,
        frequencies: [RangeAction: Double],
        chartAction: RangeAction
    ) -> String {
        let nonZero = frequencies
            .filter { $0.value >= 0.05 && $0.key != .mixed }
            .sorted { $0.value > $1.value }

        if nonZero.count <= 1 {
            return "\(combo) wants \(chartAction.displayName.lowercased())."
        }

        let parts = nonZero.prefix(3).map { (action, freq) in
            "\(action.displayName.lowercased()) \(Int((freq * 100).rounded()))%"
        }
        return "Mixed spot — chart plays \(combo) \(parts.joined(separator: " / "))."
    }

    private static func reasonTemplate(
        reason: MistakeReason,
        family: HandClass.Family,
        handClass: HandClass,
        combo: String,
        position: TablePosition,
        depthBB: Int,
        facing: FacingAction,
        userAction: RangeAction,
        chartAction: RangeAction
    ) -> String {
        let pos = position.displayName
        let bb = depthBB

        switch (reason, family) {

        // MARK: tooTight
        case (.tooTight, .ace):
            return "Suited aces and strong offsuit aces have the equity + blockers to keep going here. Folding \(combo) gives up too much."
        case (.tooTight, .pair):
            if handClass == .smallPair && bb <= 20 {
                return "At \(bb) BB, a small pair has enough showdown + fold equity to take a flop or jam — folding burns chips."
            }
            return "Pairs play themselves vs typical opens. \(combo) is a snap-continue from \(pos) at \(bb) BB."
        case (.tooTight, .broadway):
            return "Broadway hands hold their equity well against opening ranges. \(combo) is too live to fold at \(bb) BB."
        case (.tooTight, .suitedConnector):
            return "Suited connectors realize equity via straights and flushes — folding pre throws that away. Defend or 3-bet."
        case (.tooTight, .suitedOther):
            return "Suited Kx/Qx still flop top pair + a flush draw enough to continue here. Folding \(combo) is too tight."
        case (.tooTight, .junk):
            return "Even the chart says you can continue with \(combo) in this spot — typically a price-driven blind defense."

        // MARK: tooLoose
        case (.tooLoose, .junk):
            return "\(combo) is the kind of offsuit hand that bleeds chips. Folding from \(pos) is the simple, profitable move."
        case (.tooLoose, .ace):
            if handClass == .offsuitAce {
                return "Offsuit aces below AJo are dominated more often than they dominate from \(pos). \(combo) plays better as a fold."
            }
            return "Suited aces still need the right price + position — at \(bb) BB from \(pos), \(combo) doesn't have enough equity to continue."
        case (.tooLoose, .pair):
            return "Set-mining a small pair only pays at deep stacks. At \(bb) BB the implied odds aren't there from \(pos)."
        case (.tooLoose, .broadway):
            return "Even broadway hands lose money out of position vs strong ranges. \(combo) is a fold from \(pos) here."
        case (.tooLoose, .suitedConnector):
            return "Suited connectors need implied odds and good position. From \(pos) at \(bb) BB, \(combo) is just lighting chips on fire."
        case (.tooLoose, .suitedOther):
            return "Marginal suited hands like \(combo) don't flop strong enough often enough from \(pos) — fold and keep your stack."

        // MARK: missedMix
        case (.missedMix, _):
            return "This is a mixed spot — \(combo) gets played multiple ways. The chart slightly prefers \(chartAction.displayName.lowercased()); your line is the minority leg."

        // MARK: overcommit
        case (.overcommit, .pair):
            if bb <= 20 { return "At \(bb) BB the math wants you committing this pair, but not the way you did. Pick the line the chart prefers." }
            return "Pairs play \(chartAction.displayName.lowercased()) here — three-betting or jamming \(combo) over-commits and folds out worse."
        case (.overcommit, _):
            return "You took the bigger line when \(chartAction.displayName.lowercased()) was the right speed — \(combo) plays better passively here, you're folding out worse and getting called by better."

        // MARK: undercommit
        case (.undercommit, .pair):
            if bb <= 20 { return "At \(bb) BB the pair wants to commit — jamming or 3-betting denies equity. Flatting lets villain realize too much." }
            return "Calling concedes the initiative. \(combo) is strong enough to put pressure on — the chart wants \(chartAction.displayName.lowercased())."
        case (.undercommit, .ace), (.undercommit, .broadway):
            return "These hands play best by applying pressure. Flatting \(combo) lets villain realize their equity — \(chartAction.displayName.lowercased()) is the chart line."
        case (.undercommit, _):
            return "Too passive — \(combo) wants to be \(chartAction.displayName.lowercased()) at this depth, not just called."

        // MARK: wrongLine
        case (.wrongLine, _):
            return "You picked an action the chart doesn't take with \(combo) here. The correct line is \(chartAction.displayName.lowercased())."

        // MARK: correct
        case (.correct, _):
            return "Solid — \(combo) is a textbook \(chartAction.displayName.lowercased()) from \(pos) at \(bb) BB."
        }
    }

    private static func contextTemplate(
        handClass: HandClass,
        position: TablePosition,
        depthBB: Int,
        facing: FacingAction
    ) -> String {
        let bb = depthBB

        switch handClass {
        case .premiumPair:
            return "Premium pairs are value-first — get money in fast and don't slow-play out of position."
        case .midPair:
            if bb <= 25 { return "Mid pairs at \(bb) BB are jam/fold candidates — set-mining doesn't have the implied odds yet." }
            return "Mid pairs flop an overpair or under-pair more than they flop sets — play them for value, not for mining."
        case .smallPair:
            if bb <= 20 { return "Below 20 BB, small pairs play as showdown + fold-equity shoves more than set-miners." }
            return "Small pairs need ~15× implied odds to set-mine — that math is friendlier deeper than shallower."
        case .suitedAce:
            return "Suited aces double-up as blockers and flush draws — they 3-bet well and defend well, just not from the worst seats."
        case .offsuitAce:
            return "Offsuit aces have reverse-implied-odds problems — they hit top pair but get out-kicked by stronger aces."
        case .suitedBroadway:
            return "Suited broadway is the bread-and-butter of pressure ranges — flat, 3-bet, or defend depending on the open size."
        case .offsuitBroadway:
            return "Offsuit broadway plays better from late position; from early seats they're easy to dominate."
        case .suitedKing, .suitedQueen:
            return "Suited Kx/Qx hits flushes and top-pair-flush-draws — strong post-flop, but only when the pre-flop price is right."
        case .suitedConnector:
            if facing == .vsOpen {
                return "Suited connectors are 3-bet bluffs and blind defenders — they need to realize equity, so position and stack depth matter."
            }
            return "Suited connectors prefer multi-way pots with implied odds — pure heads-up shoving doesn't fit their structure."
        case .suitedGapper:
            return "Gappers play like worse versions of connectors — same idea, lower equity, tighter spots."
        case .offsuitJunk:
            return "Offsuit junk is just chip-loss surface area outside of free blind defense — keep it tight, especially out of position."
        }
    }
}
