import SwiftUI
import SwiftData

struct DrillTrainerView: View {
    let category: DrillCategory

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(ProgressStore.self) private var progress
    @State private var vm = DrillTrainerViewModel()

    /// Single source of truth for the post-answer flow. `.idle` accepts
    /// taps; `.silentCorrect` shows a brief edge tick and auto-advances;
    /// `.revealed` puts the overlay up and waits for the user.
    @State private var phase: FeedbackPhase = .idle

    /// Counter bumped on every submit so `.sensoryFeedback` fires once per
    /// answer regardless of how the phase transitions afterwards.
    @State private var feedbackTick: Int = 0

    /// Auxiliary sheet for "View range" — built from the current question
    /// when the user taps the overlay's CTA.
    @State private var rangeDetail: RangeDetailPayload?

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
        .overlay { feedbackOverlay }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .sensoryFeedback(trigger: feedbackTick) { _, _ in
            haptic(for: vm.lastOutcome)
        }
        .sheet(item: $rangeDetail) { payload in
            RangeDetailSheet(payload: payload)
                .presentationDetents([.fraction(0.5), .medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            vm.modelContext = modelContext
            vm.progress = progress
            vm.load(category: category)
        }
    }

    // MARK: - Table display

    @ViewBuilder
    private var tableDisplay: some View {
        if let spot = vm.current?.spot {
            PokerTableView(snapshot: .from(spot: spot))
        } else {
            Color.clear.frame(height: 150)
        }
    }

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

    private var handDisplay: some View {
        VStack(spacing: AppSpacing.xs) {
            if let combo = vm.current?.combo {
                HandCardView(hand: combo.notation)
                    .frame(height: 168)
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

    // MARK: - Edge tick

    /// Slim mint rule pinned to the top of the safe area. Lights up briefly
    /// on a correct answer (the silent-affirmation path), then fades out as
    /// the next hand is dealt. No edge tick for mistakes — the overlay
    /// carries the entire feedback signal in that case.
    @ViewBuilder
    private var edgeTick: some View {
        if case .silentCorrect = phase {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(AppColors.primaryMint)
                .frame(height: 2)
                .frame(maxWidth: .infinity)
                .transition(.opacity)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Feedback overlay

    @ViewBuilder
    private var feedbackOverlay: some View {
        if case .revealed(let payload) = phase {
            FeedbackOverlay(
                payload: payload,
                onNext: { advance() },
                onViewRange: vm.current.map { question in
                    {
                        rangeDetail = RangeDetailPayload(
                            combo: question.combo,
                            frequencies: question.chart.frequencies(for: question.combo),
                            chart: question.chart
                        )
                    }
                }
            )
            .transition(overlayTransition)
        }
    }

    private var overlayTransition: AnyTransition {
        if reduceMotion { return .opacity }
        return .opacity.combined(with: .scale(scale: 0.96, anchor: .center))
    }

    // MARK: - Haptics

    private func haptic(for outcome: AnswerOutcome?) -> SensoryFeedback? {
        switch outcome {
        case .correct: return .success
        case .close:   return .impact(weight: .medium, intensity: 0.7)
        case .mistake: return .warning
        case .punt:    return .error
        case .none:    return nil
        }
    }

    // MARK: - Action row

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
                    darkForeground: action.prefersDarkForeground,
                    disabled: !isIdle
                ) { submit(action) }
            }
        }
    }

    private var isIdle: Bool {
        if case .idle = phase { return true }
        return false
    }

    // MARK: - Submission flow

    /// Submit → haptic → branch on outcome.
    /// `.correct`            → silent-correct: edge tick + auto-advance.
    /// `.close/.mistake/.punt` → overlay reveal; user controls advance.
    private func submit(_ action: RangeAction) {
        guard isIdle else { return }
        vm.submit(action)
        feedbackTick &+= 1
        guard let outcome = vm.lastOutcome else { return }

        if outcome == .correct {
            let token = UUID()
            withAnimation(AppMotion.respecting(reduceMotion, .easeOut(duration: 0.18))) {
                phase = .silentCorrect(token: token)
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 520_000_000)
                guard case .silentCorrect(let active) = phase, active == token else { return }
                advance()
            }
        } else if let payload = vm.lastPayload {
            withAnimation(AppMotion.respecting(reduceMotion, .spring(response: 0.35, dampingFraction: 0.85))) {
                phase = .revealed(payload)
            }
        }
    }

    /// Single dismissal / advance path used by every overlay exit
    /// (Next button, backdrop tap, swipe-down) and by the silent-correct
    /// timer. Returns the trainer to `.idle` and loads the next spot.
    private func advance() {
        withAnimation(AppMotion.respecting(reduceMotion, .easeOut(duration: 0.22))) {
            phase = .idle
        }
        vm.next()
    }
}
