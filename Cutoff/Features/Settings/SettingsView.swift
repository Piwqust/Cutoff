import SwiftUI

struct SettingsView: View {
    @Environment(ConfigStore.self) private var config
    @Environment(LocalizationManager.self) private var l10n
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

                    languageCard

                    VStack(spacing: AppSpacing.md) {
                        SecondaryButton(title: l10n.t(.editTournamentRules)) {
                            showingSetup = true
                        }
                        SecondaryButton(title: l10n.t(.resetOnboarding)) {
                            config.hasOnboarded = false
                        }
                    }

                }
                .padding(.horizontal, AppSpacing.pageHorizontal)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxxl)
            }
        }
        .navigationTitle(l10n.t(.settingsTitle))
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .sheet(isPresented: $showingSetup) {
            TournamentSetupView()
                .environment(config)
                .environment(l10n)
        }
    }

    private var languageCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(l10n.t(.language))
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                VStack(spacing: 0) {
                    ForEach(AppLanguage.allCases) { lang in
                        Button {
                            l10n.language = lang
                        } label: {
                            HStack {
                                Text(lang.displayName)
                                    .font(AppTypography.body)
                                    .foregroundStyle(AppColors.textPrimary)
                                Spacer()
                                if l10n.language == lang {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppColors.primaryMint)
                                }
                            }
                            .padding(.vertical, AppSpacing.sm)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if lang != AppLanguage.allCases.last {
                            Divider().overlay(AppColors.divider)
                        }
                    }
                }
            }
        }
    }
}
