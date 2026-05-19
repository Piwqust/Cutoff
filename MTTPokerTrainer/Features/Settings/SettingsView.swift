import SwiftUI

struct SettingsView: View {
    @Environment(ConfigStore.self) private var config
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

                    VStack(spacing: AppSpacing.md) {
                        SecondaryButton(title: "Edit tournament rules") {
                            showingSetup = true
                        }
                        SecondaryButton(title: "Reset onboarding") {
                            config.hasOnboarded = false
                        }
                    }

                }
                .padding(.horizontal, AppSpacing.pageHorizontal)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxxl)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .sheet(isPresented: $showingSetup) {
            TournamentSetupView()
                .environment(config)
        }
    }
}
