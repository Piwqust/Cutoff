import SwiftUI

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
                        .padding(.vertical, 4)
                        .background(AppColors.primaryMint.opacity(0.15))
                        .clipShape(Capsule())
                }
                
                // Position Selector
                HStack(spacing: AppSpacing.sm) {
                    Button(action: { inPosition = true }) {
                        Text("В позиции (IP)")
                            .font(AppTypography.subheadline)
                            .foregroundStyle(inPosition ? AppColors.backgroundDeep : AppColors.textPrimary)
                            .padding(.vertical, AppSpacing.xs)
                            .frame(maxWidth: .infinity)
                            .background(inPosition ? AppColors.primaryMint : Color.clear)
                            .overlay(RoundedRectangle(cornerRadius: AppRadius.chip).stroke(AppColors.divider, lineWidth: inPosition ? 0 : 1))
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { inPosition = false }) {
                        Text("Вне позы (OOP)")
                            .font(AppTypography.subheadline)
                            .foregroundStyle(!inPosition ? AppColors.backgroundDeep : AppColors.textPrimary)
                            .padding(.vertical, AppSpacing.xs)
                            .frame(maxWidth: .infinity)
                            .background(!inPosition ? AppColors.primaryMint : Color.clear)
                            .overlay(RoundedRectangle(cornerRadius: AppRadius.chip).stroke(AppColors.divider, lineWidth: !inPosition ? 0 : 1))
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip))
                    }
                    .buttonStyle(.plain)
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
                        .padding(.vertical, 4)
                        .background(AppColors.accentLime.opacity(0.15))
                        .clipShape(Capsule())
                }
                
                // Position Selector
                HStack(spacing: AppSpacing.sm) {
                    ForEach(0..<positions.count, id: \.self) { i in
                        Button(action: { positionIndex = i }) {
                            Text(positions[i])
                                .font(AppTypography.subheadline)
                                .foregroundStyle(positionIndex == i ? AppColors.backgroundDeep : AppColors.textPrimary)
                                .padding(.vertical, AppSpacing.xs)
                                .frame(maxWidth: .infinity)
                                .background(positionIndex == i ? AppColors.primaryMint : Color.clear)
                                .overlay(RoundedRectangle(cornerRadius: AppRadius.chip).stroke(AppColors.divider, lineWidth: positionIndex == i ? 0 : 1))
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip))
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Strategy Selector
                HStack(spacing: AppSpacing.sm) {
                    Button(action: { isExploitative = false }) {
                        Text("Стандартный TAG")
                            .font(AppTypography.footnote)
                            .foregroundStyle(!isExploitative ? AppColors.backgroundDeep : AppColors.textPrimary)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .background(!isExploitative ? AppColors.accentPeach : Color.clear)
                            .overlay(RoundedRectangle(cornerRadius: AppRadius.chip).stroke(AppColors.divider, lineWidth: !isExploitative ? 0 : 1))
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { isExploitative = true }) {
                        Text("Широкий эксплойт")
                            .font(AppTypography.footnote)
                            .foregroundStyle(isExploitative ? AppColors.backgroundDeep : AppColors.textPrimary)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .background(isExploitative ? AppColors.accentPeach : Color.clear)
                            .overlay(RoundedRectangle(cornerRadius: AppRadius.chip).stroke(AppColors.divider, lineWidth: isExploitative ? 0 : 1))
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip))
                    }
                    .buttonStyle(.plain)
                }
                
                // Range display
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Диапазон открытия:")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    Text(handText)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(AppSpacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.backgroundDeep.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.chip)
                                .stroke(AppColors.divider, lineWidth: 0.5)
                        )
                }
                
                Text(isExploitative ? "🔥 Эксплойт: блайнды слишком тайтовые! Открываем широчайший спектр рук, чтобы забрать мертвые деньги." : "🛡️ Стандарт: классический плотный спектр открытия для защиты от 3-бетов.")
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColors.textSecondary)
                    .italic()
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
                        .padding(.vertical, 4)
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
                            Button(action: { selectedDepth = d }) {
                                Text("\(d) BB")
                                    .font(AppTypography.numericSmall)
                                    .foregroundStyle(selectedDepth == d ? AppColors.backgroundDeep : AppColors.textPrimary)
                                    .padding(.horizontal, AppSpacing.sm)
                                    .padding(.vertical, 6)
                                    .background(selectedDepth == d ? AppColors.accentPeach : Color.clear)
                                    .overlay(RoundedRectangle(cornerRadius: AppRadius.chip).stroke(AppColors.divider, lineWidth: selectedDepth == d ? 0 : 1))
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Position Selector
                HStack(spacing: AppSpacing.sm) {
                    ForEach(0..<positions.count, id: \.self) { i in
                        Button(action: { positionIndex = i }) {
                            Text(positions[i])
                                .font(AppTypography.subheadline)
                                .foregroundStyle(positionIndex == i ? AppColors.backgroundDeep : AppColors.textPrimary)
                                .padding(.vertical, AppSpacing.xs)
                                .frame(maxWidth: .infinity)
                                .background(positionIndex == i ? AppColors.primaryMint : Color.clear)
                                .overlay(RoundedRectangle(cornerRadius: AppRadius.chip).stroke(AppColors.divider, lineWidth: positionIndex == i ? 0 : 1))
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip))
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Range display
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Диапазон прямого пуша:")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    
                    Text(shovingRange)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(AppSpacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.backgroundDeep.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.chip)
                                .stroke(AppColors.divider, lineWidth: 0.5)
                        )
                }
                
                Text(selectedDepth >= 18 ? "⚠️ При 18 ББ диапазон пуша очень тайтовый. Здесь уже можно прибыльно минрейзить сильный бродвей для провокации." : "💡 При \(selectedDepth) ББ мин-рейзить маргинально — прямой пуш максимизирует фолд-эквити.")
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColors.textSecondary)
                    .italic()
            }
        }
    }
}

// MARK: - 4. C-Bet Situation Card
struct CBetSituationCard: View {
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
                
                // Situation 1: Dry Board
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Text("1. Сухая доска (Dry Rainbow)")
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppColors.textPrimary)
                            .bold()
                        Spacer()
                        Text("C-Bet: 80%+")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.primaryMint)
                            .bold()
                    }
                    
                    HStack(spacing: AppSpacing.md) {
                        // Let's render visual cards: Kc 7d 2s
                        BoardView(board: [
                            Card(notation: "Kc")!,
                            Card(notation: "7d")!,
                            Card(notation: "2s")!
                        ])
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Сайзинг: 25-33% пота")
                                .font(AppTypography.footnote)
                                .foregroundStyle(AppColors.accentLime)
                                .bold()
                            Text("Ставим со всем спектром. Оппоненты редко попадут и легко выкинут мусор.")
                                .font(AppTypography.footnote)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
                .padding(AppSpacing.sm)
                .background(AppColors.backgroundDeep.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip))
                
                // Situation 2: Wet Board
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Text("2. Дровяная доска (Wet Board)")
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppColors.textPrimary)
                            .bold()
                        Spacer()
                        Text("C-Bet: 30-40%")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.accentPeach)
                            .bold()
                    }
                    
                    HStack(spacing: AppSpacing.md) {
                        // Let's render visual cards: Qc Jd 9c
                        BoardView(board: [
                            Card(notation: "Qc")!,
                            Card(notation: "Jd")!,
                            Card(notation: "9c")!
                        ])
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Сайзинг: 65% - 75% пота")
                                .font(AppTypography.footnote)
                                .foregroundStyle(AppColors.accentCoral)
                                .bold()
                            Text("Только плотное велью или супер-дро. Пустые руки чекаем и сдаемся.")
                                .font(AppTypography.footnote)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
                .padding(AppSpacing.sm)
                .background(AppColors.backgroundDeep.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip))
            }
        }
    }
}

// MARK: - 5. Pot Odds & Equity Trainer Card
struct PotOddsTrainerCard: View {
    @State private var outs = 9
    @State private var betFraction = 0.5 // Bet size as fraction of pot (0.25 to 1.5)
    
    var equityFlop: Int {
        return outs * 4
    }
    
    var equityTurn: Int {
        return outs * 2
    }
    
    var requiredEquity: Double {
        // formula: bet / (pot + bet + call)
        // If bet is fraction of pot F: F / (1.0 + F + F) = F / (1.0 + 2F)
        return (betFraction / (1.0 + 2.0 * betFraction)) * 100.0
    }
    
    var isCallProfitable: Bool {
        return Double(equityFlop) >= requiredEquity
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
                        .padding(.vertical, 4)
                        .background(isCallProfitable ? AppColors.accentLime : AppColors.accentPeach)
                        .clipShape(Capsule())
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
                        Text("Ваше Эквити (Флоп):")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        Text("~ \(equityFlop)%")
                            .font(AppTypography.numericMedium)
                            .foregroundStyle(AppColors.primaryMint)
                    }
                    
                    HStack {
                        Text("Ваше Эквити (Терн):")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        Text("~ \(equityTurn)%")
                            .font(AppTypography.numericMedium)
                            .foregroundStyle(AppColors.textPrimary)
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
                
                Text(isCallProfitable ? "✅ Колл ВЫГОДЕН! Ваша вероятность доехать на флопе (\(equityFlop)%) выше стоимости билета (\(Int(requiredEquity))%). Это плюсовое действие на дистанции." : "❌ Колл НЕВЫГОДЕН. Шансов собрать руку (\(equityFlop)%) не хватает, чтобы перебить цену колла (\(Int(requiredEquity))%). Ищите фолд, если нет скрытых имплайд-оддсов.")
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(AppSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(isCallProfitable ? AppColors.primaryMint.opacity(0.08) : AppColors.accentPeach.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip))
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
