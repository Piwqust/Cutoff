import SwiftUI

/// Color-coded action button used in trainers.
///
/// Color is always paired with the action label + glyph so users do not rely
/// on color alone (accessibility).
struct ActionButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    /// When true, foreground is `backgroundDeep` for contrast on light fills.
    /// When false, foreground is `textPrimary` for dark/muted fills (Fold).
    var darkForeground: Bool = true
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .bold))
                Text(title)
                    .font(AppTypography.bodyBold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundStyle(darkForeground ? AppColors.backgroundDeep : AppColors.textPrimary)
            .background(Capsule().fill(tint))
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
        VStack(spacing: AppSpacing.sm) {
            ActionButton(title: "Fold", systemImage: "xmark", tint: AppColors.actionFold, darkForeground: false) {}
            ActionButton(title: "Call", systemImage: "equal", tint: AppColors.actionCall) {}
            ActionButton(title: "Raise", systemImage: "arrow.up.right", tint: AppColors.actionRaise) {}
            ActionButton(title: "3-bet", systemImage: "arrow.up.right.circle.fill", tint: AppColors.actionThreeBet) {}
            ActionButton(title: "Jam", systemImage: "flame.fill", tint: AppColors.actionJam) {}
        }
        .padding()
    }
}
