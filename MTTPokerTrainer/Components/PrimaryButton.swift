import SwiftUI

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(title)
                    .font(AppTypography.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundStyle(AppColors.backgroundDeep)
            .background(
                Capsule().fill(
                    LinearGradient(
                        colors: [AppColors.primaryMint, AppColors.primaryEmerald],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            )
            .scaleEffect(pressed ? AppMotion.pressed : 1)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in
                withAnimation(AppMotion.respecting(reduceMotion, AppMotion.quick)) { pressed = true }
            }
            .onEnded { _ in
                withAnimation(AppMotion.respecting(reduceMotion, AppMotion.quick)) { pressed = false }
            }
        )
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: AppSpacing.md) {
            PrimaryButton(title: "Start training") {}
            PrimaryButton(title: "Save profile", systemImage: "checkmark.circle.fill") {}
        }
        .padding()
    }
}
