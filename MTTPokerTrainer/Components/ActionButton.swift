import SwiftUI

/// Color-coded action button used in trainers.
///
/// Color is always paired with the action label + glyph so users do not rely
/// on color alone (accessibility). When `disabled` is true the button is
/// visually present but non-interactive — so the layout never shifts between
/// spots that allow different action sets.
struct ActionButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    /// When true, foreground is `backgroundDeep` for contrast on light fills.
    /// When false, foreground is `textPrimary` for dark/muted fills (Fold).
    var darkForeground: Bool = true
    var disabled: Bool = false
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: systemImage)
                    .font(AppTypography.bodyBold)
                Text(title)
                    .font(AppTypography.bodyBold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundStyle(darkForeground ? AppColors.backgroundDeep : AppColors.textPrimary)
            .background(Capsule().fill(tint))
            .opacity(disabled ? 0.32 : 1)
            .scaleEffect(pressed && !disabled ? AppMotion.pressed : 1)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityLabel(disabled ? "\(title), not available in this spot" : title)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !disabled else { return }
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
            ActionButton(title: "Raise 2.5x", systemImage: "arrow.up.right.circle", tint: AppColors.actionRaise) {}
            ActionButton(title: "Raise 3x", systemImage: "arrow.up.right.circle.fill", tint: AppColors.actionThreeBet) {}
            ActionButton(title: "Jam", systemImage: "flame.fill", tint: AppColors.actionJam, disabled: true) {}
        }
        .padding()
    }
}
