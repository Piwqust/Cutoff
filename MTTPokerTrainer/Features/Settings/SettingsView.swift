import SwiftUI

struct SettingsView: View {
    @Environment(ConfigStore.self) private var config
    @Environment(ProgressStore.self) private var progress
    @State private var showingSetup = false
    @State private var showingResetConfirm = false

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    TournamentSummaryCard(
                        stack: config.config.startingStack,
                        smallBlind: config.config.smallBlind,
                        bigBlind: config.config.bigBlind,
                        tableSize: config.config.tableSize,
                        bbCount: config.config.startingBB,
                        levelMinutes: config.config.blindLevelDuration.minutes
                    )

                    progressCard

                    VStack(spacing: AppSpacing.md) {
                        SecondaryButton(title: "Edit tournament rules") {
                            showingSetup = true
                        }
                        SecondaryButton(title: "Reset progress") {
                            showingResetConfirm = true
                        }
                    }

                    Text(AppTheme.fullLegalLine)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.top, AppSpacing.xl)
                }
                .padding(.horizontal, AppSpacing.pageHorizontal)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxxl)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingSetup) {
            TournamentSetupView()
                .environment(config)
        }
        .confirmationDialog("Reset progress?", isPresented: $showingResetConfirm, titleVisibility: .visible) {
            Button("Reset rating, XP and streak", role: .destructive) {
                progress.resetForTesting()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears your level, ratings and streak. History stays in Review.")
        }
    }

    private var progressCard: some View {
        GlassCard(tint: AppColors.cardSurfaceGreen) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Your progress")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                HStack(alignment: .firstTextBaseline) {
                    Text("Level \(progress.level) · \(progress.rank)")
                        .font(AppTypography.title2)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Text("\(progress.totalXP) XP")
                        .font(AppTypography.numericMedium)
                        .foregroundStyle(AppColors.primaryMint)
                }
                Text("Streak: \(progress.streakDays) day\(progress.streakDays == 1 ? "" : "s")")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}
