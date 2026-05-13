import SwiftUI

struct RangesView: View {
    @State private var vm = RangesViewModel()
    @State private var detail: RangeDetailPayload?

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
        .onAppear { vm.load() }
        .sheet(item: $detail) { payload in
            RangeDetailSheet(payload: payload)
                .presentationDetents([.fraction(0.4), .medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Filters

    private var filterRow: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(TablePosition.nineMaxOrder) { pos in
                        FilterChip(
                            title: pos.displayName,
                            isSelected: vm.selectedPosition == pos,
                            isEnabled: vm.isPositionEnabled(pos)
                        ) {
                            vm.selectPosition(pos)
                        }
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(StackDepthBucket.allCases.reversed()) { bucket in
                        FilterChip(
                            title: bucket.label,
                            isSelected: vm.selectedDepthBucket == bucket,
                            isEnabled: vm.isDepthEnabled(bucket)
                        ) {
                            vm.selectDepth(bucket)
                        }
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(FacingAction.allCases) { facing in
                        FilterChip(
                            title: facing.displayName,
                            isSelected: vm.selectedFacing == facing,
                            isEnabled: vm.isFacingEnabled(facing)
                        ) {
                            vm.selectFacing(facing)
                        }
                    }
                }
            }
        }
    }

    private var gridContainer: some View {
        // GeometryReader gives the grid a square frame that fills the parent
        // width — otherwise LazyVGrid shrinks to its intrinsic content size
        // and the cells truncate.
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            Group {
                if vm.activeChart != nil {
                    RangeGridView(chart: vm.activeChart) { combo, action in
                        guard let chart = vm.activeChart else { return }
                        detail = RangeDetailPayload(combo: combo, action: action, chart: chart)
                    }
                } else {
                    noRangeForCombo
                }
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var noRangeForCombo: some View {
        GlassCard(padding: AppSpacing.xl) {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "questionmark.square.dashed")
                    .font(.system(size: 32))
                    .foregroundStyle(AppColors.textSecondary)
                Text("No chart for this combination")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)
                Text("That spot isn't possible at a 9-max table (e.g. facing an open from UTG, or defending blinds anywhere but BB).")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var legendAndDisclaimer: some View {
        VStack(spacing: AppSpacing.xs) {
            RangeLegendView()
            if let chart = vm.activeChart {
                Text("\(chart.source.humanLabel) · \(chart.spot.position.displayName) · \(chart.spot.stackDepthBB) BB · \(chart.spot.facingAction.displayName)")
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
    let action: RangeAction
    let chart: RangeChart
}

struct RangeDetailSheet: View {
    let payload: RangeDetailPayload

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                HandCardView(hand: payload.combo.notation, size: .compact)
                VStack(alignment: .leading, spacing: 4) {
                    Text(payload.combo.notation)
                        .font(AppTypography.numericLarge)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("\(payload.chart.spot.position.displayName) · \(payload.chart.spot.stackDepthBB) BB · \(payload.chart.spot.facingAction.displayName)")
                        .font(AppTypography.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            HStack(spacing: 6) {
                Image(systemName: payload.action.systemImage)
                Text(payload.action.displayName)
            }
            .font(AppTypography.bodyBold)
            .foregroundStyle(payload.action.prefersDarkForeground ? AppColors.backgroundDeep : AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 6)
            .background(Capsule().fill(payload.action.tint))

            Text(ExplanationBuilder.explain(spot: payload.chart.trainingSpot, combo: payload.combo, correct: payload.action))
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(payload.chart.source.fullDisclaimer)
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
