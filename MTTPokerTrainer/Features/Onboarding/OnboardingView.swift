import SwiftUI

struct OnboardingView: View {
    @Environment(ConfigStore.self) private var config
    @State private var showingSetup = false

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    header
                    pitchCard
                    TournamentSummaryCard(
                        stack: config.config.startingStack,
                        smallBlind: config.config.smallBlind,
                        bigBlind: config.config.bigBlind,
                        tableSize: config.config.tableSize,
                        bbCount: config.config.startingBB,
                        levelMinutes: config.config.blindLevelDuration.minutes
                    )
                    actions
                    Text(AppTheme.fullLegalLine)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                }
                .padding(.horizontal, AppSpacing.pageHorizontal)
                .padding(.top, AppSpacing.xxl)
                .padding(.bottom, AppSpacing.xxxl)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingSetup) {
            TournamentSetupView()
                .environment(config)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("MTT Poker Trainer")
                .font(AppTypography.largeTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text("Drill the spots you actually see in your live MTT — short-stack jams, re-jams, calling all-ins, and stealing blinds.")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var pitchCard: some View {
        GlassCard(tint: AppColors.cardSurfaceGreen) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Label("Built for 9-max live MTTs", systemImage: "person.2.fill")
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
                pitchRow("Practical spots biased to 15–40 BB.")
                pitchRow("Real history with replay + leak detection.")
                pitchRow("Rating, level and streak that update as you play.")
            }
        }
    }

    private func pitchRow(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppColors.primaryMint)
                .font(.system(size: 14, weight: .bold))
            Text(text)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var actions: some View {
        VStack(spacing: AppSpacing.md) {
            PrimaryButton(title: "Start training") {
                withAnimation(AppMotion.quick) {
                    config.hasOnboarded = true
                }
            }
            .accessibilityLabel(AppTheme.fullLegalLine)
            SecondaryButton(title: "Customize tournament") {
                showingSetup = true
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environment(ConfigStore())
}
