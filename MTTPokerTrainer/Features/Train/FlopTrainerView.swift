import SwiftUI

struct FlopTrainerView: View {
    @State private var vm = FlopTrainerViewModel()

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    statsRow
                    filterRow
                    if let spot = vm.currentSpot {
                        spotCard(spot)
                        if let result = vm.lastResult {
                            resultCard(result)
                            nextButton
                        } else {
                            actionButtons(spot)
                        }
                    } else {
                        loadingPlaceholder
                    }
                    disclaimer
                }
                .padding(.horizontal, AppSpacing.pageHorizontal)
                .padding(.vertical, AppSpacing.lg)
            }
        }
        .navigationTitle("Flop Trainer")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { vm.load() }
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: AppSpacing.sm) {
            StatCard(label: "Hands", value: "\(vm.totalAnswered)", hint: "this session")
            StatCard(label: "Accuracy", value: vm.totalAnswered == 0 ? "—" : "\(vm.accuracy)%", hint: "session avg")
        }
    }

    // MARK: - Filters

    private var filterRow: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    FilterChip(title: "All scenarios", isSelected: vm.selectedScenarioFilter == nil) {
                        vm.setScenario(nil)
                    }
                    ForEach(PreflopScenario.allCases) { scenario in
                        FilterChip(title: scenario.displayName, isSelected: vm.selectedScenarioFilter == scenario) {
                            vm.setScenario(scenario)
                        }
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    FilterChip(title: "All textures", isSelected: vm.selectedTextureFilter == nil) {
                        vm.setTexture(nil)
                    }
                    ForEach(BoardTextureClass.allCases) { tex in
                        FilterChip(title: tex.displayName, isSelected: vm.selectedTextureFilter == tex) {
                            vm.setTexture(tex)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Spot card

    private func spotCard(_ spot: PostflopSpot) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            scenarioHeader(spot)
            boardStrip(spot.sampleBoard)
            historyList(spot.history)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(AppColors.cardSurface)
        )
    }

    private func scenarioHeader(_ spot: PostflopSpot) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(spot.scenario.displayName)
                .font(AppTypography.bodyBold)
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            Text("\(spot.stackDepthBB) BB")
                .font(AppTypography.numericMedium)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private func boardStrip(_ notation: String) -> some View {
        let cards = parseBoard(notation)
        return HStack(spacing: AppSpacing.xs) {
            ForEach(Array(cards.enumerated()), id: \.offset) { _, card in
                boardCard(card)
            }
            Spacer()
        }
    }

    private func boardCard(_ card: Card) -> some View {
        VStack(spacing: 2) {
            Text(card.rank.rawValue)
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text(card.suit.symbol)
                .font(.system(size: 22))
        }
        .foregroundStyle(card.suit.isRed ? AppColors.actionJam : AppColors.textPrimary)
        .frame(width: 56, height: 76)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppColors.backgroundDeep)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(AppColors.divider, lineWidth: 1)
                )
        )
    }

    private func historyList(_ history: [String]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(history.indices, id: \.self) { i in
                Text("• " + history[i])
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    // MARK: - Action buttons

    private func actionButtons(_ spot: PostflopSpot) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Text("Action on you")
                .font(AppTypography.caption)
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(spot.availableActions, id: \.self) { action in
                Button { vm.submit(action: action) } label: {
                    HStack {
                        Image(systemName: action.systemImage)
                        Text(action.displayName)
                            .font(AppTypography.bodyBold)
                        Spacer()
                    }
                    .padding(AppSpacing.md)
                    .foregroundStyle(AppColors.textPrimary)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                            .fill(AppColors.cardSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                                    .strokeBorder(AppColors.divider, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Result card

    private func resultCard(_ result: FlopAnswerResult) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: result.outcome == .correct ? "checkmark.circle.fill" : "info.circle.fill")
                    .foregroundStyle(outcomeColor(result.outcome))
                Text(result.outcome.headline)
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Text("+\(result.outcome.score)")
                    .font(AppTypography.numericMedium)
                    .foregroundStyle(outcomeColor(result.outcome))
            }

            // Solution breakdown
            VStack(alignment: .leading, spacing: 4) {
                Text("Solver consensus")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                ForEach(sortedSolution(result.spot), id: \.0) { (key, freq) in
                    HStack {
                        Text(PostflopAction(rawValue: key)?.displayName ?? key)
                            .font(AppTypography.subheadline)
                        Spacer()
                        Text("\(Int((freq * 100).rounded()))%")
                            .font(AppTypography.numericSmall)
                    }
                    .foregroundStyle(key == result.chosen.rawValue ? AppColors.primaryMint : AppColors.textSecondary)
                }
            }

            Text(result.spot.coachingNote)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.top, AppSpacing.xs)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(AppColors.cardSurface)
        )
    }

    private var nextButton: some View {
        Button { vm.nextSpot() } label: {
            HStack {
                Text("Next spot")
                    .font(AppTypography.headline)
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(AppColors.backgroundDeep)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.sm)
            .background(Capsule().fill(AppColors.primaryMint))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var loadingPlaceholder: some View {
        Text("Loading flop library…")
            .font(AppTypography.subheadline)
            .foregroundStyle(AppColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(AppSpacing.lg)
    }

    private var disclaimer: some View {
        Text(AppTheme.fullLegalLine)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, AppSpacing.md)
    }

    // MARK: - Helpers

    private func parseBoard(_ notation: String) -> [Card] {
        guard let b = Board(notation) else { return [] }
        return b.cards
    }

    private func sortedSolution(_ spot: PostflopSpot) -> [(String, Double)] {
        spot.solution.sorted { $0.value > $1.value }
    }

    private func outcomeColor(_ outcome: AnswerOutcome) -> Color {
        switch outcome {
        case .correct: return AppColors.accentGreen
        case .close:   return AppColors.accentLime
        case .mistake: return AppColors.accentPeach
        case .punt:    return AppColors.accentCoral
        }
    }
}

#Preview {
    NavigationStack { FlopTrainerView() }
}
