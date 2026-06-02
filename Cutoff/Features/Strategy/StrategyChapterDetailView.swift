import SwiftUI

// MARK: - Parent Chapter Pager View
struct StrategyChapterDetailView: View {
    let startingChapterId: Int
    @State private var activeWeekId: String
    @State private var selectedChapterId: Int?

    @Environment(LocalizationManager.self) private var l10n
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

            // 1. Swiping pager and soft black fade gradient (ignoring safe areas to bleed under tab bar)
            ZStack(alignment: .bottom) {
                // Horizontal Swiping Pager
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(chapters, id: \.id) { chap in
                            StrategyChapterDetailContentView(chapter: chap, weekId: activeWeekId)
                                .id(chap.id)
                                .containerRelativeFrame(.horizontal)
                                .containerRelativeFrame(.vertical)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $selectedChapterId)
                .sensoryFeedback(.selection, trigger: selectedChapterId) // Subtle haptic tick on page flip!
                .ignoresSafeArea(edges: .bottom) // Let the pager content flow all the way under the tab bar!

                // Apple-style soft black fade gradient behind the dock for flawless contrast
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.85), // Gentle backing at the bottom edge to absorb refraction
                        Color.black.opacity(0.4),  // Light mid-fade cover
                        Color.black.opacity(0.0)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 160) // Lighter and more compact cover spanning over tab bar & dock
                .allowsHitTesting(false) // Allow touch interaction to pass through to the scroll view
            }
            .ignoresSafeArea(edges: .bottom) // Expand ZStack to the absolute bottom screen edge

            // 2. Navigation Footer Card (respecting safe areas so it floats beautifully above the tab bar)
            VStack {
                Spacer()
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
                navPill(text: "Назад", systemImage: "chevron.left", tint: AppColors.primaryMint, font: AppTypography.subheadline) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedChapterId = currentChapterId - 1
                    }
                }
            } else if hasPrevFutureWeek {
                // Transition to Future Week (e.g. Chapter 5 of next week)
                navPill(text: l10n.language == .russianGenZ ? "Новее катка" : "Новее", systemImage: "arrow.left.to.line.compact", tint: AppColors.accentLime, font: AppTypography.caption) {
                    let prevWeek = guides[currentWeekIndex - 1]
                    withAnimation(.easeInOut(duration: 0.35)) {
                        activeWeekId = prevWeek.id
                        selectedChapterId = prevWeek.chapters.count
                    }
                }
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
                        .animation(reduceMotion ? nil : .spring, value: currentChapterId)
                }
            }

            Spacer()

            // NEXT BUTTON
            if currentChapterId < chapters.count {
                // Standard Next Chapter
                navPill(text: "Далее", systemImage: "chevron.right", tint: AppColors.primaryMint, font: AppTypography.subheadline, trailingIcon: true) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedChapterId = currentChapterId + 1
                    }
                }
            } else if hasNextPastWeek {
                // Transition to chronological Past Week (Chapter 1)
                navPill(text: l10n.language == .russianGenZ ? "Архив каток" : "Архив", systemImage: "arrow.right.to.line.compact", tint: AppColors.accentPeach, font: AppTypography.caption, trailingIcon: true) {
                    let nextWeek = guides[currentWeekIndex + 1]
                    withAnimation(.easeInOut(duration: 0.35)) {
                        activeWeekId = nextWeek.id
                        selectedChapterId = 1
                    }
                }
            } else {
                // Last Chapter of Last Week -> Back to list
                navPill(text: "Закончить", systemImage: "checkmark.circle.fill", tint: AppColors.accentLime, font: AppTypography.caption, trailingIcon: true) {
                    dismiss()
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.md)
        .liquidGlass(in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .padding(.horizontal, AppSpacing.pageHorizontal)
        .padding(.bottom, AppSpacing.md)
    }

    // MARK: - Reusable Nav Pill
    @ViewBuilder
    private func navPill(text: String, systemImage: String, tint: Color, font: Font, trailingIcon: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xxs) {
                if !trailingIcon { Image(systemName: systemImage) }
                Text(text)
                if trailingIcon { Image(systemName: systemImage) }
            }
            .font(font)
            .foregroundStyle(tint)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .liquidGlass(in: Capsule(), interactive: true)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Child Detailed Content View
struct StrategyChapterDetailContentView: View {
    let chapter: StrategyChapter
    let weekId: String

    @Environment(LocalizationManager.self) private var l10n

    private var progress: StrategyProgressStore { .shared }
    private var isCompleted: Bool { progress.isStudied(week: weekId, chapter: chapter.id) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {

                // Chapter Title Area
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack {
                        Text(chapter.localizedTag(for: l10n.language).uppercased())
                            .font(AppTypography.caption)
                            .bold()
                            .foregroundStyle(AppColors.primaryMint)
                            .padding(.horizontal, AppSpacing.xs)
                            .padding(.vertical, AppSpacing.xxs)
                            .background(AppColors.primaryMint.opacity(0.12))
                            .clipShape(Capsule())

                        Spacer()

                        if isCompleted {
                            HStack(spacing: AppSpacing.xxs) {
                                Image(systemName: "checkmark.seal.fill")
                                Text("ИЗУЧЕНО")
                            }
                            .font(AppTypography.caption)
                            .bold()
                            .foregroundStyle(AppColors.accentLime)
                            .padding(.horizontal, AppSpacing.xs)
                            .padding(.vertical, AppSpacing.xxs)
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
                    Text("ИНТЕРАКТИВНЫЙ ИНСТРУМЕНТ")
                        .font(AppTypography.caption)
                        .bold()
                        .foregroundStyle(AppColors.textSecondary)
                        .tracking(1.0)

                    if weekId == "2026-06-01" {
                        embeddedComponent(for: chapter.id)
                    } else {
                        historicalStaticComponent()
                    }
                }

                // Detailed Theory Blocks
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("ТЕОРЕТИЧЕСКИЙ РАЗБОР")
                        .font(AppTypography.caption)
                        .bold()
                        .foregroundStyle(AppColors.textSecondary)
                        .tracking(1.0)

                    // WHAT TO DO PANEL
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColors.accentLime)
                            Text("ЧТО ДЕЛАТЬ:")
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

                    // WHY PANEL (the reasoning, scenario stripped out)
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        HStack(spacing: 6) {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundStyle(AppColors.textSecondary)
                            Text("ПОЧЕМУ ЭТО РАБОТАЕТ:")
                                .font(AppTypography.caption)
                                .bold()
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        Text(chapter.whyReason(for: l10n.language))
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

                    // LIVE HAND EXAMPLE — its own scannable card
                    if let scenario = chapter.whyScenario(for: l10n.language) {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            HStack(spacing: 6) {
                                Image(systemName: "book.pages.fill")
                                    .foregroundStyle(AppColors.primaryMint)
                                Text(scenario.title.uppercased())
                                    .font(AppTypography.caption)
                                    .bold()
                                    .foregroundStyle(AppColors.primaryMint)
                            }
                            Text(scenario.body)
                                .font(AppTypography.subheadline)
                                .foregroundStyle(AppColors.textPrimary)
                                .lineSpacing(4)
                        }
                        .padding(AppSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                                .fill(AppColors.primaryMint.opacity(0.07))
                        )
                        .overlay(alignment: .leading) {
                            // Accent spine to set the worked example apart visually.
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AppColors.primaryMint)
                                .frame(width: 3)
                                .padding(.vertical, AppSpacing.sm)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.card)
                                .stroke(AppColors.primaryMint.opacity(0.25), lineWidth: 0.5)
                        )
                    }
                }

                Spacer(minLength: AppSpacing.lg)

                // Mark as Studied Haptic Button
                Button(action: toggleCompletion) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.headline)
                        Text(isCompleted ? "Глава изучена! Сбросить" : "Отметить как изученное")
                            .font(AppTypography.bodyBold)
                    }
                    .foregroundStyle(isCompleted ? AppColors.backgroundDeep : AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        Group {
                            if isCompleted {
                                RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                                    .fill(AppColors.accentLime)
                            } else {
                                RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                                    .fill(Color.clear)
                                    .liquidGlass(in: RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous), interactive: true)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.success, trigger: isCompleted) // iOS 17+ sensory feedback!
            }
            .padding(.horizontal, AppSpacing.pageHorizontal)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, 180) // Clears the floating nav dock while avoiding excess dead scroll
        }
    }

    // MARK: - Toggle Actions & Haptics
    private func toggleCompletion() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            progress.toggle(week: weekId, chapter: chapter.id)
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
    private func historicalStaticComponent() -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(AppColors.textSecondary)
                    Text("Архивный тренажер")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Text("Этот интерактивный инструмент относится к архивной неделе обучения. Изучите исторические примеры выше.")
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColors.textSecondary)
                    .italic()
            }
        }
    }
}
