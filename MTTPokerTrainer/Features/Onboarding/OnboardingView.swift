import SwiftUI

/// First-run screen. One CTA, one quiet customize link. The tournament
/// profile lives behind that link, not in the user's face on day one.
struct OnboardingView: View {
    @Environment(ConfigStore.self) private var config
    @State private var showingSetup = false

    var body: some View {
        ZStack {
            AppBackground()

            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Spacer(minLength: AppSpacing.huge)

                Text("MTT Poker Trainer")
                    .font(AppTypography.largeTitle)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Drill the preflop spots you see in live MTTs.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                PrimaryButton(title: "Start training") {
                    withAnimation(AppMotion.quick) {
                        config.hasOnboarded = true
                    }
                }

                Button {
                    showingSetup = true
                } label: {
                    Text("Customize tournament")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Customize tournament")
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
}
