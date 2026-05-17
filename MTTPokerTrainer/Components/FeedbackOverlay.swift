import SwiftUI

/// Full-screen overlay shown after a non-correct answer in either trainer.
///
/// Replaces the old `FeedbackSheet` bottom sheet and the parallel
/// `PostflopFeedbackSheet`. The overlay carries no action-enum knowledge —
/// it renders a `FeedbackPayload` produced by the trainer's view model.
///
/// Dismissal: tap the dimmed backdrop, swipe the card down, or tap "Next hand".
/// "View full range" is wired to an optional callback the parent provides
/// (preflop only — postflop passes `nil`).
struct FeedbackOverlay: View {
    let payload: FeedbackPayload
    let onNext: () -> Void
    var onViewRange: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @AccessibilityFocusState private var focusOnOutcome: Bool

    /// Swipe-down dismiss state. Drag the card; release past the threshold to
    /// advance. Falls back to the parent's `onNext` so the same dismissal path
    /// (overlay fade-out, advance to next spot) runs for every gesture.
    @State private var dragOffset: CGFloat = 0
    private let dismissThreshold: CGFloat = 80

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                backdrop
                card(maxHeight: proxy.size.height * 0.85)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, AppSpacing.pageHorizontal)
            }
        }
        .ignoresSafeArea()
        .accessibilityAddTraits(.isModal)
        .onAppear { focusOnOutcome = true }
    }

    // MARK: - Backdrop

    /// Dimmed glass behind the card. Tapping anywhere on the backdrop
    /// advances. Reduce Transparency swaps the material for a solid wash so
    /// the dark UI never goes flat-gray under the accessibility setting.
    private var backdrop: some View {
        ZStack {
            if reduceTransparency {
                AppColors.backgroundDeep.opacity(0.92)
            } else {
                Rectangle().fill(.ultraThinMaterial)
                Color.black.opacity(0.45)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onNext() }
        .accessibilityHidden(true)
    }

    // MARK: - Card

    private func card(maxHeight: CGFloat) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                outcomeHeader
                actionDiff
                if payload.mistakeReason != nil || !bodyParagraphs.isEmpty {
                    reasonAndBody
                }
                if !payload.siblingHands.isEmpty {
                    siblings
                }
                ctaRow
                    .padding(.top, AppSpacing.xs)
            }
            .padding(AppSpacing.xl)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: 480)
        .frame(maxHeight: maxHeight)
        .glassBackground(cornerRadius: AppRadius.hero, tint: AppColors.cardSurface)
        // Block taps from leaking through to the backdrop while keeping the
        // drag gesture active for swipe-down dismiss.
        .contentShape(RoundedRectangle(cornerRadius: AppRadius.hero, style: .continuous))
        .onTapGesture { /* swallow */ }
        .offset(y: dragOffset)
        .gesture(swipeToDismiss)
        .animation(AppMotion.respecting(reduceMotion, .spring(response: 0.32, dampingFraction: 0.86)), value: dragOffset)
    }

    private var swipeToDismiss: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                // Only respond to downward drags. Apply rubber-band resistance
                // so the card doesn't fly off the screen mid-gesture.
                let dy = value.translation.height
                dragOffset = dy > 0 ? dy * 0.55 : 0
            }
            .onEnded { value in
                if value.translation.height > dismissThreshold {
                    onNext()
                } else {
                    dragOffset = 0
                }
            }
    }

    // MARK: - Outcome header

    /// Big glyph + outcome label on one line; the chart's verdict beneath.
    private var outcomeHeader: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Image(systemName: outcomeGlyph)
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(outcomeTint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(payload.outcome.headline)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(outcomeTint)
                    .accessibilityFocused($focusOnOutcome)
                Text(payload.verdict)
                    .font(AppTypography.body)
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

    /// "Your pick → Right move." pills side by side with an arrow between.
    /// The user pill always uses the error palette so the contrast against
    /// the chart's recommended pill is unambiguous.
    private var actionDiff: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.md) {
                labeledPill(label: "You", desc: payload.userAction, role: .userMistake)
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)
                    .accessibilityHidden(true)
                labeledPill(label: "Chart", desc: payload.correctAction, role: .correct)
                Spacer(minLength: 0)
            }
        }
    }

    private enum PillRole { case userMistake, correct }

    private func labeledPill(label: String, desc: ActionDescriptor, role: PillRole) -> some View {
        let tint: Color = {
            switch role {
            case .userMistake: return AppColors.accentPeach
            case .correct:     return desc.tint
            }
        }()
        let foreground: Color = {
            switch role {
            case .userMistake: return tint
            case .correct:     return desc.isFold ? AppColors.textPrimary : tint
            }
        }()
        return VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppTypography.caption.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
            HStack(spacing: 6) {
                Image(systemName: desc.systemImage)
                    .font(.system(size: 14, weight: .bold))
                Text(desc.displayName)
                    .font(AppTypography.bodyBold)
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 8)
            .background(Capsule().fill(tint.opacity(0.16)))
            .overlay(Capsule().strokeBorder(tint.opacity(0.32), lineWidth: 0.5))
            .accessibilityLabel("\(label): \(desc.displayName)")
        }
    }

    // MARK: - Reason chip + paragraphs

    /// The chip dropped from the old "Why?" disclosure, plus the body
    /// paragraphs (reason + context). Skipping the disclosure entirely —
    /// the overlay has the room and the player benefits from seeing the
    /// explanation up front, especially on punts.
    private var reasonAndBody: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if let reason = payload.mistakeReason {
                HStack(spacing: AppSpacing.xs) {
                    MistakeReasonChip(reason: reason)
                    Spacer(minLength: 0)
                }
            }
            ForEach(Array(bodyParagraphs.enumerated()), id: \.offset) { _, p in
                Text(p)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        }
    }

    /// The verdict already heads the card; everything else from the explainer
    /// is body copy. Postflop has no extra paragraphs — `verdict` carries the
    /// whole explanation in that case.
    private var bodyParagraphs: [String] {
        payload.paragraphs
    }

    // MARK: - Siblings

    private var siblings: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Same line")
                .font(AppTypography.caption.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(payload.siblingHands, id: \.self) { combo in
                        VStack(spacing: 4) {
                            HandCardView(hand: combo.notation, size: .compact)
                                .frame(height: 96)
                            Text(combo.notation)
                                .font(AppTypography.caption.weight(.semibold))
                                .foregroundStyle(AppColors.textPrimary)
                        }
                        .frame(width: 96)
                    }
                }
                .padding(.vertical, AppSpacing.xs)
                .padding(.horizontal, 2)
            }
            .accessibilityLabel("Same line as: \(payload.siblingHands.map(\.notation).joined(separator: ", "))")
        }
    }

    // MARK: - CTAs

    private var ctaRow: some View {
        HStack(spacing: AppSpacing.sm) {
            if let onViewRange {
                SecondaryButton(title: "View range", systemImage: "rectangle.grid.3x2", action: onViewRange)
            }
            PrimaryButton(title: "Next hand", systemImage: "arrow.right", action: onNext)
        }
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: AppSpacing.lg) {
            HandCardView(hand: "AJs")
            Text("Hero hand").foregroundStyle(.white)
        }
    }
    .overlay {
        FeedbackOverlay(
            payload: FeedbackPayload(
                outcome: .mistake,
                userAction: ActionDescriptor(RangeAction.fold),
                correctAction: ActionDescriptor(RangeAction.raise),
                verdict: "Mixed spot — chart plays AJs raise 70% / 3-bet 30%.",
                paragraphs: [
                    "Suited aces have the equity + blockers to keep going here. Folding AJs gives up too much.",
                    "Suited aces double-up as blockers and flush draws — they 3-bet well and defend well, just not from the worst seats."
                ],
                mistakeReason: .tooTight,
                siblingHands: [
                    HandCombo(highRank: .ace, lowRank: .ten, category: .suited),
                    HandCombo(highRank: .king, lowRank: .queen, category: .suited),
                    HandCombo(highRank: .king, lowRank: .jack, category: .suited)
                ]
            ),
            onNext: {},
            onViewRange: {}
        )
    }
}
