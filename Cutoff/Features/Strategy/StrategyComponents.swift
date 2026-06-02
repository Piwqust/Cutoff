import SwiftUI

// MARK: - Reusable Selectable Chip
/// Segmented-style toggle chip used across the strategy sandbox cards.
/// Filled with `tint` when selected, liquid glass otherwise.
struct StrategyChip: View {
    let title: String
    let isSelected: Bool
    var tint: Color = AppColors.primaryMint
    var font: Font = AppTypography.subheadline
    var fillWidth: Bool = true
    var verticalPadding: CGFloat = AppSpacing.xs
    var horizontalPadding: CGFloat = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(font)
                .foregroundStyle(isSelected ? AppColors.backgroundDeep : AppColors.textPrimary)
                .padding(.vertical, verticalPadding)
                .padding(.horizontal, horizontalPadding)
                .frame(maxWidth: fillWidth ? .infinity : nil)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: AppRadius.chip).fill(tint)
                        } else {
                            RoundedRectangle(cornerRadius: AppRadius.chip)
                                .fill(Color.clear)
                                .liquidGlass(in: RoundedRectangle(cornerRadius: AppRadius.chip), interactive: true)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reusable Range Visualizer + Copyable Shorthand
/// Pairs the 13×13 mini grid with a tap-to-copy shorthand string, with a
/// clear copy affordance and an accessible button trait.
struct RangeShorthandDisplay: View {
    let shorthand: String
    let activeColor: Color

    @State private var didCopy = false

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            MiniRangeGridView(shorthand: shorthand, activeColor: activeColor)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Визуальный спектр:")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .bold()

                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 10))
                    Text(didCopy ? "Скопировано!" : "Шорткод (клик для копии):")
                        .font(AppTypography.caption2)
                }
                .foregroundStyle(didCopy ? AppColors.accentLime : AppColors.textSecondary.opacity(0.8))

                Text(shorthand)
                    .font(AppTypography.monoCaption)
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(AppSpacing.xs)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.clear)
                            .liquidGlass(in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    )
                    .onTapGesture { copyShorthand() }
                    .accessibilityElement()
                    .accessibilityLabel("Диапазон рук: \(shorthand)")
                    .accessibilityHint("Дважды коснитесь, чтобы скопировать")
                    .accessibilityAddTraits(.isButton)
            }
        }
    }

    private func copyShorthand() {
        UIPasteboard.general.string = shorthand
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.easeInOut(duration: 0.2)) { didCopy = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) { didCopy = false }
        }
    }
}

// MARK: - 1. Limper Isolation Card
struct LimperIsolationCard: View {
    @State private var limperCount = 1
    @State private var inPosition = true

    var baseSizing: Int {
        return inPosition ? 4 : 5
    }

    var finalSizing: Int {
        return baseSizing + limperCount
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Image(systemName: "scalemass.fill")
                        .foregroundStyle(AppColors.primaryMint)
                    Text("Калькулятор Изолейта")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Text(inPosition ? "В позиции (IP)" : "Вне позиции (OOP)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.primaryMint)
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(AppColors.primaryMint.opacity(0.15))
                        .clipShape(Capsule())
                }

                // Position Selector
                HStack(spacing: AppSpacing.sm) {
                    StrategyChip(title: "В позиции (IP)", isSelected: inPosition) { inPosition = true }
                    StrategyChip(title: "Вне позы (OOP)", isSelected: !inPosition) { inPosition = false }
                }

                // Limper Slider
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    HStack {
                        Text("Кол-во лимперов в банке:")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        Text("\(limperCount)")
                            .font(AppTypography.numericMedium)
                            .foregroundStyle(AppColors.primaryMint)
                    }
                    Slider(value: Binding(
                        get: { Double(limperCount) },
                        set: { limperCount = Int($0) }
                    ), in: 1...4, step: 1)
                    .tint(AppColors.primaryMint)
                }

                Divider().overlay(AppColors.divider)

                // Sizing Output
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Формула сайзинга:")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        Text(inPosition ? "4 BB + 1 BB за лимпера" : "5 BB + 1 BB за лимпера")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Размер рейза:")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                        Text("\(finalSizing) BB")
                            .font(AppTypography.numericLarge)
                            .foregroundStyle(AppColors.accentLime)
                    }
                }
            }
        }
    }
}

// MARK: - 2. Steal Ranges Card
struct StealRangesCard: View {
    @State private var positionIndex = 1 // 0: CO, 1: BTN, 2: SB
    @State private var isExploitative = true

    private let positions = ["CO", "BTN", "SB"]

    // Hand definitions for visual presentation
    var handText: String {
        switch (positionIndex, isExploitative) {
        case (0, false): return "22+, A2s+, A9o+, KTs+, KJo+, QTs+, JTs, T9s"
        case (0, true):  return "22+, A2s+, A7o+, K6s+, KTo+, Q8s+, QTo+, J8s+, JTo, T8s+, 98s, 87s"
        case (1, false): return "22+, A2s+, A7o+, K9s+, KTo+, Q9s+, QJo, J9s+, JTo, T9s, 98s, 87s"
        case (1, true):  return "22+, A2s+, A2o+, K2s+, K8o+, Q4s+, QTo+, J6s+, J9o+, T6s+, 96s+, 85s+, 75s+, 64s+, 54s"
        case (2, false): return "22+, A2s+, A2o+, K2s+, K9o+, Q6s+, QTo+, J7s+, J9o+, T7s+, 97s+, 86s+, 76s"
        case (2, true):  return "22+, A2s+, A2o+, K2s+, K5o+, Q2s+, Q9o+, J2s+, J9o+, T4s+, 95s+, 85s+, 74s+, 64s+, 53s+"
        default:         return "22+, A2s+"
        }
    }

    var openPercentage: Int {
        switch (positionIndex, isExploitative) {
        case (0, false): return 28
        case (0, true):  return 38
        case (1, false): return 43
        case (1, true):  return 62
        case (2, false): return 50
        case (2, true):  return 72
        default:         return 40
        }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(AppColors.primaryMint)
                    Text("Стилы с поздних позиций")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Text("\(openPercentage)% рук")
                        .font(AppTypography.numericSmall)
                        .foregroundStyle(AppColors.accentLime)
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(AppColors.accentLime.opacity(0.15))
                        .clipShape(Capsule())
                }

                // Position Selector
                HStack(spacing: AppSpacing.sm) {
                    ForEach(0..<positions.count, id: \.self) { i in
                        StrategyChip(title: positions[i], isSelected: positionIndex == i) { positionIndex = i }
                    }
                }

                // Strategy Selector
                HStack(spacing: AppSpacing.sm) {
                    StrategyChip(title: "Стандартный TAG", isSelected: !isExploitative,
                                 tint: AppColors.accentPeach, font: AppTypography.footnote, verticalPadding: 6) {
                        isExploitative = false
                    }
                    StrategyChip(title: "Широкий эксплойт", isSelected: isExploitative,
                                 tint: AppColors.accentPeach, font: AppTypography.footnote, verticalPadding: 6) {
                        isExploitative = true
                    }
                }

                // Range display with Visual Grid on the left
                RangeShorthandDisplay(shorthand: handText, activeColor: AppColors.primaryMint)

                HStack(alignment: .top, spacing: AppSpacing.xs) {
                    Image(systemName: isExploitative ? "flame.fill" : "shield.fill")
                        .foregroundStyle(isExploitative ? AppColors.accentPeach : AppColors.primaryMint)
                        .font(.footnote)
                        .padding(.top, 2)

                    Text(isExploitative ?
                         "Эксплойт: блайнды слишком тайтовые! Открываем широчайший спектр рук, чтобы забрать мертвые деньги." :
                         "Стандарт: классический плотный спектр открытия для защиты от 3-бетов.")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColors.textSecondary)
                        .italic()
                }
            }
        }
    }
}

// MARK: - 3. First-In Jam Card
struct FirstInJamCard: View {
    @State private var selectedDepth = 15 // 12, 15, 18
    @State private var positionIndex = 1 // 0: CO, 1: BTN, 2: SB

    private let positions = ["CO", "BTN", "SB"]
    private let depths = [12, 15, 18]

    var shovingRange: String {
        switch (selectedDepth, positionIndex) {
        case (12, 0): return "22+, A2s+, A8o+, KJs+, KQo, QJs"
        case (12, 1): return "22+, A2s+, A3o+, K9s+, KTo+, QTs+, QJo, JTs, T9s"
        case (12, 2): return "22+, A2s+, A2o+, K4s+, K8o+, Q8s+, QTo+, J8s+, T8s+, 98s"
        case (15, 0): return "22+, A7s+, AJo, KQs"
        case (15, 1): return "22+, A2s+, A7o+, KTs+, KTo+, QTs+, JTs"
        case (15, 2): return "22+, A2s+, A2o+, K8s+, KTo+, Q9s+, QJo, J9s+, T9s"
        case (18, 0): return "55+, AQs+, AQo"
        case (18, 1): return "22+, A8s+, ATo+, KJs+, KQo"
        case (18, 2): return "22+, A2s+, A8o+, KTs+, KTo+, QTs+, JTs"
        default: return "22+, A2s+"
        }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(AppColors.accentPeach)
                    Text("First-in Jam (ChipEV)")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Text("Пуш-Фолд")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.accentPeach)
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(AppColors.accentPeach.opacity(0.15))
                        .clipShape(Capsule())
                }

                // Stack Depth Selector
                HStack(spacing: AppSpacing.sm) {
                    Text("Стек (BB):")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    HStack(spacing: AppSpacing.xs) {
                        ForEach(depths, id: \.self) { d in
                            StrategyChip(title: "\(d) BB", isSelected: selectedDepth == d,
                                         tint: AppColors.accentPeach, font: AppTypography.numericSmall,
                                         fillWidth: false, verticalPadding: 6, horizontalPadding: AppSpacing.sm) {
                                selectedDepth = d
                            }
                        }
                    }
                }

                // Position Selector
                HStack(spacing: AppSpacing.sm) {
                    ForEach(0..<positions.count, id: \.self) { i in
                        StrategyChip(title: positions[i], isSelected: positionIndex == i) { positionIndex = i }
                    }
                }

                // Range display with Visual Grid on the left
                RangeShorthandDisplay(shorthand: shovingRange, activeColor: AppColors.accentPeach)

                HStack(alignment: .top, spacing: AppSpacing.xs) {
                    Image(systemName: selectedDepth >= 18 ? "exclamationmark.triangle.fill" : "lightbulb.fill")
                        .foregroundStyle(selectedDepth >= 18 ? AppColors.accentPeach : AppColors.accentLime)
                        .font(.footnote)
                        .padding(.top, 2)

                    Text(selectedDepth >= 18 ?
                         "При 18 ББ диапазон пуша очень тайтовый. Здесь уже можно прибыльно минрейзить сильный бродвей для провокации." :
                         "При \(selectedDepth) ББ мин-рейзить маргинально — прямой пуш максимизирует фолд-эквити.")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColors.textSecondary)
                        .italic()
                }
            }
        }
    }
}

// MARK: - 4. C-Bet Situation Card
struct CBetSituationCard: View {
    enum Texture: String, CaseIterable, Identifiable {
        case dry, wet, paired, monotone
        var id: String { rawValue }
        var label: String {
            switch self {
            case .dry:      return "Сухая"
            case .wet:      return "Дровяная"
            case .paired:   return "Спаренная"
            case .monotone: return "Монотон"
            }
        }
    }

    /// Resolved guidance for the selected flop texture.
    struct Config {
        let subtitle: String
        let cbetLabel: String
        let cbetTint: Color
        let board: [String]
        let sizingLabel: String
        let sizingTint: Color
        let detail: String
    }

    @State private var texture: Texture = .dry

    private func config(for texture: Texture) -> Config {
        switch texture {
        case .dry:
            return Config(
                subtitle: "(Dry Rainbow)",
                cbetLabel: "C-Bet: 80%+",
                cbetTint: AppColors.primaryMint,
                board: ["Kc", "7d", "2s"],
                sizingLabel: "25-33% пота",
                sizingTint: AppColors.accentLime,
                detail: "Ставим со всем спектром. Оппоненты редко попадут и легко выкинут мусор."
            )
        case .wet:
            return Config(
                subtitle: "(Wet Board)",
                cbetLabel: "C-Bet: 30-40%",
                cbetTint: AppColors.accentPeach,
                board: ["Qc", "Jd", "9c"],
                sizingLabel: "65-75% пота",
                sizingTint: AppColors.accentCoral,
                detail: "Только плотное велью или супер-дро. Пустые руки чекаем и сдаемся."
            )
        case .paired:
            return Config(
                subtitle: "(Paired)",
                cbetLabel: "C-Bet: 65-75%",
                cbetTint: AppColors.primaryMint,
                board: ["Kc", "Kd", "4s"],
                sizingLabel: "25-33% пота",
                sizingTint: AppColors.accentLime,
                detail: "У коллера редко тройка — лупим частый мелкий контбет почти всем диапазоном за счёт перевеса в старших картах."
            )
        case .monotone:
            return Config(
                subtitle: "(Monotone)",
                cbetLabel: "C-Bet: 25-30%",
                cbetTint: AppColors.accentPeach,
                board: ["Ac", "9c", "5c"],
                sizingLabel: "33% / чек",
                sizingTint: AppColors.accentLime,
                detail: "Эквити сближается, банки опасны. Много чекаем; ставим мелко с готовым флешем или натсовым флеш-дро."
            )
        }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Image(systemName: "circle.grid.3x3.fill")
                        .foregroundStyle(AppColors.primaryMint)
                    Text("Постфлоп: Анализатор флопов")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textPrimary)
                }

                // Texture selector — drives the dynamic guidance below
                HStack(spacing: AppSpacing.xs) {
                    ForEach(Texture.allCases) { t in
                        StrategyChip(title: t.label, isSelected: texture == t,
                                     font: AppTypography.footnote, verticalPadding: 6) {
                            texture = t
                        }
                    }
                }

                let cfg = config(for: texture)
                boardSituation(
                    title: texture.label + " доска",
                    subtitle: cfg.subtitle,
                    cbetLabel: cfg.cbetLabel,
                    cbetTint: cfg.cbetTint,
                    board: cfg.board,
                    sizingLabel: cfg.sizingLabel,
                    sizingTint: cfg.sizingTint,
                    detail: cfg.detail
                )
                .id(texture)
                .transition(.opacity)
            }
            .animation(.easeInOut(duration: 0.2), value: texture)
        }
    }

    @ViewBuilder
    private func boardSituation(title: String, subtitle: String, cbetLabel: String, cbetTint: Color,
                                board: [String], sizingLabel: String, sizingTint: Color, detail: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header Row
            HStack(alignment: .center) {
                HStack(spacing: AppSpacing.xxs) {
                    Text(title)
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Text(cbetLabel)
                    .font(AppTypography.caption)
                    .bold()
                    .foregroundStyle(AppColors.backgroundDeep)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xxs)
                    .background(cbetTint)
                    .clipShape(Capsule())
            }

            Divider()
                .background(AppColors.divider.opacity(0.3))

            HStack(spacing: AppSpacing.md) {
                // Left Column: Visual Cards
                BoardView(board: board.compactMap { Card(notation: $0) })
                    .frame(width: 172)

                // Vertical divider line for beautiful structure
                RoundedRectangle(cornerRadius: 1)
                    .fill(AppColors.divider.opacity(0.3))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)

                // Right Column: Tactical details
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("САЙЗИНГ:")
                            .font(AppTypography.caption)
                            .bold()
                            .foregroundStyle(AppColors.textSecondary)

                        Text(sizingLabel)
                            .font(AppTypography.footnote)
                            .bold()
                            .foregroundStyle(sizingTint)
                    }

                    Text(detail)
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineSpacing(3)
                }
            }
            .frame(minHeight: 76) // Align the board grid; grow for longer guidance text
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(Color.clear)
                .liquidGlass(in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        )
    }
}

// MARK: - 5. Pot Odds & Equity Trainer Card
struct PotOddsTrainerCard: View {
    @State private var outs = 9
    @State private var betFraction = 0.5 // Bet size as fraction of pot (0.25 to 1.5)
    @State private var cardsToCome = 1   // 1 = facing a bet on one street, 2 = all-in (both cards)

    /// Rule of 4 — equity across both remaining cards (only realised when all-in).
    var equityBothCards: Int { outs * 4 }
    /// Rule of 2 — equity for the single next card.
    var equityOneCard: Int { outs * 2 }

    /// The equity that actually applies to this decision.
    var effectiveEquity: Int { cardsToCome == 2 ? equityBothCards : equityOneCard }

    var requiredEquity: Double {
        // formula: bet / (pot + bet + call)
        // If bet is fraction of pot F: F / (1.0 + F + F) = F / (1.0 + 2F)
        return (betFraction / (1.0 + 2.0 * betFraction)) * 100.0
    }

    var isCallProfitable: Bool {
        return Double(effectiveEquity) >= requiredEquity
    }

    var betLabel: String {
        switch betFraction {
        case 0.25: return "1/4 пота"
        case 0.33: return "1/3 пота"
        case 0.5:  return "1/2 пота"
        case 0.67: return "2/3 пота"
        case 1.0:  return "Пот-бет"
        case 1.5:  return "Овербет 1.5x"
        default:   return "\(Int(betFraction * 100))% пота"
        }
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(AppColors.primaryMint)
                    Text("Математический Тренажер")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()

                    // +EV Badge
                    Text(isCallProfitable ? "+EV Call" : "-EV Fold/Marginal")
                        .font(AppTypography.caption)
                        .bold()
                        .foregroundStyle(isCallProfitable ? AppColors.backgroundDeep : AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(isCallProfitable ? AppColors.accentLime : AppColors.accentPeach)
                        .clipShape(Capsule())
                }

                // Street Selector (cards to come) — drives which equity applies
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Сколько карт впереди:")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColors.textSecondary)
                    HStack(spacing: AppSpacing.sm) {
                        StrategyChip(title: "1 карта (ставка)", isSelected: cardsToCome == 1,
                                     font: AppTypography.footnote, verticalPadding: 6) { cardsToCome = 1 }
                        StrategyChip(title: "Олл-ин (2 карты)", isSelected: cardsToCome == 2,
                                     font: AppTypography.footnote, verticalPadding: 6) { cardsToCome = 2 }
                    }
                }

                // Slider 1: Outs
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    HStack {
                        Text("Ваши ауты (Outs):")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        Text("\(outs) аутов")
                            .font(AppTypography.numericMedium)
                            .foregroundStyle(AppColors.primaryMint)
                    }
                    Slider(value: Binding(
                        get: { Double(outs) },
                        set: { outs = Int($0) }
                    ), in: 1...15, step: 1)
                    .tint(AppColors.primaryMint)

                    Text("Например: \(outsTextForDescription)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .italic()
                }

                // Slider 2: Bet Fraction
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    HStack {
                        Text("Ставка оппонента:")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        Text(betLabel)
                            .font(AppTypography.numericMedium)
                            .foregroundStyle(AppColors.accentPeach)
                    }
                    Slider(value: Binding(
                        get: { betFraction },
                        set: { betFraction = snapBetFraction($0) }
                    ), in: 0.25...1.5, step: 0.05)
                    .tint(AppColors.accentPeach)
                }

                Divider().overlay(AppColors.divider)

                // Calculations Breakdown
                VStack(spacing: AppSpacing.sm) {
                    HStack {
                        Text("Эквити, 2 карты (×4):")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        Text("~ \(equityBothCards)%")
                            .font(AppTypography.numericMedium)
                            .foregroundStyle(cardsToCome == 2 ? AppColors.primaryMint : AppColors.textSecondary)
                    }

                    HStack {
                        Text("Эквити, 1 карта (×2):")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        Text("~ \(equityOneCard)%")
                            .font(AppTypography.numericMedium)
                            .foregroundStyle(cardsToCome == 1 ? AppColors.primaryMint : AppColors.textSecondary)
                    }

                    HStack {
                        Text("Шансы банка (Пот-оддсы):")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        Text("\(Int(requiredEquity))% нужно")
                            .font(AppTypography.numericMedium)
                            .foregroundStyle(AppColors.accentLime)
                    }
                }

                HStack(alignment: .top, spacing: AppSpacing.xs) {
                    Image(systemName: isCallProfitable ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isCallProfitable ? AppColors.accentLime : AppColors.accentPeach)
                        .font(.footnote)
                        .padding(.top, 2)

                    Text(isCallProfitable ?
                         "Колл ВЫГОДЕН! Ваше эквити (\(effectiveEquity)%) выше стоимости билета (\(Int(requiredEquity))%). Это плюсовое действие на дистанции." :
                         "Колл НЕВЫГОДЕН. Эквити (\(effectiveEquity)%) не хватает, чтобы перебить цену колла (\(Int(requiredEquity))%). Ищите фолд, если нет скрытых имплайд-оддсов.")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(AppSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous)
                        .fill(Color.clear)
                        .liquidGlass(in: RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous))
                )
            }
        }
    }

    private var outsTextForDescription: String {
        switch outs {
        case 1...3: return "Бэкдор или оверкарта (мало шансов)"
        case 4: return "Гатшот (нужна 1 конкретная карта)"
        case 8: return "Двустороннее стрейт-дро (OESD)"
        case 9: return "Флеш-дро (9 карт одной масти)"
        case 12: return "Флеш-дро + гатшот (сильное дро)"
        case 15: return "Флеш-дро + двустороннее стрейт-дро (Монстр!)"
        default: return "\(outs) аутов на улучшение"
        }
    }

    private func snapBetFraction(_ val: Double) -> Double {
        // Snap to common poker sizes
        if abs(val - 0.25) < 0.04 { return 0.25 }
        if abs(val - 0.33) < 0.04 { return 0.33 }
        if abs(val - 0.5) < 0.05 { return 0.5 }
        if abs(val - 0.67) < 0.05 { return 0.67 }
        if abs(val - 1.0) < 0.08 { return 1.0 }
        if abs(val - 1.5) < 0.1 { return 1.5 }
        return Double(round(val * 20) / 20)
    }
}

// MARK: - Hand Shorthand Range Parser
struct RangeParser {
    static func parse(_ shorthand: String) -> Set<String> {
        let parts = shorthand.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        var result: Set<String> = []

        for part in parts {
            if part.isEmpty { continue }

            if part.hasSuffix("+") {
                let handStr = String(part.dropLast())
                guard let combo = HandCombo.parse(handStr) else { continue }

                switch combo.category {
                case .pair:
                    for rank in HandCombo.Rank.allCases {
                        if rank >= combo.highRank {
                            result.insert("\(rank.rawValue)\(rank.rawValue)")
                        }
                    }
                case .suited:
                    let highRank = combo.highRank
                    for rank in HandCombo.Rank.allCases {
                        if rank >= combo.lowRank && rank < highRank {
                            result.insert("\(highRank.rawValue)\(rank.rawValue)s")
                        }
                    }
                case .offsuit:
                    let highRank = combo.highRank
                    for rank in HandCombo.Rank.allCases {
                        if rank >= combo.lowRank && rank < highRank {
                            result.insert("\(highRank.rawValue)\(rank.rawValue)o")
                        }
                    }
                }
            } else {
                guard let combo = HandCombo.parse(part) else { continue }
                result.insert(combo.notation)
            }
        }
        return result
    }
}

// MARK: - Mini Range Grid Visualizer (iOS 26 Liquid Glass)
struct MiniRangeGridView: View {
    let shorthand: String
    let activeColor: Color

    var body: some View {
        // Parse once per render rather than once per cell.
        let parsedHands = RangeParser.parse(shorthand)

        VStack(spacing: 1.5) {
            ForEach(0..<13, id: \.self) { row in
                HStack(spacing: 1.5) {
                    ForEach(0..<13, id: \.self) { col in
                        let combo = HandCombo.combo(forRow: row, column: col)
                        let inRange = parsedHands.contains(combo.notation)

                        RoundedRectangle(cornerRadius: 1)
                            .fill(inRange ? activeColor : AppColors.cardSurface.opacity(0.18))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.clear)
                .liquidGlass(in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        )
    }
}
