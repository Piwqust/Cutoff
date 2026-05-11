import SwiftUI

/// Pure presentational card. Wrap in a `Button` or `NavigationLink` at the
/// call site — embedding a Button here would swallow taps when this view is
/// used as a NavigationLink label.
struct TrainingModeCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var tint: Color = AppColors.primaryMint

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: systemImage)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)
                Text(subtitle)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: AppSpacing.xs)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .glassBackground(cornerRadius: AppRadius.card)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: AppSpacing.sm) {
            TrainingModeCard(title: "Preflop Trainer", subtitle: "Drill 9-max preflop spots", systemImage: "rectangle.grid.3x2.fill")
            TrainingModeCard(title: "Push / Fold", subtitle: "Short-stack jam practice", systemImage: "flame.fill", tint: AppColors.accentCoral)
        }
        .padding()
    }
}
