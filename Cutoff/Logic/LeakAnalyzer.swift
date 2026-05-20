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
    /// Actions that represent "playing the hand" (any non-fold preflop line).
    private static let playingActions: Set<RangeAction> = [
        .call, .raise, .threeBet, .jam
    ]

    /// Hand-class accuracy threshold below which a class is flagged as a leak.
    private static let handClassAccuracyFloor = 55

    /// Minimum sample for hand-class leaks.
    private static let handClassMinSample = 5

    /// Headline-level leak emitted when one direction of error dominates the
    /// user's mistakes overall. Requires a chart-resolver so reasons can be
    /// reconstructed against the played combo's true frequency distribution.
    static func leaks(
        from results: [QuizResult],
        in lang: AppLanguage = .english,
        chartByID: (String) -> RangeChart? = { _ in nil }
    ) -> [Leak] {
        guard results.count >= 8 else { return [] }

        var leaks: [Leak] = []

        // 1) Loose UTG opens — opening hands from UTG that the chart wants folded.
        let utg = results.filter { $0.position == .utg }
        if utg.count >= 5 {
            let looseOpens = utg.filter {
                playingActions.contains($0.userAction) && $0.correctAction == .fold
            }.count
            let ratio = Double(looseOpens) / Double(utg.count)
            if ratio > 0.18 {
                leaks.append(Leak(
                    id: "too_loose_utg",
                    title: looseUTGTitle(in: lang),
                    detail: looseUTGDetail(in: lang),
                    severity: min(1, ratio * 2),
                    suggestedSpot: (.utg, 100, .unopened)
                ))
            }
        }

        // 2) Overfolding BB — folding hands from BB that the chart wants to defend.
        let bbDefense = results.filter { $0.position == .bb && $0.facingAction == .vsOpen }
        if bbDefense.count >= 5 {
            let overFolds = bbDefense.filter {
                $0.userAction == .fold && $0.correctAction != .fold
            }.count
            let ratio = Double(overFolds) / Double(bbDefense.count)
            if ratio > 0.25 {
                leaks.append(Leak(
                    id: "overfolding_bb",
                    title: overfoldBBTitle(in: lang),
                    detail: overfoldBBDetail(in: lang),
                    severity: min(1, ratio * 1.6),
                    suggestedSpot: (.bb, 30, .vsOpen)
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
                    title: looseCallVs3Title(in: lang),
                    detail: looseCallVs3Detail(in: lang),
                    severity: min(1, ratio * 1.4),
                    suggestedSpot: (.btn, 100, .vs3Bet)
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
                    title: missedReshoveTitle(in: lang),
                    detail: missedReshoveDetail(in: lang),
                    severity: min(1, ratio * 1.3),
                    suggestedSpot: (.btn, 15, .pushFold)
                ))
            }
        }

        // 5) Hand-class accuracy leaks — class-level patterns the user
        //    misplays across positions/depths.
        var byClass: [HandClass: [QuizResult]] = [:]
        for row in results {
            guard let combo = HandCombo.parse(row.combo) else { continue }
            byClass[HandClass.of(combo), default: []].append(row)
        }
        for (hc, slice) in byClass where slice.count >= handClassMinSample {
            let snap = ReviewAnalyzer.snapshot(slice)
            if snap.accuracy < handClassAccuracyFloor {
                let severity = min(1.0, Double(handClassAccuracyFloor - snap.accuracy) / 40.0)
                let hcName = hc.displayName(in: lang)
                leaks.append(Leak(
                    id: "handclass_\(hc.rawValue)",
                    title: L10n.handClassLeakTitle(hcName, in: lang),
                    detail: L10n.handClassLeakDetail(name: hcName, accuracy: snap.accuracy, total: snap.total, in: lang),
                    severity: severity,
                    suggestedSpot: nil
                ))
            }
        }

        // 6) Direction-of-error leak — looks at *why* you miss, not just where.
        let mistakes = results.filter { $0.outcome == .mistake || $0.outcome == .punt }
        if mistakes.count >= 6 {
            var reasonCounts: [MistakeReason: Int] = [:]
            for row in mistakes {
                let reason = ReviewAnalyzer.classify(row: row, chartByID: chartByID)
                reasonCounts[reason, default: 0] += 1
            }
            let total = Double(mistakes.count)
            if let (topReason, topCount) = reasonCounts.max(by: { $0.value < $1.value }) {
                let share = Double(topCount) / total
                if share >= 0.45 {
                    leaks.append(Leak(
                        id: "direction_\(topReason.rawValue)",
                        title: directionLeakTitle(topReason, in: lang),
                        detail: L10n.directionLeakDetail(
                            share: Int((share * 100).rounded()),
                            reason: topReason.displayName(in: lang),
                            in: lang
                        ),
                        severity: min(1, share * 1.2),
                        suggestedSpot: nil
                    ))
                }
            }
        }

        return leaks.sorted { $0.severity > $1.severity }
    }

    private static func directionLeakTitle(_ reason: MistakeReason, in lang: AppLanguage) -> String {
        switch lang {
        case .english:
            switch reason {
            case .tooTight:     return "You play too tight"
            case .tooLoose:     return "You play too loose"
            case .overcommit:   return "Over-commitment leak"
            case .undercommit:  return "Under-commitment leak"
            case .wrongLine:    return "Wrong-line bias"
            case .missedMix:    return "Missing mixed-strategy lines"
            case .correct:      return "Calibration check"
            }
        case .russian:
            switch reason {
            case .tooTight:     return "Играешь слишком тайтово"
            case .tooLoose:     return "Играешь слишком лузово"
            case .overcommit:   return "Перекомитмент"
            case .undercommit:  return "Недокомитмент"
            case .wrongLine:    return "Уход в неверную линию"
            case .missedMix:    return "Пропуск миксов"
            case .correct:      return "Калибровка"
            }
        case .russianGenZ:
            switch reason {
            case .tooTight:     return "ты тайтуешь как дед"
            case .tooLoose:     return "ты сливаешь луз-стайл"
            case .overcommit:   return "перекомитишь, бро"
            case .undercommit:  return "не докомичиваешь — кринж"
            case .wrongLine:    return "уходишь не в ту линию"
            case .missedMix:    return "пропускаешь миксы"
            case .correct:      return "калибровка"
            }
        }
    }

    // MARK: - Static leak strings (the four pattern leaks have fixed copy)

    private static func looseUTGTitle(in lang: AppLanguage) -> String {
        switch lang {
        case .english:     return "Too loose UTG"
        case .russian:     return "Слишком лузово с UTG"
        case .russianGenZ: return "лузишь с UTG — кринж"
        }
    }
    private static func looseUTGDetail(in lang: AppLanguage) -> String {
        switch lang {
        case .english:     return "You're opening hands from early position that play badly out of position."
        case .russian:     return "Открываешь руки с ранней позиции, которые плохо играют OOP."
        case .russianGenZ: return "открываешь с ранней позы трэшак, который OOP не катит. подумой."
        }
    }
    private static func overfoldBBTitle(in lang: AppLanguage) -> String {
        switch lang {
        case .english:     return "Overfolding the Big Blind"
        case .russian:     return "Перефолд большого блайнда"
        case .russianGenZ: return "сливаешь BB слишком часто"
        }
    }
    private static func overfoldBBDetail(in lang: AppLanguage) -> String {
        switch lang {
        case .english:     return "You're folding to opens too often. The blinds are already in — defend wider."
        case .russian:     return "Слишком часто фолдишь на опен. Блайнды уже в банке — защищайся шире."
        case .russianGenZ: return "фолдишь на опен как нит. блайнды уже в банке — го дефендить шире."
        }
    }
    private static func looseCallVs3Title(in lang: AppLanguage) -> String {
        switch lang {
        case .english:     return "Calling too much vs 3-bet"
        case .russian:     return "Слишком часто колишь 3-беты"
        case .russianGenZ: return "колишь 3-беты на изи — пас"
        }
    }
    private static func looseCallVs3Detail(in lang: AppLanguage) -> String {
        switch lang {
        case .english:     return "Flatting 3-bets out of position with marginal hands loses chips."
        case .russian:     return "Флэт 3-бета OOP с маргинальными руками сливает фишки."
        case .russianGenZ: return "флэтить 3-бет OOP с трэшем — лютый слив фишек. не делай так."
        }
    }
    private static func missedReshoveTitle(in lang: AppLanguage) -> String {
        switch lang {
        case .english:     return "Missing reshove spots"
        case .russian:     return "Пропускаешь решовы"
        case .russianGenZ: return "пропускаешь решовы — фолд эквити мимо"
        }
    }
    private static func missedReshoveDetail(in lang: AppLanguage) -> String {
        switch lang {
        case .english:     return "You're folding short-stack hands that have enough fold equity to jam."
        case .russian:     return "Фолдишь короткостековые руки, в которых хватает fold equity на джем."
        case .russianGenZ: return "фолдишь короткий стек, хотя fold equity вагон — джемить надо, бро."
        }
    }
}
