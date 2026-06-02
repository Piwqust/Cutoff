import SwiftUI
import SwiftData

struct DrillTrainerView: View {
    let category: DrillCategory

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(ProgressStore.self) private var progress
    @Environment(LocalizationManager.self) private var l10n
    @Environment(ConfigStore.self) private var config
    @State private var vm = DrillTrainerViewModel()

    /// Two atomic pieces of feedback state. They're independent on purpose —
    /// `silentCorrectToken` drives the brief edge-tick affirmation on a
    /// correct answer, `feedback` drives the iOS sheet presentation for
    /// every other outcome.
    @State private var silentCorrectToken: UUID?
    @State private var feedback: IdentifiedFeedback?

    /// Counter bumped on every submit so `.sensoryFeedback` fires once per
    /// answer regardless of which path runs afterwards.
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
        .overlay(alignment: .top) { edgeTick }
        .navigationTitle(category.title(in: l10n.language))
        .navigationBarTitleDisplayMode(.inline)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .sensoryFeedback(trigger: feedbackTick) { _, _ in
            haptic(for: vm.lastOutcome)
        }
        .sheet(item: $feedback, onDismiss: { advance() }) { item in
            FeedbackSheet(
                payload: item.payload,
                onNext: { feedback = nil },
                rangePayload: vm.current.map { question in
                    RangeDetailPayload(
                        combo: question.combo,
                        frequencies: question.chart.frequencies(for: question.combo),
                        chart: question.chart
                    )
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            vm.modelContext = modelContext
            vm.progress = progress
            vm.language = l10n.language
            vm.load(category: category)
        }
        .onChange(of: l10n.language) { _, new in
            vm.language = new
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
                    .font(AppTypography.footnote.weight(.bold))
                    .foregroundStyle(situationTint(for: spot?.facingAction))
                Text(spot?.facingAction.headline(in: l10n.language) ?? l10n.t(.loading))
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
            }
            Spacer(minLength: AppSpacing.xs)
            HStack(spacing: 6) {
                Image(systemName: villain.systemImage)
                    .font(AppTypography.footnote.weight(.bold))
                    .foregroundStyle(villainTint(for: villain))
                Text(villain.displayName(in: l10n.language))
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
        case .vs3BetJam:     return AppColors.actionJam
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
    /// the next hand is dealt.
    @ViewBuilder
    private var edgeTick: some View {
        if silentCorrectToken != nil {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(AppColors.primaryMint)
                .frame(height: 2)
                .frame(maxWidth: .infinity)
                .transition(.opacity)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Haptics

    private func haptic(for outcome: AnswerOutcome?) -> SensoryFeedback? {
        guard config.hapticsEnabled else { return nil }
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
                    title: action.displayName(in: l10n.language),
                    systemImage: action.systemImage,
                    tint: action.tint,
                    darkForeground: action.prefersDarkForeground,
                    disabled: !isIdle
                ) { submit(action) }
            }
        }
    }

    private var isIdle: Bool {
        silentCorrectToken == nil && feedback == nil
    }

    // MARK: - Submission flow

    /// Submit → haptic → branch on outcome.
    /// `.correct`            → edge-tick affirmation, auto-advance.
    /// `.close/.mistake/.punt` → present sheet; user controls advance.
    private func submit(_ action: RangeAction) {
        guard isIdle else { return }
        vm.submit(action)
        feedbackTick &+= 1
        guard let outcome = vm.lastOutcome else { return }

        if outcome == .correct {
            let token = UUID()
            withAnimation(AppMotion.respecting(reduceMotion, .easeOut(duration: 0.18))) {
                silentCorrectToken = token
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 520_000_000)
                guard silentCorrectToken == token else { return }
                advance()
            }
        } else if let payload = vm.lastPayload {
            feedback = IdentifiedFeedback(payload: payload)
        }
    }

    /// Single dismissal / advance path used by every sheet exit
    /// (Next button, drag-down) and by the silent-correct timer.
    /// Returns the trainer to idle and loads the next spot.
    private func advance() {
        withAnimation(AppMotion.respecting(reduceMotion, .easeOut(duration: 0.22))) {
            silentCorrectToken = nil
        }
        feedback = nil
        vm.next()
    }
}
