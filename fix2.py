content = """import SwiftUI

struct OnboardingView: View {
    @Environment(ConfigStore.self) private var config
    @State private var showingSetup = false
    @State private var selectedLevel: PlayerLevel = .amateur

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    header
                    TournamentSummaryCard(
                        stack: config.config.startingStack,
                        smallBlind: config.config.smallBlind,
                        bigBlind: config.config.bigBlind,
                        tableSize: config.config.tableSize,
                        bbCount: config.config.startingBB,
                        levelMinutes: config.config.blindLevelDuration.minutes
                    )
                    playerLevelPicker
                    actions
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

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("MTT Poker Trainer")
                .font(AppTypography.largeTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text("Nail your preflop fundamentals. Drill push/fold, 3-bet thresholds, and blind defense for 9-max tournaments.")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var playerLevelPicker: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Who are you playing against?")
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.textPrimary)
            VStack(spacing: AppSpacing.sm) {
                ForEach([PlayerLevel.beginner, .amateur, .advanced], id: \\.self) { lvl in
                    levelRow(lvl)
                }
            }
        }
    }

    private func levelRow(_ level: PlayerLevel) -> some View {
        let isSelected = selectedLevel == level
        return Button {
            withAnimation(AppMotion.quick) { selectedLevel = level }
        } label: {
            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.displayName)
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(level.subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? AppColors.primaryMint : AppColors.textSecondary)
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .fill(isSelected ? AnyShapeStyle(AppColors.cardSurfaceGreen) : AnyShapeStyle(AppColors.cardSurface))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .strokeBorder(isSelected ? AppColors.primaryMint.opacity(0.3) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var actions: some View {
        VStack(spacing: AppSpacing.md) {
            PrimaryButton(title: "Start training") {
                withAnimation(AppMotion.quick) {
                    config.hasOnboarded = true
                }
            }
            SecondaryButton(title: "Customize tournament") {
                showingSetup = true
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environment(ConfigStore())
}"""
with open("MTTPokerTrainer/Features/Onboarding/OnboardingView.swift", "w") as f:
    f.write(content)
