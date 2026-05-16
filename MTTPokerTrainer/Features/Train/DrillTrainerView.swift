import SwiftUI
import SwiftData

struct DrillTrainerView: View {
    let category: DrillCategory

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(ProgressStore.self) private var progress
    @State private var vm = DrillTrainerViewModel()
    @State private var feedbackVisible = false
    @State private var feedbackTick: Int = 0

    /// Edge tick state. `tickOutcome` is set on submit and cleared after the
    /// tick fades out. `tickProgress` drives the slide-in from leading edge.
    /// `tickOpacity` drives the fade-out.
    @State private var tickOutcome: AnswerOutcome? = nil
    @State private var tickProgress: CGFloat = 0
    @State private var tickOpacity: Double = 1

    /// Auto-dismiss task for the correct + close paths. Cancelled on any
    /// user interaction so the sheet never closes while the player reads.
    @State private var autoDismissTask: Task<Void, Never>? = nil

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
        .overlay(alignment: .top) { edgeTick }
        // Tap anywhere outside the sheet to dismiss + advance. Implemented
        // as a conditional overlay so it does NOT capture the initial
        // action-button tap that opens the sheet in the first place.
        .overlay { tapDismissShield }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .sensoryFeedback(trigger: feedbackTick) { _, _ in
            haptic(for: vm.lastOutcome)
        }
        .sheet(isPresented: $feedbackVisible) {
            if let outcome = vm.lastOutcome, let question = vm.current {
                FeedbackSheet(
                    outcome: outcome,
                    correctAction: question.correctAction,
                    explanation: vm.lastExplanation,
                    deepDive: vm.lastDeepDive,
                    onNext: { feedbackVisible = false },
                    onInteraction: { cancelAutoDismiss() }
                )
                .presentationDetents([.fraction(0.6)])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.6)))
            }
        }
        .onChange(of: feedbackVisible) { _, isPresented in
            if !isPresented { handleSheetDismissed() }
        }
        .onDisappear { cancelAutoDismiss() }
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
    /// bottoms.
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
    }

    // MARK: - Tap-to-dismiss shield

    /// Transparent layer that only exists while the sheet is up. Tapping
    /// any visible region outside the sheet flips `feedbackVisible` false;
    /// `onChange` handles cleanup and advances the spot. The shield is
    /// conditional so it cannot capture the action-button tap that
    /// opened the sheet.
    @ViewBuilder
    private var tapDismissShield: some View {
        if feedbackVisible {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { feedbackVisible = false }
                .accessibilityHidden(true)
        }
    }

    // MARK: - Edge tick

    /// 2pt rounded rule pinned to the top of the safe area. Slides in from
    /// the leading edge over 300ms, sits while the sheet is up, fades out
    /// when the sheet closes. Peripheral by design.
    @ViewBuilder
    private var edgeTick: some View {
        if let outcome = tickOutcome {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(tickColor(for: outcome))
                .frame(height: 2)
                .frame(maxWidth: .infinity)
                .scaleEffect(x: tickProgress, y: 1, anchor: .leading)
                .opacity(tickOpacity)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private func tickColor(for outcome: AnswerOutcome) -> Color {
        switch outcome {
        case .correct: return AppColors.primaryMint
        case .close:   return AppColors.accentLime
        case .mistake: return AppColors.accentPeach
        case .punt:    return AppColors.errorSoft
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

    // MARK: - Submission flow

    /// Submit → haptic → edge tick slides in → sheet presents. On
    /// correct / close the sheet auto-dismisses at 1.5s unless the user
    /// interacts with it.
    private func submit(_ action: RangeAction) {
        vm.submit(action)
        feedbackTick &+= 1
        guard let outcome = vm.lastOutcome else { return }

        // Reset edge-tick state and animate it in.
        tickOutcome = outcome
        tickProgress = 0
        tickOpacity = 1
        withAnimation(AppMotion.respecting(reduceMotion, .easeOut(duration: 0.3))) {
            tickProgress = 1
        }

        feedbackVisible = true

        if outcome == .correct || outcome == .close {
            scheduleAutoDismiss()
        }
    }

    private func scheduleAutoDismiss() {
        autoDismissTask?.cancel()
        autoDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            feedbackVisible = false   // onChange handles the rest
        }
    }

    private func cancelAutoDismiss() {
        autoDismissTask?.cancel()
        autoDismissTask = nil
    }

    /// Single point of cleanup when the sheet closes for any reason
    /// (tap-above, drag-down, Next button, auto-dismiss). Fades the tick
    /// out, advances to the next spot, clears the auto-dismiss task.
    private func handleSheetDismissed() {
        cancelAutoDismiss()
        withAnimation(AppMotion.respecting(reduceMotion, .easeOut(duration: 0.2))) {
            tickOpacity = 0
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 220_000_000)
            if !feedbackVisible {
                tickOutcome = nil
                tickProgress = 0
                tickOpacity = 1
            }
        }
        if vm.lastOutcome != nil {
            vm.next()
        }
    }
}
