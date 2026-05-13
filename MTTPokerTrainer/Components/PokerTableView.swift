import SwiftUI

/// Renders a single training spot as a top-down poker table diagram:
/// seats arranged on an oval, posted blinds + chips, dealer button, pot in
/// the centre, and an orange ring on the hero. Pure presentation; takes a
/// `PokerTableSnapshot` so the data shape stays testable.
struct PokerTableView: View {
    enum Size {
        case hero      // full-bleed inside a trainer screen
        case compact   // small inline summary (range detail sheet, leak card)
    }

    let snapshot: PokerTableSnapshot
    var size: Size = .hero

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        // GeometryReader inside a flexible VStack can collapse to 0×0; give it
        // an explicit height and let it fill the available width so seats lay
        // out against a known canvas.
        let height: CGFloat = (size == .hero) ? 220 : 90
        return GeometryReader { geo in
            ZStack {
                tableOval(in: geo.size)
                potLabel
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                ForEach(orderedSeats) { seat in
                    let point = seatPoint(for: seat, in: geo.size)
                    let diameter = seat.isHero ? metrics.heroDiameter : metrics.seatDiameter
                    seatCircle(seat: seat, diameter: diameter)
                        .position(point)
                    if let blind = seat.postedBlindBB {
                        chip(value: blind)
                            .position(blindChipPoint(seatPoint: point, canvas: geo.size, diameter: diameter))
                    }
                    if seat.hasButton {
                        dealerButton
                            .position(buttonPoint(seatPoint: point, canvas: geo.size, diameter: diameter))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Layout

    private struct Metrics {
        let aspect: CGFloat
        let seatDiameter: CGFloat
        let heroDiameter: CGFloat
        let positionFont: Font
        let stackFont: Font
        let potFont: Font
        let chipDiameter: CGFloat
        let chipFont: Font
        let ovalInset: CGFloat
    }

    private var metrics: Metrics {
        switch size {
        case .hero:
            return Metrics(
                aspect: 1.55,
                seatDiameter: 52,
                heroDiameter: 60,
                positionFont: .system(size: 11, weight: .semibold, design: .rounded),
                stackFont:    .system(size: 13, weight: .bold,     design: .rounded).monospacedDigit(),
                potFont:      .system(size: 18, weight: .bold,     design: .rounded).monospacedDigit(),
                chipDiameter: 22,
                chipFont:     .system(size: 10, weight: .bold,     design: .rounded).monospacedDigit(),
                ovalInset: 36
            )
        case .compact:
            return Metrics(
                aspect: 1.55,
                seatDiameter: 28,
                heroDiameter: 32,
                positionFont: .system(size: 8,  weight: .semibold, design: .rounded),
                stackFont:    .system(size: 9,  weight: .bold,     design: .rounded).monospacedDigit(),
                potFont:      .system(size: 12, weight: .bold,     design: .rounded).monospacedDigit(),
                chipDiameter: 12,
                chipFont:     .system(size: 6,  weight: .bold,     design: .rounded).monospacedDigit(),
                ovalInset: 18
            )
        }
    }

    /// Seats in clockwise display order starting from the hero (at the bottom).
    private var orderedSeats: [PokerTableSeat] {
        let order = TablePosition.nineMaxOrder
        guard let heroIdx = order.firstIndex(of: snapshot.heroPosition) else { return snapshot.seats }
        // Action moves clockwise in poker: hero, then the player to hero's
        // left (next in `order`), wrapping back round to the player on hero's
        // right just before hero.
        let rotated = Array(order[heroIdx...] + order[..<heroIdx])
        return rotated.compactMap { pos in snapshot.seats.first(where: { $0.position == pos }) }
    }

    private func tableOval(in canvas: CGSize) -> some View {
        let rect = CGRect(
            x: metrics.ovalInset,
            y: metrics.ovalInset,
            width:  canvas.width  - metrics.ovalInset * 2,
            height: canvas.height - metrics.ovalInset * 2
        )
        return Ellipse()
            .strokeBorder(AppColors.divider.opacity(0.55), lineWidth: 0.8)
            .frame(width: rect.width, height: rect.height)
            .position(x: canvas.width / 2, y: canvas.height / 2)
    }

    private var potLabel: some View {
        Text(formatBB(snapshot.potBB))
            .font(metrics.potFont)
            .foregroundStyle(AppColors.textPrimary)
            .accessibilityHidden(true)
    }

    private func seatCircle(seat: PokerTableSeat, diameter: CGFloat) -> some View {
        let ringColor: Color = seat.isHero ? AppColors.accentPeach : .clear
        let fillOpacity: Double = seat.isFolded ? 0.35 : 1.0
        return ZStack {
            Circle()
                .fill(AppColors.cardSurface)
                .overlay(Circle().strokeBorder(AppColors.divider.opacity(0.6), lineWidth: 0.5))
            Circle()
                .strokeBorder(ringColor, lineWidth: seat.isHero ? 2 : 0)
            VStack(spacing: 1) {
                Text(seat.position.displayName)
                    .font(metrics.positionFont)
                    .foregroundStyle(AppColors.textSecondary)
                Text(formatStack(seat.stackBB))
                    .font(metrics.stackFont)
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .frame(width: diameter, height: diameter)
        .opacity(fillOpacity)
    }

    private func chip(value: Double) -> some View {
        ZStack {
            Circle()
                .fill(AppColors.primaryEmerald)
                .overlay(Circle().strokeBorder(AppColors.primaryMint.opacity(0.8), lineWidth: 1))
            Text(formatStack(value))
                .font(metrics.chipFont)
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(width: metrics.chipDiameter, height: metrics.chipDiameter)
        .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 1)
    }

    private var dealerButton: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(AppColors.backgroundSurface)
            .overlay(
                Text("D")
                    .font(.system(size: max(8, metrics.chipDiameter * 0.55), weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            )
            .frame(width: metrics.chipDiameter, height: metrics.chipDiameter)
    }

    // MARK: - Geometry helpers

    /// Hero at the bottom (90°), remaining seats stepped clockwise around the oval.
    private func seatPoint(for seat: PokerTableSeat, in canvas: CGSize) -> CGPoint {
        guard let idx = orderedSeats.firstIndex(of: seat) else {
            return CGPoint(x: canvas.width / 2, y: canvas.height / 2)
        }
        let n = orderedSeats.count
        let delta = 360.0 / Double(n)
        // Screen-space angle: +X right, +Y down. 90° = bottom. Going clockwise
        // visually means DECREASING the angle, so subtract delta * i.
        let angleDeg = 90.0 - Double(idx) * delta
        let theta = angleDeg * .pi / 180

        let cx = canvas.width / 2
        let cy = canvas.height / 2
        let rx = (canvas.width  - metrics.ovalInset * 2) / 2
        let ry = (canvas.height - metrics.ovalInset * 2) / 2
        return CGPoint(
            x: cx + rx * cos(theta),
            y: cy + ry * sin(theta)
        )
    }

    /// Position a chip just inboard of the seat (toward table centre).
    private func blindChipPoint(seatPoint: CGPoint, canvas: CGSize, diameter: CGFloat) -> CGPoint {
        let cx = canvas.width / 2
        let cy = canvas.height / 2
        let dx = cx - seatPoint.x
        let dy = cy - seatPoint.y
        let len = max(0.0001, sqrt(dx * dx + dy * dy))
        let inset = diameter * 0.55 + metrics.chipDiameter * 0.4
        return CGPoint(
            x: seatPoint.x + dx / len * inset,
            y: seatPoint.y + dy / len * inset
        )
    }

    /// Dealer button sits inboard like a blind chip but slightly offset
    /// circumferentially so it doesn't overlap the chip when BTN is next to SB.
    private func buttonPoint(seatPoint: CGPoint, canvas: CGSize, diameter: CGFloat) -> CGPoint {
        let p = blindChipPoint(seatPoint: seatPoint, canvas: canvas, diameter: diameter)
        // Nudge slightly toward the hero side (downward in our convention).
        return CGPoint(x: p.x, y: p.y + metrics.chipDiameter * 0.7)
    }

    // MARK: - Formatting

    private func formatStack(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }

    private func formatBB(_ value: Double) -> String {
        let stripped = formatStack(value)
        return "\(stripped)bb"
    }

    private var accessibilityDescription: String {
        let hero = snapshot.seats.first(where: { $0.isHero })
        let heroPart = hero.map { "Hero at \($0.position.displayName) with \(formatStack($0.stackBB)) BB" } ?? ""
        return "\(heroPart). Pot \(formatBB(snapshot.potBB))."
    }
}

#Preview {
    let spot = TrainingSpot(
        position: .utg,
        stackDepthBB: 40,
        facingAction: .unopened,
        anteType: .bigBlindAnte,
        tableSize: 9
    )
    return ZStack {
        AppBackground()
        VStack(spacing: AppSpacing.xl) {
            PokerTableView(snapshot: .from(spot: spot))
                .padding(.horizontal, AppSpacing.lg)
            PokerTableView(snapshot: .from(spot: TrainingSpot(
                position: .bb, stackDepthBB: 25, facingAction: .vsOpen,
                anteType: .bigBlindAnte, tableSize: 9
            )), size: .compact)
                .frame(width: 200)
        }
    }
}
