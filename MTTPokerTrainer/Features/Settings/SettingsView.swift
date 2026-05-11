import SwiftUI

struct SettingsView: View {
    @Environment(ConfigStore.self) private var config
    @Environment(\.dismiss) private var dismiss
    @State private var showingSetup = false

    var body: some View {
        NavigationStack {
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

                        VStack(spacing: AppSpacing.md) {
                            SecondaryButton(title: "Edit tournament rules") {
                                showingSetup = true
                            }
                            SecondaryButton(title: "Reset onboarding") {
                                config.hasOnboarded = false
                                dismiss()
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColors.primaryMint)
                }
            }
            .sheet(isPresented: $showingSetup) {
                TournamentSetupView()
                    .environment(config)
            }
        }
    }
}
