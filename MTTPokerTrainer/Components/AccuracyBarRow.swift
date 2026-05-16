import SwiftUI

/// Single accuracy bar row used by the per-position, per-depth, per-facing,
/// and per-hand-class breakdowns in the Review dashboard.
///
/// Bar gradient is the same outcome scale used by `LeakCard.severityBar`
/// (green → lime → coral), but reversed so high accuracy reads green.
struct AccuracyBarRow: View {
    let label: String
    let total: Int
    let accuracy: Int   // 0...100
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 16)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(label)
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Text("\(accuracy)%")
                        .font(AppTypography.numericSmall)
                        .foregroundStyle(tint)
                    Text("· \(total)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                bar
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(accuracy)% accuracy across \(total) hands.")
    }

    private var bar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(AppColors.divider).frame(height: 6)
                Capsule()
                    .fill(tint)
                    .frame(width: max(6, geo.size.width * fraction), height: 6)
            }
        }
        .frame(height: 6)
    }

    private var fraction: Double {
        max(0, min(1, Double(accuracy) / 100))
    }

    private var tint: Color {
        switch accuracy {
        case ..<50:  return AppColors.accentCoral
        case ..<70:  return AppColors.accentPeach
        case ..<85:  return AppColors.accentLime
        default:     return AppColors.primaryMint
        }
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: AppSpacing.sm) {
            AccuracyBarRow(label: "Suited connectors", total: 42, accuracy: 38, systemImage: "link")
            AccuracyBarRow(label: "Premium pairs", total: 18, accuracy: 91, systemImage: "rectangle.stack.fill")
            AccuracyBarRow(label: "Offsuit junk", total: 12, accuracy: 67, systemImage: "questionmark.diamond")
        }
        .padding(AppSpacing.lg)
    }
}
