import SwiftUI

struct StackDepthTrainerView: View {
    private let highlights: [StackDepthBucket] = [.bb125, .bb75, .bb50, .bb30, .bb20, .bb15, .bb10]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("How your strategy shifts as your stack shrinks. One short lesson per depth.")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)

                ForEach(highlights) { bucket in
                    DepthCard(bucket: bucket)
                }

                Text(AppTheme.demoDataDisclaimer)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, AppSpacing.md)
            }
            .padding(.horizontal, AppSpacing.pageHorizontal)
            .padding(.vertical, AppSpacing.lg)
        }
        .background(AppBackground().ignoresSafeArea())
        .navigationTitle("Stack depth")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DepthCard: View {
    let bucket: StackDepthBucket

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(bucket.bb)")
                        .font(.system(size: 40, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(AppColors.textPrimary)
                    Text("BB")
                        .font(AppTypography.title2)
                        .foregroundStyle(AppColors.primaryMint)
                    Spacer()
                    severityChip
                }
                Text(bucket.lesson)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                NavigationLink {
                    // Drill spots that match this depth
                    PreflopTrainerView()
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Text("Drill this depth")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(AppColors.primaryMint)
                    .font(AppTypography.subheadline)
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var severityChip: some View {
        let (label, color): (String, Color) = {
            switch bucket {
            case .bb125, .bb100, .bb75: return ("Deep",      AppColors.accentGreen)
            case .bb50, .bb40:          return ("Mid",       AppColors.accentLime)
            case .bb30, .bb25:          return ("Pressure",  AppColors.accentPeach)
            case .bb20, .bb15, .bb10:   return ("Short",     AppColors.accentCoral)
            }
        }()
        return Text(label)
            .font(AppTypography.caption)
            .foregroundStyle(color)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 4)
            .background(Capsule().fill(color.opacity(0.14)))
    }
}

#Preview {
    NavigationStack { StackDepthTrainerView() }
}
