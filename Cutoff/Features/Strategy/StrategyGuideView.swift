import SwiftUI

struct StrategyGuideView: View {
    @Environment(LocalizationManager.self) private var l10n
    @Environment(ConfigStore.self) private var config

    @State private var selectedGuide: WeeklyGuide = StrategyStore.activeGuide
    @State private var showDeveloperMenu = false

    /// Reactive completion state — drives the "Studied" badges without manual redraws.
    private var progress: StrategyProgressStore { .shared }

    /// Number of chapters in the selected week the user has marked studied.
    private var studiedCount: Int {
        selectedGuide.chapters.filter { progress.isStudied(week: selectedGuide.id, chapter: $0.id) }.count
    }

    /// The Strategy tab is authored in Russian only. Other languages get a notice.
    private var isLanguageSupported: Bool {
        l10n.language != .english
    }

    var body: some View {
        ZStack {
            AppBackground()

            if isLanguageSupported {
                guideContent
            } else {
                StrategyUnsupportedLanguageView()
            }
        }
        .navigationTitle(isLanguageSupported ? selectedGuide.title(for: l10n.language) : "Стратегия")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(isLanguageSupported ? selectedGuide.title(for: l10n.language) : "Стратегия")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)
                    .onTapGesture(count: 5) {
                        showDeveloperMenu = true
                    }
            }
        }
        .sheet(isPresented: $showDeveloperMenu) {
            DeveloperStrategyDocView()
        }
    }

    // MARK: - Guide Content (Russian)
    private var guideContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {

                // Week Selector Dropdown Menu
                weekSelectorMenu

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack {
                        Text("ГЛАВЫ ОБУЧЕНИЯ")
                            .font(AppTypography.caption)
                            .bold()
                            .foregroundStyle(AppColors.textSecondary)
                            .tracking(1.0)
                        Spacer()
                        progressBadge(studied: studiedCount, total: selectedGuide.chapters.count)
                    }
                    .padding(.horizontal, AppSpacing.xxs)

                    // List of Chapters as NavLinks
                    VStack(spacing: AppSpacing.md) {
                        ForEach(selectedGuide.chapters) { chapter in
                            let isCompleted = progress.isStudied(week: selectedGuide.id, chapter: chapter.id)

                            NavigationLink(
                                destination: StrategyChapterDetailView(
                                    chapter: chapter,
                                    weekId: selectedGuide.id
                                )
                            ) {
                                chapterRow(chapter: chapter, isCompleted: isCompleted)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.pageHorizontal)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, 80) // Luxurious bottom spacing above tab bar
        }
    }

    // MARK: - Aggregate Progress Badge
    /// Compact ring + "x/y" pill summarizing how many chapters in the week are studied.
    @ViewBuilder
    private func progressBadge(studied: Int, total: Int) -> some View {
        let fraction = total > 0 ? Double(studied) / Double(total) : 0
        let isComplete = total > 0 && studied == total
        let tint = isComplete ? AppColors.accentLime : AppColors.primaryMint

        HStack(spacing: AppSpacing.xxs) {
            ZStack {
                Circle()
                    .stroke(AppColors.divider.opacity(0.4), lineWidth: 2.5)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(tint, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 15, height: 15)

            Text("\(studied)/\(total)")
                .font(AppTypography.caption)
                .bold()
                .foregroundStyle(isComplete ? AppColors.accentLime : AppColors.textSecondary)
                .monospacedDigit()
        }
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, AppSpacing.xxs)
        .background(tint.opacity(0.12))
        .clipShape(Capsule())
        .animation(.easeInOut(duration: 0.25), value: studied)
        .accessibilityElement()
        .accessibilityLabel("Изучено \(studied) из \(total) глав")
    }

    // MARK: - Chapter Row
    @ViewBuilder
    private func chapterRow(chapter: StrategyChapter, isCompleted: Bool) -> some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    // Category Tag Badge
                    Text(chapter.localizedTag(for: l10n.language).uppercased())
                        .font(AppTypography.caption)
                        .bold()
                        .foregroundStyle(AppColors.primaryMint)
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, 2)
                        .background(AppColors.primaryMint.opacity(0.12))
                        .clipShape(Capsule())

                    Spacer()

                    // Dynamic studied checkmark
                    if isCompleted {
                        HStack(spacing: AppSpacing.xxs) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColors.accentLime)
                            Text("Изучено")
                                .font(AppTypography.caption)
                                .bold()
                                .foregroundStyle(AppColors.accentLime)
                        }
                        .padding(.horizontal, AppSpacing.xs)
                        .padding(.vertical, 2)
                        .background(AppColors.accentLime.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }

                // Chapter Title
                Text(chapter.title(for: l10n.language))
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.leading)

                // 1-line Description preview
                Text(chapter.shortDescription(for: l10n.language))
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            // Disclosure chevron
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(AppSpacing.md)
        .liquidGlass(in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous), interactive: true)
    }

    // MARK: - Week Dropdown Menu
    private var weekSelectorMenu: some View {
        Menu {
            ForEach(StrategyStore.allGuides) { guide in
                Button(action: {
                    withAnimation {
                        selectedGuide = guide
                    }
                }) {
                    HStack {
                        Text(guide.subtitle(for: l10n.language))
                        if selectedGuide.id == guide.id {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(AppColors.primaryMint)

                VStack(alignment: .leading, spacing: 2) {
                    Text(l10n.t(.pastGuides))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Text(selectedGuide.subtitle(for: l10n.language))
                        .font(AppTypography.subheadline)
                        .bold()
                        .foregroundStyle(AppColors.textPrimary)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.footnote)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(AppSpacing.md)
            .liquidGlass(in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous), interactive: true)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Unsupported Language Notice
struct StrategyUnsupportedLanguageView: View {
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "globe")
                .font(.system(size: 44))
                .foregroundStyle(AppColors.primaryMint)

            VStack(spacing: AppSpacing.xs) {
                Text("Язык пока не поддерживается")
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Вкладка «Стратегия» сейчас доступна только на русском языке. Перейдите на вкладку Настройки (Settings), чтобы переключить язык.")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppSpacing.pageHorizontal)
    }
}

#Preview {
    NavigationStack {
        StrategyGuideView()
            .environment(ConfigStore())
            .environment(LocalizationManager())
    }
}
