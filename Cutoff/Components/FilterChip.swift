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
                .background(chipBackground)
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

    /// Selected chips fill mint for high-contrast active state; unselected
    /// chips use Liquid Glass so they read as inert controls floating over
    /// the surrounding content.
    @ViewBuilder
    private var chipBackground: some View {
        if isSelected {
            Capsule().fill(AppColors.primaryMint)
        } else {
            Capsule()
                .fill(Color.clear)
                .liquidGlass(in: Capsule(), interactive: isEnabled)
        }
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
