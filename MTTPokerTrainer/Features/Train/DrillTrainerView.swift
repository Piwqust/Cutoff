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

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    tableDisplay
                    situationRow(vm.current?.spot)
                    villainRow
                    Spacer(minLength: AppSpacing.sm)
                    handDisplay
                    Spacer(minLength: AppSpacing.sm)
                    actionRow
                }
                .padding(.horizontal, AppSpacing.pageHorizontal)
                .padding(.vertical, AppSpacing.lg)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
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
                .presentationDetents([.fraction(0.5), .large])
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

    private func situationRow(_ spot: TrainingSpot?) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: spot?.facingAction.systemImage ?? "circle")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(situationTint(for: spot?.facingAction))
            Text(spot?.facingAction.headline ?? "Loading…")
                .font(AppTypography.bodyBold)
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
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

    // MARK: - Villain row (full text, no truncation)

    private var villainRow: some View {
        let villain = vm.current?.villain ?? .standard
        return HStack(alignment: .center, spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(villainTint(for: villain).opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: villain.systemImage)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(villainTint(for: villain))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(villain.displayName)
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
                Text(villain.shortNote)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.xs)
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
        VStack(spacing: AppSpacing.xl) {
            if let combo = vm.current?.combo {
                HandCardView(hand: combo.notation)
                    .frame(height: 176)  // 156 card + ~20pt rotation/offset slack
                Text(combo.notation)
                    .font(AppTypography.numericLarge)
                    .foregroundStyle(AppColors.textPrimary)
            } else {
                ProgressView()
                    .tint(AppColors.primaryMint)
                    .frame(height: 176)
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
