import SwiftUI

/// Tab root for the Ranges section. A single explorer screen (no drilldown):
/// chip rails for position/depth/scenario pivot the active chart in place,
/// search and bookmarks live in the toolbar.
struct RangesView: View {
    @Environment(RangeService.self) private var rangeService
    @State private var vm = RangesViewModel()
    @StateObject private var browsing = RangeBrowsingStore()

    var body: some View {
        NavigationStack {
            RangeExplorerView()
        }
        .environment(vm)
        .environmentObject(browsing)
        .onAppear { vm.load(using: rangeService) }
    }

    static func tabRoot() -> some View { RangesView() }
}

struct RangeDetailPayload: Identifiable {
    var id: String { combo.notation + chart.id }
    let combo: HandCombo
    let frequencies: HandFrequencies
    let chart: RangeChart
}

struct RangeDetailSheet: View {
    let payload: RangeDetailPayload
    @Environment(LocalizationManager.self) private var l10n

    var body: some View {
        let dominant = payload.frequencies.dominantAction
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                HandCardView(hand: payload.combo.notation, size: .compact)
                VStack(alignment: .leading, spacing: 4) {
                    Text(payload.combo.notation)
                        .font(AppTypography.numericLarge)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("\(payload.chart.position.displayName) · \(payload.chart.stackDepth) BB · \(payload.chart.facingAction.displayName(in: l10n.language))")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
                PokerTableView(snapshot: .from(spot: payload.chart.trainingSpot), size: .compact)
                    .frame(width: 130)
            }

            HStack(spacing: 6) {
                Image(systemName: dominant.systemImage)
                Text(dominant.displayName(in: l10n.language))
            }
            .font(AppTypography.bodyBold)
            .foregroundStyle(dominant.prefersDarkForeground ? AppColors.backgroundDeep : AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 6)
            .background(Capsule().fill(dominant.tint))

            Text(ExplanationBuilder.explain(spot: payload.chart.trainingSpot, combo: payload.combo, frequencies: payload.frequencies, in: l10n.language))
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

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
        .environment(LocalizationManager())
}
