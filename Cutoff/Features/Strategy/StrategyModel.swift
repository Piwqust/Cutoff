import Foundation
import Observation

/// Reactive source of truth for which chapters the user has marked "studied".
/// Backed by `UserDefaults` but exposed through an `@Observable` set so SwiftUI
/// views update automatically — no manual `.id()` redraw hacks needed.
@MainActor
@Observable
final class StrategyProgressStore {
    static let shared = StrategyProgressStore()

    private static let storageKey = "strategy.completedChapters"

    /// Completion keys in the form `"<weekId>.<chapterId>"`.
    private(set) var completed: Set<String>

    init() {
        let stored = UserDefaults.standard.stringArray(forKey: Self.storageKey) ?? []
        completed = Set(stored)
        migrateLegacyKeysIfNeeded()
    }

    private func key(week: String, chapter: Int) -> String { "\(week).\(chapter)" }

    func isStudied(week: String, chapter: Int) -> Bool {
        completed.contains(key(week: week, chapter: chapter))
    }

    func setStudied(_ studied: Bool, week: String, chapter: Int) {
        let k = key(week: week, chapter: chapter)
        if studied { completed.insert(k) } else { completed.remove(k) }
        persist()
    }

    func toggle(week: String, chapter: Int) {
        setStudied(!isStudied(week: week, chapter: chapter), week: week, chapter: chapter)
    }

    private func persist() {
        UserDefaults.standard.set(Array(completed), forKey: Self.storageKey)
    }

    /// One-time migration from the old per-chapter boolean keys
    /// (`"strategy.completed.<week>.<chapter>"`) to the consolidated set.
    private func migrateLegacyKeysIfNeeded() {
        let defaults = UserDefaults.standard
        var migrated = false
        for guide in StrategyStore.allGuides {
            for chapter in guide.chapters {
                let legacyKey = "strategy.completed.\(guide.id).\(chapter.id)"
                if defaults.object(forKey: legacyKey) != nil {
                    if defaults.bool(forKey: legacyKey) {
                        completed.insert(key(week: guide.id, chapter: chapter.id))
                    }
                    defaults.removeObject(forKey: legacyKey)
                    migrated = true
                }
            }
        }
        if migrated { persist() }
    }
}

struct StrategyChapter: Identifiable, Hashable {
    var id: Int // 1 to 5 corresponding to the 5 themes
    let icon: String // SF Symbol
    let tag: String // Category label (e.g. Preflop, Postflop, Math)
    
    // Localized values based on language
    func title(for lang: AppLanguage) -> String {
        switch lang {
        case .english: return engTitle
        case .russian: return ruTitle
        case .russianGenZ: return ruGenzTitle
        }
    }
    
    func shortDescription(for lang: AppLanguage) -> String {
        switch lang {
        case .english: return engShortDesc
        case .russian: return ruShortDesc
        case .russianGenZ: return ruGenzShortDesc
        }
    }
    
    func whatsDo(for lang: AppLanguage) -> String {
        switch lang {
        case .english: return engWhatsDo
        case .russian: return ruWhatsDo
        case .russianGenZ: return ruGenzWhatsDo
        }
    }
    
    func why(for lang: AppLanguage) -> String {
        switch lang {
        case .english: return engWhy
        case .russian: return ruWhy
        case .russianGenZ: return ruGenzWhy
        }
    }

    /// The "why" explanation with the embedded 📖 hand example stripped out,
    /// so the reasoning and the worked example can live in separate cards.
    func whyReason(for lang: AppLanguage) -> String {
        let full = why(for: lang)
        return full.components(separatedBy: "📖").first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? full
    }

    /// The embedded live-hand example, split into (title, body). Nil when the
    /// chapter has no 📖 scenario (e.g. archived weeks).
    func whyScenario(for lang: AppLanguage) -> (title: String, body: String)? {
        let parts = why(for: lang).components(separatedBy: "📖")
        guard parts.count > 1 else { return nil }
        let raw = parts[1...].joined(separator: "📖").trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = raw.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
        let title = lines.first.map {
            $0.trimmingCharacters(in: CharacterSet(charactersIn: " :"))
        } ?? "Пример"
        let body = lines.count > 1 ? String(lines[1]).trimmingCharacters(in: .whitespacesAndNewlines) : ""
        return (title, body)
    }

    /// Localized category badge. English keeps the canonical poker terms; the
    /// Russian registers get their standard translated equivalents so the chip
    /// doesn't read as mixed-language inside an otherwise Russian UI.
    func localizedTag(for lang: AppLanguage) -> String {
        guard lang != .english else { return tag }
        switch tag.lowercased() {
        case "preflop":   return "Префлоп"
        case "postflop":  return "Постфлоп"
        case "push/fold": return "Пуш-Фолд"
        case "math":      return "Математика"
        default:          return tag
        }
    }
    
    // Raw localized strings
    let engTitle: String
    let ruTitle: String
    let ruGenzTitle: String
    
    let engShortDesc: String
    let ruShortDesc: String
    let ruGenzShortDesc: String
    
    let engWhatsDo: String
    let ruWhatsDo: String
    let ruGenzWhatsDo: String
    
    let engWhy: String
    let ruWhy: String
    let ruGenzWhy: String
}

struct WeeklyGuide: Identifiable, Hashable {
    let id: String // Key like "2026-06-01"
    let date: Date
    
    func title(for lang: AppLanguage) -> String {
        switch lang {
        case .english: return engTitle
        case .russian: return ruTitle
        case .russianGenZ: return ruGenzTitle
        }
    }
    
    func subtitle(for lang: AppLanguage) -> String {
        switch lang {
        case .english: return engSubtitle
        case .russian: return ruSubtitle
        case .russianGenZ: return ruGenzSubtitle
        }
    }
    
    let engTitle: String
    let ruTitle: String
    let ruGenzTitle: String
    
    let engSubtitle: String
    let ruSubtitle: String
    let ruGenzSubtitle: String
    
    let chapters: [StrategyChapter]
}

enum StrategyStore {
    static let allGuides: [WeeklyGuide] = [
        // Week 1: Current Week (Active)
        WeeklyGuide(
            id: "2026-06-01",
            date: DateComponents(calendar: .current, year: 2026, month: 6, day: 1).date ?? Date(),
            engTitle: "Controlled Aggression & Live MTT Exploits",
            ruTitle: "Контролируемая агрессия и эксплойты в живых МТТ",
            ruGenzTitle: "Агрессивный врыв и разнос пассивных полей",
            engSubtitle: "Week of June 1, 2026",
            ruSubtitle: "Неделя от 1 июня 2026",
            ruGenzSubtitle: "Катка от 1 июня 2026",
            chapters: [
                StrategyChapter(
                    id: 1,
                    icon: "scalemass.fill",
                    tag: "Preflop",
                    engTitle: "Open Sizes & Limper Isolation Formula",
                    ruTitle: "Размеры опен-рейзов и изоляция лимперов",
                    ruGenzTitle: "Сайзинги опен-рейзов и карательный изолейт",
                    engShortDesc: "Optimize preflop sizes and punish weak players entering with a flat call.",
                    ruShortDesc: "Оптимизируйте префлоп-сайзинги и наказывайте слабых лимперов.",
                    ruGenzShortDesc: "Прекрати минрейзить в лимперов. Считаем идеальный карательный сайзинг.",
                    engWhatsDo: "• Open Raise: 2.2x to 2.5x BB when deep (>40bb), decreasing to 2.0x BB (min-raise) when stack <30bb.\n• In-Position Isolation: 4.0x BB + 1.0x BB for each limper in the pot.\n• Out-of-Position Isolation: 5.0x BB + 1.0x BB for each limper.",
                    ruWhatsDo: "• Открывающий рейз: 2.2x-2.5x BB при глубоком стеке (>40bb). Снижайте до 2.0x BB (мин-рейз) при стеке <30bb.\n• Изоляция в позиции (IP): 4.0x BB + 1.0x BB за каждого лимпера в банке.\n• Изоляция вне позиции (OOP): 5.0x BB + 1.0x BB за каждого лимпера.",
                    ruGenzWhatsDo: "• Стандартный опен: 2.2x-2.5x ББ на дипстеках (>40 ББ). На коротких стеках (<30 ББ) катай строго минрейзом 2.0x.\n• Изоляция в позиции (IP): заряжай 4 ББ + 1 ББ за каждого лимпера.\n• Изоляция без позы (OOP): фигачь 5 ББ + 1 ББ за каждого лимпера.",
                    engWhy: "Limping indicates a weak, capped preflop range. Raising isolating sizes denies their equity and plays a bloated pot heads-up with positional advantage.\n\n📖 SCENARIO:\nBlinds 100/200, ante 200. EP limps (200). You are on the BTN with AsQd. Instead of a standard 2.2x raise (440), you isolate to 5x BB (1000). The blinds fold, the EP limper calls. Flop is Kh-8d-3c. Opponent checks. You fire a C-bet of 350 (1/3 pot) and they fold instantly. Easy pot won preflop!",
                    ruWhy: "Лимперы входят в игру со слабым спектром. Наша укрупненная ставка изолирует слабого игрока один на один, забирая инициативу и выбивая блайнды.\n\n📖 ПРИМЕР ИЗ ИГРЫ:\nБлайнды 100/200, анте 200. EP играет лимп (колл 200). У вас на баттоне AsQd. Вместо стандартного рейза в 450 вы делаете изолейт 5 BB (1000 фишек). Блайнды выкидывают, лимпер коллирует без позиции. На флопе Kh-8d-3c оппонент чекает. Вы ставите мелкий C-bet 350 фишек (1/3 пота) и оппонент мгновенно сбрасывает. Банк взят!",
                    ruGenzWhy: "Лимперы — это ходячие фишки с мусорными картами. Большой сайзинг заставляет их платить за просмотр флопа без позы.\n\n📖 ЖИЗНЕННЫЙ СПОТ:\nБлайнды 100/200, анте 200. Лимп из ранней. У тебя AsQd на баттоне. Заряжаем карательный изолейт 5 ББ (1000 фишек). Блайнды пас, лимпер колл. Флоп Kh-8d-3c, опп чек. Ты лепишь контбет 1/3 пота (350 фишек) — оппонент инста-пас. Изи налутанный банк!"
                ),
                StrategyChapter(
                    id: 2,
                    icon: "crown.fill",
                    tag: "Preflop",
                    engTitle: "Blind Stealing Ranges from CO / BTN / SB",
                    ruTitle: "Диапазоны кражи блайндов (CO / BTN / SB)",
                    ruGenzTitle: "Безжалостный стил блайндов с баттона и катоффа",
                    engShortDesc: "Widen your opening ranges to exploit passive nits on the blinds.",
                    ruShortDesc: "Расширяйте диапазон открытия, чтобы красть блайнды у пассивных оппонентов.",
                    ruGenzShortDesc: "Пассивные блайнды буквально дарят фишки. Расширяем спектр стила до предела.",
                    engWhatsDo: "• Against tight or passive blinds (Fold to Steal > 70%), widen your BTN opening range to 55-65%.\n• Play all suited cards, any Ace, K2s+, Q6s+, JT-54s, J9s-75s.\n• Steal with small sizes (2.0x-2.2x BB) to risk the minimum amount of chips.",
                    ruWhatsDo: "• Если на блайндах сидят тайтовые оппоненты (Fold to Steal > 70%), расширяйте стил с BTN до 55-65% диапазона.\n• Открывайте все одномастные карты, любых тузов, K2s+, Q6s+, коннекторы и гапперы.\n• Открывайтесь мелким размером (2.0x-2.2x BB), чтобы минимизировать риск.",
                    ruGenzWhatsDo: "• Видишь тайтовых нитов на блайндах (Fold to Steal > 70%)? Раздувай спектр стила с баттона до 60%.\n• Открывай все одномастные карты, любые тузы, K2s+, Q6s+, коннекторы и гапперы.\n• Стиль мелким сайзингом — 2.0x-2.2x ББ, чтобы кража стоила дешево.",
                    engWhy: "Tight players defend their blinds far less than GTO recommends, giving you immediate preflop auto-profit.\n\n📖 SCENARIO:\nEffective stack 35bb. You are on the BTN with Jd8d. SB and BB are tight players. You open to 2.2x BB. Both opponents fold. You win blinds and antes (2.5bb total) with zero postflop risk.",
                    ruWhy: "Тайтовые любители защищают блайнды только с премиум-картами. Открываясь шире, вы забираете мертвые деньги без риска.\n\n📖 ПРИМЕР ИЗ ИГРЫ:\nСтек 35bb. Вы на BTN с Jd8d. На блайндах тайтовые регуляры. Вы делаете рейз 2.2 BB. Оба оппонента сбрасывают. Вы забираете блайнды и анте (2.5 BB) абсолютно без риска.",
                    ruGenzWhy: "Любители боятся защищать блайнды без хороших карт. Мы просто забираем блайнды и анте на автопилоте.\n\n📖 ЖИЗНЕННЫЙ СПОТ:\nСтек 35 ББ. У тебя Jd8d на баттоне. Блайнды — супер-ниты. Ты делаешь опен-рейз 2.2 ББ. Оба оппа скидывают карты. Ты налутал 2.5 ББ без боя на флопе!"
                ),
                StrategyChapter(
                    id: 3,
                    icon: "flame.fill",
                    tag: "Push/Fold",
                    engTitle: "ChipEV Push-Fold Strategy (12-18 BB)",
                    ruTitle: "Математика Пуш-Фолда в ChipEV (12-18 BB)",
                    ruGenzTitle: "First-in Jam по ChipEV: уничтожение шорт-стеком",
                    engShortDesc: "When to jam — and when 13–18 BB lets you mix in a min-raise. Pure ChipEV, no ICM.",
                    ruShortDesc: "Когда пушить, а когда на 13–18 ББ подмешать мин-рейз. Чистый ChipEV без ICM.",
                    ruGenzShortDesc: "На 12 ББ твой бро — олл-ин. На 15–18 ББ подключаем минрейз премиумом. Считаем по ChipEV.",
                    engWhatsDo: "• ≤12 BB: pure Push-Fold is optimal — jam or fold, no min-raises.\n• 12 BB BTN jam range: 22+, A2s+, A3o+, K9s+, KTo+, QTs+, QJo, JTs, T9s.\n• 13–18 BB: the highest-EV play is a MIX — min-raise your premiums (to play post-flop in position) and jam the rest. Pure jamming is the simpler, lower-variance baseline if you're not yet confident post-flop.\n• 15 BB BTN jam baseline: 22+, A2s+, A7o+, KTs+, KTo+, QTs+, JTs.",
                    ruWhatsDo: "• До 12 ББ: чистый Пуш-Фолд оптимален — только олл-ин или пас, без мин-рейзов.\n• Диапазон пуша (BTN) при 12 ББ: карманные пары 22+, все одномастные тузы, разномастные тузы от A3o+, K9s+, KTo+, QTs+, QJo, JTs, T9s.\n• 13–18 ББ: максимально прибыльна СМЕШАННАЯ стратегия — мин-рейз с премиумом (чтобы играть постфлоп в позиции) и пуш остальным диапазоном. Чистый пуш — простой и низкодисперсный базис, если вы пока не уверены в постфлопе.\n• Базовый диапазон пуша (BTN) при 15 ББ: 22+, A2s+, A7o+, KTs+, KTo+, QTs+, JTs.",
                    ruGenzWhatsDo: "• До 12 ББ: чистый пуш-фолд — это закон. Только олл-ин или пас, без минрейзов.\n• Диапазон пуша с BTN при 12 ББ: 22+, A2s+, A3o+, K9s+, KTo+, QTs+, QJo, JTs, T9s.\n• 13–18 ББ: топ по EV — это МИКС: минрейзь премиум (чтобы катать постфлоп в позе) и пуш остальным. Чистый пуш — изи-режим с низкой дисперсией, если постфлоп пока не твоё.\n• Базовый пуш-диапазон с BTN при 15 ББ: 22+, A2s+, A7o+, KTs+, KTo+, QTs+, JTs.",
                    engWhy: "Raise-folding with a short stack burns too much valuable equity. Going all-in maximizes fold equity and protects your equity from multi-way sticky flops. Above ~13–15 BB you keep enough behind to min-raise premiums and realize post-flop equity in position — modern solvers show this mix beats pure jamming.\n\n📖 SCENARIO:\nStack 12bb. You hold KTo on the BTN. If you min-raise to 2bb and receive a shove from the BB, you must fold, losing 17% of your stack. Shoving directly forces hands like A2o-A5o and QJo to fold, which have huge equity against you.",
                    ruWhy: "Рейз-фолд с коротким стеком сжигает фишки. Прямой олл-ин заставляет оппонентов выбрасывать сильные живые карты. Но начиная с ~13–15 ББ за спиной остаётся достаточно фишек, чтобы мин-рейзить премиум и играть постфлоп в позиции — современные солверы показывают, что такой микс прибыльнее чистого пуша.\n\n📖 ПРИМЕР ИЗ ИГРЫ:\nСтек 12bb. У вас KTo на BTN. Если вы сыграете мин-рейз до 2bb и получите олл-ин от BB, вам придется выбросить руку, потеряв 17% своего стека. Прямой пуш заставляет BB выкинуть руки типа A2o-A5o, QJo, которые имеют отличное эквити против вашей руки.",
                    ruGenzWhy: "Делать рейз-фолд на коротыше — это слив. Прямой олл-ин генерирует тонну фолд-эквити и выбивает доминирующие руки соперников. Но с ~13–15 ББ за спиной остаётся достаточно фишек, чтобы минрейзить премиум и катать постфлоп в позе — по солверам этот микс жирнее чистого пуша.\n\n📖 ЖИЗНЕННЫЙ СПОТ:\nСтек 12 ББ. У тебя KTo на баттоне. Сыграешь минрейз 2 ББ и получишь пуш от ББ — придется фолдить, подарив 17% стека. Пихаешь олл-ин сразу — ББ выкидывает руки типа A3o, QJo. Банк твой!"
                ),
                StrategyChapter(
                    id: 4,
                    icon: "circle.grid.3x3.fill",
                    tag: "Postflop",
                    engTitle: "Continuation Bets (C-Bet) Dry vs. Wet Boards",
                    ruTitle: "Контбеты на сухих и дровяных флопах",
                    ruGenzTitle: "Умные контбеты: изи-фолды и жесткий добор",
                    engShortDesc: "Sizing and frequency guidelines based on flop coordination.",
                    ruShortDesc: "Правила частоты и сайзингов C-bet в зависимости от структуры доски.",
                    ruGenzShortDesc: "Флоп K-7-2 радуга и Q-J-9 с флеш-дро требуют абсолютно разной игры. Разбор.",
                    engWhatsDo: "• Dry Boards (e.g. Ks-7d-2c): C-bet high frequency (80%+), small sizing (25-33% pot) with your entire range.\n• Wet Boards (e.g. Qc-Jd-9s): C-bet low frequency (30-40%), large sizing (65-75% pot) only with strong value hands and monsters draws.\n• LIVE EXPLOIT: Against calling stations, size up slightly. If they float 33% bets, use larger bets/overbets on dry boards to exploit their attachment to high cards.",
                    ruWhatsDo: "• Сухие флопы (например, Ks-7d-2c): Ставьте очень часто (80%+), мелким размером (25-33% пота) со всем вашим диапазоном.\n• Дровяные флопы (например, Qc-Jd-9s): Ставьте редко (30-40%), крупным размером (65-75% пота) только со своими сильными готовыми руками и монстр-дро.\n• ЭКСПЛОЙТ В ЖИВОЙ ИГРЕ: Против телефонов увеличивайте сайзинг. Если они тащат на ставки 33%, используйте овербеты на сухих досках, чтобы выбить их старшие карты.",
                    ruGenzWhatsDo: "• Сухой флоп (Ks-7d-2c радуга): лупи контбет 1/3 пота почти со всем ренжем (частота 80%+).\n• Мокрый флоп (Qc-Jd-9s с флеш-дро): играй аккуратно (частота 35%). Ставь крупно (65%-75% пота) только на плотное велью или с монстр-дро. Остальное — чек/фолд.\n• ЖИВОЙ ЭКСПЛОЙТ: Если за столом телефоны, которые не верят в 1/3 пота — заряжай плотнее. На сухих досках можно даже лепить овербеты, чтобы выбить их любимые картинки.",
                    engWhy: "On dry boards, the opponent misses completely and folds to any small bet. On wet boards, calling stations call any small bet with draw or pairs, so you must charge draws heavily.\n\n📖 SCENARIO:\nAs BTN open-raiser, you hit a flop of Ks-7h-2c. BB checks. You hold QdJd (air). You fire a C-bet of 33% pot. BB folds 9d8d instantly. On a flop of Qc-Jd-9c with QdJd, you check back. GTO range connects heavily with BB's caller range, making a C-bet bluff highly unprofitable.",
                    ruWhy: "На сухих досках оппонент часто промахивается и фолдит на мелкую ставку. На мокрых досках соперники коллируют по любым совпадениям — нужно добирать или чекать.\n\n📖 ПРИМЕР ИЗ ИГРЫ:\nВы открылись на баттоне, BB коллировал. Флоп: Ks-7h-2c. У вас QdJd (воздух). Вы ставите контбет 33% пота. Оппонент сбрасывает 9d8d. На флопе Qc-Jd-9c с той же QdJd вы играете чек вслед, так как эта доска идеально подходит диапазону колла BB.",
                    ruGenzWhy: "Сухой флоп соперник зацепить не может, мелкая ставка 30% пота заставит его сдаться. На мокром флопе телефоны потащат любое совпадение — блефовать мелко нельзя.\n\n📖 ЖИЗНЕННЫЙ СПОТ:\nТы открылся на BTN, ББ колл. Флоп Ks-7h-2c. У тебя QdJd (воздух). Ты ставишь контбет 1/3 пота. Опп фолдит 9d8d. На мокром флопе Qc-Jd-9c с той же QdJd — чекаем вслед, опп зацепился 100%!"
                ),
                StrategyChapter(
                    id: 5,
                    icon: "brain.head.profile",
                    tag: "Math",
                    engTitle: "Mental Pot Odds & Equity Calculations",
                    ruTitle: "Ментальный расчет банка и пот-оддсов",
                    ruGenzTitle: "Сверхбыстрый расчет шансов банка и эквити в уме",
                    engShortDesc: "Instantly estimate draw probabilities and required calling equity.",
                    ruShortDesc: "Мгновенная методика оценки вероятностей в уме во время живой раздачи.",
                    ruGenzShortDesc: "Сложно считать в уме за столом? Правило 2 и 4 + простая формула цены колла.",
                    engWhatsDo: "• Draw Equity: Flop: Outs x 4 = % Equity. Turn: Outs x 2 = % Equity.\n• Pot Odds: Call Amount / (Total Pot + Bet + Call) = % Required Equity.\n• Shortcut Table: 1/3 pot bet needs 20% equity; 1/2 pot needs 25%; full pot needs 33% equity.",
                    ruWhatsDo: "• Расчет эквити: На флопе: Кол-во аутов х 4 = % Эквити. На терне: Кол-во аутов х 2 = % Эквити.\n• Пот-оддсы: Сумма колла / (Общий банк + Ставка + Колл) = % Требуемого Эквити.\n• Шпаргалка в уме: Колл ставки 33% пота требует 20% эквити; ставки 50% пота — 25% эквити; ставки 100% пота — 33% эквити.",
                    ruGenzWhatsDo: "• Эквити (шанс доехать): Флоп: Ауты х 4 = % Эквити. Тёрн: Ауты х 2 = % Эквити.\n• Пот-оддсы (цена билета): Колл / (Банк + Ставка + Твой Колл) = сколько % эквити нужно.\n• Шпаргалка: опп ставит 1/3 пота -> надо 20% эквити. Ставит 1/2 пота -> надо 25% эквити. Ставит пот -> надо 33%.",
                    engWhy: "Math is the absolute defense against burning chips. If your draw equity (Rule of 2/4) is greater than the required pot odds, it is a mathematically profitable (+EV) call.\n\n📖 SCENARIO:\nOn the turn, there is 1000 in the pot. Opponent bets 500 (1/2 pot). You hold a flush draw (9 outs). Call amount is 500. Pot odds needed = 500 / 2000 = 25%. Your equity = 9 outs x 2 = 18%. Since your equity (18%) is LESS than required pot odds (25%), a raw call is mathematically unprofitable (-EV). Fold immediately!",
                    ruWhy: "Математика предохраняет вас от пустых трат. Если ваше эквити больше пот-оддсов — это прибыльный колл. Если меньше — это слив фишек.\n\n📖 ПРИМЕР ИЗ ИГРЫ:\nНа терне в банке 1000 фишек. У вас флеш-дро (9 аутов). Оппонент ставит 500 фишек (1/2 пота). Вам нужно коллировать 500. Цена колла (пот-оддсы) = 500 / (1000 + 500 + 500) = 25%. По правилу 2 и 4 на терне ваше эквити = 9 аутов х 2 = 18%. Поскольку ваше эквити (18%) МЕНЬШЕ пот-оддсов (25%), колл невыгоден. Фолд!",
                    ruGenzWhy: "Это твоя защита от бездумного дарения фишек. Если шанс доехать выше, чем цена колла — жми колл (+EV). Иначе — легкий пас.\n\n📖 ЖИЗНЕННЫЙ СПОТ:\nНа тёрне в банке 1000. Опп ставит 500 (1/2 пота). У тебя флеш-дро (9 аутов). Для колла надо 500. Пот-оддсы = 25% нужного эквити. Твое эквити = 9 х 2 = 18%. Твои 18% меньше нужных 25% — колл минусовый. Жми фолд!"
                )
            ]
        ),
        
        // Week 0: Historical Week (Archive)
        WeeklyGuide(
            id: "2026-05-25",
            date: DateComponents(calendar: .current, year: 2026, month: 5, day: 25).date ?? Date(),
            engTitle: "Solid TAG Foundations & EV Preservation",
            ruTitle: "Основы дисциплины TAG и сохранение стека",
            ruGenzTitle: "Железный TAG-деф и сохранение драгоценных ББ",
            engSubtitle: "Week of May 25, 2026",
            ruSubtitle: "Неделя от 25 мая 2026",
            ruGenzSubtitle: "Катка от 25 мая 2026",
            chapters: [
                StrategyChapter(
                    id: 1,
                    icon: "shield.fill",
                    tag: "Preflop",
                    engTitle: "Preflop Tightness & Hand Selection",
                    ruTitle: "Жесткий отбор стартовых рук",
                    ruGenzTitle: "Фолд мусора на префлопе — залог выживания",
                    engShortDesc: "Discipline is your main weapon. Fold junk cards early.",
                    ruShortDesc: "Дисциплина — главное оружие. Сбрасывайте маргинальные карты на ранних позициях.",
                    ruGenzShortDesc: "Перестань играть руки вроде KTo и QJo из ранних полей. Будь железным скалой.",
                    engWhatsDo: "• Keep preflop VPIP strict around 18-20%.\n• Fold marginal offsuit cards (KTo, QJo, A2o-A9o) in early and middle positions.\n• Enter only with strong pairs, suited Aces, and broadways.",
                    ruWhatsDo: "• Держите показатель VPIP в районе 18-20%.\n• Безжалостно сбрасывайте разномастные офф-карты (KTo, QJo, A2o-A9o) в ранних и средних позициях.\n• Входите в игру только с сильными парами, одномастными тузами и бродвеем.",
                    ruGenzWhatsDo: "• VPIP строго на отметке 18-20%. Никакого спева префлоп.\n• Разномастный мусор типа KTo, QJo, слабые тузы A2o-A9o — сразу летят в пас из ранних поз.\n• Играй только карманки, одномастных тузов и сильный бродвей. Защити себя от глупых раздач.",
                    engWhy: "Playing tight hand selection avoids marginal and tricky spots postflop where amateur players leak their initial stacks out of position.",
                    ruWhy: "Тайтовый диапазон префлопа страхует вас от сложных маргинальных ситуаций на постфлопе вне позиции, где неопытные игроки чаще всего теряют фишки.",
                    ruGenzWhy: "Тайтовый спектр защищает тебя от тяжелых решений без позы postflop. Пока соперники лудоходят и бьются лбами, ты спокойно забираешь фишки с сильными картами."
                ),
                StrategyChapter(
                    id: 2,
                    icon: "arrow.up.forward.square.fill",
                    tag: "Preflop",
                    engTitle: "Standard Deep Stack Sizing",
                    ruTitle: "Стандартные префлоп сайзинги открытия",
                    ruGenzTitle: "Сайзинги на глубоких стеках: без лишней грязи",
                    engShortDesc: "How to size open raises on deep stacks to maintain pot control.",
                    ruShortDesc: "Размеры открывающих ставок на глубоких стеках для контроля банка.",
                    ruGenzShortDesc: "Не раздувай банки с плохими картами. Держим сайзинги под контролем.",
                    engWhatsDo: "• In early stages (stack >60 BB), use 2.2x to 2.5x BB open size.\n• Maintain consistent sizing regardless of hand strength.\n• Do not open limping yourself — raise first in or fold.",
                    ruWhatsDo: "• На ранних уровнях (стек >60 BB) открывайтесь размером 2.2x-2.5x BB.\n• Используйте одинаковый сайзинг для всех разыгрываемых рук preflop.\n• Никогда не заходите лимпом сами — либо рейз, либо фолд.",
                    ruGenzWhatsDo: "• На ранней стадии турнира (стек >60 ББ) открывайся плотнее — 2.2x-2.5x ББ.\n• Держи сайзинг одинаковым — соперники не должны читать твои тузы по размеру рейза.\n• Забыть про первый лимп! Если заходишь первым — делай рейз. Нет силы — жми фолд.",
                    engWhy: "Limping allows opponents to see the flop cheap and outdraw your good hands. Flat, consistent open sizes build stable pots for value hands.",
                    ruWhy: "Лимп позволяет оппонентам дешево заходить в банк и переезжать ваши сильные руки. Единообразные сайзинги рейза строят оптимальные банки для сильного диапазона.",
                    ruGenzWhy: "Сам никогда не лимпуй — лимп-колл preflop сжигает EV и дарит оппонентам бесплатную информацию. Открывайся рейзом, чтобы сразу забрать банк или играть хедз-ап с инициативой."
                )
            ]
        )
    ]
    
    static var activeGuide: WeeklyGuide {
        allGuides.first!
    }
}
