import SwiftUI

/// Miniature 13×13 representation of a chart's action mosaic — text-free,
/// suitable for use inside lists and matrix cells. If `chart` is nil renders
/// an empty muted tile (signals "no chart bundled for this spot").
struct RangeThumbnailView: View {
    let chart: RangeChart?
    var cornerRadius: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            let cell = geo.size.width / 13
            ZStack {
                if let chart {
                    Canvas { ctx, _ in
                        for (i, combo) in HandCombo.allInMatrixOrder.enumerated() {
                            let row = i / 13
                            let col = i % 13
                            let rect = CGRect(x: CGFloat(col) * cell, y: CGFloat(row) * cell, width: cell, height: cell)
                            let action = chart.action(for: combo)
                            let color = thumbnailColor(for: action)
                            ctx.fill(Path(rect), with: .color(color))
                        }
                    }
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(AppColors.cardSurface.opacity(0.4))
                        .overlay(
                            Image(systemName: "rectangle.dashed")
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.textSecondary)
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppColors.divider.opacity(0.5), lineWidth: 0.5)
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func thumbnailColor(for action: RangeAction) -> Color {
        // Use slightly desaturated tints so the thumbnail reads as a glanceable
        // shape, not a competing element next to detailed UI.
        switch action {
        case .fold:     return AppColors.actionFold.opacity(0.35)
        case .call:     return action.tint.opacity(0.85)
        case .raise:    return action.tint.opacity(0.9)
        case .threeBet: return action.tint.opacity(0.9)
        case .jam:      return action.tint.opacity(0.9)
        case .mixed:    return action.tint.opacity(0.85)
        }
    }
}
