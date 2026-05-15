import SwiftUI
import SwiftData

struct DrillTrainerView: View {
    let category: DrillCategory

    @Environment(\.modelContext) private var modelContext
    @Environment(ProgressStore.self) private var progress
    @State private var vm = DrillTrainerViewModel()
    @State private var feedbackVisible = false

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
                .presentationDragIndicator(.visible)
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

    private func submit(_ action: RangeAction) {
        vm.submit(action)
        feedbackVisible = true
    }
}
