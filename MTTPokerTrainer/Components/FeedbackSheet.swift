import SwiftUI

/// Native iOS sheet shown after a non-correct answer in either trainer.
///
/// System chrome (drag indicator, rounded top, dim-behind backdrop) handles
/// the framing — the body just lays out the feedback content as a tight
/// vertical stack. Postflop spots degrade gracefully: no reason chip, no
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
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                outcomeHeader
                actionDiff
                if hasBody {
                    reasonAndBody
                }
                if !payload.siblingHands.isEmpty {
                    siblings
                }
                ctaRow
                    .padding(.top, AppSpacing.xs)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.lg)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showRange) {
            if let rangePayload {
                RangeDetailSheet(payload: rangePayload)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Outcome header

    /// Two compact rows: glyph + headline on the first, verdict beneath.
    /// Splitting them means the icon never collides with the headline text
    /// the way the previous overlay did when both shared an HStack.
    private var outcomeHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: outcomeGlyph)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(outcomeTint)
                    .accessibilityHidden(true)
                Text(payload.outcome.headline)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(outcomeTint)
                Spacer(minLength: 0)
            }
            Text(payload.verdict)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
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

    /// "You ▸ Chart" pills with an arrow between. The user pill is always
    /// rendered in the error palette so the contrast against the chart pill
    /// is unambiguous regardless of which actions the spot allowed.
    private var actionDiff: some View {
        HStack(spacing: AppSpacing.sm) {
            actionPill(label: "You", desc: payload.userAction, role: .userMistake)
            Image(systemName: "arrow.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
                .accessibilityHidden(true)
            actionPill(label: "Chart", desc: payload.correctAction, role: .correct)
            Spacer(minLength: 0)
        }
    }

    private enum PillRole { case userMistake, correct }

    private func actionPill(label: String, desc: ActionDescriptor, role: PillRole) -> some View {
        let tint: Color = (role == .userMistake) ? AppColors.accentPeach : desc.tint
        let foreground: Color = (role == .userMistake) ? tint : (desc.isFold ? AppColors.textPrimary : tint)
        return VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
            HStack(spacing: 5) {
                Image(systemName: desc.systemImage)
                    .font(.system(size: 12, weight: .bold))
                Text(desc.displayName)
                    .font(AppTypography.subheadline.weight(.semibold))
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 5)
            .background(Capsule().fill(tint.opacity(0.16)))
            .overlay(Capsule().strokeBorder(tint.opacity(0.32), lineWidth: 0.5))
            .accessibilityLabel("\(label): \(desc.displayName)")
        }
    }

    // MARK: - Reason + body

    private var hasBody: Bool {
        payload.mistakeReason != nil || !payload.paragraphs.isEmpty
    }

    private var reasonAndBody: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            if let reason = payload.mistakeReason {
                HStack {
                    MistakeReasonChip(reason: reason)
                    Spacer(minLength: 0)
                }
            }
            ForEach(Array(payload.paragraphs.enumerated()), id: \.offset) { _, p in
                Text(p)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(1)
            }
        }
    }

    // MARK: - Siblings

    /// Tiny text-only pills. The previous design rendered each sibling as a
    /// full `HandCardView` — visually loud and tall. A monospaced notation
    /// chip carries the same teaching value at a fraction of the space.
    private var siblings: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Same line")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
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
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(AppColors.cardSurface))
            .overlay(Capsule().strokeBorder(AppColors.divider.opacity(0.6), lineWidth: 0.5))
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
                    outcome: .mistake,
                    userAction: ActionDescriptor(RangeAction.jam),
                    correctAction: ActionDescriptor(RangeAction.fold),
                    verdict: "62o wants fold.",
                    paragraphs: [
                        "62o is the kind of offsuit hand that bleeds chips. Folding from BTN is the simple, profitable move.",
                        "Offsuit junk is just chip-loss surface area outside of free blind defense — keep it tight, especially out of position."
                    ],
                    mistakeReason: .tooLoose,
                    siblingHands: [
                        HandCombo(highRank: .six, lowRank: .three, category: .offsuit),
                        HandCombo(highRank: .seven, lowRank: .two, category: .offsuit),
                        HandCombo(highRank: .five, lowRank: .two, category: .offsuit)
                    ]
                ),
                onNext: {}
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
}
