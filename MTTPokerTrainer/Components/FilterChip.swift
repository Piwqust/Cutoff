import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.subheadline)
                .foregroundStyle(isSelected ? AppColors.backgroundDeep : AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(
                    Capsule().fill(isSelected ? AnyShapeStyle(AppColors.primaryMint) : AnyShapeStyle(.ultraThinMaterial))
                )
                .overlay(
                    Capsule().strokeBorder(isSelected ? .clear : AppColors.divider, lineWidth: 1)
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    ZStack {
        AppBackground()
        HStack {
            FilterChip(title: "UTG", isSelected: true) {}
            FilterChip(title: "CO", isSelected: false) {}
            FilterChip(title: "BTN", isSelected: false) {}
        }
    }
}
