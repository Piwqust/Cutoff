import SwiftUI

struct StatCard: View {
    let label: String
    let value: String
    var hint: String? = nil
    var trendUp: Bool? = nil

    var body: some View {
        GlassCard(cornerRadius: AppRadius.card, padding: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(label)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Text(value)
                    .font(AppTypography.numericMedium)
                    .foregroundStyle(AppColors.textPrimary)
                if let hint {
                    HStack(spacing: AppSpacing.xxs) {
                        if let trendUp {
                            Image(systemName: trendUp ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(trendUp ? AppColors.accentGreen : AppColors.accentPeach)
                        }
                        Text(hint)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ZStack {
        AppBackground()
        HStack(spacing: AppSpacing.sm) {
            StatCard(label: "Accuracy", value: "76%", hint: "+4%", trendUp: true)
            StatCard(label: "Hands", value: "248", hint: "today: 22")
        }
        .padding()
    }
}
