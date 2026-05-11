import SwiftUI

/// Single entry point for Liquid Glass / Material surfaces. Always respects
/// Reduce Transparency by falling back to a solid `cardSurface`. Use as:
///
///     content.glassBackground(cornerRadius: AppRadius.card)
///
/// Or, for a soft tinted variant (used on the "today's drill" hero):
///
///     content.glassBackground(cornerRadius: AppRadius.hero, tint: AppColors.cardSurfaceGreen)
struct AppGlassBackground: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color?

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content.background(material)
    }

    @ViewBuilder
    private var material: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if reduceTransparency {
            shape
                .fill(AppColors.cardSurface)
                .overlay(shape.strokeBorder(AppColors.divider, lineWidth: 0.5))
        } else {
            ZStack {
                shape.fill(.ultraThinMaterial)
                if let tint {
                    shape.fill(tint.opacity(0.35))
                }
                shape.strokeBorder(AppColors.divider, lineWidth: 0.5)
            }
        }
    }
}

extension View {
    func glassBackground(cornerRadius: CGFloat = AppRadius.card, tint: Color? = nil) -> some View {
        modifier(AppGlassBackground(cornerRadius: cornerRadius, tint: tint))
    }
}
