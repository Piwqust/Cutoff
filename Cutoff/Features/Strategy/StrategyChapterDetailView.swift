import SwiftUI

// MARK: - Parent Chapter Pager View
struct StrategyChapterDetailView: View {
    let startingChapterId: Int
    @State private var activeWeekId: String
    @State private var selectedChapterId: Int?
    
    @Environment(LocalizationManager.self) private var l10n
    @Environment(\.dismiss) private var dismiss
    
    init(chapter: StrategyChapter, weekId: String) {
        self.startingChapterId = chapter.id
        self._activeWeekId = State(initialValue: weekId)
        self._selectedChapterId = State(initialValue: chapter.id)
    }
    
    var body: some View {
        let guides = StrategyStore.allGuides
        let currentGuide = guides.first(where: { $0.id == activeWeekId }) ?? StrategyStore.activeGuide
        let chapters = currentGuide.chapters
        
        ZStack {
            AppBackground()
            
            VStack(spacing: 0) {
                // Horizontal Swiping Pager
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(chapters, id: \.id) { chap in
                            StrategyChapterDetailContentView(chapter: chap, weekId: activeWeekId)
                                .id(chap.id)
                                .containerRelativeFrame(.horizontal)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $selectedChapterId)
                .sensoryFeedback(.selection, trigger: selectedChapterId) // Subtle haptic tick on page flip!
                
                // Dynamic Navigation Footer Card
                bottomNavigationCard(chapters: chapters, guides: guides)
            }
        }
        .navigationTitle(currentGuide.subtitle(for: l10n.language))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Dynamic Bottom Navigation Footer
    @ViewBuilder
    private func bottomNavigationCard(chapters: [StrategyChapter], guides: [WeeklyGuide]) -> some View {
        let currentWeekIndex = guides.firstIndex(where: { $0.id == activeWeekId }) ?? 0
        let hasNextPastWeek = currentWeekIndex + 1 < guides.count
        let hasPrevFutureWeek = currentWeekIndex - 1 >= 0
        
        let currentChapterId = selectedChapterId ?? 1
        
        HStack {
            // PREVIOUS BUTTON
            if currentChapterId > 1 {
                // Standard Previous Chapter
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedChapterId = currentChapterId - 1
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(l10n.language == .english ? "Prev" : "Назад")
                    }
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.primaryMint)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 8)
                    .background(AppColors.primaryMint.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else if hasPrevFutureWeek {
                // Transition to Future Week (e.g. Chapter 5 of next week)
                Button(action: {
                    let prevWeek = guides[currentWeekIndex - 1]
                    withAnimation(.easeInOut(duration: 0.35)) {
                        activeWeekId = prevWeek.id
                        selectedChapterId = prevWeek.chapters.count
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left.to.line.compact")
                        Text(l10n.language == .english ? "Newer Week" : "Новее катка")
                    }
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.accentLime)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 8)
                    .background(AppColors.accentLime.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else {
                // Placeholder to maintain spacing
                Spacer().frame(width: 10)
            }
            
            Spacer()
            
            // CHAPTER DOT INDICATORS
            HStack(spacing: 6) {
                ForEach(chapters, id: \.id) { chap in
                    Circle()
                        .fill(currentChapterId == chap.id ? AppColors.primaryMint : AppColors.divider.opacity(0.5))
                        .frame(width: currentChapterId == chap.id ? 8 : 6, height: currentChapterId == chap.id ? 8 : 6)
                        .scaleEffect(currentChapterId == chap.id ? 1.2 : 1.0)
                        .animation(.spring, value: currentChapterId)
                }
            }
            
            Spacer()
            
            // NEXT BUTTON
            if currentChapterId < chapters.count {
                // Standard Next Chapter
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedChapterId = currentChapterId + 1
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(l10n.language == .english ? "Next" : "Далее")
                        Image(systemName: "chevron.right")
                    }
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.primaryMint)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 8)
                    .background(AppColors.primaryMint.opacity(0.1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else if hasNextPastWeek {
                // Transition to chronological Past Week (Chapter 1)
                Button(action: {
                    let nextWeek = guides[currentWeekIndex + 1]
                    withAnimation(.easeInOut(duration: 0.35)) {
                        activeWeekId = nextWeek.id
                        selectedChapterId = 1
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(l10n.language == .english ? "Past Week" : "Архив каток")
                        Image(systemName: "arrow.right.to.line.compact")
                    }
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.accentPeach)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 8)
                    .background(AppColors.accentPeach.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else {
                // Last Chapter of Last Week -> Back to list
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Text(l10n.language == .english ? "Exit Guide" : "Закончить")
                        Image(systemName: "checkmark.circle.fill")
                    }
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.accentLime)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 8)
                    .background(AppColors.accentLime.opacity(0.15))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.pageHorizontal)
        .padding(.vertical, AppSpacing.sm)
        .background(.ultraThinMaterial)
        .overlay(Divider().overlay(AppColors.divider.opacity(0.5)), alignment: .top)
    }
}

// MARK: - Child Detailed Content View
struct StrategyChapterDetailContentView: View {
    let chapter: StrategyChapter
    let weekId: String
    
    @Environment(LocalizationManager.self) private var l10n
    
    @State private var isCompleted: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                
                // Chapter Title Area
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack {
                        Text(chapter.tag.uppercased())
                            .font(AppTypography.caption)
                            .bold()
                            .foregroundStyle(AppColors.primaryMint)
                            .padding(.horizontal, AppSpacing.xs)
                            .padding(.vertical, 4)
                            .background(AppColors.primaryMint.opacity(0.12))
                            .clipShape(Capsule())
                        
                        Spacer()
                        
                        if isCompleted {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                Text(l10n.language == .english ? "STUDIED" : "ИЗУЧЕНО")
                            }
                            .font(AppTypography.caption)
                            .bold()
                            .foregroundStyle(AppColors.accentLime)
                            .padding(.horizontal, AppSpacing.xs)
                            .padding(.vertical, 4)
                            .background(AppColors.accentLime.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }
                    
                    Text(chapter.title(for: l10n.language))
                        .font(AppTypography.title)
                        .foregroundStyle(AppColors.textPrimary)
                }
                
                // Dedicated Container for Interactive Utility
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(l10n.language == .english ? "SANDBOX UTILITY" : "ИНТЕРАКТИВНЫЙ ИНСТРУМЕНТ")
                        .font(AppTypography.caption)
                        .bold()
                        .foregroundStyle(AppColors.textSecondary)
                        .tracking(1.0)
                    
                    if weekId == "2026-06-01" {
                        embeddedComponent(for: chapter.id)
                    } else {
                        historicalStaticComponent(for: chapter.id)
                    }
                }
                
                // Detailed Theory Blocks
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text(l10n.language == .english ? "TACTICAL SUMMARY" : "ТЕОРЕТИЧЕСКИЙ РАЗБОР")
                        .font(AppTypography.caption)
                        .bold()
                        .foregroundStyle(AppColors.textSecondary)
                        .tracking(1.0)
                    
                    // WHAT TO DO PANEL
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColors.accentLime)
                            Text(l10n.language == .english ? "WHAT TO DO:" : "ЧТО ДЕЛАТЬ:")
                                .font(AppTypography.caption)
                                .bold()
                                .foregroundStyle(AppColors.accentLime)
                        }
                        Text(chapter.whatsDo(for: l10n.language))
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textPrimary)
                            .lineSpacing(4)
                    }
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.primaryMint.opacity(0.06))
                    .cornerRadius(AppRadius.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.card)
                            .stroke(AppColors.divider.opacity(0.4), lineWidth: 0.5)
                    )
                    
                    // WHY PANEL (WITH LIVE HAND HISTORY SCENARIO)
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        HStack(spacing: 6) {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundStyle(AppColors.textSecondary)
                            Text(l10n.language == .english ? "WHY & LIVE EXAMPLE:" : "ПОЧЕМУ И ЖИВОЙ ПРИМЕР:")
                                .font(AppTypography.caption)
                                .bold()
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        Text(chapter.why(for: l10n.language))
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineSpacing(4)
                    }
                    .padding(AppSpacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.18))
                    .cornerRadius(AppRadius.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.card)
                            .stroke(AppColors.divider.opacity(0.3), lineWidth: 0.5)
                    )
                }
                
                Spacer(minLength: AppSpacing.lg)
                
                // Mark as Studied Haptic Button
                Button(action: toggleCompletion) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.headline)
                        Text(isCompleted ? 
                             (l10n.language == .english ? "Studied! Tap to Undo" : "Глава изучена! Сбросить") :
                             (l10n.language == .english ? "Mark as Studied" : "Отметить как изученное"))
                            .font(AppTypography.bodyBold)
                    }
                    .foregroundStyle(isCompleted ? AppColors.backgroundDeep : AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(isCompleted ? AppColors.accentLime : AppColors.primaryMint.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.button)
                            .stroke(isCompleted ? Color.clear : AppColors.primaryMint, lineWidth: 1.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.success, trigger: isCompleted) // iOS 17+ sensory feedback!
            }
            .padding(.horizontal, AppSpacing.pageHorizontal)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, AppSpacing.huge) // Extra breathing room for pager bottom footer
        }
        .onAppear {
            isCompleted = UserDefaults.standard.bool(forKey: "strategy.completed.\(weekId).\(chapter.id)")
        }
    }
    
    // MARK: - Toggle Actions & Haptics
    private func toggleCompletion() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            isCompleted.toggle()
            UserDefaults.standard.set(isCompleted, forKey: "strategy.completed.\(weekId).\(chapter.id)")
        }
    }
    
    // MARK: - Router for Embedded Widgets
    @ViewBuilder
    private func embeddedComponent(for chapterId: Int) -> some View {
        switch chapterId {
        case 1: LimperIsolationCard()
        case 2: StealRangesCard()
        case 3: FirstInJamCard()
        case 4: CBetSituationCard()
        case 5: PotOddsTrainerCard()
        default: EmptyView()
        }
    }
    
    // MARK: - Static Widget for History Archives
    @ViewBuilder
    private func historicalStaticComponent(for chapterId: Int) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(AppColors.textSecondary)
                    Text(l10n.language == .english ? "Archive Sandbox" : "Архивный тренажер")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Text(l10n.language == .english ? 
                     "This sandbox calculator belonged to a previous weekly training session. Review the historical hand examples above." :
                     "Этот интерактивный инструмент относится к архивной неделе обучения. Изучите исторические примеры выше.")
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColors.textSecondary)
                    .italic()
            }
        }
    }
}
