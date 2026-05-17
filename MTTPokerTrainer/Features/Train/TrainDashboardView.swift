import SwiftUI
import SwiftData

struct TrainDashboardView: View {
    @Environment(ProgressStore.self) private var progress
    @Query(sort: [SortDescriptor(\QuizResult.createdAt, order: .reverse)])
    private var allResults: [QuizResult]

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    statStrip
                    heroDrillCard
                    drillGrid
                    customDrillLink
                    reviewLink
                }
                .padding(.horizontal, AppSpacing.pageHorizontal)
                .padding(.vertical, AppSpacing.lg)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Train")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
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
                .font(.system(size: 11, weight: .bold))
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

    // MARK: - Hero drill (Mixed live)

    private var heroDrillCard: some View {
        GlassCard(cornerRadius: AppRadius.hero, padding: AppSpacing.xl) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Today's MTT drill")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.5)

                Text(DrillCategory.mixed.title)
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)

                Text(DrillCategory.mixed.subtitle)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                NavigationLink {
                    DrillTrainerView(category: .mixed)
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Text("Start")
                            .font(AppTypography.headline)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .bold))
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

    private var drillGrid: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(DrillCategory.allCases.filter { $0 != .mixed }) { category in
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

    private var customDrillLink: some View {
        NavigationLink { DrillPickerView() } label: {
            TrainingModeCard(
                title: "Custom Drill",
                subtitle: "Pick position, depth & scenario",
                systemImage: "slider.horizontal.3",
                tint: AppColors.accentGreen
            )
        }
        .buttonStyle(.plain)
    }

    private var reviewLink: some View {
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
}

#Preview {
    NavigationStack { TrainDashboardView() }
        .environment(ConfigStore())
        .environment(ProgressStore())
        .environment(RangeService())
        .modelContainer(for: [QuizResult.self, TrainingSession.self], inMemory: true)
}
