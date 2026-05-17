import SwiftUI

/// Native iOS sheet shown after a non-correct answer in either trainer.
///
/// Five vertical zones, separated by clear whitespace rather than dividers:
/// hero (badge + headline + verdict), action diff, explanation, sibling
/// chips, CTAs. Postflop spots degrade gracefully — no reason chip, no
/// sibling chips, no "View range" button.
struct FeedbackSheet: View {
    let payload: FeedbackPayload
    let onNext: () -> Void
    /// Optional pre-built range payload for the "View range" CTA. When nil
    /// the button is hidden (postflop). When non-nil, tapping the button
    /// stacks `RangeDetailSheet` on top of this sheet.
    var rangePayload: RangeDetailPayload? = nil

    @State private var showRange = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                hero
                actionDiff
                if hasExplanation {
                    explanation
                }
                if !payload.siblingHands.isEmpty {
                    siblings
                }
                ctaRow
                    .padding(.top, AppSpacing.xs)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xl)
        }
        .scrollIndicators(.hidden)
        .presentationBackground(.regularMaterial)
        .sheet(isPresented: $showRange) {
            if let rangePayload {
                RangeDetailSheet(payload: rangePayload)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Hero

    /// Tinted circular badge (notification-style) paired with the outcome
    /// headline and the chart's one-line verdict. Switching from a bare SF
    /// Symbol to a filled badge gives the header an anchor weight and stops
    /// the icon and headline from competing for the eye.
    private var hero: some View {
        HStack(alignment: .center, spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(outcomeTint.opacity(0.18))
                Image(systemName: outcomeGlyph)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(outcomeTint)
            }
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(payload.outcome.headline)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(outcomeTint)
                Text(payload.verdict)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var outcomeTint: Color {
        switch payload.outcome {
        case .correct: return AppColors.primaryMint
        case .close:   return AppColors.accentLime
        case .mistake: return AppColors.accentPeach
        case .punt:    return AppColors.errorSoft
        }
    }

    private var outcomeGlyph: String {
        switch payload.outcome {
        case .correct: return "checkmark.circle.fill"
        case .close:   return "circle.lefthalf.filled"
        case .mistake: return "exclamationmark.circle.fill"
        case .punt:    return "xmark.octagon.fill"
        }
    }

    // MARK: - Action diff

    /// "You played → Chart wants" — labelled pills with a clear arrow. The
    /// user pill is always in the error palette so the contrast against the
    /// chart pill is unambiguous regardless of which actions the spot
    /// allowed. Pills have body-weight typography and generous padding so
    /// they read as a primary unit, not a secondary detail.
    private var actionDiff: some View {
        HStack(alignment: .bottom, spacing: AppSpacing.sm) {
            pillColumn(label: "You played", desc: payload.userAction, role: .userMistake)
            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .padding(.bottom, 10)
                .accessibilityHidden(true)
            pillColumn(label: "Chart wants", desc: payload.correctAction, role: .correct)
            Spacer(minLength: 0)
        }
    }

    private enum PillRole { case userMistake, correct }

    private func pillColumn(label: String, desc: ActionDescriptor, role: PillRole) -> some View {
        let tint: Color = (role == .userMistake) ? AppColors.accentPeach : desc.tint
        let foreground: Color = (role == .userMistake) ? tint : (desc.isFold ? AppColors.textPrimary : tint)
        return VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.6)
            HStack(spacing: 6) {
                Image(systemName: desc.systemImage)
                    .font(.system(size: 13, weight: .bold))
                Text(desc.displayName)
                    .font(AppTypography.subheadline.weight(.semibold))
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, 8)
            .background(Capsule().fill(tint.opacity(0.18)))
            .overlay(Capsule().strokeBorder(tint.opacity(0.36), lineWidth: 0.5))
            .accessibilityLabel("\(label): \(desc.displayName)")
        }
    }

    // MARK: - Explanation

    private var hasExplanation: Bool {
        payload.mistakeReason != nil || !payload.paragraphs.isEmpty
    }

    /// Reason chip acts as a tag-line header for the body copy beneath.
    /// Tight spacing between the chip and the first paragraph makes the
    /// association clear without needing a literal "Reason:" label.
    private var explanation: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if let reason = payload.mistakeReason {
                HStack(spacing: AppSpacing.xs) {
                    MistakeReasonChip(reason: reason)
                    Spacer(minLength: 0)
                }
            }
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                ForEach(Array(payload.paragraphs.enumerated()), id: \.offset) { _, p in
                    Text(p)
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                }
            }
        }
    }

    // MARK: - Siblings

    /// Tiny text-only chips. A full `HandCardView` per sibling overwhelmed
    /// the sheet; monospaced notation pills carry the same teaching value
    /// in a fraction of the space.
    private var siblings: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Same line")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.6)
            HStack(spacing: 6) {
                ForEach(payload.siblingHands, id: \.self) { combo in
                    siblingChip(combo)
                }
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Same line as: \(payload.siblingHands.map(\.notation).joined(separator: ", "))")
        }
    }

    private func siblingChip(_ combo: HandCombo) -> some View {
        Text(combo.notation)
            .font(.system(.footnote, design: .rounded).weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 5)
            .background(Capsule().fill(AppColors.cardSurface))
            .overlay(Capsule().strokeBorder(AppColors.divider.opacity(0.7), lineWidth: 0.5))
    }

    // MARK: - CTAs

    private var ctaRow: some View {
        HStack(spacing: AppSpacing.sm) {
            if rangePayload != nil {
                SecondaryButton(title: "View range", systemImage: "rectangle.grid.3x2") {
                    showRange = true
                }
            }
            PrimaryButton(title: "Next hand", systemImage: "arrow.right", action: onNext)
        }
    }
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            FeedbackSheet(
                payload: FeedbackPayload(
                    outcome: .punt,
                    userAction: ActionDescriptor(RangeAction.fold),
                    correctAction: ActionDescriptor(RangeAction.jam),
                    verdict: "KQo wants jam.",
                    paragraphs: [
                        "Broadway hands hold their equity well against opening ranges. KQo is too live to fold at 12 BB.",
                        "Offsuit broadway plays better from late position; from early seats they're easy to dominate."
                    ],
                    mistakeReason: .tooTight,
                    siblingHands: [
                        HandCombo(highRank: .king, lowRank: .jack, category: .offsuit),
                        HandCombo(highRank: .queen, lowRank: .jack, category: .offsuit),
                        HandCombo(highRank: .king, lowRank: .ten, category: .offsuit)
                    ]
                ),
                onNext: {}
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
}
