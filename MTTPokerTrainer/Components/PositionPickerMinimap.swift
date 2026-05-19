import SwiftUI

/// Interactive oval table for picking hero position.
///
/// Seats are tappable; the selected seat is mint-filled, unavailable seats
/// are muted, and a dealer button sits beside BTN. Reuses the same oval
/// geometry as `TableMinimapView` so the two screens read consistently.
struct PositionPickerMinimap: View {
    let positions: [TablePosition]
    let selected: TablePosition?
    let enabled: Set<TablePosition>
    let onSelect: (TablePosition) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let seatSize: CGFloat = 38
    private let buttonSize: CGFloat = 11
    private let height: CGFloat = 168

    var body: some View {
        GeometryReader { geo in
            let frame = geo.size
            let inset: CGFloat = AppSpacing.md
            let center = CGPoint(x: frame.width / 2, y: frame.height / 2)
            let radiusX = max(0, frame.width / 2 - inset - seatSize / 2)
            let radiusY = max(0, frame.height / 2 - inset - seatSize / 2)

            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.hero, style: .continuous)
                    .fill(AppColors.cardSurfaceGreen)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.hero, style: .continuous)
                            .strokeBorder(AppColors.divider.opacity(0.5), lineWidth: 1)
                    )

                ForEach(positions) { pos in
                    seatGroup(for: pos, center: center, radiusX: radiusX, radiusY: radiusY)
                }
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Position picker")
    }

    @ViewBuilder
    private func seatGroup(for pos: TablePosition, center: CGPoint, radiusX: CGFloat, radiusY: CGFloat) -> some View {
        let idx = positions.firstIndex(of: pos) ?? 0
        let angle = TableMinimapView.seatAngle(forIndex: idx, total: positions.count)
        let point = TableMinimapView.point(at: angle, center: center, radiusX: radiusX, radiusY: radiusY)

        seatButton(for: pos)
            .position(point)
            .animation(AppMotion.respecting(reduceMotion, AppMotion.spring), value: selected)

        if pos == .btn {
            dealerButton(at: point)
        }
    }

    @ViewBuilder
    private func seatButton(for pos: TablePosition) -> some View {
        let isSelected = pos == selected
        let isEnabled = enabled.contains(pos)

        Button { if isEnabled { onSelect(pos) } } label: {
            ZStack {
                Circle()
                    .fill(fill(isSelected: isSelected, isEnabled: isEnabled))
                    .frame(width: seatSize * (isSelected ? 1.12 : 1.0),
                           height: seatSize * (isSelected ? 1.12 : 1.0))
                    .overlay(
                        Circle().strokeBorder(
                            isSelected ? AppColors.primaryEmerald : AppColors.divider.opacity(0.6),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                    )
                Text(pos.displayName)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? AppColors.backgroundDeep : AppColors.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(.horizontal, 2)
            }
            .opacity(isEnabled ? 1 : 0.35)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel("Position \(pos.displayName)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityValue(isEnabled ? (isSelected ? "Selected" : "Not selected") : "Unavailable")
    }

    private func fill(isSelected: Bool, isEnabled: Bool) -> Color {
        if isSelected { return AppColors.primaryMint }
        if !isEnabled { return AppColors.cardSurface.opacity(0.6) }
        return AppColors.cardSurface
    }

    private func dealerButton(at point: CGPoint) -> some View {
        Circle()
            .fill(AppColors.accentPeach)
            .frame(width: buttonSize, height: buttonSize)
            .overlay(
                Circle().strokeBorder(AppColors.backgroundDeep, lineWidth: 0.5)
            )
            .position(x: point.x + seatSize * 0.65, y: point.y + seatSize * 0.55)
            .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        AppBackground()
        PositionPickerMinimap(
            positions: TablePosition.nineMaxOrder,
            selected: .bb,
            enabled: Set(TablePosition.nineMaxOrder).subtracting([.utg1]),
            onSelect: { _ in }
        )
        .padding(.horizontal, AppSpacing.pageHorizontal)
    }
}
