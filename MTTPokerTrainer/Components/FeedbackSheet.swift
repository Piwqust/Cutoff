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
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            outcomeBadge
            answerBlock
            if deepDive != nil {
                whyDisclosure
            }
            ctaRow
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(outcome.headline). Best answer is \(correctAction.displayName). \(explanation)")
    }

    // MARK: - Answer block

    /// Big, featured "what was the right play" headline followed by the
    /// supporting explanation. Replaces the older two-pill header that
    /// awkwardly paired the outcome and the answer side-by-side.
    private var answerBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("The right move")
                .font(AppTypography.caption.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.6)

            HStack(spacing: AppSpacing.sm) {
                Image(systemName: correctAction.systemImage)
                    .font(.system(size: 22, weight: .bold))
                Text(correctAction.displayName)
                    .font(.system(.title, design: .rounded).weight(.bold))
            }
            .foregroundStyle(answerTint)

            Text(supportingExplanation)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, AppSpacing.xxs)
        }
    }

    /// Fold's tint is intentionally muted (passive action), but using it as
    /// large-text foreground reads as faded on a dark sheet. Promote to a
    /// readable primary text color while still distinguishing it from the
    /// other actions via the icon shape.
    private var answerTint: Color {
        correctAction == .fold ? AppColors.textPrimary : correctAction.tint
    }

    /// The engine-generated explanation always leads with "<Action>." (e.g.
    /// "Fold. Not strong enough at this depth from UTG."). The action is
    /// already shown as the big headline, so strip the redundant prefix
    /// when displaying the body copy.
    private var supportingExplanation: String {
        let prefix = "\(correctAction.displayName)."
        let trimmed = explanation.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix(prefix) else { return trimmed }
        return String(trimmed.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
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
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.primaryMint)
                    Text(whyExpanded ? "Hide the why" : "Why this hand?")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary)
                        .rotationEffect(.degrees(whyExpanded ? 180 : 0))
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
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
                .font(.system(size: 12, weight: .bold))
            Text(outcome.headline)
                .font(AppTypography.footnote.weight(.semibold))
                .lineLimit(1)
                .textCase(.uppercase)
                .tracking(0.4)
        }
        .foregroundStyle(outcomeTint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(outcomeTint.opacity(0.14)))
        .overlay(
            Capsule().strokeBorder(outcomeTint.opacity(0.25), lineWidth: 0.5)
        )
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
