import SwiftUI

/// Per-combo frequency distribution as a stack of horizontal bars — one row
/// per RangeAction with non-zero frequency. The bar the user actually chose
/// gets a ring + "YOU" tag; the bar with the highest frequency gets a "CHART"
/// tag. Used inside `FeedbackSheet` and `MistakeDetailSheet`.
struct FrequencyDistributionView: View {
    let frequencies: [RangeAction: Double]
    let userAction: RangeAction
    var compact: Bool = false

    private let ordered: [RangeAction] = [.fold, .call, .raise, .threeBet, .jam]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            ForEach(ordered, id: \.self) { action in
                let pct = frequencies[action] ?? 0
                if pct > 0 || action == userAction {
                    row(action: action, fraction: pct)
                }
            }
        }
    }

    private func row(action: RangeAction, fraction: Double) -> some View {
        let isUser = action == userAction
        let isChart = action == dominant
        let trackHeight: CGFloat = compact ? 10 : 14

        return HStack(spacing: AppSpacing.xs) {
            HStack(spacing: 4) {
                Image(systemName: action.systemImage)
                    .font(AppTypography.caption.weight(.bold))
                Text(action.displayName)
                    .font(AppTypography.caption.weight(.semibold))
            }
            .foregroundStyle(action.tint)
            .frame(width: 70, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.divider.opacity(0.6))
                        .frame(height: trackHeight)
                    Capsule()
                        .fill(action.tint)
                        .frame(width: max(2, geo.size.width * fraction), height: trackHeight)
                    if isUser {
                        Capsule()
                            .stroke(AppColors.textPrimary.opacity(0.85), lineWidth: 1.5)
                            .frame(height: trackHeight)
                    }
                }
            }
            .frame(height: trackHeight)

            Text("\(Int((fraction * 100).rounded()))%")
                .font(AppTypography.numericSmall)
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: 38, alignment: .trailing)

            tagPair(isUser: isUser, isChart: isChart)
                .frame(width: 60, alignment: .leading)
        }
    }

    private func tagPair(isUser: Bool, isChart: Bool) -> some View {
        HStack(spacing: 2) {
            if isUser {
                tag("YOU", color: AppColors.textPrimary)
            }
            if isChart {
                tag("CHART", color: AppColors.primaryMint)
            }
        }
    }

    private func tag(_ text: String, color: Color) -> some View {
        Text(text)
            // Fixed size: badges sit in a 60pt-wide column; growing them
            // would overflow into adjacent columns at large Dynamic Type.
            .font(.system(size: 8, weight: .heavy, design: .rounded))
            .tracking(0.8)
            .foregroundStyle(color)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(Capsule().fill(color.opacity(0.18)))
    }

    private var dominant: RangeAction {
        frequencies.max(by: { $0.value < $1.value })?.key ?? .fold
    }
}

#Preview {
    ZStack {
        AppBackground()
        FrequencyDistributionView(
            frequencies: [.fold: 0.2, .raise: 0.55, .threeBet: 0.25],
            userAction: .fold
        )
        .padding(AppSpacing.lg)
    }
}
