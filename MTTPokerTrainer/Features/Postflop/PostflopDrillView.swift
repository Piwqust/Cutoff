import SwiftUI
import SwiftData

struct PostflopDrillView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = PostflopDrillViewModel()
    @State private var feedbackVisible = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    if let spot = vm.currentSpot {
                        contextStrip(for: spot)
                        BoardView(board: spot.board)
                        HoleCardsView(hand: spot.heroHand)
                        actionGrid(for: spot)
                    } else {
                        ProgressView().tint(AppColors.primaryMint)
                    }
                    disclaimer
                }
                .padding(.horizontal, AppSpacing.pageHorizontal)
                .padding(.vertical, AppSpacing.lg)
            }
        }
        .navigationTitle("Postflop")
        .navigationBarTitleDisplayMode(.inline)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .sheet(isPresented: $feedbackVisible) {
            if let outcome = vm.lastOutcome, let spot = vm.currentSpot {
                PostflopFeedbackSheet(
                    outcome: outcome,
                    correctAction: spot.dominantAction,
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

    private func contextStrip(for spot: PostflopSpot) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xs) {
                chip(spot.heroPosition.displayName)
                chip(spot.isInPosition ? "IP" : "OOP")
                chip(spot.boardTexture.displayName)
                Spacer()
            }
            HStack(spacing: AppSpacing.xs) {
                chip("Pot \(formatted(spot.potSizeBB)) BB")
                chip("Eff \(formatted(spot.effectiveStackBB)) BB")
                Spacer()
            }
        }
    }

    private func chip(_ s: String) -> some View {
        Text(s)
            .font(AppTypography.subheadline)
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 6)
            .background(Capsule().fill(AppColors.cardSurface))
    }

    private func actionGrid(for spot: PostflopSpot) -> some View {
        let pairs = chunked(spot.validActions, size: 2)
        return VStack(spacing: AppSpacing.xs) {
            ForEach(0..<pairs.count, id: \.self) { i in
                HStack(spacing: AppSpacing.xs) {
                    ForEach(pairs[i], id: \.self) { action in
                        ActionButton(
                            title: action.displayName,
                            systemImage: action.systemImage,
                            tint: action.tint,
                            darkForeground: action.prefersDarkForeground
                        ) {
                            submit(action)
                        }
                    }
                    if pairs[i].count == 1 {
                        Color.clear.frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var disclaimer: some View {
        VStack(spacing: 4) {
            Text(AppTheme.demoDataDisclaimer)
            Text(AppTheme.disclaimer)
        }
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textSecondary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private func submit(_ action: PostflopAction) {
        vm.submit(action)
        feedbackVisible = true
    }

    private func formatted(_ value: Double) -> String {
        let r = (value * 10).rounded() / 10
        if r == r.rounded() { return "\(Int(r))" }
        return String(format: "%.1f", r)
    }

    private func chunked<T>(_ array: [T], size: Int) -> [[T]] {
        stride(from: 0, to: array.count, by: size).map { Array(array[$0..<min($0 + size, array.count)]) }
    }
}

/// Feedback sheet variant for the postflop drill (different action enum).
struct PostflopFeedbackSheet: View {
    let outcome: AnswerOutcome
    let correctAction: PostflopAction
    let explanation: String
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                outcomeBadge
                Spacer()
                Text(AppTheme.demoDataDisclaimer)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.trailing)
            }
            HStack(alignment: .center, spacing: AppSpacing.sm) {
                Text("Best answer")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                HStack(spacing: 6) {
                    Image(systemName: correctAction.systemImage)
                        .font(.system(size: 14, weight: .bold))
                    Text(correctAction.displayName)
                        .font(AppTypography.bodyBold)
                }
                .foregroundStyle(correctAction.prefersDarkForeground ? AppColors.backgroundDeep : AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, 6)
                .background(Capsule().fill(correctAction.tint))
            }
            Text(explanation)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "Next spot", systemImage: "arrow.right", action: onNext)
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.sheet, style: .continuous)
                .fill(AppColors.cardSurface)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var outcomeBadge: some View {
        let (color, glyph): (Color, String) = {
            switch outcome {
            case .correct: return (AppColors.primaryMint, "checkmark.circle.fill")
            case .close:   return (AppColors.accentLime, "circle.lefthalf.filled")
            case .mistake: return (AppColors.accentPeach, "exclamationmark.circle.fill")
            case .punt:    return (AppColors.errorSoft, "xmark.octagon.fill")
            }
        }()
        return HStack(spacing: 6) {
            Image(systemName: glyph)
                .font(.system(size: 16, weight: .bold))
            Text(outcome.headline)
                .font(AppTypography.headline)
        }
        .foregroundStyle(color)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 6)
        .background(Capsule().fill(color.opacity(0.16)))
    }
}

#Preview {
    NavigationStack { PostflopDrillView() }
        .modelContainer(for: [PostflopDrillSession.self, PostflopResult.self], inMemory: true)
}
