import Foundation

/// Central translation table. Keyed by `L10n.Key`; values per `AppLanguage`.
/// Missing keys fall back to English. The Gen Z Russian voice leans into
/// poker-Telegram slang ("джем", "слив", "кринж") and meme/ironic energy.
enum L10n {

    // MARK: - Keys

    enum Key: String, Hashable {
        // App / generic
        case appName
        case loading
        case cancel
        case done
        case clear
        case start
        case search
        case more
        case hideMore
        case showMore

        // Tabs
        case tabTrain
        case tabRanges
        case tabReview
        case tabSettings

        // Onboarding
        case onboardingSubtitle
        case startTraining
        case customizeTournament

        // Settings
        case settingsTitle
        case editTournamentRules
        case resetOnboarding
        case language
        case languageEnglish
        case languageRussian
        case languageRussianGenZ

        // Tournament setup
        case tournamentProfile
        case saveProfile
        case startingStack
        case blinds
        case blindSmall
        case blindBig
        case tableSize
        case tableSize6
        case tableSize8
        case tableSize9
        case blindLevelDuration
        case ante
        case anteNone
        case anteClassic
        case anteBigBlind
        case anteUnknown
        case currentHeroStack
        case heroStackPlaceholder

        // Train dashboard
        case startToTrack
        case statAccuracy
        case statHand
        case statHands
        case statToday
        case continueLabel
        case warmupKicker
        case leakKicker
        case customDrillTitle
        case customDrillSubtitle
        case reviewMistakesTitle
        case reviewMistakesSubtitle

        // Drill picker
        case position
        case stackDepth
        case scenario
        case allPositionsAllDepthsAllScenarios
        case startDrill
        case buildADrill

        // Review
        case reviewTitle
        case noHistoryYet
        case noHistoryHint
        case mistakesLabel
        case closeLabel
        case correctLabel
        case allLabel
        case trend
        case deepDive
        case hideDeepDive
        case showDeepDive
        case whereYouLeak
        case accuracyBySpot
        case byHandClass
        case mistakeReasons
        case patternsWeNoticed
        case reviewYourHands
        case nothingMatchesFilter
        case worstLabel
        case scope7d
        case scope30d
        case scopeAll

        // Mistake sheet
        case youLabel
        case chartLabel
        case frequencies
        case whyLabel
        case drillThisSpot

        // Ranges
        case rangesTitle
        case depth
        case actionMix
        case swipeToChangeDepth
        case noChartMatches
        case searchRanges
        case recentsAndFavorites
        case favoriteThisChart
        case unfavoriteThisChart
        case rangeSearchPlaceholder
        case noChartsMatch
        case bookmarksTitle
        case recents
        case favorites
        case noChartsViewed
        case noFavoritesYet

        // Postflop
        case postflopTitle

        // Drill categories — title
        case drillStandardRoutineTitle
        case drillFirstInJamTitle
        case drillReJamTitle
        case drillCallJamTitle
        case drillStealBlindsTitle
        case drillVsManiacTitle
        case drillMixedTitle

        // Drill categories — subtitle
        case drillStandardRoutineSubtitle
        case drillFirstInJamSubtitle
        case drillReJamSubtitle
        case drillCallJamSubtitle
        case drillStealBlindsSubtitle
        case drillVsManiacSubtitle
        case drillMixedSubtitle

        // RangeAction (coarse)
        case actionFold
        case actionCall
        case actionRaise
        case actionThreeBet
        case actionJam
        case actionMixed

        // PreflopAction (fine)
        case preflopFold
        case preflopCall
        case preflopMinRaise
        case preflopRaise25x
        case preflopRaise3x
        case preflopShove
        case preflopLimp
        case preflopLimpRaise
        case shortJam
        case shortLRz

        // PostflopAction
        case postActionCheck
        case postActionBet33
        case postActionBet67
        case postActionBet100
        case postActionRaise
        case postActionFold
        case postActionCall
        case postActionShove

        // FacingAction
        case facingUnopened
        case facingVsOpen
        case facingVs3Bet
        case facingBlindDefense
        case facingSqueeze
        case facingPushFold

        // FacingAction headline (sentence-style)
        case headlineUnopened
        case headlineVsOpen
        case headlineVs3Bet
        case headlineBlindDefense
        case headlineSqueeze
        case headlinePushFold

        // VillainType
        case villainStandard
        case villainLoose
        case villainManiac
        case villainNit
        case villainStandardNote
        case villainLooseNote
        case villainManiacNote
        case villainNitNote

        // HandClass
        case hcPremiumPair
        case hcMidPair
        case hcSmallPair
        case hcSuitedAce
        case hcOffsuitAce
        case hcSuitedBroadway
        case hcOffsuitBroadway
        case hcSuitedKing
        case hcSuitedQueen
        case hcSuitedConnector
        case hcSuitedGapper
        case hcOffsuitJunk

        // BoardTexture
        case textureDryRainbow
        case textureWetMonotone
        case texturePaired
        case textureConnected
        case textureBroadway
        case textureLowScatter

        // MistakeReason — display & short
        case mrCorrect
        case mrMissedMix
        case mrTooTight
        case mrTooLoose
        case mrWrongLine
        case mrOvercommit
        case mrUndercommit
        case mrShortCorrect
        case mrShortMix
        case mrShortTight
        case mrShortLoose
        case mrShortWrongLine
        case mrShortOver
        case mrShortUnder

        // Position/in/out
        case inPosition
        case outOfPosition
        case potChip
        case effChip

        // Streak
        case streakLabel

        // FeedbackSheet
        case outcomeCorrect
        case outcomeAlmost
        case outcomeMistake
        case outcomeBigMistake
        case youPlayed
        case chartWants
        case sameLine
        case viewRange
        case nextHand

        // Component fragments
        case drillAFewHands
        case noClosePeers
        case playsSameWay
        case coolerEqualsMiss
        case tournamentProfileTitle
        case bbUnit
        case stackLabel
        case blindsLabel
        case levelsLabel
        case minutesShort
        case tableMaxSuffix
        case last7d
        case last30d
        case flatLabel
    }

    // MARK: - Lookup

    static func string(_ key: Key, in lang: AppLanguage) -> String {
        if let v = table[lang]?[key] { return v }
        return table[.english]?[key] ?? key.rawValue
    }

    // MARK: - Parameterized helpers

    /// "Continue {title}" with verb agreement per language.
    static func continueWith(_ title: String, in lang: AppLanguage) -> String {
        switch lang {
        case .english:     return "Continue \(title)"
        case .russian:     return "Продолжить: \(title)"
        case .russianGenZ: return "погнали дальше: \(title)"
        }
    }

    /// "X day streak" with plural agreement.
    static func dayStreak(_ days: Int, in lang: AppLanguage) -> String {
        switch lang {
        case .english:
            return "\(days) day streak"
        case .russian:
            let form = ruPlural(days, one: "день", few: "дня", many: "дней")
            return "\(days) \(form) подряд"
        case .russianGenZ:
            let form = ruPlural(days, one: "день", few: "дня", many: "дней")
            return "\(days) \(form) на стрике"
        }
    }

    /// "Last N hand/hands" — review snapshot eyebrow.
    static func lastNHands(_ n: Int, in lang: AppLanguage) -> String {
        switch lang {
        case .english:
            return "Last \(n) hand\(n == 1 ? "" : "s")"
        case .russian:
            let form = ruPlural(n, one: "раздачи", few: "раздач", many: "раздач")
            return "За последние \(n) \(form)"
        case .russianGenZ:
            let form = ruPlural(n, one: "раздачи", few: "раздач", many: "раздач")
            return "крайние \(n) \(form)"
        }
    }

    /// "Worst: {label}".
    static func worstLabel(_ label: String, in lang: AppLanguage) -> String {
        switch lang {
        case .english:     return "Worst: \(label)"
        case .russian:     return "Хуже всего: \(label)"
        case .russianGenZ: return "лютый зашквар: \(label)"
        }
    }

    /// "X of Y wrong" — leak spot row.
    static func ofWrong(mistakes m: Int, total t: Int, in lang: AppLanguage) -> String {
        switch lang {
        case .english:     return "\(m) of \(t) wrong"
        case .russian:     return "\(m) из \(t) неверно"
        case .russianGenZ: return "слил \(m) из \(t)"
        }
    }

    /// "N range/ranges available" — drill picker.
    static func rangesAvailable(_ n: Int, in lang: AppLanguage) -> String {
        switch lang {
        case .english:
            return "\(n) range\(n == 1 ? "" : "s") available"
        case .russian:
            let form = ruPlural(n, one: "диапазон", few: "диапазона", many: "диапазонов")
            return "\(n) \(form) доступно"
        case .russianGenZ:
            let form = ruPlural(n, one: "ренж", few: "ренжа", many: "ренжей")
            return "налутал \(n) \(form)"
        }
    }

    /// "Starting BB: N".
    static func startingBB(_ n: Int, in lang: AppLanguage) -> String {
        switch lang {
        case .english:     return "Starting BB: \(n)"
        case .russian:     return "Стартовых BB: \(n)"
        case .russianGenZ: return "стартовых ББ: \(n)"
        }
    }

    /// "N BB" suffix used by the hero stack ratio (e.g. "12 BB").
    static func bbValue(_ n: Int, in lang: AppLanguage) -> String {
        switch lang {
        case .english:     return "\(n) BB"
        case .russian:     return "\(n) BB"
        case .russianGenZ: return "\(n) ББ"
        }
    }

    /// "Leaks in {handclass}" — LeakAnalyzer headline.
    static func handClassLeakTitle(_ name: String, in lang: AppLanguage) -> String {
        switch lang {
        case .english:     return "Leaks in \(name.lowercased())"
        case .russian:     return "Утечки на \(name.lowercased())"
        case .russianGenZ: return "сливаешь \(name.lowercased())"
        }
    }

    /// LeakAnalyzer detail: "Accuracy on X is Y% across Z hands — work on this class."
    static func handClassLeakDetail(name: String, accuracy: Int, total: Int, in lang: AppLanguage) -> String {
        switch lang {
        case .english:
            return "Accuracy on \(name.lowercased()) is \(accuracy)% across \(total) hands — work on this class."
        case .russian:
            return "Точность на \(name.lowercased()) — \(accuracy)% из \(total). Поработай над этим классом."
        case .russianGenZ:
            return "по \(name.lowercased()) точность \(accuracy)% за \(total). тут жирный лик — иди дрочить."
        }
    }

    /// LeakAnalyzer detail: "X% of your mistakes are Y — work in the opposite direction."
    static func directionLeakDetail(share: Int, reason: String, in lang: AppLanguage) -> String {
        switch lang {
        case .english:
            return "\(share)% of your mistakes are \(reason.lowercased()) — work in the opposite direction."
        case .russian:
            return "\(share)% ошибок — \(reason.lowercased()). Двигайся в обратную сторону."
        case .russianGenZ:
            return "\(share)% твоих сливов — \(reason.lowercased()). крути в обратку."
        }
    }

    // MARK: - Russian plural helper

    /// Russian three-form pluralization (1 / 2–4 / 5–20). Handles the 11–14
    /// exception ("11 дней" not "11 день").
    static func ruPlural(_ n: Int, one: String, few: String, many: String) -> String {
        let mod10  = abs(n) % 10
        let mod100 = abs(n) % 100
        if mod100 >= 11 && mod100 <= 14 { return many }
        switch mod10 {
        case 1:       return one
        case 2, 3, 4: return few
        default:      return many
        }
    }

    // MARK: - Table

    private static let table: [AppLanguage: [Key: String]] = [
        .english: en,
        .russian: ru,
        .russianGenZ: ruZ,
    ]

    private static let en: [Key: String] = [
        .appName: "MTT Poker Trainer",
        .loading: "Loading…",
        .cancel: "Cancel",
        .done: "Done",
        .clear: "Clear",
        .start: "Start",
        .search: "Search",
        .more: "More",
        .hideMore: "Hide more",
        .showMore: "Show more",

        .tabTrain: "Train",
        .tabRanges: "Ranges",
        .tabReview: "Review",
        .tabSettings: "Settings",

        .onboardingSubtitle: "Drill the preflop spots you see in live MTTs.",
        .startTraining: "Start training",
        .customizeTournament: "Customize tournament",

        .settingsTitle: "Settings",
        .editTournamentRules: "Edit tournament rules",
        .resetOnboarding: "Reset onboarding",
        .language: "Language",
        .languageEnglish: "English",
        .languageRussian: "Русский",
        .languageRussianGenZ: "Русский (Gen Z)",

        .tournamentProfile: "Tournament profile",
        .saveProfile: "Save profile",
        .startingStack: "Starting stack",
        .blinds: "Blinds",
        .blindSmall: "Small",
        .blindBig: "Big",
        .tableSize: "Table size",
        .tableSize6: "6-max",
        .tableSize8: "8-max",
        .tableSize9: "9-max",
        .blindLevelDuration: "Blind level duration",
        .ante: "Ante",
        .anteNone: "No ante",
        .anteClassic: "Classic ante",
        .anteBigBlind: "Big Blind ante",
        .anteUnknown: "Not set",
        .currentHeroStack: "Current hero stack (optional)",
        .heroStackPlaceholder: "e.g. 18000",

        .startToTrack: "Start a drill to track accuracy.",
        .statAccuracy: "accuracy",
        .statHand: "hand",
        .statHands: "hands",
        .statToday: "today",
        .continueLabel: "Continue",
        .warmupKicker: "Today's warmup",
        .leakKicker: "Today's leak",
        .customDrillTitle: "Custom Drill",
        .customDrillSubtitle: "Pick position, depth & scenario",
        .reviewMistakesTitle: "Review mistakes",
        .reviewMistakesSubtitle: "Replay spots where you lost EV",

        .position: "Position",
        .stackDepth: "Stack Depth",
        .scenario: "Scenario",
        .allPositionsAllDepthsAllScenarios: "All positions · all depths · all scenarios",
        .startDrill: "Start Drill",
        .buildADrill: "Build a Drill",

        .reviewTitle: "Review",
        .noHistoryYet: "No history yet",
        .noHistoryHint: "Answer a few drills and your mistakes and patterns will show up here.",
        .mistakesLabel: "Mistakes",
        .closeLabel: "Close",
        .correctLabel: "Correct",
        .allLabel: "All",
        .trend: "Trend",
        .deepDive: "Deep dive",
        .hideDeepDive: "Hide deep dive",
        .showDeepDive: "Show deep dive",
        .whereYouLeak: "Where you leak",
        .accuracyBySpot: "Accuracy by spot",
        .byHandClass: "By hand class",
        .mistakeReasons: "Mistake reasons",
        .patternsWeNoticed: "Patterns we noticed",
        .reviewYourHands: "Review your hands",
        .nothingMatchesFilter: "Nothing matches this filter yet.",
        .worstLabel: "Worst",
        .scope7d: "7d",
        .scope30d: "30d",
        .scopeAll: "All",

        .youLabel: "YOU",
        .chartLabel: "CHART",
        .frequencies: "Frequencies",
        .whyLabel: "Why",
        .drillThisSpot: "Drill this spot",

        .rangesTitle: "Ranges",
        .depth: "Depth",
        .actionMix: "Action mix",
        .swipeToChangeDepth: "swipe to change depth",
        .noChartMatches: "No chart matches these filters.",
        .searchRanges: "Search ranges",
        .recentsAndFavorites: "Recents and favorites",
        .favoriteThisChart: "Favorite this chart",
        .unfavoriteThisChart: "Unfavorite this chart",
        .rangeSearchPlaceholder: "e.g. \"BTN 100\" or \"squeeze\"",
        .noChartsMatch: "No charts match.",
        .bookmarksTitle: "Bookmarks",
        .recents: "Recents",
        .favorites: "Favorites",
        .noChartsViewed: "No charts viewed yet.",
        .noFavoritesYet: "No favorites yet — tap the star on a chart.",

        .postflopTitle: "Postflop",

        .drillStandardRoutineTitle: "Standard routine",
        .drillFirstInJamTitle: "First-in jam",
        .drillReJamTitle: "Re-jam over an open",
        .drillCallJamTitle: "Call an all-in",
        .drillStealBlindsTitle: "Steal the blinds",
        .drillVsManiacTitle: "Play vs a maniac",
        .drillMixedTitle: "Mixed live drill",

        .drillStandardRoutineSubtitle: "Random preflop — any position, stack, or scenario.",
        .drillFirstInJamSubtitle: "12–25 BB · find the jam, don't min-raise yourself broke.",
        .drillReJamSubtitle: "15–30 BB · when someone opens, can you shove?",
        .drillCallJamSubtitle: "Snap, call, or fold the all-in based on price.",
        .drillStealBlindsSubtitle: "Late position, 20–40 BB · open wider when nobody fights back.",
        .drillVsManiacSubtitle: "25–40 BB · they 3-bet light — fold less, jam more.",
        .drillMixedSubtitle: "A live MTT mix biased to 15–40 BB.",

        .actionFold: "Fold",
        .actionCall: "Call",
        .actionRaise: "Raise",
        .actionThreeBet: "3-bet",
        .actionJam: "Jam",
        .actionMixed: "Mixed",

        .preflopFold: "Fold",
        .preflopCall: "Call",
        .preflopMinRaise: "Min-raise",
        .preflopRaise25x: "Raise 2.5x",
        .preflopRaise3x: "Raise 3x",
        .preflopShove: "Shove",
        .preflopLimp: "Limp",
        .preflopLimpRaise: "Limp-raise",
        .shortJam: "Jam",
        .shortLRz: "L-Rz",

        .postActionCheck: "Check",
        .postActionBet33: "Bet 33%",
        .postActionBet67: "Bet 67%",
        .postActionBet100: "Bet pot",
        .postActionRaise: "Raise",
        .postActionFold: "Fold",
        .postActionCall: "Call",
        .postActionShove: "Shove",

        .facingUnopened: "RFI",
        .facingVsOpen: "vs Open",
        .facingVs3Bet: "vs 3-bet",
        .facingBlindDefense: "Blind defense",
        .facingSqueeze: "Squeeze",
        .facingPushFold: "Push/Fold",

        .headlineUnopened: "First in",
        .headlineVsOpen: "Facing an open",
        .headlineVs3Bet: "Facing a 3-bet",
        .headlineBlindDefense: "Defending the blinds",
        .headlineSqueeze: "Squeeze spot",
        .headlinePushFold: "Push or fold",

        .villainStandard: "Standard reg",
        .villainLoose: "Loose caller",
        .villainManiac: "Maniac",
        .villainNit: "Nit",
        .villainStandardNote: "Plays close to a sensible default.",
        .villainLooseNote: "Calls wide — value-bet bigger, bluff less.",
        .villainManiacNote: "Opens / 3-bets light — fold less, jam more.",
        .villainNitNote: "Tight ranges — believe their pressure.",

        .hcPremiumPair: "Premium pairs",
        .hcMidPair: "Mid pairs",
        .hcSmallPair: "Small pairs",
        .hcSuitedAce: "Suited aces",
        .hcOffsuitAce: "Offsuit aces",
        .hcSuitedBroadway: "Suited broadway",
        .hcOffsuitBroadway: "Offsuit broadway",
        .hcSuitedKing: "Suited kings",
        .hcSuitedQueen: "Suited queens",
        .hcSuitedConnector: "Suited connectors",
        .hcSuitedGapper: "Suited gappers",
        .hcOffsuitJunk: "Offsuit junk",

        .textureDryRainbow: "Dry / rainbow",
        .textureWetMonotone: "Wet / monotone",
        .texturePaired: "Paired",
        .textureConnected: "Connected",
        .textureBroadway: "Broadway",
        .textureLowScatter: "Low scatter",

        .mrCorrect: "Correct",
        .mrMissedMix: "Missed mix",
        .mrTooTight: "Too tight",
        .mrTooLoose: "Too loose",
        .mrWrongLine: "Wrong line",
        .mrOvercommit: "Over-committed",
        .mrUndercommit: "Under-committed",
        .mrShortCorrect: "Correct",
        .mrShortMix: "Mix",
        .mrShortTight: "Tight",
        .mrShortLoose: "Loose",
        .mrShortWrongLine: "Wrong line",
        .mrShortOver: "Over",
        .mrShortUnder: "Under",

        .inPosition: "IP",
        .outOfPosition: "OOP",
        .potChip: "Pot",
        .effChip: "Eff",

        .streakLabel: "day streak",

        .outcomeCorrect: "Correct",
        .outcomeAlmost: "Almost",
        .outcomeMistake: "Mistake",
        .outcomeBigMistake: "Big mistake",
        .youPlayed: "You played",
        .chartWants: "Chart wants",
        .sameLine: "Same line",
        .viewRange: "View range",
        .nextHand: "Next hand",

        .drillAFewHands: "Drill a few hands",
        .noClosePeers: "No close peers in this chart.",
        .playsSameWay: "Plays the same way",
        .coolerEqualsMiss: "Cooler = miss",
        .tournamentProfileTitle: "Tournament profile",
        .bbUnit: "BB",
        .stackLabel: "Stack",
        .blindsLabel: "Blinds",
        .levelsLabel: "Levels",
        .minutesShort: "min",
        .tableMaxSuffix: "-max MTT",
        .last7d: "Last 7d",
        .last30d: "Last 30d",
        .flatLabel: "Flat",
    ]

    private static let ru: [Key: String] = [
        .appName: "MTT Покер Тренер",
        .loading: "Загрузка…",
        .cancel: "Отмена",
        .done: "Готово",
        .clear: "Сброс",
        .start: "Старт",
        .search: "Поиск",
        .more: "Ещё",
        .hideMore: "Свернуть",
        .showMore: "Показать ещё",

        .tabTrain: "Тренировка",
        .tabRanges: "Диапазоны",
        .tabReview: "Разбор",
        .tabSettings: "Настройки",

        .onboardingSubtitle: "Тренируй префлоп-споты из живых MTT.",
        .startTraining: "Начать тренировку",
        .customizeTournament: "Настроить турнир",

        .settingsTitle: "Настройки",
        .editTournamentRules: "Изменить параметры турнира",
        .resetOnboarding: "Сбросить онбординг",
        .language: "Язык",
        .languageEnglish: "English",
        .languageRussian: "Русский",
        .languageRussianGenZ: "Русский (Gen Z)",

        .tournamentProfile: "Параметры турнира",
        .saveProfile: "Сохранить",
        .startingStack: "Стартовый стек",
        .blinds: "Блайнды",
        .blindSmall: "Малый",
        .blindBig: "Большой",
        .tableSize: "Размер стола",
        .tableSize6: "6-max",
        .tableSize8: "8-max",
        .tableSize9: "9-max",
        .blindLevelDuration: "Длительность уровня",
        .ante: "Анте",
        .anteNone: "Без анте",
        .anteClassic: "Классическое анте",
        .anteBigBlind: "BB-анте",
        .anteUnknown: "Не задано",
        .currentHeroStack: "Текущий стек героя (опц.)",
        .heroStackPlaceholder: "напр. 18000",

        .startToTrack: "Запусти раздачу, чтобы видеть точность.",
        .statAccuracy: "точность",
        .statHand: "раздача",
        .statHands: "раздач",
        .statToday: "сегодня",
        .continueLabel: "Продолжить",
        .warmupKicker: "Разогрев на сегодня",
        .leakKicker: "Утечка дня",
        .customDrillTitle: "Свой дрилл",
        .customDrillSubtitle: "Выбери позицию, стек и сценарий",
        .reviewMistakesTitle: "Разбор ошибок",
        .reviewMistakesSubtitle: "Пересмотри раздачи, где терял EV",

        .position: "Позиция",
        .stackDepth: "Стек",
        .scenario: "Сценарий",
        .allPositionsAllDepthsAllScenarios: "Все позиции · все стеки · все сценарии",
        .startDrill: "Начать дрилл",
        .buildADrill: "Собрать дрилл",

        .reviewTitle: "Разбор",
        .noHistoryYet: "Пока нет истории",
        .noHistoryHint: "Сыграй несколько раздач — здесь появятся ошибки и закономерности.",
        .mistakesLabel: "Ошибки",
        .closeLabel: "Близко",
        .correctLabel: "Верно",
        .allLabel: "Все",
        .trend: "Тренд",
        .deepDive: "Углубиться",
        .hideDeepDive: "Свернуть разбор",
        .showDeepDive: "Раскрыть разбор",
        .whereYouLeak: "Где сливаешь",
        .accuracyBySpot: "Точность по спотам",
        .byHandClass: "По типу рук",
        .mistakeReasons: "Причины ошибок",
        .patternsWeNoticed: "Замеченные паттерны",
        .reviewYourHands: "Пересмотри свои раздачи",
        .nothingMatchesFilter: "Под этот фильтр пока ничего нет.",
        .worstLabel: "Хуже всего",
        .scope7d: "7 дн",
        .scope30d: "30 дн",
        .scopeAll: "Всё",

        .youLabel: "ТЫ",
        .chartLabel: "ЧАРТ",
        .frequencies: "Частоты",
        .whyLabel: "Почему",
        .drillThisSpot: "Тренировать этот спот",

        .rangesTitle: "Диапазоны",
        .depth: "Стек",
        .actionMix: "Микс действий",
        .swipeToChangeDepth: "свайп — сменить стек",
        .noChartMatches: "Под эти фильтры чартов нет.",
        .searchRanges: "Поиск по диапазонам",
        .recentsAndFavorites: "Недавние и избранное",
        .favoriteThisChart: "В избранное",
        .unfavoriteThisChart: "Убрать из избранного",
        .rangeSearchPlaceholder: "напр. \"BTN 100\" или \"squeeze\"",
        .noChartsMatch: "Совпадений нет.",
        .bookmarksTitle: "Закладки",
        .recents: "Недавние",
        .favorites: "Избранное",
        .noChartsViewed: "Ещё ничего не смотрел.",
        .noFavoritesYet: "Пока пусто — добавь чарт звёздочкой.",

        .postflopTitle: "Постфлоп",

        .drillStandardRoutineTitle: "Стандартная разминка",
        .drillFirstInJamTitle: "Первым в банк джемом",
        .drillReJamTitle: "3-бет джем поверх опена",
        .drillCallJamTitle: "Колл олл-ина",
        .drillStealBlindsTitle: "Воровать блайнды",
        .drillVsManiacTitle: "Игра против маньяка",
        .drillMixedTitle: "Микс-дрилл",

        .drillStandardRoutineSubtitle: "Случайный префлоп — любая позиция, стек, сценарий.",
        .drillFirstInJamSubtitle: "12–25 BB · находи джем, не сливай мин-рейзами.",
        .drillReJamSubtitle: "15–30 BB · открыли — можешь ли ты пушнуть?",
        .drillCallJamSubtitle: "Колл, фолд или снап по цене.",
        .drillStealBlindsSubtitle: "Поздняя позиция, 20–40 BB · открывайся шире, когда не сопротивляются.",
        .drillVsManiacSubtitle: "25–40 BB · 3-бетят легко — фолди меньше, джемь больше.",
        .drillMixedSubtitle: "Микс живого MTT с уклоном 15–40 BB.",

        .actionFold: "Фолд",
        .actionCall: "Колл",
        .actionRaise: "Рейз",
        .actionThreeBet: "3-бет",
        .actionJam: "Джем",
        .actionMixed: "Микс",

        .preflopFold: "Фолд",
        .preflopCall: "Колл",
        .preflopMinRaise: "Мин-рейз",
        .preflopRaise25x: "Рейз 2.5x",
        .preflopRaise3x: "Рейз 3x",
        .preflopShove: "Олл-ин",
        .preflopLimp: "Лимп",
        .preflopLimpRaise: "Лимп-рейз",
        .shortJam: "Джем",
        .shortLRz: "Л-Рз",

        .postActionCheck: "Чек",
        .postActionBet33: "Ставка 33%",
        .postActionBet67: "Ставка 67%",
        .postActionBet100: "Ставка в банк",
        .postActionRaise: "Рейз",
        .postActionFold: "Фолд",
        .postActionCall: "Колл",
        .postActionShove: "Олл-ин",

        .facingUnopened: "RFI",
        .facingVsOpen: "vs опен",
        .facingVs3Bet: "vs 3-бет",
        .facingBlindDefense: "Защита блайндов",
        .facingSqueeze: "Сквиз",
        .facingPushFold: "Пуш/фолд",

        .headlineUnopened: "Первым в банк",
        .headlineVsOpen: "Против опена",
        .headlineVs3Bet: "Против 3-бета",
        .headlineBlindDefense: "Защита блайндов",
        .headlineSqueeze: "Сквиз-спот",
        .headlinePushFold: "Пуш или фолд",

        .villainStandard: "Стандартный рег",
        .villainLoose: "Луз-коллер",
        .villainManiac: "Маньяк",
        .villainNit: "Нит",
        .villainStandardNote: "Играет близко к разумному дефолту.",
        .villainLooseNote: "Колит широко — велью бей крупнее, блефуй меньше.",
        .villainManiacNote: "Открывается / 3-бетит легко — фолди меньше, джемь больше.",
        .villainNitNote: "Тайтовые диапазоны — верь давлению.",

        .hcPremiumPair: "Премиум-пары",
        .hcMidPair: "Средние пары",
        .hcSmallPair: "Мелкие пары",
        .hcSuitedAce: "Одномастные тузы",
        .hcOffsuitAce: "Разномастные тузы",
        .hcSuitedBroadway: "Одномастный бродвей",
        .hcOffsuitBroadway: "Разномастный бродвей",
        .hcSuitedKing: "Одномастные короли",
        .hcSuitedQueen: "Одномастные дамы",
        .hcSuitedConnector: "Одномастные коннекторы",
        .hcSuitedGapper: "Одномастные геппи",
        .hcOffsuitJunk: "Мусор оффсьют",

        .textureDryRainbow: "Сухой / радуга",
        .textureWetMonotone: "Мокрый / монотон",
        .texturePaired: "Спаренный",
        .textureConnected: "Связный",
        .textureBroadway: "Бродвей",
        .textureLowScatter: "Низкий разрозненный",

        .mrCorrect: "Верно",
        .mrMissedMix: "Промах в миксе",
        .mrTooTight: "Слишком тайтово",
        .mrTooLoose: "Слишком лузово",
        .mrWrongLine: "Не та линия",
        .mrOvercommit: "Перекомитил",
        .mrUndercommit: "Недокомитил",
        .mrShortCorrect: "Верно",
        .mrShortMix: "Микс",
        .mrShortTight: "Тайт",
        .mrShortLoose: "Луз",
        .mrShortWrongLine: "Линия",
        .mrShortOver: "Пере",
        .mrShortUnder: "Недо",

        .inPosition: "IP",
        .outOfPosition: "OOP",
        .potChip: "Банк",
        .effChip: "Эфф",

        .streakLabel: "дней подряд",

        .outcomeCorrect: "Верно",
        .outcomeAlmost: "Почти",
        .outcomeMistake: "Ошибка",
        .outcomeBigMistake: "Грубая ошибка",
        .youPlayed: "Ты сыграл",
        .chartWants: "Чарт хочет",
        .sameLine: "Та же линия",
        .viewRange: "Открыть диапазон",
        .nextHand: "Следующая",

        .drillAFewHands: "Сыграй несколько раздач",
        .noClosePeers: "Близких аналогов в этом чарте нет.",
        .playsSameWay: "Играется так же",
        .coolerEqualsMiss: "Холоднее = промах",
        .tournamentProfileTitle: "Параметры турнира",
        .bbUnit: "BB",
        .stackLabel: "Стек",
        .blindsLabel: "Блайнды",
        .levelsLabel: "Уровни",
        .minutesShort: "мин",
        .tableMaxSuffix: "-max MTT",
        .last7d: "За 7 дн",
        .last30d: "За 30 дн",
        .flatLabel: "Ровно",
    ]

    private static let ruZ: [Key: String] = [
        .appName: "MTT покер тренер",
        .loading: "грузим…",
        .cancel: "забить",
        .done: "всё",
        .clear: "снести",
        .start: "погнали",
        .search: "поиск",
        .more: "ещё",
        .hideMore: "скрыть",
        .showMore: "ещё",

        .tabTrain: "тренить",
        .tabRanges: "ренжи",
        .tabReview: "разбор",
        .tabSettings: "настройки",

        .onboardingSubtitle: "дрочи префлоп-споты из живых турников. без вот этого вашего теоркрафта.",
        .startTraining: "погнали гриндить",
        .customizeTournament: "настроить турик",

        .settingsTitle: "настройки",
        .editTournamentRules: "поменять правила турика",
        .resetOnboarding: "снести туториал",
        .language: "язык",
        .languageEnglish: "English",
        .languageRussian: "Русский",
        .languageRussianGenZ: "Русский (Gen Z)",

        .tournamentProfile: "профиль турика",
        .saveProfile: "сохранить (го)",
        .startingStack: "стартовый стак",
        .blinds: "блайнды",
        .blindSmall: "малый",
        .blindBig: "большой",
        .tableSize: "размер стола",
        .tableSize6: "6-макс",
        .tableSize8: "8-макс",
        .tableSize9: "9-макс",
        .blindLevelDuration: "длина уровня",
        .ante: "анте",
        .anteNone: "без анте",
        .anteClassic: "классика",
        .anteBigBlind: "BB-анте",
        .anteUnknown: "хз",
        .currentHeroStack: "сколько у тебя сейчас стак (мб)",
        .heroStackPlaceholder: "ну типа 18000",

        .startToTrack: "запусти раздачу, иначе точности не будет, братик.",
        .statAccuracy: "точность",
        .statHand: "раздача",
        .statHands: "раздач",
        .statToday: "сегодня",
        .continueLabel: "погнали дальше",
        .warmupKicker: "разогрев",
        .leakKicker: "сегодня сливаешь",
        .customDrillTitle: "свой дрилл",
        .customDrillSubtitle: "позиция · стек · сценарий — пуш",
        .reviewMistakesTitle: "разбор зашкваров",
        .reviewMistakesSubtitle: "пересмотри, где ливанул EV",

        .position: "позиция",
        .stackDepth: "стек",
        .scenario: "сценарий",
        .allPositionsAllDepthsAllScenarios: "все позиции · все стеки · все сценарии. изи.",
        .startDrill: "погнали дрилл",
        .buildADrill: "соберём дрилл",

        .reviewTitle: "разбор",
        .noHistoryYet: "истории пока нема",
        .noHistoryHint: "сыграй хоть пару раздач, потом расскажу где ты лажаешь.",
        .mistakesLabel: "зашквары",
        .closeLabel: "близко",
        .correctLabel: "топ",
        .allLabel: "всё",
        .trend: "тренд",
        .deepDive: "глубже",
        .hideDeepDive: "свернуть разбор",
        .showDeepDive: "раскрыть разбор",
        .whereYouLeak: "где ты сливаешь",
        .accuracyBySpot: "точность по спотам",
        .byHandClass: "по типу рук",
        .mistakeReasons: "почему лажа",
        .patternsWeNoticed: "увидели паттерны",
        .reviewYourHands: "пересмотри раздачи",
        .nothingMatchesFilter: "под этот фильтр пусто. кринж.",
        .worstLabel: "лютый зашквар",
        .scope7d: "7д",
        .scope30d: "30д",
        .scopeAll: "всё",

        .youLabel: "ТЫ",
        .chartLabel: "ЧАРТ",
        .frequencies: "частоты",
        .whyLabel: "почему",
        .drillThisSpot: "дрочить этот спот",

        .rangesTitle: "ренжи",
        .depth: "стек",
        .actionMix: "микс экшнов",
        .swipeToChangeDepth: "свайпни, чтоб поменять стек",
        .noChartMatches: "под эти фильтры чартов нема.",
        .searchRanges: "найти ренж",
        .recentsAndFavorites: "недавнее и избранное",
        .favoriteThisChart: "в избранное (го)",
        .unfavoriteThisChart: "из избранного — пас",
        .rangeSearchPlaceholder: "ну типа \"BTN 100\" или \"squeeze\"",
        .noChartsMatch: "ничего не нашлось, бро.",
        .bookmarksTitle: "закладки",
        .recents: "недавнее",
        .favorites: "избранное",
        .noChartsViewed: "ничё не смотрел пока.",
        .noFavoritesYet: "пусто. тыкни звезду на чарте.",

        .postflopTitle: "постфлоп",

        .drillStandardRoutineTitle: "база (стандарт)",
        .drillFirstInJamTitle: "джем первым",
        .drillReJamTitle: "ре-джем поверх опена",
        .drillCallJamTitle: "колл олл-ина",
        .drillStealBlindsTitle: "украсть блайнды",
        .drillVsManiacTitle: "vs маньяк",
        .drillMixedTitle: "микс-дрилл",

        .drillStandardRoutineSubtitle: "рандомный префлоп — любая позиция, стек, сценарий. ну изи.",
        .drillFirstInJamSubtitle: "12–25 ББ · находи джем, не сливай мин-рейзами как лох.",
        .drillReJamSubtitle: "15–30 ББ · опен сверху — пушнёшь или сольёшь?",
        .drillCallJamSubtitle: "снап, колл или фолд по цене. думай быстро.",
        .drillStealBlindsSubtitle: "поздняя позиция, 20–40 ББ · вскрывай шире, если все терпят.",
        .drillVsManiacSubtitle: "25–40 ББ · бро 3-бетит на воздухе — фолди меньше, джемь больше.",
        .drillMixedSubtitle: "микс живого MTT, уклон 15–40 ББ.",

        .actionFold: "слив",
        .actionCall: "кол",
        .actionRaise: "рейз",
        .actionThreeBet: "3-бет",
        .actionJam: "джем",
        .actionMixed: "микс",

        .preflopFold: "слив",
        .preflopCall: "кол",
        .preflopMinRaise: "мин-рейз",
        .preflopRaise25x: "рейз 2.5x",
        .preflopRaise3x: "рейз 3x",
        .preflopShove: "пуш",
        .preflopLimp: "лимп",
        .preflopLimpRaise: "лимп-рейз",
        .shortJam: "джем",
        .shortLRz: "л-рз",

        .postActionCheck: "чек",
        .postActionBet33: "бет 33%",
        .postActionBet67: "бет 67%",
        .postActionBet100: "бет в банк",
        .postActionRaise: "рейз",
        .postActionFold: "слив",
        .postActionCall: "кол",
        .postActionShove: "пуш",

        .facingUnopened: "RFI",
        .facingVsOpen: "vs опен",
        .facingVs3Bet: "vs 3-бет",
        .facingBlindDefense: "защита блайндов",
        .facingSqueeze: "сквиз",
        .facingPushFold: "пуш/слив",

        .headlineUnopened: "первым в банк",
        .headlineVsOpen: "лицом к опену",
        .headlineVs3Bet: "лицом к 3-бету",
        .headlineBlindDefense: "защищаем блайнды",
        .headlineSqueeze: "сквиз-спот",
        .headlinePushFold: "пуш или слив",

        .villainStandard: "рег по дефолту",
        .villainLoose: "луз-коллер",
        .villainManiac: "маньяк",
        .villainNit: "нит",
        .villainStandardNote: "играет ровно, без сюрпризов.",
        .villainLooseNote: "колит всё подряд — велью бей крупнее, блеф в топку.",
        .villainManiacNote: "3-бетит на воздухе — фолди меньше, джемь больше.",
        .villainNitNote: "ренжи как у нита-старичка — верь его давлению.",

        .hcPremiumPair: "премиум-пары",
        .hcMidPair: "средние пары",
        .hcSmallPair: "мелкие пары",
        .hcSuitedAce: "тузы в масть",
        .hcOffsuitAce: "тузы оффсьют",
        .hcSuitedBroadway: "бродвей в масть",
        .hcOffsuitBroadway: "бродвей оффсьют",
        .hcSuitedKing: "короли в масть",
        .hcSuitedQueen: "дамы в масть",
        .hcSuitedConnector: "коннекторы в масть",
        .hcSuitedGapper: "геппи в масть",
        .hcOffsuitJunk: "мусор оффсьют",

        .textureDryRainbow: "сухая / радуга",
        .textureWetMonotone: "мокрая / монотон",
        .texturePaired: "спаренная",
        .textureConnected: "связная",
        .textureBroadway: "бродвей",
        .textureLowScatter: "мелочь врассыпную",

        .mrCorrect: "топ",
        .mrMissedMix: "промах в миксе",
        .mrTooTight: "слишком тайт",
        .mrTooLoose: "слишком луз",
        .mrWrongLine: "не та линия",
        .mrOvercommit: "перекомитил",
        .mrUndercommit: "недокомитил",
        .mrShortCorrect: "топ",
        .mrShortMix: "микс",
        .mrShortTight: "тайт",
        .mrShortLoose: "луз",
        .mrShortWrongLine: "линия",
        .mrShortOver: "пере",
        .mrShortUnder: "недо",

        .inPosition: "IP",
        .outOfPosition: "OOP",
        .potChip: "банк",
        .effChip: "эфф",

        .streakLabel: "дней на стрике",

        .outcomeCorrect: "топ",
        .outcomeAlmost: "почти",
        .outcomeMistake: "лажа",
        .outcomeBigMistake: "лютый зашквар",
        .youPlayed: "ты сыграл",
        .chartWants: "чарт хочет",
        .sameLine: "та же линия",
        .viewRange: "глянуть ренж",
        .nextHand: "следующая",

        .drillAFewHands: "сыграй пару раздач",
        .noClosePeers: "близких аналогов в этом чарте нема.",
        .playsSameWay: "играется так же",
        .coolerEqualsMiss: "холоднее = слив",
        .tournamentProfileTitle: "профиль турика",
        .bbUnit: "ББ",
        .stackLabel: "стек",
        .blindsLabel: "блайнды",
        .levelsLabel: "уровни",
        .minutesShort: "мин",
        .tableMaxSuffix: "-макс турик",
        .last7d: "за 7 дн",
        .last30d: "за 30 дн",
        .flatLabel: "ровно",
    ]
}
