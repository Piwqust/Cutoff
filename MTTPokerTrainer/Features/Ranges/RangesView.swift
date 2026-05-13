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
    @Environment(RangeService.self) private var rangeService
    @State private var vm = RangesViewModel()
    @State private var detail: RangeDetailPayload?
    @State private var detailHeight: CGFloat = 280

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: AppSpacing.md) {
                filterRow
                gridContainer
                legendAndDisclaimer
            }
            .padding(.horizontal, AppSpacing.pageHorizontal)
            .padding(.top, AppSpacing.sm)
            .padding(.bottom, AppSpacing.lg)
        }
        .navigationTitle("Ranges")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .onAppear { vm.load(using: rangeService) }
        .sheet(item: $detail) { payload in
            RangeDetailSheet(payload: payload)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: RangeDetailHeightKey.self, value: geo.size.height)
                    }
                )
                .onPreferenceChange(RangeDetailHeightKey.self) { h in
                    if h > 0 { detailHeight = h }
                }
                .presentationDetents([.height(detailHeight)])
                .presentationBackground(AppColors.cardSurface)
                .presentationDragIndicator(.visible)
        }
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
                Spacer()
                PokerTableView(snapshot: .from(spot: payload.chart.trainingSpot), size: .compact)
                    .frame(width: 130)
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
    }
}

struct RangeDetailHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    NavigationStack { RangesView() }
        .environment(RangeService())
}
