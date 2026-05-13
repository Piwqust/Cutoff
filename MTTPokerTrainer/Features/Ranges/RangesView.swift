import SwiftUI

/// Root of the Ranges tab. Hosts a drill-down: library → matrix → chart.
/// Root of the Ranges tab.
///
/// The shared `RangesViewModel` and `RangeBrowsingStore` must be installed on
/// the *enclosing* `NavigationStack` rather than on `RangeLibraryView`, because
/// SwiftUI's `.navigationDestination(for:)` resolves its destination view in
/// the environment of the NavigationStack — not the view where the modifier
/// is attached. Without this, every push (position / depth / facing / chart)
/// crashes when the pushed view tries to read those environment values.
struct RangesView: View {
    @State private var vm = RangesViewModel()
    @StateObject private var browsing = RangeBrowsingStore()

    var body: some View {
        RangeLibraryView()
            .onAppear { vm.load() }
    }

    /// Convenience for the tab root: wraps `RangesView` in a NavigationStack
    /// and installs the shared model/store at the stack level so all pushed
    /// destinations inherit them.
    static func tabRoot() -> some View {
        TabRoot()
    }

    private var gridContainer: some View {
        GeometryReader { geo in
            let _ = geo
            RangeGridView(chart: vm.activeChart) { combo, freqs in
                guard let chart = vm.activeChart else { return }
                detail = RangeDetailPayload(combo: combo, frequencies: freqs, chart: chart)
            }
            .environment(vm)
            .environmentObject(browsing)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var legendAndDisclaimer: some View {
        VStack(spacing: AppSpacing.xs) {
            RangeLegendView()
            if let chart = vm.activeChart {
                Text("\(chart.source.humanLabel) · \(chart.position.displayName) · \(chart.stackDepth) BB · \(chart.facingAction.displayName)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Text(AppTheme.fullLegalLine)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct RangeDetailPayload: Identifiable {
    var id: String { combo.notation + chart.id }
    let combo: HandCombo
    let frequencies: HandFrequencies
    let chart: RangeChart
}

struct RangeDetailSheet: View {
    let payload: RangeDetailPayload

    var body: some View {
        let dominant = payload.frequencies.dominantAction
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                HandCardView(hand: payload.combo.notation, size: .compact)
                VStack(alignment: .leading, spacing: 4) {
                    Text(payload.combo.notation)
                        .font(AppTypography.numericLarge)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("\(payload.chart.position.displayName) · \(payload.chart.stackDepth) BB · \(payload.chart.facingAction.displayName)")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            HStack(spacing: 6) {
                Image(systemName: dominant.systemImage)
                Text(dominant.displayName)
            }
            .font(AppTypography.bodyBold)
            .foregroundStyle(dominant.prefersDarkForeground ? AppColors.backgroundDeep : AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 6)
            .background(Capsule().fill(dominant.tint))

            Text(ExplanationBuilder.explain(spot: payload.chart.trainingSpot, combo: payload.combo, frequencies: payload.frequencies))
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(payload.chart.source.fullDisclaimer)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            Text(AppTheme.disclaimer)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardSurface.ignoresSafeArea(edges: .bottom))
    }
}

#Preview {
    NavigationStack { RangesView() }
}
