import SwiftUI

/// Compact oval table widget used in the trainer header.
///
/// Renders 8 seat dots around an oval, with the hero seat accented, opponents
/// who have already acted muted, and a dealer button placed beside the BTN.
/// Tokens-only — no images, no UIKit, never hardcodes a color or radius.
struct TableMinimapView: View {
    let config: TournamentConfig
    let heroPosition: TablePosition
    let actedPositions: [TablePosition]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let seatSize: CGFloat = 22
    private let buttonSize: CGFloat = 10
    private let height: CGFloat = 116

    var body: some View {
        GeometryReader { geo in
            let frame = geo.size
            let inset: CGFloat = AppSpacing.md
            let center = CGPoint(x: frame.width / 2, y: frame.height / 2)
            let radiusX = max(0, frame.width / 2 - inset - seatSize / 2)
            let radiusY = max(0, frame.height / 2 - inset - seatSize / 2)
            let positions = TablePosition.nineMaxOrder

            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.hero, style: .continuous)
                    .fill(AppColors.cardSurfaceGreen)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.hero, style: .continuous)
                            .strokeBorder(AppColors.divider.opacity(0.5), lineWidth: 1)
                    )

                ForEach(positions) { pos in
                    seatGroup(for: pos, center: center, radiusX: radiusX, radiusY: radiusY, positions: positions)
                }
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - Per-seat content

    @ViewBuilder
    private func seatGroup(for pos: TablePosition, center: CGPoint, radiusX: CGFloat, radiusY: CGFloat, positions: [TablePosition]) -> some View {
        let idx = positions.firstIndex(of: pos) ?? 0
        let angle = Self.seatAngle(forIndex: idx, total: positions.count)
        let point = Self.point(at: angle, center: center, radiusX: radiusX, radiusY: radiusY)

        seatDot(for: pos)
            .position(point)
            .animation(AppMotion.respecting(reduceMotion, AppMotion.spring), value: actedPositions)
            .animation(AppMotion.respecting(reduceMotion, AppMotion.spring), value: heroPosition)

        if pos == .btn {
            dealerButton(at: point)
        }
    }

    @ViewBuilder
    private func seatDot(for pos: TablePosition) -> some View {
        let isHero = pos == heroPosition
        let hasActed = actedPositions.contains(pos)
        let baseColor: Color = {
            if isHero { return AppColors.primaryMint }
            if hasActed { return AppColors.textSecondary.opacity(0.55) }
            return AppColors.cardSurface
        }()

        ZStack {
            Circle()
                .fill(baseColor)
                .frame(width: seatSize * (isHero ? 1.2 : 1.0), height: seatSize * (isHero ? 1.2 : 1.0))
                .overlay(
                    Circle().strokeBorder(isHero ? AppColors.primaryEmerald : AppColors.divider.opacity(0.6), lineWidth: 1)
                )
            Text(pos.displayName)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(isHero ? AppColors.backgroundDeep : AppColors.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .padding(.horizontal, 2)
        }
    }

    private func dealerButton(at point: CGPoint) -> some View {
        Circle()
            .fill(AppColors.accentPeach)
            .frame(width: buttonSize, height: buttonSize)
            .overlay(
                Circle().strokeBorder(AppColors.backgroundDeep, lineWidth: 0.5)
            )
            .position(x: point.x + seatSize * 0.7, y: point.y + seatSize * 0.55)
    }

    // MARK: - Geometry helpers (pure / testable)

    static func seatAngle(forIndex index: Int, total: Int) -> Double {
        // Start at top (-π/2) and step clockwise around the oval.
        let step = (2 * Double.pi) / Double(total)
        return -Double.pi / 2 + step * Double(index)
    }

    static func point(at angle: Double, center: CGPoint, radiusX: CGFloat, radiusY: CGFloat) -> CGPoint {
        CGPoint(x: center.x + radiusX * CGFloat(cos(angle)),
                y: center.y + radiusY * CGFloat(sin(angle)))
    }

    private var accessibilitySummary: String {
        let acted = actedPositions.map(\.displayName).joined(separator: ", ")
        return "Table minimap. Hero seated at \(heroPosition.displayName). Acted: \(acted.isEmpty ? "none" : acted). Dealer button at BTN."
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: AppSpacing.md) {
            TableMinimapView(config: .default, heroPosition: .co, actedPositions: [.utg, .hj])
                .padding(.horizontal, AppSpacing.pageHorizontal)
            TableMinimapView(config: .default, heroPosition: .bb, actedPositions: [.btn])
                .padding(.horizontal, AppSpacing.pageHorizontal)
        }
    }
}
