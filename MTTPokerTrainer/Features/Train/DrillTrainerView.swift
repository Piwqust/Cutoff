import SwiftUI
import SwiftData

struct DrillTrainerView: View {
    let category: DrillCategory

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(ProgressStore.self) private var progress
    @State private var vm = DrillTrainerViewModel()
    @State private var feedbackVisible = false
    @State private var flashOutcome: AnswerOutcome? = nil
    @State private var feedbackTick: Int = 0

    var body: some View {
        ZStack {
            AppBackground()

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                tableDisplay
                contextRow
                Spacer(minLength: 0)
                handDisplay
                Spacer(minLength: 0)
                actionRow
            }
            .padding(.horizontal, AppSpacing.pageHorizontal)
            .padding(.top, AppSpacing.xs)
            .padding(.bottom, AppSpacing.sm)
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .sensoryFeedback(trigger: feedbackTick) { _, _ in
            haptic(for: vm.lastOutcome)
        }
        // Tap anywhere above the sheet to advance. When the sheet is up,
        // the action row is occluded so this never fights button taps.
        .simultaneousGesture(
            TapGesture().onEnded {
                guard feedbackVisible else { return }
                feedbackVisible = false
                vm.next()
            }
        )
        .sheet(isPresented: $feedbackVisible) {
            if let outcome = vm.lastOutcome, let question = vm.current {
                FeedbackSheet(
                    outcome: outcome,
                    correctAction: question.correctAction,
                    explanation: vm.lastExplanation,
                    deepDive: vm.lastDeepDive,
                    onNext: {
                        feedbackVisible = false
                        vm.next()
                    }
                )
                .presentationDetents([.fraction(0.6)])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.6)))
            }
        }
        .onAppear {
            vm.modelContext = modelContext
            vm.progress = progress
            vm.load(category: category)
        }
    }

    // MARK: - Table display

    /// Minimalist top-down table diagram standing in for a "position +
    /// stack" header — hero seat ringed in orange, seats labelled with
    /// position and stack, blinds and dealer marked, pot in the centre.
    @ViewBuilder
    private var tableDisplay: some View {
        if let spot = vm.current?.spot {
            PokerTableView(snapshot: .from(spot: spot))
        } else {
            Color.clear.frame(height: 150)
        }
    }

    /// One compact row carrying both "what's happening" (facing action) and
    /// "who you're against" (villain), replacing the previous two-row stack.
    private var contextRow: some View {
        let spot = vm.current?.spot
        let villain = vm.current?.villain ?? .standard
        return HStack(spacing: AppSpacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: spot?.facingAction.systemImage ?? "circle")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(situationTint(for: spot?.facingAction))
                Text(spot?.facingAction.headline ?? "Loading…")
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
            }
            Spacer(minLength: AppSpacing.xs)
            HStack(spacing: 6) {
                Image(systemName: villain.systemImage)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(villainTint(for: villain))
                Text(villain.displayName)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
            }
        }
    }

    private func situationTint(for facing: FacingAction?) -> Color {
        switch facing {
        case .unopened:      return AppColors.accentGreen
        case .vsOpen:        return AppColors.accentLime
        case .vs3Bet:        return AppColors.accentPeach
        case .blindDefense:  return AppColors.actionCall
        case .squeeze:       return AppColors.accentCoral
        case .pushFold:      return AppColors.actionJam
        case .none:          return AppColors.textSecondary
        }
    }

    private func villainTint(for v: VillainType) -> Color {
        switch v {
        case .standard: return AppColors.textSecondary
        case .loose:    return AppColors.accentLime
        case .maniac:   return AppColors.actionJam
        case .nit:      return AppColors.actionCall
        }
    }

    // MARK: - Hand display

    /// Full cards (never cropped). The HandCardView's rotated layout has a
    /// taller-than-natural bounding box; we reserve explicit vertical room so
    /// the combo label below the cards never overlaps with the rotated card
    /// bottoms. The flash overlay anchors here because this is where the
    /// player's eye already is at decision time.
    private var handDisplay: some View {
        VStack(spacing: AppSpacing.xs) {
            if let combo = vm.current?.combo {
                HandCardView(hand: combo.notation)
                    .frame(height: 168)  // 156 card + ~12pt rotation/offset slack
                Text(combo.notation)
                    .font(AppTypography.numericMedium)
                    .foregroundStyle(AppColors.textPrimary)
            } else {
                ProgressView()
                    .tint(AppColors.primaryMint)
                    .frame(height: 168)
            }
        }
        .frame(maxWidth: .infinity)
        .overlay { flashOverlay }
    }

    // MARK: - Flash overlay (correct + close path)

    /// Centered glyph on the hand cards. Single SF Symbol with a soft halo,
    /// no copy. Held just long enough for the player to register, then
    /// auto-advance fires before the fade-out completes so the new spot is
    /// already laying in when the overlay clears.
    @ViewBuilder
    private var flashOverlay: some View {
        if let outcome = flashOutcome, let style = flashStyle(outcome) {
            ZStack {
                Circle()
                    .fill(style.tint.opacity(0.18))
                    .frame(width: 160, height: 160)
                    .blur(radius: 10)
                Image(systemName: style.glyph)
                    .font(.system(size: 96, weight: .bold))
                    .foregroundStyle(style.tint)
                    .shadow(color: style.tint.opacity(0.45), radius: 16, x: 0, y: 0)
            }
            .transition(.opacity)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private struct FlashStyle {
        let tint: Color
        let glyph: String
    }

    private func flashStyle(_ outcome: AnswerOutcome) -> FlashStyle? {
        switch outcome {
        case .correct: return FlashStyle(tint: AppColors.primaryMint, glyph: "checkmark.circle.fill")
        case .close:   return FlashStyle(tint: AppColors.accentLime,  glyph: "circle.lefthalf.filled")
        default:       return nil
        }
    }

    // MARK: - Haptics

    /// Map outcomes to the iOS sensory feedback vocabulary. `.success` /
    /// `.warning` / `.error` are notification-class haptics that carry
    /// semantics; `.impact` is for the gentler "close" nudge.
    private func haptic(for outcome: AnswerOutcome?) -> SensoryFeedback? {
        switch outcome {
        case .correct: return .success
        case .close:   return .impact(weight: .medium, intensity: 0.7)
        case .mistake: return .warning
        case .punt:    return .error
        case .none:    return nil
        }
    }

    // MARK: - Actions

    private var actionRow: some View {
        let actions = vm.current?.availableActions ?? category.availableActions
        return LazyVGrid(
            columns: Array(
                repeating: GridItem(.flexible(), spacing: AppSpacing.xs),
                count: min(actions.count, 2)
            ),
            spacing: AppSpacing.xs
        ) {
            ForEach(actions, id: \.self) { action in
                ActionButton(
                    title: action.displayName,
                    systemImage: action.systemImage,
                    tint: action.tint,
                    darkForeground: action.prefersDarkForeground
                ) { submit(action) }
            }
        }
    }

    /// Branch on outcome:
    ///   - correct / close → silent flash + auto-advance, no sheet
    ///   - mistake / punt  → present the full feedback sheet
    private func submit(_ action: RangeAction) {
        vm.submit(action)
        feedbackTick &+= 1
        guard let outcome = vm.lastOutcome else { return }

        switch outcome {
        case .correct, .close:
            withAnimation(AppMotion.respecting(reduceMotion, .easeOut(duration: 0.06))) {
                flashOutcome = outcome
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 410_000_000) // 60 in + 350 hold
                vm.next()
                withAnimation(AppMotion.respecting(reduceMotion, .easeOut(duration: 0.09))) {
                    flashOutcome = nil
                }
            }
        case .mistake, .punt:
            feedbackVisible = true
        }
    }
}
