import SwiftUI
import SwiftData

struct TrainDashboardView: View {
    @Environment(ConfigStore.self) private var config
    @Query(sort: [SortDescriptor(\QuizResult.createdAt, order: .reverse)])
    private var allResults: [QuizResult]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                profileChip
                heroDrillCard
                modeGrid
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

    // MARK: - Sections

    private var profileChip: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "person.2.fill")
                .foregroundStyle(AppColors.primaryMint)
            Text("\(config.config.tableSize)-max MTT · \(config.config.startingBB) BB start")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 6)
        .background(Capsule().fill(AppColors.cardSurface))
        .accessibilityLabel("Active profile: \(config.config.tableSize)-max MTT at \(config.config.startingBB) big blinds")
    }

    private var heroDrillCard: some View {
        GlassCard(cornerRadius: AppRadius.hero, tint: AppColors.cardSurfaceGreen, padding: AppSpacing.xl) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Today's MTT drill")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.5)

                Text("\(config.config.startingBB) BB · \(config.config.tableSize)-max · Preflop")
                    .font(AppTypography.title2)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Drill the spots you'll see most often at the start of a tournament.")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                NavigationLink {
                    PreflopTrainerView()
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

    private var statsRow: some View {
        let totalHands = allResults.count
        let accuracy = totalHands == 0 ? 0 : Int(round(Double(allResults.map(\.score).reduce(0, +)) / Double(totalHands)))
        let today = allResults.filter { Calendar.current.isDateInToday($0.createdAt) }.count
        let biggestLeak = LeakAnalyzer.leaks(from: allResults).first?.title ?? "—"

        return VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                StatCard(label: "Accuracy", value: totalHands == 0 ? "—" : "\(accuracy)%", hint: totalHands == 0 ? "Start a drill" : "all-time")
                StatCard(label: "Hands trained", value: "\(totalHands)", hint: "today: \(today)")
            }
            StatCard(label: "Biggest leak", value: biggestLeak, hint: biggestLeak == "—" ? "We'll spot leaks as you play" : "Tap Review for details")
        }
    }
}

#Preview {
    NavigationStack { TrainDashboardView() }
        .environment(ConfigStore())
        .modelContainer(for: [QuizResult.self, TrainingSession.self], inMemory: true)
}
