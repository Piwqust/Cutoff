import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: { if isEnabled { action() } }) {
            Text(title)
                .font(AppTypography.subheadline)
                .foregroundStyle(foreground)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(
                    Capsule().fill(background)
                )
                .overlay(
                    Capsule().strokeBorder(borderColor, lineWidth: 1)
                )
                .contentShape(Capsule())
                .opacity(isEnabled ? 1 : 0.35)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityValueText)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var foreground: Color {
        if isSelected { return AppColors.backgroundDeep }
        return AppColors.textPrimary
    }

    /// Selected chips fill mint; unselected use a plain tinted surface
    /// (not Liquid Glass material) so chips read as chips without
    /// competing with the cards they may sit near.
    private var background: AnyShapeStyle {
        if isSelected { return AnyShapeStyle(AppColors.primaryMint) }
        return AnyShapeStyle(AppColors.cardSurface)
    }

    private var borderColor: Color {
        isSelected ? .clear : AppColors.divider
    }

    private var accessibilityValueText: String {
        if !isEnabled { return "Unavailable" }
        return isSelected ? "Selected" : "Not selected"
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack {
            HStack {
                FilterChip(title: "UTG", isSelected: true) {}
                FilterChip(title: "CO", isSelected: false) {}
                FilterChip(title: "BTN", isSelected: false) {}
            }
            HStack {
                FilterChip(title: "vsOpen", isSelected: false, isEnabled: false) {}
                FilterChip(title: "Squeeze", isSelected: false, isEnabled: false) {}
            }
        }
    }
}
