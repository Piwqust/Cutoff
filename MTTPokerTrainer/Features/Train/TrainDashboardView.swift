import SwiftUI
import SwiftData

struct TrainDashboardView: View {
    @Environment(ProgressStore.self) private var progress
    @Query(sort: [SortDescriptor(\QuizResult.createdAt, order: .reverse)])
    private var allResults: [QuizResult]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                progressCard
                heroDrillCard
                drillGrid
                statsRow
            }
            .padding(.horizontal, AppSpacing.pageHorizontal)
            .padding(.vertical, AppSpacing.lg)
        }
        .background(AppBackground().ignoresSafeArea())
        .navigationTitle("Train")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    // MARK: - Progress

    private var progressCard: some View {
        GlassCard(tint: AppColors.cardSurfaceGreen) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Level \(progress.level) · \(progress.rank)")
                            .font(AppTypography.title2)
                            .foregroundStyle(AppColors.textPrimary)
                        Text("\(progress.totalXP) XP · streak \(progress.streakDays)d")
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    Spacer()
                    if progress.streakDays > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                            Text("\(progress.streakDays)")
                                .font(AppTypography.bodyBold)
                        }
                        .foregroundStyle(AppColors.actionJam)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(AppColors.actionJam.opacity(0.14)))
                    }
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(AppColors.divider).frame(height: 8)
                        Capsule()
                            .fill(LinearGradient(
                                colors: [AppColors.primaryEmerald, AppColors.primaryMint],
                                startPoint: .leading,
                                endPoint: .trailing))
                            .frame(width: max(8, geo.size.width * max(0, min(1, progress.levelProgress))), height: 8)
                    }
                }
                .frame(height: 8)
                Text("\(progress.xpToNextLevel) XP to level \(progress.level + 1)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
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

    private var modeGrid: some View {
        VStack(spacing: AppSpacing.sm) {
            NavigationLink { PreflopTrainerView() } label: {
                TrainingModeCard(
                    title: TrainingMode.preflop.title,
                    subtitle: TrainingMode.preflop.subtitle,
                    systemImage: TrainingMode.preflop.systemImage
                )
            }.buttonStyle(.plain)
            NavigationLink { StackDepthTrainerView() } label: {
                TrainingModeCard(
                    title: TrainingMode.stackDepth.title,
                    subtitle: TrainingMode.stackDepth.subtitle,
                    systemImage: TrainingMode.stackDepth.systemImage,
                    tint: AppColors.accentLime
                )
            }.buttonStyle(.plain)
            NavigationLink { PushFoldTrainerView() } label: {
                TrainingModeCard(
                    title: TrainingMode.pushFold.title,
                    subtitle: TrainingMode.pushFold.subtitle,
                    systemImage: TrainingMode.pushFold.systemImage,
                    tint: AppColors.accentCoral
                )
            }.buttonStyle(.plain)
            NavigationLink { FlopTrainerView() } label: {
                TrainingModeCard(
                    title: TrainingMode.flop.title,
                    subtitle: TrainingMode.flop.subtitle,
                    systemImage: TrainingMode.flop.systemImage,
                    tint: AppColors.accentGreen
                )
            }.buttonStyle(.plain)
            NavigationLink { ReviewView() } label: {
                TrainingModeCard(
                    title: TrainingMode.mistakes.title,
                    subtitle: TrainingMode.mistakes.subtitle,
                    systemImage: TrainingMode.mistakes.systemImage,
                    tint: AppColors.accentPeach
                )
            }.buttonStyle(.plain)
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        let totalHands = allResults.count
        let accuracy = totalHands == 0 ? 0 : Int(round(Double(allResults.map(\.score).reduce(0, +)) / Double(totalHands)))
        let today = allResults.filter { Calendar.current.isDateInToday($0.createdAt) }.count
        let mistakes = allResults.filter { $0.outcome == .mistake || $0.outcome == .punt }.count

        return VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                StatCard(label: "Accuracy", value: totalHands == 0 ? "—" : "\(accuracy)%", hint: totalHands == 0 ? "Start a drill" : "all-time")
                StatCard(label: "Hands", value: "\(totalHands)", hint: "today: \(today)")
            }
            HStack(spacing: AppSpacing.sm) {
                StatCard(label: "Mistakes", value: "\(mistakes)", hint: "tap Review")
                StatCard(label: "Best drill", value: bestDrillLabel, hint: "highest rating")
            }
        }
    }

    private var bestDrillLabel: String {
        let scored = DrillCategory.allCases.map { ($0, progress.rating(for: $0)) }
        guard let top = scored.max(by: { $0.1 < $1.1 }), top.1 > 1000 else { return "—" }
        return top.0.title
    }
}

private struct DrillRow: View {
    let category: DrillCategory
    let rating: Int

    var body: some View {
        GlassCard(padding: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: category.systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .foregroundStyle(AppColors.primaryMint)
                    .background(Circle().fill(AppColors.primaryMint.opacity(0.14)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.title)
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(category.subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(rating)")
                        .font(AppTypography.numericMedium)
                        .foregroundStyle(ratingColor)
                    Text("rating")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
    }

    private var ratingColor: Color {
        switch rating {
        case ..<950:   return AppColors.accentCoral
        case ..<1050:  return AppColors.textPrimary
        case ..<1200:  return AppColors.accentLime
        default:       return AppColors.primaryMint
        }
    }
}

#Preview {
    NavigationStack { TrainDashboardView() }
        .environment(ConfigStore())
        .environment(ProgressStore())
        .modelContainer(for: [QuizResult.self, TrainingSession.self], inMemory: true)
}
