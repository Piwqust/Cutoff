import SwiftUI

/// First-run screen. One CTA, one quiet customize link. The tournament
/// profile lives behind that link, not in the user's face on day one.
struct OnboardingView: View {
    @Environment(ConfigStore.self) private var config
    @Environment(LocalizationManager.self) private var l10n
    @State private var showingSetup = false

    var body: some View {
        ZStack {
            AppBackground()

            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Spacer(minLength: AppSpacing.huge)

                Text(l10n.t(.appName))
                    .font(AppTypography.largeTitle)
                    .foregroundStyle(AppColors.textPrimary)

                Text(l10n.t(.onboardingSubtitle))
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                PrimaryButton(title: l10n.t(.startTraining)) {
                    withAnimation(AppMotion.quick) {
                        config.hasOnboarded = true
                    }
                }

                Button {
                    showingSetup = true
                } label: {
                    Text(l10n.t(.customizeTournament))
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(l10n.t(.customizeTournament))
            }
            .padding(.horizontal, AppSpacing.pageHorizontal)
            .padding(.bottom, AppSpacing.xxl)
        }
        .preferredColorScheme(.dark)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .sheet(isPresented: $showingSetup) {
            TournamentSetupView()
                .environment(config)
        }
    }
}

#Preview {
    OnboardingView()
        .environment(ConfigStore())
        .environment(LocalizationManager())
}
