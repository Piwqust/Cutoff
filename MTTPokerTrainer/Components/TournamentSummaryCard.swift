import SwiftUI

/// Hero card showing the user's tournament profile in big readable numbers.
/// Used on Onboarding and the Train Dashboard.
struct TournamentSummaryCard: View {
    let stack: Int
    let smallBlind: Int
    let bigBlind: Int
    let tableSize: Int
    let bbCount: Int
    var levelMinutes: Int? = nil

    var body: some View {
        GlassCard(cornerRadius: AppRadius.hero, tint: AppColors.cardSurfaceGreen, padding: AppSpacing.xl) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                HStack {
                    Text("Tournament profile")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Text("\(tableSize)-max MTT")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColors.primaryMint)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(AppColors.primaryMint.opacity(0.12)))
                }

                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xs) {
                    Text("\(bbCount)")
                        .font(AppTypography.numericHero)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("BB")
                        .font(AppTypography.title2)
                        .foregroundStyle(AppColors.primaryMint)
                    Spacer()
                }

                Divider().overlay(AppColors.divider)

                HStack(spacing: AppSpacing.xl) {
                    summaryItem("Stack", "\(stack.formatted(.number))")
                    summaryItem("Blinds", "\(smallBlind) / \(bigBlind)")
                    if let levelMinutes {
                        summaryItem("Levels", "\(levelMinutes) min")
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tournament profile: \(tableSize)-max MTT, \(stack) stack, \(smallBlind) over \(bigBlind) blinds, \(bbCount) big blinds.")
    }

    private func summaryItem(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            Text(value)
                .font(AppTypography.numericMedium)
                .foregroundStyle(AppColors.textPrimary)
        }
    }
}

#Preview {
    ZStack {
        AppBackground()
        TournamentSummaryCard(stack: 25_000, smallBlind: 100, bigBlind: 200, tableSize: 9, bbCount: 125, levelMinutes: 15)
            .padding()
    }
}
