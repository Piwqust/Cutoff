import SwiftUI

struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let tint: Color?
    let padding: CGFloat
    @ViewBuilder var content: Content

    init(
        cornerRadius: CGFloat = AppRadius.card,
        tint: Color? = nil,
        padding: CGFloat = AppSpacing.lg,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .glassBackground(cornerRadius: cornerRadius, tint: tint)
    }
}

#Preview {
    ZStack {
        AppBackground()
        GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Glass card")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)
                Text("Used everywhere a surface needs depth.")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding()
    }
}
