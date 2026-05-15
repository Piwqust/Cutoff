import SwiftUI

/// Bottom-sheet feedback shown after the user answers a preflop spot.
struct FeedbackSheet: View {
    let outcome: AnswerOutcome
    let correctAction: RangeAction
    let explanation: String
    var deepDive: DeepDive? = nil
    let onNext: () -> Void
    var onViewRange: (() -> Void)? = nil

    @AppStorage("feedbackSheet.whyExpanded") private var whyExpanded: Bool = false

    /// Rich content rendered when the user expands the "Why?" disclosure.
    struct DeepDive: Hashable {
        let frequencies: [RangeAction: Double]
        let userAction: RangeAction
        let paragraphs: [String]
        let mistakeReason: MistakeReason
        let siblingHands: [String]   // notation strings
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            headerRow
            explanationBlock
            if deepDive != nil {
                whyDisclosure
            }
            Spacer(minLength: AppSpacing.xs)
            ctaRow
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, AppSpacing.lg)
        .padding(.bottom, AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(outcome.headline). Best answer is \(correctAction.displayName). \(explanation)")
    }

    // MARK: - Header

    /// Outcome (how you did) on the left, best action (what was right) on the
    /// right — paired so the reveal reads as one beat.
    private var headerRow: some View {
        HStack(alignment: .center, spacing: AppSpacing.sm) {
            outcomeBadge
            Spacer(minLength: AppSpacing.xs)
            bestActionPill
        }
    }

    private var bestActionPill: some View {
        HStack(spacing: 6) {
            Image(systemName: correctAction.systemImage)
                .font(.system(size: 13, weight: .bold))
            Text(correctAction.displayName)
                .font(AppTypography.bodyBold)
        }
        .foregroundStyle(correctAction.prefersDarkForeground ? AppColors.backgroundDeep : AppColors.textPrimary)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 8)
        .background(Capsule().fill(correctAction.tint))
        .accessibilityLabel("Best play: \(correctAction.displayName)")
    }

    // MARK: - Explanation

    /// Explanation with a thin left accent bar tinted by outcome — visually
    /// links the body copy to the result above.
    private var explanationBlock: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(outcomeTint.opacity(0.55))
                .frame(width: 3)
            Text(explanation)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - CTA row

    private var ctaRow: some View {
        HStack(spacing: AppSpacing.sm) {
            if let onViewRange {
                SecondaryButton(title: "View range", systemImage: "rectangle.grid.3x2", action: onViewRange)
            }
            PrimaryButton(title: "Next hand", systemImage: "arrow.right", action: onNext)
        }
    }

    // MARK: - Why? disclosure

    private var whyDisclosure: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Button {
                withAnimation(AppMotion.quick) { whyExpanded.toggle() }
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppColors.primaryMint)
                    Text(whyExpanded ? "Hide the why" : "Why?")
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary)
                        .rotationEffect(.degrees(whyExpanded ? 180 : 0))
                }
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous)
                        .fill(AppColors.cardSurface.opacity(0.55))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous)
                        .strokeBorder(AppColors.divider.opacity(0.35), lineWidth: 0.5)
                )
                .contentShape(RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous))
            }
            .buttonStyle(.plain)

            if whyExpanded, let deepDive {
                deepDiveBody(deepDive)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func deepDiveBody(_ deep: DeepDive) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                MistakeReasonChip(reason: deep.mistakeReason)
                Spacer()
            }
            FrequencyDistributionView(
                frequencies: deep.frequencies,
                userAction: deep.userAction,
                compact: true
            )
            ForEach(Array(deep.paragraphs.enumerated()), id: \.offset) { _, p in
                Text(p)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !deep.siblingHands.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Plays the same way")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    HStack(spacing: AppSpacing.xs) {
                        ForEach(deep.siblingHands, id: \.self) { combo in
                            Text(combo)
                                .font(AppTypography.caption.weight(.semibold))
                                .foregroundStyle(AppColors.textPrimary)
                                .padding(.horizontal, AppSpacing.xs)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(AppColors.cardSurfaceGreen.opacity(0.5)))
                        }
                    }
                }
            }
        }
        .padding(.top, AppSpacing.xs)
    }

    private var outcomeBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: outcomeGlyph)
                .font(.system(size: 15, weight: .bold))
            Text(outcome.headline)
                .font(AppTypography.headline)
                .lineLimit(1)
        }
        .foregroundStyle(outcomeTint)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 7)
        .background(Capsule().fill(outcomeTint.opacity(0.16)))
    }

    private var outcomeTint: Color {
        switch outcome {
        case .correct: return AppColors.primaryMint
        case .close:   return AppColors.accentLime
        case .mistake: return AppColors.accentPeach
        case .punt:    return AppColors.errorSoft
        }
    }

    private var outcomeGlyph: String {
        switch outcome {
        case .correct: return "checkmark.circle.fill"
        case .close:   return "circle.lefthalf.filled"
        case .mistake: return "exclamationmark.circle.fill"
        case .punt:    return "xmark.octagon.fill"
        }
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
                    outcome: .mistake,
                    correctAction: .raise,
                    explanation: "Open. CO at 100 BB can lead with this hand.",
                    deepDive: .init(
                        frequencies: [.fold: 0.0, .raise: 0.7, .threeBet: 0.3],
                        userAction: .fold,
                        paragraphs: [
                            "Mixed spot — chart plays AJs raise 70% / three-bet 30%.",
                            "Suited aces have the equity + blockers to keep going here. Folding gives up too much.",
                            "Suited aces double up as blockers and flush draws — they 3-bet well and defend well."
                        ],
                        mistakeReason: .tooTight,
                        siblingHands: ["KQs", "ATs", "KJs"]
                    ),
                    onNext: {}, onViewRange: {}
                )
            }
    }
}
