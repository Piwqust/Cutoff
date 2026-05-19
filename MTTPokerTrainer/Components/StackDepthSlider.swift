import SwiftUI

/// Horizontal slider with discrete tick marks for choosing a stack depth.
///
/// Each tick is a `StackDepthBucket`. The user can drag the thumb across
/// ticks or tap a tick directly to snap to it. Ticks for which no chart
/// exists are rendered muted but remain selectable so the explorer can
/// fall back to its nearest-match logic.
struct StackDepthSlider: View {
    let buckets: [StackDepthBucket]
    let selected: StackDepthBucket?
    let available: Set<StackDepthBucket>
    let onSelect: (StackDepthBucket) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let trackHeight: CGFloat = 4
    private let tickHeight: CGFloat = 12
    private let thumbDiameter: CGFloat = 26
    private let rowHeight: CGFloat = 56

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let n = max(buckets.count - 1, 1)
            let step = width / CGFloat(n)
            let selectedIdx = selected.flatMap { buckets.firstIndex(of: $0) } ?? 0
            let thumbX = step * CGFloat(selectedIdx)

            ZStack(alignment: .leading) {
                // Track: Liquid Glass capsule so it sits naturally over
                // whatever surface is behind the explorer.
                Color.clear
                    .frame(height: trackHeight)
                    .frame(maxWidth: .infinity)
                    .liquidGlass(in: Capsule())
                    .position(x: width / 2, y: rowHeight / 2)

                // Filled portion up to thumb — solid mint so the active
                // range stays high-contrast against the glass track.
                Capsule()
                    .fill(AppColors.primaryMint.opacity(0.75))
                    .frame(width: max(0, thumbX), height: trackHeight)
                    .position(x: max(0, thumbX) / 2, y: rowHeight / 2)

                // Ticks + labels
                ForEach(Array(buckets.enumerated()), id: \.element) { idx, bucket in
                    tick(at: CGFloat(idx) * step, bucket: bucket, isSelected: bucket == selected)
                }

                // Thumb: interactive Liquid Glass disc tinted mint. The
                // mint accent reads as the active control even through the
                // glass while letting the system handle press/focus.
                Color.clear
                    .frame(width: thumbDiameter, height: thumbDiameter)
                    .liquidGlass(in: Circle(), tint: AppColors.primaryMint, interactive: true)
                    .overlay(
                        Circle()
                            .strokeBorder(AppColors.primaryEmerald.opacity(0.7), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
                    .position(x: thumbX, y: rowHeight / 2)
                    .animation(AppMotion.respecting(reduceMotion, AppMotion.spring), value: selectedIdx)
            }
            .frame(width: width, height: rowHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let idx = nearestIndex(toX: value.location.x, step: step)
                        let bucket = buckets[idx]
                        if bucket != selected { onSelect(bucket) }
                    }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Stack depth")
            .accessibilityValue(selected?.label ?? "")
            .accessibilityAdjustableAction { direction in
                guard let selected, let i = buckets.firstIndex(of: selected) else { return }
                switch direction {
                case .increment: if i + 1 < buckets.count { onSelect(buckets[i + 1]) }
                case .decrement: if i > 0 { onSelect(buckets[i - 1]) }
                @unknown default: break
                }
            }
        }
        .frame(height: rowHeight)
    }

    @ViewBuilder
    private func tick(at x: CGFloat, bucket: StackDepthBucket, isSelected: Bool) -> some View {
        let isAvailable = available.contains(bucket)
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(tickColor(isSelected: isSelected, isAvailable: isAvailable))
                .frame(width: 2, height: tickHeight)
            Text("\(bucket.bb)")
                .font(AppTypography.caption.weight(isSelected ? .bold : .regular))
                .foregroundStyle(labelColor(isSelected: isSelected, isAvailable: isAvailable))
                .monospacedDigit()
        }
        .position(x: x, y: rowHeight / 2 + 8)
    }

    private func tickColor(isSelected: Bool, isAvailable: Bool) -> Color {
        if isSelected { return AppColors.primaryEmerald }
        if isAvailable { return AppColors.textSecondary }
        return AppColors.textSecondary.opacity(0.35)
    }

    private func labelColor(isSelected: Bool, isAvailable: Bool) -> Color {
        if isSelected { return AppColors.textPrimary }
        if isAvailable { return AppColors.textSecondary }
        return AppColors.textSecondary.opacity(0.4)
    }

    private func nearestIndex(toX x: CGFloat, step: CGFloat) -> Int {
        guard step > 0 else { return 0 }
        let raw = Int((x / step).rounded())
        return min(max(raw, 0), buckets.count - 1)
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack {
            StackDepthSlider(
                buckets: StackDepthBucket.allCases,
                selected: .bb40,
                available: Set(StackDepthBucket.allCases),
                onSelect: { _ in }
            )
            .padding(.horizontal, AppSpacing.pageHorizontal)
        }
    }
}
