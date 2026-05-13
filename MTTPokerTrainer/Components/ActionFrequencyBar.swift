import SwiftUI

/// Horizontal bar summarizing a chart's action-frequency breakdown:
/// what % of combos fold, call, raise, 3-bet, jam, mix. Segments only
/// render when non-zero.
struct ActionFrequencyBar: View {
    let frequencies: [RangeAction: Double]

    private let ordered: [RangeAction] = [.fold, .call, .raise, .threeBet, .jam, .mixed]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            GeometryReader { geo in
                HStack(spacing: 1) {
                    ForEach(ordered, id: \.self) { action in
                        let pct = frequencies[action] ?? 0
                        if pct > 0 {
                            Rectangle()
                                .fill(action.tint)
                                .frame(width: max(2, geo.size.width * pct))
                        }
                    }
                }
                .frame(height: 10)
                .clipShape(Capsule())
            }
            .frame(height: 10)

            HStack(spacing: AppSpacing.sm) {
                ForEach(ordered, id: \.self) { action in
                    let pct = frequencies[action] ?? 0
                    if pct > 0.005 {
                        HStack(spacing: 4) {
                            Circle().fill(action.tint).frame(width: 8, height: 8)
                            Text("\(action.displayName) \(Int((pct * 100).rounded()))%")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
            }
        }
    }
}
