import SwiftUI

/// "Hands like this also play this way" — shows up to 6 other combos that
/// share both `HandClass` and dominant chart action with the focus combo.
struct SiblingHandsRow: View {
    let chart: RangeChart
    let focusCombo: HandCombo
    let expectedAction: RangeAction
    var limit: Int = 6

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Plays the same way")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    if siblings.isEmpty {
                        Text("No close peers in this chart.")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    } else {
                        ForEach(siblings, id: \.self) { combo in
                            chip(for: combo)
                        }
                    }
                }
            }
        }
    }

    private func chip(for combo: HandCombo) -> some View {
        HStack(spacing: 4) {
            Text(combo.notation)
                .font(AppTypography.caption.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
            Circle()
                .fill(expectedAction.tint)
                .frame(width: 6, height: 6)
        }
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, 4)
        .background(Capsule().fill(AppColors.cardSurfaceGreen.opacity(0.45)))
        .overlay(
            Capsule().stroke(AppColors.divider.opacity(0.7), lineWidth: 0.5)
        )
    }

    private var siblings: [HandCombo] {
        let focusClass = HandClass.of(focusCombo)
        let candidates = HandCombo.allInMatrixOrder
            .filter { $0 != focusCombo }
            .filter { HandClass.of($0) == focusClass }
            .filter { chart.action(for: $0) == expectedAction }

        // Prefer near-ranked siblings — sort by rank distance to the focus combo.
        return candidates
            .sorted { lhs, rhs in
                distance(lhs, focusCombo) < distance(rhs, focusCombo)
            }
            .prefix(limit)
            .map { $0 }
    }

    private func distance(_ a: HandCombo, _ b: HandCombo) -> Int {
        abs(a.highRank.sortValue - b.highRank.sortValue) +
        abs(a.lowRank.sortValue - b.lowRank.sortValue)
    }
}
