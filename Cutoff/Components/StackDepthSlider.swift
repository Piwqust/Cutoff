import SwiftUI

/// Discrete-depth slider rebuilt around Apple's Liquid Glass primitives.
///
/// Track and thumb are both `.glassEffect` surfaces wrapped in a
/// `GlassEffectContainer` so the system morphs them together as the
/// thumb travels — the same behavior Apple uses in the iOS 26 system
/// sliders. The thumb is a tall Liquid Glass pill that carries the
/// current BB value, so the active depth is legible without a separate
/// readout. Tap-or-drag anywhere on the row snaps to the nearest tick.
struct StackDepthSlider: View {
    let buckets: [StackDepthBucket]
    let selected: StackDepthBucket?
    let available: Set<StackDepthBucket>
    let onSelect: (StackDepthBucket) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let trackHeight: CGFloat = 30
    private let thumbWidth: CGFloat = 56
    private let thumbHeight: CGFloat = 42
    private let labelGap: CGFloat = 6
    private let labelHeight: CGFloat = 16

    private var rowHeight: CGFloat { thumbHeight + labelGap + labelHeight }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            // Inset the rail by half a thumb on each end so the thumb
            // doesn't clip the ends of the track when at the extremes.
            let inset: CGFloat = thumbWidth / 2
            let usableWidth = max(0, width - 2 * inset)
            let n = max(buckets.count - 1, 1)
            let step = usableWidth / CGFloat(n)
            let selectedIdx = selected.flatMap { buckets.firstIndex(of: $0) } ?? 0
            let thumbX = inset + step * CGFloat(selectedIdx)
            let trackCenterY = thumbHeight / 2

            ZStack(alignment: .topLeading) {
                glassRail(width: width, centerY: trackCenterY, thumbX: thumbX, selectedIdx: selectedIdx)

                ForEach(Array(buckets.enumerated()), id: \.element) { idx, bucket in
                    tickLabel(
                        at: inset + step * CGFloat(idx),
                        bucket: bucket,
                        isSelected: bucket == selected
                    )
                }
            }
            .frame(width: width, height: rowHeight, alignment: .topLeading)
            .contentShape(Rectangle())
            .gesture(dragGesture(inset: inset, step: step))
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

    // MARK: - Liquid Glass rail (track + ticks + thumb)

    @ViewBuilder
    private func glassRail(width: CGFloat, centerY: CGFloat, thumbX: CGFloat, selectedIdx: Int) -> some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer {
                railContent(width: width, centerY: centerY, thumbX: thumbX, selectedIdx: selectedIdx)
            }
        } else {
            railContent(width: width, centerY: centerY, thumbX: thumbX, selectedIdx: selectedIdx)
        }
    }

    /// Wrapped in an explicit ZStack + frame so `.position()` calls inside
    /// have a concrete coordinate space. Without this, the children all use
    /// `.position()` (which has no intrinsic size), the surrounding
    /// `GlassEffectContainer` collapses to zero, and the track / ticks /
    /// thumb scatter across the screen.
    private func railContent(width: CGFloat, centerY: CGFloat, thumbX: CGFloat, selectedIdx: Int) -> some View {
        ZStack(alignment: .topLeading) {
            // Glass track: a tall capsule that fills the row horizontally.
            Color.clear
                .frame(height: trackHeight)
                .frame(maxWidth: .infinity)
                .liquidGlass(in: Capsule())
                .position(x: width / 2, y: centerY)

            // Inner tick dots — embedded inside the track so they read as
            // engraved guides rather than separate UI elements.
            ForEach(Array(buckets.enumerated()), id: \.element) { idx, bucket in
                tickDot(
                    at: trackTickX(idx: idx, width: width),
                    isSelected: bucket == selected,
                    isAvailable: available.contains(bucket),
                    y: centerY
                )
            }

            // Glass thumb pill carrying the current BB value. Tinted mint so
            // it reads as the active control; sized larger than the track so
            // it visibly sits "above" it in z-order.
            thumbView(selectedIdx: selectedIdx)
                .position(x: thumbX, y: centerY)
        }
        .frame(width: width, height: thumbHeight, alignment: .topLeading)
    }

    @ViewBuilder
    private func thumbView(selectedIdx: Int) -> some View {
        Text(selected.map { "\($0.bb)" } ?? "—")
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(AppColors.backgroundDeep)
            .padding(.horizontal, AppSpacing.sm)
            .frame(width: thumbWidth, height: thumbHeight)
            .background(Capsule().fill(AppColors.primaryMint))
            .liquidGlass(in: Capsule(), interactive: true)
            .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
            .animation(AppMotion.respecting(reduceMotion, AppMotion.spring), value: selectedIdx)
    }

    // MARK: - Tick visuals

    private func trackTickX(idx: Int, width: CGFloat) -> CGFloat {
        let inset = thumbWidth / 2
        let usableWidth = max(0, width - 2 * inset)
        let n = max(buckets.count - 1, 1)
        let step = usableWidth / CGFloat(n)
        return inset + step * CGFloat(idx)
    }

    private func tickDot(at x: CGFloat, isSelected: Bool, isAvailable: Bool, y: CGFloat) -> some View {
        let size: CGFloat = isSelected ? 6 : 4
        return Circle()
            .fill(tickColor(isSelected: isSelected, isAvailable: isAvailable))
            .frame(width: size, height: size)
            .position(x: x, y: y)
    }

    private func tickColor(isSelected: Bool, isAvailable: Bool) -> Color {
        if isSelected { return AppColors.primaryEmerald }
        if isAvailable { return AppColors.textSecondary.opacity(0.7) }
        return AppColors.textSecondary.opacity(0.3)
    }

    @ViewBuilder
    private func tickLabel(at x: CGFloat, bucket: StackDepthBucket, isSelected: Bool) -> some View {
        let isAvailable = available.contains(bucket)
        Text("\(bucket.bb)")
            .font(AppTypography.caption.weight(isSelected ? .bold : .regular))
            .monospacedDigit()
            .foregroundStyle(labelColor(isSelected: isSelected, isAvailable: isAvailable))
            .position(x: x, y: thumbHeight + labelGap + labelHeight / 2)
    }

    private func labelColor(isSelected: Bool, isAvailable: Bool) -> Color {
        if isSelected { return AppColors.textPrimary }
        if isAvailable { return AppColors.textSecondary }
        return AppColors.textSecondary.opacity(0.4)
    }

    // MARK: - Gesture

    private func dragGesture(inset: CGFloat, step: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let idx = nearestIndex(toX: value.location.x, inset: inset, step: step)
                let bucket = buckets[idx]
                if bucket != selected { onSelect(bucket) }
            }
    }

    private func nearestIndex(toX x: CGFloat, inset: CGFloat, step: CGFloat) -> Int {
        guard step > 0 else { return 0 }
        let raw = Int(((x - inset) / step).rounded())
        return min(max(raw, 0), buckets.count - 1)
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: AppSpacing.xl) {
            StackDepthSlider(
                buckets: StackDepthBucket.allCases,
                selected: .bb40,
                available: Set(StackDepthBucket.allCases),
                onSelect: { _ in }
            )
            StackDepthSlider(
                buckets: StackDepthBucket.allCases,
                selected: .bb100,
                available: Set(StackDepthBucket.allCases.dropLast(2)),
                onSelect: { _ in }
            )
        }
        .padding(.horizontal, AppSpacing.pageHorizontal)
    }
}
