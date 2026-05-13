import SwiftUI

/// Bottom-sheet feedback shown after the user answers a preflop spot.
struct FeedbackSheet: View {
    let outcome: AnswerOutcome
    let correctAction: PreflopAction
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

/// PreferenceKey used by `feedbackSheet(isPresented:...)` to size the sheet
/// detent to the content's actual height.
private struct FeedbackSheetHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

extension View {
    /// Presents a `FeedbackSheet` whose bottom-sheet detent matches the content
    /// height. Sized via a `GeometryReader` preference key on first layout, so
    /// the sheet hugs its content instead of locking to a fixed fraction.
    func feedbackSheet(
        isPresented: Binding<Bool>,
        outcome: AnswerOutcome?,
        correctAction: RangeAction,
        explanation: String,
        measuredHeight: Binding<CGFloat>,
        onNext: @escaping () -> Void
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            if let outcome {
                FeedbackSheet(
                    outcome: outcome,
                    correctAction: correctAction,
                    explanation: explanation,
                    onNext: onNext
                )
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: FeedbackSheetHeightKey.self, value: geo.size.height)
                    }
                )
                .onPreferenceChange(FeedbackSheetHeightKey.self) { h in
                    if h > 0 { measuredHeight.wrappedValue = h }
                }
                .presentationDetents([.height(measuredHeight.wrappedValue)])
                .presentationBackground(AppColors.cardSurface)
                .presentationDragIndicator(.visible)
            }
        }
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack { Spacer() }
            .overlay(alignment: .bottom) {
                FeedbackSheet(
                    outcome: .correct,
                    correctAction: .raise25x,
                    explanation: "Open. CO at 100 BB can lead with this hand.",
                    onNext: {}, onViewRange: {}
                )
            }
    }
}
