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
        chart: RangeChart?,
        in lang: AppLanguage = .english
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
            reason: reason,
            lang: lang
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
        chart: RangeChart,
        chartAction: RangeAction? = nil,
        coarseFrequencies: [RangeAction: Double]? = nil,
        in lang: AppLanguage = .english
    ) -> Explanation {
        let frequencies = coarseFrequencies
            ?? FrequencyCollapser.coarse(chart.frequencies(for: combo))
        let handClass = HandClass.of(combo)
        let resolvedChartAction = chartAction ?? chart.action(for: combo)
        let reason = MistakeReason.classify(userAction: userAction, frequencies: frequencies)
        return build(
            combo: combo.notation,
            position: position,
            depthBB: depthBB,
            facing: facing,
            userAction: userAction,
            chartAction: resolvedChartAction,
            frequencies: frequencies,
            handClass: handClass,
            reason: reason,
            lang: lang
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
        reason: MistakeReason,
        lang: AppLanguage
    ) -> Explanation {
        let verdict = verdictLine(
            combo: combo,
            frequencies: frequencies,
            chartAction: chartAction,
            lang: lang
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
            chartAction: chartAction,
            lang: lang
        )
        let contextLine = contextTemplate(
            handClass: handClass,
            position: position,
            depthBB: depthBB,
            facing: facing,
            lang: lang
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
        chartAction: RangeAction,
        lang: AppLanguage
    ) -> String {
        let nonZero = frequencies
            .filter { $0.value >= 0.05 && $0.key != .mixed }
            .sorted { $0.value > $1.value }

        let action = chartAction.displayName(in: lang).lowercased()

        if nonZero.count <= 1 {
            switch lang {
            case .english:     return "\(combo) wants \(action)."
            case .russian:     return "\(combo) хочет \(action)."
            case .russianGenZ: return "\(combo) хочет \(action). го."
            }
        }

        let parts = nonZero.prefix(3).map { (act, freq) in
            "\(act.displayName(in: lang).lowercased()) \(Int((freq * 100).rounded()))%"
        }
        let joined = parts.joined(separator: " / ")
        switch lang {
        case .english:     return "Mixed spot — chart plays \(combo) \(joined)."
        case .russian:     return "Микс — чарт играет \(combo) \(joined)."
        case .russianGenZ: return "микс-спот — чарт катит \(combo) \(joined)."
        }
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
        chartAction: RangeAction,
        lang: AppLanguage
    ) -> String {
        let pos = position.displayName
        let bb = depthBB
        let chart = chartAction.displayName(in: lang).lowercased()

        switch lang {
        case .english:
            return reasonEN(reason: reason, family: family, handClass: handClass, combo: combo, pos: pos, bb: bb, facing: facing, chart: chart)
        case .russian:
            return reasonRU(reason: reason, family: family, handClass: handClass, combo: combo, pos: pos, bb: bb, facing: facing, chart: chart)
        case .russianGenZ:
            return reasonRUZ(reason: reason, family: family, handClass: handClass, combo: combo, pos: pos, bb: bb, facing: facing, chart: chart)
        }
    }

    // MARK: - English reason templates

    private static func reasonEN(reason: MistakeReason, family: HandClass.Family, handClass: HandClass, combo: String, pos: String, bb: Int, facing: FacingAction, chart: String) -> String {
        switch (reason, family) {
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
        case (.missedMix, _):
            return "This is a mixed spot — \(combo) gets played multiple ways. The chart slightly prefers \(chart); your line is the minority leg."
        case (.overcommit, .pair):
            if bb <= 20 { return "At \(bb) BB the math wants you committing this pair, but not the way you did. Pick the line the chart prefers." }
            return "Pairs play \(chart) here — three-betting or jamming \(combo) over-commits and folds out worse."
        case (.overcommit, _):
            return "You took the bigger line when \(chart) was the right speed — \(combo) plays better passively here, you're folding out worse and getting called by better."
        case (.undercommit, .pair):
            if bb <= 20 { return "At \(bb) BB the pair wants to commit — jamming or 3-betting denies equity. Flatting lets villain realize too much." }
            return "Calling concedes the initiative. \(combo) is strong enough to put pressure on — the chart wants \(chart)."
        case (.undercommit, .ace), (.undercommit, .broadway):
            return "These hands play best by applying pressure. Flatting \(combo) lets villain realize their equity — \(chart) is the chart line."
        case (.undercommit, _):
            return "Too passive — \(combo) wants to be \(chart) at this depth, not just called."
        case (.wrongLine, _):
            return "You picked an action the chart doesn't take with \(combo) here. The correct line is \(chart)."
        case (.correct, _):
            return "Solid — \(combo) is a textbook \(chart) from \(pos) at \(bb) BB."
        }
    }

    // MARK: - Russian reason templates

    private static func reasonRU(reason: MistakeReason, family: HandClass.Family, handClass: HandClass, combo: String, pos: String, bb: Int, facing: FacingAction, chart: String) -> String {
        switch (reason, family) {
        case (.tooTight, .ace):
            return "У одномастных тузов и сильных оффсьют-тузов хватает эквити и блокеров. Фолд \(combo) — слишком тайтово."
        case (.tooTight, .pair):
            if handClass == .smallPair && bb <= 20 {
                return "На \(bb) BB у мелкой пары хватает шоудаун-эквити и fold equity, чтобы взять флоп или пушить. Фолд жжёт фишки."
            }
            return "Пары играют сами на типичные опены. \(combo) — снап-континью с \(pos) на \(bb) BB."
        case (.tooTight, .broadway):
            return "Бродвей-руки держат эквити против ренжей опена. \(combo) слишком живое, чтобы фолдить на \(bb) BB."
        case (.tooTight, .suitedConnector):
            return "Одномастные коннекторы реализуют эквити через стриты и флэши — фолд префлоп это выбрасывает. Защищай или 3-бет."
        case (.tooTight, .suitedOther):
            return "Одномастные Kx/Qx достаточно часто собирают топ-пэйр + флэш-дро. Фолд \(combo) — слишком тайтово."
        case (.tooTight, .junk):
            return "Даже чарт говорит играть \(combo) в этом споте — обычно ценовая защита блайнда."
        case (.tooLoose, .junk):
            return "\(combo) — оффсьют-рука, которая тихо сливает стек. Фолд с \(pos) — простое и прибыльное решение."
        case (.tooLoose, .ace):
            if handClass == .offsuitAce {
                return "Оффсьют-тузы слабее AJo доминируются чаще, чем доминируют сами с \(pos). \(combo) — это фолд."
            }
            return "Одномастным тузам тоже нужна правильная цена и позиция. На \(bb) BB с \(pos) у \(combo) не хватает эквити."
        case (.tooLoose, .pair):
            return "Сет-майнинг мелкой парой окупается только на глубоких стеках. На \(bb) BB с \(pos) implied odds не те."
        case (.tooLoose, .broadway):
            return "Даже бродвей теряет деньги OOP против сильных ренжей. \(combo) — это фолд с \(pos)."
        case (.tooLoose, .suitedConnector):
            return "Коннекторам нужны implied odds и хорошая позиция. С \(pos) на \(bb) BB \(combo) просто жжёт фишки."
        case (.tooLoose, .suitedOther):
            return "Маргинальные одномастные руки вроде \(combo) недостаточно часто попадают сильно с \(pos). Фолди, береги стек."
        case (.missedMix, _):
            return "Спот микс — \(combo) играется по-разному. Чарт чуть больше любит \(chart); ты выбрал миноритарный путь."
        case (.overcommit, .pair):
            if bb <= 20 { return "На \(bb) BB математика хочет коммита парой, но не так, как ты сделал. Выбирай линию, которую любит чарт." }
            return "Пары здесь играют \(chart) — 3-бет или джем \(combo) перекомитит и сфолдит худшее."
        case (.overcommit, _):
            return "Ты взял более крупную линию, когда нужно было \(chart). \(combo) здесь лучше играть пассивнее — иначе фолдишь худшее и коллишь лучшее."
        case (.undercommit, .pair):
            if bb <= 20 { return "На \(bb) BB пара хочет коммититься — джем или 3-бет отнимает эквити. Колл даёт виллану реализовать слишком много." }
            return "Колл отдаёт инициативу. \(combo) достаточно сильна, чтобы давить — чарт хочет \(chart)."
        case (.undercommit, .ace), (.undercommit, .broadway):
            return "Эти руки лучше играют через давление. Колл \(combo) даёт виллану реализовать эквити — линия чарта это \(chart)."
        case (.undercommit, _):
            return "Слишком пассивно — \(combo) на этой глубине хочет быть \(chart), а не просто коллом."
        case (.wrongLine, _):
            return "Ты выбрал действие, которое чарт не делает с \(combo). Правильная линия — \(chart)."
        case (.correct, _):
            return "Чисто — \(combo) это учебный \(chart) с \(pos) на \(bb) BB."
        }
    }

    // MARK: - Gen Z Russian reason templates

    private static func reasonRUZ(reason: MistakeReason, family: HandClass.Family, handClass: HandClass, combo: String, pos: String, bb: Int, facing: FacingAction, chart: String) -> String {
        switch (reason, family) {
        case (.tooTight, .ace):
            return "одномастные тузы и норм оффсьют-тузы держат эквити + блокеры. \(combo) фолдить — лютый тайт, не делай так."
        case (.tooTight, .pair):
            if handClass == .smallPair && bb <= 20 {
                return "на \(bb) ББ у мелкой пары хватает шоудауна и fold equity, чтобы джем/флоп — фолд жжёт фишки в труху."
            }
            return "пары катят сами на опены. \(combo) — снап-континью с \(pos) на \(bb) ББ. изи."
        case (.tooTight, .broadway):
            return "бродвей держит эквити против опенов как папа. \(combo) фолдить на \(bb) ББ — кринж."
        case (.tooTight, .suitedConnector):
            return "коннекторы в масть реализуются через стриты и флэши — фолд префлоп это слив. дефенди или 3-бетай."
        case (.tooTight, .suitedOther):
            return "одномастные Kx/Qx часто собирают топ-пэйр + флэш-дро. \(combo) фолдить — тайт-старичок мод."
        case (.tooTight, .junk):
            return "даже чарт говорит играть \(combo) — обычно по цене на дефенде блайнда. не зашквар, бро."
        case (.tooLoose, .junk):
            return "\(combo) — оффсьют, который тихо ливает стек. фолд с \(pos) — изи и прибыльно."
        case (.tooLoose, .ace):
            if handClass == .offsuitAce {
                return "оффсьют-тузы ниже AJo доминируются чаще, чем доминируют. с \(pos) \(combo) — фолд, не выпендривайся."
            }
            return "даже одномастным тузам нужна цена + позиция. на \(bb) ББ с \(pos) у \(combo) эквити нема."
        case (.tooLoose, .pair):
            return "сет-майнить мелочью окупается только глубоко. на \(bb) ББ с \(pos) implied odds не те. слив."
        case (.tooLoose, .broadway):
            return "бродвей OOP против сильных ренжей сливает. \(combo) с \(pos) — фолд."
        case (.tooLoose, .suitedConnector):
            return "коннекторам нужны implied odds и позиция. с \(pos) на \(bb) ББ \(combo) — лютый слив фишек."
        case (.tooLoose, .suitedOther):
            return "маргинальные одномастные вроде \(combo) недостаточно часто попадают сильно с \(pos). фолди, бро."
        case (.missedMix, _):
            return "спот микс — \(combo) играется по-разному. чарт чуть больше за \(chart); ты выбрал миноритку."
        case (.overcommit, .pair):
            if bb <= 20 { return "на \(bb) ББ матан хочет коммита парой, но не так. бери линию, которую чарт любит." }
            return "пары катят \(chart). 3-бет или джем \(combo) — перекомит, фолдишь худшее."
        case (.overcommit, _):
            return "перекомит. нужно было \(chart), а ты с пушкой. \(combo) тут играется тише — иначе фолдишь худшее, коллишь лучшее. кринж."
        case (.undercommit, .pair):
            if bb <= 20 { return "на \(bb) ББ пара хочет джем/3-бет, иначе виллан реализует слишком много. колл — это недокомит." }
            return "колл отдаёт инициативу. \(combo) достаточно жирная, чтобы давить — чарт хочет \(chart)."
        case (.undercommit, .ace), (.undercommit, .broadway):
            return "эти руки катят через давление. колл \(combo) даёт виллану реализоваться — чарт хочет \(chart)."
        case (.undercommit, _):
            return "слишком пассивно. \(combo) на этой глубине хочет \(chart), а не флэт. погнали увереннее."
        case (.wrongLine, _):
            return "ты выбрал действие, которое чарт не делает с \(combo). правильно — \(chart)."
        case (.correct, _):
            return "топ — \(combo) это учебный \(chart) с \(pos) на \(bb) ББ. красавчик."
        }
    }

    // MARK: - Context templates

    private static func contextTemplate(
        handClass: HandClass,
        position: TablePosition,
        depthBB: Int,
        facing: FacingAction,
        lang: AppLanguage
    ) -> String {
        let bb = depthBB
        switch lang {
        case .english:
            return contextEN(handClass: handClass, bb: bb, facing: facing)
        case .russian:
            return contextRU(handClass: handClass, bb: bb, facing: facing)
        case .russianGenZ:
            return contextRUZ(handClass: handClass, bb: bb, facing: facing)
        }
    }

    private static func contextEN(handClass: HandClass, bb: Int, facing: FacingAction) -> String {
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

    private static func contextRU(handClass: HandClass, bb: Int, facing: FacingAction) -> String {
        switch handClass {
        case .premiumPair:
            return "Премиум-пары — это велью в первую очередь. Загружай быстрее и не слоуплей OOP."
        case .midPair:
            if bb <= 25 { return "Средние пары на \(bb) BB — кандидаты на джем/фолд, implied odds для сет-майнинга ещё нет." }
            return "Средние пары чаще ловят оверпэйр/андерпэйр, чем сет — играй на велью, а не на майнинг."
        case .smallPair:
            if bb <= 20 { return "Меньше 20 BB мелкие пары — это шоудаун + fold equity джемы, не сет-майнеры." }
            return "Мелким парам нужны ~15× implied odds для майнинга — это работает глубже, чем мельче."
        case .suitedAce:
            return "Одномастные тузы — это блокеры и флэш-дро. Хорошо 3-бетятся и защищаются, но не с худших мест."
        case .offsuitAce:
            return "У оффсьют-тузов проблема обратных implied odds — собирают топ-пэйр, но проигрывают по кикеру."
        case .suitedBroadway:
            return "Одномастный бродвей — основа давящих ренжей. Флэт, 3-бет или защита — зависит от размера опена."
        case .offsuitBroadway:
            return "Оффсьют-бродвей лучше играет с поздних позиций. С ранних его легко доминируют."
        case .suitedKing, .suitedQueen:
            return "Одномастные Kx/Qx собирают флэши и топ-пэйр-флэш-дро. Сильно постфлоп, если цена префлоп правильная."
        case .suitedConnector:
            if facing == .vsOpen {
                return "Коннекторы в масть — это 3-бет блефы и защита блайндов. Нужна реализация эквити: позиция и стек важны."
            }
            return "Коннекторам нужны многопотовые банки с implied odds — чистый хедз-ап пуш им не подходит."
        case .suitedGapper:
            return "Геппи — это худшая версия коннекторов. Та же идея, меньше эквити, уже спот."
        case .offsuitJunk:
            return "Оффсьют-мусор — просто площадь для слива фишек вне дешёвой защиты блайнда. Держи тайт, особенно OOP."
        }
    }

    private static func contextRUZ(handClass: HandClass, bb: Int, facing: FacingAction) -> String {
        switch handClass {
        case .premiumPair:
            return "премиум-пары — велью в чистом виде. загружай быстро, не слоуплей OOP, иначе кринж."
        case .midPair:
            if bb <= 25 { return "средние пары на \(bb) ББ — джем/фолд кандидаты. implied odds для майнинга ещё нет." }
            return "средние пары чаще ловят овер/андер-пэйр, чем сет. катай на велью, не на майнинг."
        case .smallPair:
            if bb <= 20 { return "ниже 20 ББ мелкая пара — это шоудаун + fold equity пуш, а не сет-майнер." }
            return "мелочи нужны ~15× implied odds для майнинга — глубже это работает, мельче — нет."
        case .suitedAce:
            return "одномастные тузы — блокеры + флэш-дро. 3-бетятся и защищаются норм, но не с худших мест."
        case .offsuitAce:
            return "оффсьют-тузы — проблема обратных implied odds. собираешь топ-пэйр и тебя кикером сжирают."
        case .suitedBroadway:
            return "одномастный бродвей — это база давящих ренжей. флэт / 3-бет / защита — смотри размер опена."
        case .offsuitBroadway:
            return "оффсьют-бродвей лучше с поздних позиций. с ранних его едят как изи."
        case .suitedKing, .suitedQueen:
            return "одномастные Kx/Qx — это флэши и топ-пэйр-флэш-дро. постфлоп пушка, если цена префлоп норм."
        case .suitedConnector:
            if facing == .vsOpen {
                return "коннекторы в масть — это 3-бет блефы + защита блайндов. эквити надо реализовать: позиция и стек важны."
            }
            return "коннекторам нужны многопотовые банки + implied odds. чистый хедз-ап пуш им не катит."
        case .suitedGapper:
            return "геппи — это коннекторы-лоу. та же идея, меньше эквити, спот уже."
        case .offsuitJunk:
            return "оффсьют-мусор — это просто площадка для слива стека вне дешёвой защиты блайнда. держи тайт, особенно OOP."
        }
    }
}
