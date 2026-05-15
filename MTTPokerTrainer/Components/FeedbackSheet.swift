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
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                outcomeBadge
                answerBlock
                if deepDive != nil {
                    whyDisclosure
                }
                ctaRow
                    .padding(.top, AppSpacing.xs)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
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

    /// Skip the first "verdict" paragraph (e.g. "43s wants fold.") — it's
    /// already implied by the big answer headline, so showing it again just
    /// fills vertical space.
    private func deepDiveParagraphs(_ deep: DeepDive) -> ArraySlice<String> {
        deep.paragraphs.count > 1 ? deep.paragraphs.dropFirst() : deep.paragraphs[...]
    }

    private func deepDiveBody(_ deep: DeepDive) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .center, spacing: AppSpacing.xs) {
                MistakeReasonChip(reason: deep.mistakeReason)
                Spacer(minLength: 0)
            }
            FrequencyDistributionView(
                frequencies: deep.frequencies,
                userAction: deep.userAction,
                compact: true
            )
            ForEach(Array(deepDiveParagraphs(deep).enumerated()), id: \.offset) { _, p in
                Text(p)
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(1)
            }
            if !deep.siblingHands.isEmpty {
                Text("Same line: ")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                + Text(deep.siblingHands.joined(separator: " · "))
                    .font(AppTypography.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .padding(.top, AppSpacing.xxs)
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
