import SwiftUI

struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(AppTypography.body)
                }
                Text(title)
                    .font(AppTypography.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundStyle(AppColors.textPrimary)
            .background(
                Capsule()
                    .strokeBorder(AppColors.divider, lineWidth: 1)
                    .background(
                        Capsule().fill(.ultraThinMaterial)
                    )
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack {
            SecondaryButton(title: "Customize tournament") {}
        }
        .padding()
    }
}
