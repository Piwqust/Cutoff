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

// MARK: - Liquid Glass (iOS 26+)

/// Apply Apple's Liquid Glass treatment to a view, falling back to a
/// `.ultraThinMaterial` surface on older OS versions and a solid
/// `cardSurface` when Reduce Transparency is on.
///
/// Prefer this over a raw `.glassEffect` so the older iOS-17 fallback path
/// and the Reduce Transparency branch stay in one place.
struct LiquidGlass<S: InsettableShape>: ViewModifier {
    let shape: S
    let tint: Color?
    let interactive: Bool

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .background(shape.fill(AppColors.cardSurface))
                .overlay(shape.strokeBorder(AppColors.divider, lineWidth: 0.5))
        } else if #available(iOS 26.0, *) {
            content.glassEffect(glass, in: shape)
        } else {
            content
                .background(
                    ZStack {
                        shape.fill(.ultraThinMaterial)
                        if let tint { shape.fill(tint.opacity(0.35)) }
                    }
                )
                .overlay(shape.strokeBorder(AppColors.divider.opacity(0.5), lineWidth: 0.5))
        }
    }

    @available(iOS 26.0, *)
    private var glass: Glass {
        var g: Glass = .regular
        if let tint { g = g.tint(tint) }
        if interactive { g = g.interactive(true) }
        return g
    }
}

extension View {
    /// Apply Liquid Glass (iOS 26+) with a graceful fallback on older OSes.
    /// `interactive` should be true for tap targets so the system can do its
    /// own press / focus styling.
    func liquidGlass<S: InsettableShape>(in shape: S, tint: Color? = nil, interactive: Bool = false) -> some View {
        modifier(LiquidGlass(shape: shape, tint: tint, interactive: interactive))
    }
}

/// Wrap several Liquid-Glass children so the system can sample and morph
/// them as a single glass surface (Apple's recommendation when more than
/// one glass element sits side-by-side). Passes content through unchanged
/// on iOS versions that pre-date the API.
struct GlassGroup<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer { content() }
        } else {
            content()
        }
    }
}
