import SwiftUI

/// Bottom-sheet feedback shown after the user answers a preflop spot.
struct FeedbackSheet: View {
    let outcome: AnswerOutcome
    let correctAction: RangeAction
    let explanation: String
    var dataLabel: String? = "Demo training range — not solver-verified."
    let onNext: () -> Void
    var onViewRange: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                outcomeBadge
                Spacer()
                if let dataLabel {
                    Text(dataLabel)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.trailing)
                }
            }

            HStack(alignment: .center, spacing: AppSpacing.sm) {
                Text("Best answer")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                HStack(spacing: 6) {
                    Image(systemName: correctAction.systemImage)
                        .font(.system(size: 14, weight: .bold))
                    Text(correctAction.displayName)
                        .font(AppTypography.bodyBold)
                }
                .foregroundStyle(correctAction.prefersDarkForeground ? AppColors.backgroundDeep : AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, 6)
                .background(Capsule().fill(correctAction.tint))
            }

            Text(explanation)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: AppSpacing.sm) {
                if let onViewRange {
                    SecondaryButton(title: "View range", systemImage: "rectangle.grid.3x2", action: onViewRange)
                }
                PrimaryButton(title: "Next hand", systemImage: "arrow.right", action: onNext)
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.sheet, style: .continuous)
                .fill(AppColors.cardSurface)
                .ignoresSafeArea(edges: .bottom)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(outcome.headline). Best answer is \(correctAction.displayName). \(explanation)")
    }

    private var outcomeBadge: some View {
        let (color, glyph): (Color, String) = {
            switch outcome {
            case .correct: return (AppColors.primaryMint,   "checkmark.circle.fill")
            case .close:   return (AppColors.accentLime,    "circle.lefthalf.filled")
            case .mistake: return (AppColors.accentPeach,   "exclamationmark.circle.fill")
            case .punt:    return (AppColors.errorSoft,     "xmark.octagon.fill")
            }
        }()
        return HStack(spacing: 6) {
            Image(systemName: glyph)
                .font(.system(size: 16, weight: .bold))
            Text(outcome.headline)
                .font(AppTypography.headline)
        }
        .foregroundStyle(color)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 6)
        .background(Capsule().fill(color.opacity(0.16)))
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack { Spacer() }
            .overlay(alignment: .bottom) {
                FeedbackSheet(
                    outcome: .correct,
                    correctAction: .raise,
                    explanation: "Open. CO at 100 BB can lead with this hand.",
                    onNext: {}, onViewRange: {}
                )
            }
    }
}
