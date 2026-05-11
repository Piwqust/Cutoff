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
                contextStrip
                Spacer(minLength: AppSpacing.md)
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
