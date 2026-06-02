import SwiftUI

/// The Cutoff app mark — a liquid-glass poker-chip mascot — drawn natively with
/// Apple's glass engine (iOS 26 `glassEffect`, `.ultraThinMaterial` fallback on
/// iOS 18 via `liquidGlass`). Rendered on a self-contained green-black field so
/// it can be exported as a full-bleed 1024² app icon (see `IconExportView`).
///
/// Not part of the shipping UI — it exists purely to generate the icon.
struct IconMarkView: View {
    /// Canvas side in points; every metric scales from a 1024 design grid.
    var size: CGFloat = 1024

    /// design-grid value → points
    private func u(_ v: CGFloat) -> CGFloat { v / 1024 * size }

    private let chip: CGFloat = 596          // chip diameter on the 1024 grid
    private let notchCount = 6

    var body: some View {
        ZStack {
            field
            glow
            chipStack
        }
        .frame(width: size, height: size)
        .clipped()
    }

    // MARK: Background field

    private var field: some View {
        RadialGradient(
            colors: [AppColors.cardSurfaceGreen, AppColors.backgroundGreenBlack, AppColors.backgroundDeep],
            center: UnitPoint(x: 0.5, y: -0.08),
            startRadius: 0,
            endRadius: u(880)
        )
    }

    private var glow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [AppColors.primaryMint.opacity(0.38),
                             AppColors.primaryEmerald.opacity(0.16),
                             AppColors.accentGreen.opacity(0)],
                    center: .center, startRadius: 0, endRadius: u(360)
                )
            )
            .frame(width: u(760), height: u(760))
            .blur(radius: u(20))
            .offset(y: u(-6))
    }

    // MARK: Chip

    private var chipStack: some View {
        ZStack {
            // Solid colored body — the glass on top samples & refracts this.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppColors.primaryMint, AppColors.primaryEmerald, AppColors.accentGreen, AppColors.accentGreen],
                        center: UnitPoint(x: 0.34, y: 0.26),
                        startRadius: 0, endRadius: u(chip * 0.72)
                    )
                )
                .frame(width: u(chip), height: u(chip))
                .overlay(bottomShade)
                .overlay(rim)

            // Apple Liquid Glass sheen sitting over the colored body.
            Color.clear
                .frame(width: u(chip * 0.995), height: u(chip * 0.995))
                .liquidGlass(in: Circle(), tint: AppColors.primaryMint)

            notches
            innerRing
            gloss
            eyes
        }
        .frame(width: u(chip), height: u(chip))
        .shadow(color: .black.opacity(0.55), radius: u(34), x: 0, y: u(30))
    }

    /// Volume: darken the lower third from inside.
    private var bottomShade: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.clear, .clear, AppColors.accentGreen.opacity(0.35), AppColors.backgroundDeep.opacity(0.72)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .blendMode(.multiply)
    }

    /// Bright top edge + crisp glass rim.
    private var rim: some View {
        Circle()
            .strokeBorder(
                AngularGradient(
                    colors: [.white.opacity(0.85), .white.opacity(0.15),
                             AppColors.backgroundDeep.opacity(0.35), .white.opacity(0.15),
                             .white.opacity(0.85)],
                    center: .center, angle: .degrees(-90)
                ),
                lineWidth: u(7)
            )
    }

    /// Classic poker-chip edge notches around the rim.
    private var notches: some View {
        ZStack {
            ForEach(0..<notchCount, id: \.self) { i in
                Capsule(style: .continuous)
                    .fill(.white.opacity(0.9))
                    .frame(width: u(46), height: u(86))
                    .overlay(Capsule().stroke(AppColors.backgroundDeep.opacity(0.25), lineWidth: u(2)))
                    .offset(y: -u(chip / 2 - 30))
                    .rotationEffect(.degrees(Double(i) / Double(notchCount) * 360))
            }
        }
        .frame(width: u(chip), height: u(chip))
        .shadow(color: AppColors.backgroundDeep.opacity(0.35), radius: u(3), y: u(2))
    }

    /// Recessed inner face plate.
    private var innerRing: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [AppColors.primaryMint.opacity(0.5), AppColors.primaryEmerald.opacity(0.25), .clear],
                    center: UnitPoint(x: 0.36, y: 0.28),
                    startRadius: 0, endRadius: u(chip * 0.34)
                )
            )
            .frame(width: u(chip * 0.62), height: u(chip * 0.62))
            .overlay(
                Circle().strokeBorder(.white.opacity(0.35), lineWidth: u(4))
            )
            .overlay(
                Circle().strokeBorder(AppColors.backgroundDeep.opacity(0.3), lineWidth: u(2))
                    .blur(radius: u(1))
            )
    }

    /// Glossy top specular highlight.
    private var gloss: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [.white.opacity(0.72), .white.opacity(0.18), .clear],
                    center: UnitPoint(x: 0.5, y: 0.32), startRadius: 0, endRadius: u(180)
                )
            )
            .frame(width: u(chip * 0.6), height: u(chip * 0.34))
            .offset(x: -u(chip * 0.05), y: -u(chip * 0.24))
            .blur(radius: u(4))
    }

    // MARK: Mascot eyes

    private var eyes: some View {
        HStack(spacing: u(70)) {
            eye
            eye
        }
        .offset(y: u(6))
    }

    private var eye: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [AppColors.cardSurfaceGreen, AppColors.backgroundGreenBlack, AppColors.backgroundDeep],
                    center: UnitPoint(x: 0.4, y: 0.3), startRadius: 0, endRadius: u(70)
                )
            )
            .frame(width: u(96), height: u(126))
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(.white.opacity(0.95))
                    .frame(width: u(32), height: u(32))
                    .blur(radius: u(1))
                    .offset(x: u(20), y: u(18))
            }
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(AppColors.primaryMint.opacity(0.9))
                    .frame(width: u(14), height: u(14))
                    .offset(x: -u(16), y: -u(22))
            }
            .shadow(color: AppColors.backgroundDeep.opacity(0.5), radius: u(3), y: u(2))
    }
}

#if DEBUG
/// Full-bleed host used to capture the mark as an icon from the simulator.
/// Launch the app with `--icon-export` to show it. The mark fills the screen
/// width as a centered square on black, so a center-square crop of the
/// screenshot yields the icon.
struct IconExportView: View {
    var body: some View {
        GeometryReader { geo in
            let side = geo.size.width
            ZStack {
                Color.black
                IconMarkView(size: side)
                    .frame(width: side, height: side)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
    }
}
#endif

#Preview("Icon mark") {
    IconMarkView(size: 360)
        .frame(width: 360, height: 360)
}
