import SwiftUI
import SwiftData

struct TrainDashboardView: View {
    @Environment(ProgressStore.self) private var progress
    @Environment(RangeService.self) private var rangeService
    @Query(sort: [SortDescriptor(\QuizResult.createdAt, order: .reverse)])
    private var allResults: [QuizResult]

    @State private var moreExpanded: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    statStrip
                    if let resume = resumeCategory { continueChip(resume) }
                    heroDrillCard
                    drillGrid
                    moreSection
                }
                .padding(.horizontal, AppSpacing.pageHorizontal)
                .padding(.vertical, AppSpacing.lg)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Train")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }

    // MARK: - Stat strip

    /// One-line caption above the hero CTA. Replaces the level/XP/streak
    /// progress card and the 2×2 stats grid. The streak chip only appears
    /// when there's a streak to celebrate.
    private var statStrip: some View {
        let totalHands = allResults.count
        let accuracy = totalHands == 0
            ? 0
            : Int(round(Double(allResults.map(\.score).reduce(0, +)) / Double(totalHands)))
        let today = allResults.filter { Calendar.current.isDateInToday($0.createdAt) }.count

        return HStack(spacing: AppSpacing.sm) {
            if totalHands == 0 {
                Text("Start a drill to track accuracy.")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            } else {
                statSegment(value: "\(accuracy)%", label: "accuracy")
                statDot
                statSegment(value: "\(totalHands)", label: totalHands == 1 ? "hand" : "hands")
                if today > 0 {
                    statDot
                    statSegment(value: "\(today)", label: "today")
                }
            }
            Spacer(minLength: 0)
            if progress.streakDays > 0 {
                streakChip
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func statSegment(value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .font(AppTypography.numericSmall)
                .foregroundStyle(AppColors.textPrimary)
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var statDot: some View {
        Circle()
            .fill(AppColors.divider)
            .frame(width: 3, height: 3)
    }

    private var streakChip: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(AppTypography.caption.weight(.bold))
            Text("\(progress.streakDays)d")
                .font(AppTypography.caption.weight(.bold))
                .monospacedDigit()
        }
        .foregroundStyle(AppColors.actionJam)
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, 3)
        .background(Capsule().fill(AppColors.actionJam.opacity(0.14)))
        .accessibilityLabel("\(progress.streakDays) day streak")
    }

    // MARK: - Continue chip

    /// The most recent answered drill, if one is recoverable from the last
    /// QuizResult's categoryRaw. Pre-rebuild rows have an empty categoryRaw
    /// and intentionally produce no chip — we'd rather hide it than guess.
    private var resumeCategory: DrillCategory? {
        guard let last = allResults.first, !last.categoryRaw.isEmpty else { return nil }
        return DrillCategory(rawValue: last.categoryRaw)
    }

    private func continueChip(_ category: DrillCategory) -> some View {
        NavigationLink { DrillTrainerView(category: category) } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "arrow.uturn.forward")
                    .font(AppTypography.footnote.weight(.bold))
                    .foregroundStyle(AppColors.accentGreen)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Continue")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1.5)
                    Text(category.title)
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(AppTypography.caption.weight(.bold))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .fill(AppColors.accentGreen.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(AppColors.accentGreen.opacity(0.30), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Continue \(category.title)")
    }

    // MARK: - Hero drill (adaptive: top leak when present, otherwise Mixed)

    /// When a high-severity leak exists, the hero card surfaces it and routes
    /// to the drill most likely to put the user in that spot. Otherwise it
    /// falls back to the Mixed live drill.
    private var heroDrillCard: some View {
        let leak = topLeak()
        let category = leak.map { drillCategory(for: $0) } ?? .standardRoutine
        let kicker  = leak == nil ? "Today's warmup" : "Today's leak"
        let title   = leak?.title    ?? category.title
        let subtitle = leak?.detail  ?? category.subtitle

        return GlassCard(cornerRadius: AppRadius.hero, padding: AppSpacing.xl) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text(kicker)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.5)

                Text(title)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)

                Text(subtitle)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                NavigationLink {
                    DrillTrainerView(category: category)
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Text("Start")
                            .font(AppTypography.headline)
                        Image(systemName: "arrow.right")
                            .font(AppTypography.footnote.weight(.bold))
                    }
                    .foregroundStyle(AppColors.backgroundDeep)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.sm)
                    .background(Capsule().fill(AppColors.primaryMint))
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Highest-severity leak from the analyzer, if it clears the same
    /// threshold ReviewView's leak cards use. Returns nil for new users
    /// (fewer than the analyzer's internal sample floor).
    private func topLeak() -> Leak? {
        let leaks = LeakAnalyzer.leaks(from: allResults) { id in
            rangeService.chart(byID: id)
        }
        return leaks.first
    }

    /// Pick the drill category whose facing-action best matches the leak's
    /// suggested spot. Fallback is .mixed when the leak has no spot hint
    /// (hand-class and direction-of-error leaks).
    private func drillCategory(for leak: Leak) -> DrillCategory {
        guard let spot = leak.suggestedSpot else { return .mixed }
        switch spot.facingAction {
        case .pushFold:     return .firstInJam
        case .vs3Bet:       return .vsManiac
        case .squeeze:      return .reJam
        case .unopened:     return .mixed
        case .vsOpen:       return .mixed
        case .blindDefense: return .mixed
        }
    }

    private var drillGrid: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(DrillCategory.allCases.filter { $0 != .mixed && $0 != .standardRoutine }) { category in
                NavigationLink { DrillTrainerView(category: category) } label: {
                    TrainingModeCard(
                        title: category.title,
                        subtitle: category.subtitle,
                        systemImage: category.systemImage
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - More (custom drill + review)

    /// Both secondary destinations hide behind a single toggle so the
    /// dashboard above the fold is just stats → continue → hero → drills.
    private var moreSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Button {
                withAnimation(AppMotion.respecting(reduceMotion, .easeOut(duration: 0.22))) {
                    moreExpanded.toggle()
                }
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Text(moreExpanded ? "Hide more" : "More")
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(AppColors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Image(systemName: "chevron.down")
                        .font(AppTypography.caption.weight(.bold))
                        .foregroundStyle(AppColors.textSecondary)
                        .rotationEffect(.degrees(moreExpanded ? 180 : 0))
                    Spacer(minLength: 0)
                }
                .padding(.vertical, AppSpacing.sm)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(moreExpanded ? "Hide more" : "Show more")

            if moreExpanded {
                VStack(spacing: AppSpacing.sm) {
                    NavigationLink { DrillPickerView() } label: {
                        TrainingModeCard(
                            title: "Custom Drill",
                            subtitle: "Pick position, depth & scenario",
                            systemImage: "slider.horizontal.3",
                            tint: AppColors.accentGreen
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink { ReviewView() } label: {
                        TrainingModeCard(
                            title: "Review mistakes",
                            subtitle: "Replay spots where you lost EV",
                            systemImage: "magnifyingglass",
                            tint: AppColors.accentPeach
                        )
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity)
            }
        }
    }
}

#Preview {
    NavigationStack { TrainDashboardView() }
        .environment(ConfigStore())
        .environment(ProgressStore())
        .environment(RangeService())
        .modelContainer(for: [QuizResult.self, TrainingSession.self], inMemory: true)
}
