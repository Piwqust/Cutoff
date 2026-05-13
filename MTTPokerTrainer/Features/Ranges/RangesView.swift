import SwiftUI

struct RangesView: View {
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
        .onAppear { vm.load() }
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

    // MARK: - Filters

    private var filterRow: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(TablePosition.nineMaxOrder) { pos in
                        FilterChip(title: pos.displayName, isSelected: vm.selectedPosition == pos) {
                            vm.selectPosition(pos)
                        }
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(StackDepthBucket.allCases.reversed()) { bucket in
                        FilterChip(title: bucket.label, isSelected: vm.selectedDepthBucket == bucket) {
                            vm.selectDepth(bucket)
                        }
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(FacingAction.allCases) { facing in
                        FilterChip(title: facing.displayName, isSelected: vm.selectedFacing == facing) {
                            vm.selectFacing(facing)
                        }
                    }
                }
            }
        }
    }

    private var gridContainer: some View {
        GeometryReader { geo in
            let _ = geo
            RangeGridView(chart: vm.activeChart) { combo, action in
                guard let chart = vm.activeChart else { return }
                detail = RangeDetailPayload(combo: combo, action: action, chart: chart)
            }
        }
        .aspectRatio(1, contentMode: .fit)
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
}
