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
    @StateObject private var browsing = RangeBrowsingStore()

    var body: some View {
        RangeLibraryView()
            .environment(vm)
            .environmentObject(browsing)
            .onAppear { vm.load(using: rangeService) }
    }

    /// Tab-root wrapper: hosts the navigation stack and shared state so the
    /// pushed destinations (matrix / chart) inherit them.
    static func tabRoot() -> some View {
        NavigationStack { RangesView() }
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
