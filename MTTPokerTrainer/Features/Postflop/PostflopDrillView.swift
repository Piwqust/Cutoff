import SwiftUI
import SwiftData

struct PostflopDrillView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var vm = PostflopDrillViewModel()

    @State private var silentCorrectToken: UUID?
    @State private var feedback: IdentifiedFeedback?
    @State private var feedbackTick: Int = 0

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
                }
                .padding(.horizontal, AppSpacing.pageHorizontal)
                .padding(.vertical, AppSpacing.lg)
            }
        }
        .overlay(alignment: .top) { edgeTick }
        .navigationTitle("Postflop")
        .navigationBarTitleDisplayMode(.inline)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .sensoryFeedback(trigger: feedbackTick) { _, _ in
            haptic(for: vm.lastOutcome)
        }
        .sheet(item: $feedback, onDismiss: { advance() }) { item in
            FeedbackSheet(payload: item.payload, onNext: { feedback = nil })
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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
                            darkForeground: action.prefersDarkForeground,
                            disabled: !isIdle
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

    // MARK: - Submission flow

    private func submit(_ action: PostflopAction) {
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

    private func advance() {
        withAnimation(AppMotion.respecting(reduceMotion, .easeOut(duration: 0.22))) {
            silentCorrectToken = nil
        }
        feedback = nil
        vm.next()
    }

    private var isIdle: Bool {
        silentCorrectToken == nil && feedback == nil
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

    // MARK: - Helpers

    private func formatted(_ value: Double) -> String {
        let r = (value * 10).rounded() / 10
        if r == r.rounded() { return "\(Int(r))" }
        return String(format: "%.1f", r)
    }

    private func chunked<T>(_ array: [T], size: Int) -> [[T]] {
        stride(from: 0, to: array.count, by: size).map { Array(array[$0..<min($0 + size, array.count)]) }
    }
}

#Preview {
    NavigationStack { PostflopDrillView() }
        .modelContainer(for: [PostflopDrillSession.self, PostflopResult.self], inMemory: true)
}
