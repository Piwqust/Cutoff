import SwiftUI

/// Level 2 — the full chart for one (position, depth, facing) spot.
/// Shows the 13×13 grid, action frequencies, source provenance, and a
/// "Drill this spot" CTA that hands off to the Train tab.
struct RangeChartView: View {
    let chart: RangeChart

    @Environment(RangesViewModel.self) private var vm
    @EnvironmentObject private var browsing: RangeBrowsingStore
    @State private var handDetail: RangeDetailPayload?

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    headerCard
                    RangeGridView(chart: chart) { combo, _ in
                        handDetail = RangeDetailPayload(
                            combo: combo,
                            frequencies: chart.frequencies(for: combo),
                            chart: chart
                        )
                    }
                    frequencyCard
                    RangeLegendView()
                    sourceCard
                    disclaimer
                }
                .padding(.horizontal, AppSpacing.pageHorizontal)
                .padding(.vertical, AppSpacing.lg)
            }
        }
        .navigationTitle(chart.spot.position.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    browsing.toggleFavorite(chart.id)
                } label: {
                    Image(systemName: browsing.isFavorite(chart.id) ? "star.fill" : "star")
                        .foregroundStyle(browsing.isFavorite(chart.id) ? AppColors.accentLime : AppColors.textPrimary)
                }
            }
        }
        .onAppear {
            browsing.markVisited(chart.id)
        }
        .sheet(item: $handDetail) { payload in
            RangeDetailSheet(payload: payload)
                .presentationDetents([.fraction(0.45), .medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("\(chart.spot.position.displayName) · \(chart.spot.stackDepthBB) BB")
                .font(AppTypography.numericLarge)
                .foregroundStyle(AppColors.textPrimary)
            Text(chart.spot.facingAction.displayName)
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var frequencyCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Action mix")
                .font(AppTypography.bodyBold)
                .foregroundStyle(AppColors.textPrimary)
            ActionFrequencyBar(frequencies: chart.actionFrequencies())
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(AppColors.cardSurface)
        )
    }

    private var sourceCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(AppColors.textSecondary)
                Text(chart.source.humanLabel)
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
            }
            Text(chart.source.fullDisclaimer)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            if let solver = chart.source.solver, let assumptions = solver.assumptions {
                Text(assumptions)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(AppColors.cardSurface.opacity(0.6))
        )
    }

    private var disclaimer: some View {
        Text(AppTheme.fullLegalLine)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}

