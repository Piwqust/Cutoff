import SwiftUI

/// Hidden editor/developer handbook for the Strategy tab.
/// Opened by tapping the Strategy navigation title 5× (see `StrategyGuideView`).
///
/// The source of truth is the `docText` Markdown string — the copy button
/// hands the whole thing to a person or an AI assistant verbatim. The view
/// renders it as lightly-styled blocks (headings, bullets, code) so a long
/// document stays readable on device.
struct DeveloperStrategyDocView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var didCopy = false

    private let docText = """
    # Cutoff — Руководство редактора и разработчика

    Внутренний справочник по вкладке «Стратегия» и по приложению в целом. \
    Кнопка «копировать» (вверху справа) выдаёт весь этот текст в Markdown — \
    передавайте его разработчику или ИИ-ассистенту целиком.

    _Обновлено: 2026-06-02._

    ## 0. Что такое Cutoff
    iPhone-приложение (SwiftUI) для тренировки префлопа в МТТ NLHE. \
    Локальное, без бэкенда и без сторонних зависимостей.
    - **Стек**: SwiftUI + MVVM на `@Observable`. iOS 17+, Swift 5.10, Xcode 26.
    - **Хранение**: `UserDefaults` — настройки (`ConfigStore`); SwiftData — `QuizResult` и `TrainingSession`; JSON-диапазоны лежат в `Resources/Ranges/`.
    - **Вкладки** (`Cutoff/Features/MainTabView.swift`): `Тренировка` (Train), `Диапазоны` (Ranges), `Разбор` (Review), `Стратегия` (Strategy).
    - **Тема**: только тёмная. Liquid Glass на iOS 18+ с фолбэком `.ultraThinMaterial`. Учитываются `accessibilityReduceTransparency` и `accessibilityReduceMotion`.

    ## 1. Карта кода: что искать и где
    Используйте эти символы как поисковые запросы (grep / «Open Quickly» в Xcode).

    ### Данные «Стратегии»
    - `StrategyStore` — массив всех недель (`allGuides`) и `activeGuide`. **Все тексты глав живут здесь.** → `Cutoff/Features/Strategy/StrategyModel.swift`
    - `WeeklyGuide` — одна неделя (id-ключ по дате, заголовок, подзаголовок, массив глав).
    - `StrategyChapter` — одна глава (id, иконка, тег + локализованные тексты).
    - `StrategyProgressStore` — отметки «изучено» (`@Observable`, общий синглтон).

    ### Экраны «Стратегии» (`Cutoff/Features/Strategy/`)
    - `StrategyGuideView` — список недель и глав, бейдж прогресса, скрытый вход в эту документацию (5 тапов по заголовку).
    - `StrategyChapterDetailView` — горизонтальный пейджер глав, нижняя навигация, кнопка «Изучено». Тут же роутер интерактивных виджетов `embeddedComponent(for:)`.
    - `StrategyComponents.swift` — все 5 интерактивных карточек + `StrategyChip`, `MiniRangeGridView`, `RangeParser`.
    - `DeveloperStrategyDocView.swift` — этот файл.

    ### Переиспользуемые компоненты (`Cutoff/Components/`)
    - `RichCardText` — превращает покерные нотации в тексте в карточки/комбо (раздел 5).
    - `ComboView`, `CardView`, `BoardView` — отрисовка комбо/карт/борда. Модель карты — `Cutoff/Models/Card.swift`, комбо — `HandCombo`.
    - `GlassCard`, `AppBackground` — стеклянная карточка и фон.

    ### Локализация
    - `L10n` (enum `L10n.Key` + три словаря) и `LocalizationManager` → `Cutoff/Theme/Localization/`. Доступ в коде: `l10n.t(.ключ)`.
    - Языки — enum `AppLanguage`: `.english`, `.russian`, `.russianGenZ`.

    ### Дизайн-токены (`Cutoff/Theme/`)
    `AppColors`, `AppSpacing` (шаг 8pt, по умолчанию `lg` = 20), `AppRadius`, `AppTypography`, `AppMotion`, `AppGlass`. **Никогда не хардкодьте цвет/отступ/радиус — только токены.**

    ## 2. Модель данных главы (реальная структура)
    `StrategyChapter` НЕ хранит готовый `content`-массив. У него фиксированный набор полей, каждый — в трёх языковых регистрах (eng / ru / ruGenZ). Геттеры выбирают нужный регистр по `AppLanguage`.

    ```swift
    StrategyChapter(
        id: 1,                       // 1...5 — номер главы в неделе (и ключ виджета)
        icon: "scalemass.fill",      // SF Symbol
        tag: "Preflop",              // "Preflop" | "Postflop" | "Push/Fold" | "Math"
        engTitle: "...",  ruTitle: "...",  ruGenzTitle: "...",
        engShortDesc: "...",  ruShortDesc: "...",  ruGenzShortDesc: "...",
        engWhatsDo: "...",  ruWhatsDo: "...",  ruGenzWhatsDo: "...",  // блок «ЧТО ДЕЛАТЬ»
        engWhy: "...",  ruWhy: "...",  ruGenzWhy: "..."              // блок «ПОЧЕМУ» (+ 📖 пример)
    )
    ```

    Полезные методы: `title(for:)`, `shortDescription(for:)`, `whatsDo(for:)`, `why(for:)`, `whyReason(for:)`, `whyScenario(for:)`, `localizedTag(for:)`.

    ## 3. Блок «ПОЧЕМУ» и живой пример (маркер 📖)
    Поле `why` состоит из двух частей, разделённых эмодзи **📖**:
    1. _Объяснение_ — почему приём работает.
    2. _Живой пример_ — раздача из игры.

    `whyReason(for:)` возвращает первую часть, `whyScenario(for:)` — вторую как `(title, body)` (или `nil`, если 📖 нет). Detail-экран рисует их в двух разных карточках. Формат для редактора:

    ```
    ...текст объяснения...

    📖 ЗАГОЛОВОК ПРИМЕРА:
    Блайнды 100/200, анте 200. ...тело примера...
    ```
    Заголовок (до первого переноса строки) показывается капсом мятным цветом; всё после — телом примера.

    ## 4. Как добавить главу или неделю
    1. Откройте `StrategyStore.allGuides` в `StrategyModel.swift`.
    2. Для новой недели добавьте `WeeklyGuide` (уникальный `id` вида `"2026-06-08"`, дата, заголовки в 3 регистрах, массив `chapters`).
    3. Главы нумеруйте `id: 1...5`. Заполните все 12 локализованных полей (eng/ru/ruGenZ × title/shortDesc/whatsDo/why).
    4. **Интерактивный виджет** привязан к `id` главы в `StrategyChapterDetailView.embeddedComponent(for:)` и **только для недели `"2026-06-01"`**. Для других недель показывается `historicalStaticComponent()` (заглушка «архивный тренажёр»). Чтобы у новой недели были свои виджеты — расширьте роутер (см. раздел 6).
    5. `activeGuide` — это `allGuides.first`, поэтому свежую неделю кладите первой в массив.

    ## 5. RichCardText — синтаксис нотаций
    `RichCardText` разбивает текст по пробелам и для каждого токена пытается отрисовать карту/комбо. Знаки препинания по краям (`,` `.` `(` `)`) аккуратно отделяются и возвращаются на место — `+` и `-` НЕ считаются пунктуацией.

    ### Карты борда
    Несколько карт — через дефис без пробелов: `Ah-Kd-2c`. Каждая часть строго 2 символа и валидная карта. Одиночная карта (терн/ривер): `Jd`, `Ts`.

    ### Карманные руки (hole cards)
    Две конкретные карты слитно, 4 символа: `QdJd`, `AhKh`, `2c2s` → две карточки.

    ### Комбо и диапазоны
    - Пары: `22`, `AA`; с плюсом: `22+`.
    - Одномастные: `K9s`, `K9s+`.
    - Разномастные: `A3o`, `A3o+`.
    - Диапазон комбо: дефис между двумя комбо — `A2o-A5o`, `22-77`, `K2s-K9s`.

    ### Правила и подводные камни
    - **Масти — строчные**: `h` `d` `c` `s`. **Ранги — заглавные/цифры**: `A K Q J T 9...2`. Только `T`, не `10`.
    - **`%` отключает парсинг токена**: `33%`, `100%` останутся текстом (чтобы `33` не стало парой 3-3). Пишите процент слитно: `33%`.
    - Длинные перечисления (например, диапазон пуша из 16 рук) рисуются как ряд комбо-картинок — это нормально, но для читабельности разбивайте очень длинные ренжи.

    ## 6. Интерактивные виджеты глав
    Роутер: `StrategyChapterDetailView.embeddedComponent(for:)` (только неделя `2026-06-01`):
    - Глава 1 → `LimperIsolationCard` (калькулятор изолейта)
    - Глава 2 → `StealRangesCard` (диапазоны стила CO/BTN/SB)
    - Глава 3 → `FirstInJamCard` (Nash пуш-фолд 12/15/18 ББ)
    - Глава 4 → `CBetSituationCard` (текстуры флопа: сухая/дровяная/спаренная/монотон)
    - Глава 5 → `PotOddsTrainerCard` (пот-оддсы и эквити)

    Все карточки используют `StrategyChip` (сегмент-переключатель) и токены дизайна. Сетку 13×13 рисует `MiniRangeGridView`, разбор шорткода — `RangeParser` (поддерживает `+` для пар/мастей и одиночные комбо).

    ## 7. Локализация
    - Вкладка «Стратегия» намеренно **только на русском** (`.russian` и `.russianGenZ`). Для `.english` показывается заглушка `StrategyUnsupportedLanguageView`. Английские поля глав уже написаны, но интерфейс карточек захардкожен по-русски — это причина гейта, не баг.
    - Строки UI вне «Стратегии» берутся из `L10n` через `l10n.t(.ключ)`. Новый ключ добавляйте в enum `L10n.Key` и **во все три словаря** (english/russian/russianGenZ), иначе покажется сырой ключ (как было с `.tabReview`).

    ## 8. Прогресс и хранение
    - `StrategyProgressStore.shared` хранит изученные главы в `UserDefaults` под ключом `strategy.completedChapters` в виде `Set<"<weekId>.<chapterId>">`.
    - Есть одноразовая миграция со старых ключей `strategy.completed.<week>.<chapter>`.
    - Бейдж «x/y» в списке и галочки «Изучено» считаются реактивно от этого стора — ручной перерисовки не нужно.

    ## 9. Точность контента (стандарты)
    - **Цель — ChipEV.** ICM в этом приложении намеренно НЕ рассматривается. Диапазоны пуш-фолда (`FirstInJamCard`) откалиброваны по чистому Nash (чарт ~12.5% анте), а не по ICM.
    - Пот-оддсы: ⅓→20%, ½→25%, пот→33% (точно). Правило 2 и 4; ×4 — только в олл-ине, «грязные» ауты вычитать.
    - Контбет: сухая 80%+ мелко; спаренная 85%+ мелко; монотон ~25-30% мелко; дровяная реже/крупнее.
    - Диапазоны — это ориентир по солверам. Подписывайте их как приближение и адаптируйте под поле и анте.

    ## 10. Сборка, тесты, запуск
    ```sh
    xcodegen generate
    xcodebuild -project Cutoff.xcodeproj -scheme Cutoff \\
      -destination 'platform=iOS Simulator,name=iPhone 17' build   # или test
    ```
    - После добавления/удаления файлов запускайте `xcodegen generate` (проект генерируется из `project.yml`).
    - Тесты «Стратегии»: `CutoffTests/StrategyModelTests.swift` (парсинг 📖, теги, покрытие `RangeParser`). Меняете поведение модели — обновляйте тесты.
    - Собирать и тестировать на симуляторе, коммитить после каждого изменения.

    ## 11. Чек-лист для разработчика / ИИ-ассистента
    - [ ] Новый текст главы — во всех 3 регистрах (eng/ru/ruGenZ).
    - [ ] Нотации оформлены по разделу 5; проценты слитно (`33%`).
    - [ ] Живой пример отделён маркером `📖` (раздел 3).
    - [ ] Новый UI-текст добавлен во все 3 словаря `L10n`.
    - [ ] Только токены дизайна, без хардкода цветов/отступов.
    - [ ] Новой неделе с виджетами расширен роутер `embeddedComponent(for:)`.
    - [ ] `xcodegen generate`, затем build + test на симуляторе зелёные.
    """

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        ForEach(Array(parseBlocks(docText).enumerated()), id: \.offset) { _, block in
                            blockView(block)
                        }
                    }
                    .padding(AppSpacing.pageHorizontal)
                    .padding(.bottom, AppSpacing.xxl)
                    .textSelection(.enabled)
                }
            }
            .navigationTitle("Документация")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("Закрыть")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.primaryMint)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: copyAll) {
                        HStack(spacing: AppSpacing.xxs) {
                            Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                            if didCopy {
                                Text("Скопировано")
                                    .font(AppTypography.caption)
                            }
                        }
                        .foregroundStyle(didCopy ? AppColors.accentLime : AppColors.primaryMint)
                    }
                }
            }
        }
    }

    private func copyAll() {
        UIPasteboard.general.string = docText
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.easeInOut(duration: 0.2)) { didCopy = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) { didCopy = false }
        }
    }

    // MARK: - Lightweight Markdown blocks

    private enum DocBlock {
        case title(String)
        case section(String)
        case subsection(String)
        case bullet(String)
        case code(String)
        case paragraph(String)
        case spacer
    }

    /// Splits the Markdown source into renderable blocks. Handles fenced code
    /// (```), ATX headings (#, ##, ###), bullets (-, •, [ ]) and paragraphs.
    private func parseBlocks(_ text: String) -> [DocBlock] {
        var blocks: [DocBlock] = []
        var inCode = false
        var codeBuffer: [String] = []

        for rawLine in text.components(separatedBy: "\n") {
            let line = rawLine

            if line.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                if inCode {
                    blocks.append(.code(codeBuffer.joined(separator: "\n")))
                    codeBuffer.removeAll()
                }
                inCode.toggle()
                continue
            }
            if inCode { codeBuffer.append(line); continue }

            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                blocks.append(.spacer)
            } else if trimmed.hasPrefix("### ") {
                blocks.append(.subsection(String(trimmed.dropFirst(4))))
            } else if trimmed.hasPrefix("## ") {
                blocks.append(.section(String(trimmed.dropFirst(3))))
            } else if trimmed.hasPrefix("# ") {
                blocks.append(.title(String(trimmed.dropFirst(2))))
            } else if trimmed.hasPrefix("- [ ] ") {
                blocks.append(.bullet(String(trimmed.dropFirst(6))))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("• ") {
                blocks.append(.bullet(String(trimmed.dropFirst(2))))
            } else {
                blocks.append(.paragraph(trimmed))
            }
        }
        if inCode, !codeBuffer.isEmpty {
            blocks.append(.code(codeBuffer.joined(separator: "\n")))
        }
        return blocks
    }

    /// `Text(.init(_:))` interprets inline Markdown (**bold**, *italic*, `code`).
    private func inline(_ s: String) -> Text { Text(.init(s)) }

    @ViewBuilder
    private func blockView(_ block: DocBlock) -> some View {
        switch block {
        case .title(let s):
            inline(s)
                .font(AppTypography.title2)
                .bold()
                .foregroundStyle(AppColors.textPrimary)
                .padding(.bottom, AppSpacing.xs)

        case .section(let s):
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Divider().overlay(AppColors.divider.opacity(0.4))
                inline(s)
                    .font(AppTypography.title3)
                    .bold()
                    .foregroundStyle(AppColors.primaryMint)
            }
            .padding(.top, AppSpacing.sm)

        case .subsection(let s):
            inline(s)
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.top, AppSpacing.xxs)

        case .bullet(let s):
            HStack(alignment: .top, spacing: AppSpacing.xs) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 5))
                    .foregroundStyle(AppColors.primaryMint)
                    .padding(.top, 7)
                inline(s)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .code(let s):
            Text(s)
                .font(.system(size: 12.5, design: .monospaced))
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous)
                        .fill(Color.black.opacity(0.25))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.chip)
                        .stroke(AppColors.divider.opacity(0.3), lineWidth: 0.5)
                )

        case .paragraph(let s):
            inline(s)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .spacer:
            Spacer().frame(height: AppSpacing.xxs)
        }
    }
}

#Preview {
    DeveloperStrategyDocView()
}
