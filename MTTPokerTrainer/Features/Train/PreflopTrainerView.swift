import SwiftUI
import SwiftData

struct PreflopTrainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ConfigStore.self) private var config
    @State private var vm = PreflopTrainerViewModel()
    @State private var feedbackVisible = false

    private static let primaryRowActions: [PreflopAction] = [.fold, .call]
    private static let raiseRowActions: [PreflopAction] = [.minRaise, .raise25x]
    private static let aggressiveRowActions: [PreflopAction] = [.raise3x, .shove]
    private static let blindRowActions: [PreflopAction] = [.limp, .limpRaise]

    var body: some View {
        ZStack {
            AppBackground()

            VStack(alignment: .leading, spacing: AppSpacing.md) {
                contextStrip
                if let chart = vm.currentChart {
                    TableMinimapView(
                        config: config.config,
                        heroPosition: chart.position,
                        actedPositions: vm.actedPositions
                    )
                }
                handDisplay
                Spacer(minLength: AppSpacing.xs)
                actionGrid
                disclaimer
            }
            .padding(.horizontal, AppSpacing.pageHorizontal)
            .padding(.vertical, AppSpacing.lg)
        }
        .navigationTitle("Preflop")
        .navigationBarTitleDisplayMode(.inline)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .sheet(isPresented: $feedbackVisible) {
            if let outcome = vm.lastOutcome {
                FeedbackSheet(
                    outcome: outcome,
                    correctAction: vm.correctAction,
                    explanation: vm.lastExplanation,
                    onNext: {
                        feedbackVisible = false
                        vm.next()
                    }
                )
                .presentationDetents([.fraction(0.45), .medium])
                .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            vm.modelContext = modelContext
            vm.load()
        }
    }

    // MARK: - Subviews

    private var contextStrip: some View {
        let spot = vm.currentChart?.trainingSpot
        return HStack(spacing: AppSpacing.xs) {
            chip(spot?.position.displayName ?? "—")
            chip("\(spot?.stackDepthBB ?? 0) BB")
            chip(spot?.facingAction.displayName ?? "—")
            Spacer()
        }
        .accessibilityLabel("Spot: \(spot?.summary ?? "loading")")
    }

    private func chip(_ s: String) -> some View {
        Text(s)
            .font(AppTypography.subheadline)
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 6)
            .background(Capsule().fill(AppColors.cardSurface))
    }

    private var handDisplay: some View {
        VStack(spacing: AppSpacing.xs) {
            if let combo = vm.currentCombo {
                HandCardView(hand: combo.notation)
                Text(combo.notation)
                    .font(AppTypography.numericLarge)
                    .foregroundStyle(AppColors.textPrimary)
            } else {
                ProgressView().tint(AppColors.primaryMint)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var actionGrid: some View {
        VStack(spacing: AppSpacing.xs) {
            actionRow(Self.primaryRowActions)
            actionRow(Self.raiseRowActions)
            actionRow(Self.aggressiveRowActions)
            actionRow(Self.blindRowActions)
        }
    }

    private func actionRow(_ actions: [PreflopAction]) -> some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(actions, id: \.self) { action in
                ActionButton(
                    title: action.shortLabel,
                    systemImage: action.systemImage,
                    tint: action.tint,
                    darkForeground: action.prefersDarkForeground,
                    disabled: !vm.isActionEnabled(action)
                ) {
                    submit(action)
                }
            }
        }
    }

    private var disclaimer: some View {
        Text(AppTheme.demoDataDisclaimer)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private func submit(_ action: PreflopAction) {
        vm.submit(action)
        feedbackVisible = true
    }
}

#Preview {
    NavigationStack { PreflopTrainerView() }
        .environment(ConfigStore())
        .modelContainer(for: [QuizResult.self, TrainingSession.self], inMemory: true)
}
