import SwiftUI

/// Compact inline table mini-map. Designed to sit beside the position label
/// in the trainer's spot header — small, readable, and never wider than
/// roughly 64×40 pt.
struct TableMiniMap: View {
    let heroPosition: TablePosition

    /// (x, y) fractional coordinates on a unit square. Seat placement matches
    /// a real 9-max layout (BTN south; SB/BB to BTN's left; UTG → CO
    /// continuing clockwise back toward BTN).
    private static let seatLayout: [(TablePosition, CGPoint)] = [
        (.btn,  CGPoint(x: 0.50, y: 0.86)),
        (.sb,   CGPoint(x: 0.22, y: 0.76)),
        (.bb,   CGPoint(x: 0.08, y: 0.50)),
        (.utg,  CGPoint(x: 0.22, y: 0.24)),
        (.utg1, CGPoint(x: 0.50, y: 0.14)),
        (.lj,   CGPoint(x: 0.78, y: 0.24)),
        (.hj,   CGPoint(x: 0.92, y: 0.50)),
        (.co,   CGPoint(x: 0.78, y: 0.76)),
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                felt
                ForEach(Self.seatLayout, id: \.0) { (pos, frac) in
                    seat(for: pos)
                        .position(x: frac.x * w, y: frac.y * h)
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Seated at \(heroPosition.displayName)")
    }

    private var felt: some View {
        Ellipse()
            .fill(AppColors.primaryEmerald.opacity(0.45))
            .overlay(
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.16), .clear],
                            center: UnitPoint(x: 0.5, y: 0.4),
                            startRadius: 1,
                            endRadius: 30
                        )
                    )
            )
            .overlay(
                Ellipse()
                    .strokeBorder(AppColors.primaryMint.opacity(0.35), lineWidth: 0.5)
            )
    }

    @ViewBuilder
    private func seat(for pos: TablePosition) -> some View {
        let isHero = pos == heroPosition
        if isHero {
            ZStack {
                Circle()
                    .fill(AppColors.primaryMint.opacity(0.30))
                    .frame(width: 12, height: 12)
                    .blur(radius: 1)
                Circle()
                    .fill(AppColors.primaryMint)
                    .frame(width: 7, height: 7)
                    .shadow(color: AppColors.primaryMint.opacity(0.7), radius: 3)
            }
        } else {
            Circle()
                .fill(AppColors.textPrimary.opacity(0.28))
                .frame(width: 4, height: 4)
        }
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: AppSpacing.sm) {
            ForEach(TablePosition.nineMaxOrder) { p in
                HStack {
                    Text(p.displayName).font(.title2.bold()).foregroundStyle(.white)
                    TableMiniMap(heroPosition: p)
                        .frame(width: 64, height: 40)
                    Spacer()
                }
            }
        }
        .padding()
    }
}
