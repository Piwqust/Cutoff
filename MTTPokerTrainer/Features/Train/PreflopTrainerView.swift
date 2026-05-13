import SwiftUI
import SwiftData

struct PreflopTrainerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = PreflopTrainerViewModel()
    @State private var feedbackVisible = false

    var body: some View {
        ZStack {
            AppBackground()

            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                tableDiagram
                Spacer(minLength: AppSpacing.sm)
                handDisplay
                Spacer(minLength: AppSpacing.md)
                actionRow
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

    @ViewBuilder
    private var tableDiagram: some View {
        if let spot = vm.currentChart?.trainingSpot {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                PokerTableView(snapshot: .from(spot: spot))
                Text(spot.facingAction.displayName)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .accessibilityLabel("Spot: \(spot.summary)")
        } else {
            Color.clear.frame(height: 1)
        }
    }

    private var handDisplay: some View {
        VStack(spacing: AppSpacing.md) {
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

    private var actionRow: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xs) {
                ActionButton(title: "Fold", systemImage: RangeAction.fold.systemImage, tint: AppColors.actionFold, darkForeground: false) { submit(.fold) }
                ActionButton(title: "Call", systemImage: RangeAction.call.systemImage, tint: AppColors.actionCall) { submit(.call) }
            }
            HStack(spacing: AppSpacing.xs) {
                ActionButton(title: "Raise",   systemImage: RangeAction.raise.systemImage,    tint: AppColors.actionRaise)    { submit(.raise) }
                ActionButton(title: "3-bet",   systemImage: RangeAction.threeBet.systemImage, tint: AppColors.actionThreeBet) { submit(.threeBet) }
            }
            ActionButton(title: "Jam", systemImage: RangeAction.jam.systemImage, tint: AppColors.actionJam) { submit(.jam) }
        }
    }

    private var disclaimer: some View {
        Text(AppTheme.demoDataDisclaimer)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private func submit(_ action: RangeAction) {
        vm.submit(action)
        feedbackVisible = true
    }
}

#Preview {
    NavigationStack { PreflopTrainerView() }
        .modelContainer(for: [QuizResult.self, TrainingSession.self], inMemory: true)
}
