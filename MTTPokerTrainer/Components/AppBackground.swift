import SwiftUI

/// Root background. Layered linear gradient with a soft mint highlight in the
/// top-left. Drift animation is suppressed under Reduce Motion.
struct AppBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift: CGFloat = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppColors.backgroundDeep,
                    AppColors.backgroundGreenBlack,
                    AppColors.backgroundSurface
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [AppColors.primaryMint.opacity(0.10), .clear],
                center: UnitPoint(x: 0.15, y: 0.12),
                startRadius: 0,
                endRadius: 320
            )
            .blendMode(.plusLighter)
            .offset(y: drift)

            RadialGradient(
                colors: [AppColors.accentPeach.opacity(0.05), .clear],
                center: UnitPoint(x: 0.95, y: 0.85),
                startRadius: 0,
                endRadius: 280
            )
            .blendMode(.plusLighter)
        }
        .ignoresSafeArea()
        .onAppear { startDriftIfAllowed() }
    }

    private func startDriftIfAllowed() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            drift = 24
        }
    }
}

#Preview {
    AppBackground()
}
