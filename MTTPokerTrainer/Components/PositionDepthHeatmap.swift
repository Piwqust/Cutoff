import SwiftUI

/// Compact position × depth-bucket accuracy grid. Tiles tint from coral (low)
/// to mint (high) and grey out when the sample is too small. Tapping a cell
/// fires `onSelect` so the parent view can route into a filtered drill.
struct PositionDepthHeatmap: View {
    let cells: [ReviewAnalyzer.HeatCell]
    var onSelect: (ReviewAnalyzer.HeatCell) -> Void = { _ in }

    private let depths: [StackDepthBucket] = [.bb10, .bb15, .bb20, .bb30, .bb50, .bb100]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            // Column header
            HStack(spacing: 2) {
                Text("")
                    .frame(width: 36, alignment: .leading)
                ForEach(depths, id: \.self) { d in
                    Text(d.label.replacingOccurrences(of: " BB", with: ""))
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            ForEach(TablePosition.nineMaxOrder, id: \.self) { pos in
                HStack(spacing: 2) {
                    Text(pos.displayName)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(width: 36, alignment: .leading)
                    ForEach(depths, id: \.self) { d in
                        cellView(for: pos, depth: d)
                    }
                }
            }

            legend
                .padding(.top, AppSpacing.xs)
        }
    }

    @ViewBuilder
    private func cellView(for pos: TablePosition, depth: StackDepthBucket) -> some View {
        if let cell = cells.first(where: { $0.position == pos && $0.bucket == depth }) {
            Button { onSelect(cell) } label: {
                cellFace(cell: cell)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(pos.displayName) at \(depth.label): \(cell.accuracy)% over \(cell.total) hands.")
        } else {
            RoundedRectangle(cornerRadius: 4)
                .fill(AppColors.divider.opacity(0.35))
                .frame(height: 26)
        }
    }

    private func cellFace(cell: ReviewAnalyzer.HeatCell) -> some View {
        let tint = tint(for: cell)
        return ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(tint)
            Text("\(cell.accuracy)")
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(textTint(for: cell))
        }
        .frame(height: 26)
    }

    private func tint(for cell: ReviewAnalyzer.HeatCell) -> Color {
        if cell.total < 3 {
            return AppColors.divider.opacity(0.55)
        }
        switch cell.accuracy {
        case ..<45:  return AppColors.accentCoral.opacity(0.85)
        case ..<60:  return AppColors.accentPeach.opacity(0.85)
        case ..<75:  return AppColors.accentLime.opacity(0.85)
        case ..<90:  return AppColors.primaryMint.opacity(0.85)
        default:     return AppColors.primaryEmerald.opacity(0.95)
        }
    }

    private func textTint(for cell: ReviewAnalyzer.HeatCell) -> Color {
        cell.total < 3 ? AppColors.textSecondary : AppColors.backgroundDeep
    }

    private var legend: some View {
        HStack(spacing: AppSpacing.xs) {
            Text("Cooler = miss")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            HStack(spacing: 2) {
                ForEach([AppColors.accentCoral, AppColors.accentPeach, AppColors.accentLime, AppColors.primaryMint, AppColors.primaryEmerald], id: \.self) { c in
                    RoundedRectangle(cornerRadius: 2).fill(c).frame(width: 14, height: 6)
                }
            }
            Text("nail")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}

#Preview {
    ZStack {
        AppBackground()
        let mock: [ReviewAnalyzer.HeatCell] = [
            .init(id: "1", position: .utg, bucket: .bb100, total: 12, accuracy: 42),
            .init(id: "2", position: .btn, bucket: .bb30, total: 18, accuracy: 78),
            .init(id: "3", position: .bb, bucket: .bb20, total: 5, accuracy: 60),
            .init(id: "4", position: .sb, bucket: .bb15, total: 8, accuracy: 91),
        ]
        PositionDepthHeatmap(cells: mock)
            .padding(AppSpacing.lg)
    }
}
