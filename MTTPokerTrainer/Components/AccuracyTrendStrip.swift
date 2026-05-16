import SwiftUI

/// Two-week accuracy sparkline + last-7 / last-30 chips + delta arrow.
/// Renders flat; the caller decides whether to wrap in a card.
struct AccuracyTrendStrip: View {
    let trend: ReviewAnalyzer.Trend

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            accuracyColumn(title: "Last 7d", value: trend.last7Accuracy)
            accuracyColumn(title: "Last 30d", value: trend.last30Accuracy)
            Spacer(minLength: AppSpacing.sm)
            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                deltaChip
                sparkline
                    .frame(width: 120, height: 36)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - Pieces

    private func accuracyColumn(title: String, value: Int?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            Text(value.map { "\($0)%" } ?? "—")
                .font(AppTypography.numericMedium)
                .foregroundStyle(AppColors.textPrimary)
        }
    }

    private var deltaChip: some View {
        let delta = trend.deltaPct
        let (glyph, color, label): (String, Color, String) = {
            if delta > 1 { return ("arrow.up.right", AppColors.primaryMint, "+\(delta)%") }
            if delta < -1 { return ("arrow.down.right", AppColors.accentCoral, "\(delta)%") }
            return ("equal", AppColors.textSecondary, "Flat")
        }()
        return HStack(spacing: 4) {
            Image(systemName: glyph)
                .font(.system(size: 11, weight: .bold))
            Text(label)
                .font(AppTypography.caption)
        }
        .foregroundStyle(color)
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.14)))
    }

    private var sparkline: some View {
        GeometryReader { geo in
            let values = trend.dailyBuckets
            let presentIndices = values.enumerated().compactMap { $0.element.isNaN ? nil : $0.offset }
            ZStack(alignment: .bottomLeading) {
                Path { path in
                    guard !presentIndices.isEmpty else { return }
                    let stepX = geo.size.width / CGFloat(max(values.count - 1, 1))
                    var first = true
                    for i in 0..<values.count {
                        let v = values[i]
                        if v.isNaN { continue }
                        let x = CGFloat(i) * stepX
                        let y = geo.size.height * (1 - CGFloat(v))
                        if first {
                            path.move(to: CGPoint(x: x, y: y))
                            first = false
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(AppColors.primaryMint, lineWidth: 1.5)

                // End-point dot
                if let last = presentIndices.last {
                    let stepX = geo.size.width / CGFloat(max(values.count - 1, 1))
                    let x = CGFloat(last) * stepX
                    let y = geo.size.height * (1 - CGFloat(values[last]))
                    Circle()
                        .fill(AppColors.primaryMint)
                        .frame(width: 5, height: 5)
                        .position(x: x, y: y)
                }
            }
            .opacity(presentIndices.isEmpty ? 0.25 : 1)
            .overlay(alignment: .center) {
                if presentIndices.isEmpty {
                    Text("Drill a few hands")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
    }

    private var accessibilitySummary: String {
        let l7 = trend.last7Accuracy.map { "\($0)%" } ?? "no data"
        let l30 = trend.last30Accuracy.map { "\($0)%" } ?? "no data"
        return "Trend: last 7 days \(l7), last 30 days \(l30), delta \(trend.deltaPct) percent."
    }
}

#Preview {
    ZStack {
        AppBackground()
        AccuracyTrendStrip(trend: .init(
            last7Accuracy: 72,
            last30Accuracy: 65,
            deltaPct: 7,
            dailyBuckets: (0..<14).map { i in
                i.isMultiple(of: 3) ? .nan : 0.4 + Double(i) * 0.04
            }
        ))
        .padding(AppSpacing.lg)
    }
}
