import SwiftUI

/// Level 1 — shows all charts on one axis (position / depth / scenario)
/// as a grid of thumbnails. Tapping a thumbnail pushes the full chart view.
struct RangeMatrixView: View {
    enum Axis: Hashable {
        case position(TablePosition)
        case depth(Int)
        case facing(FacingAction)

        var title: String {
            switch self {
            case .position(let p): return p.displayName
            case .depth(let d):    return "\(d) BB"
            case .facing(let f):   return f.displayName
            }
        }
    }

    let axis: Axis

    @Environment(RangesViewModel.self) private var vm
    @EnvironmentObject private var browsing: RangeBrowsingStore

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    header
                    matrix
                    disclaimer
                }
                .padding(.horizontal, AppSpacing.pageHorizontal)
                .padding(.vertical, AppSpacing.lg)
            }
        }
        .navigationTitle(axis.title)
        .navigationBarTitleDisplayMode(.large)
    }

    private var header: some View {
        Text(headerSubtitle)
            .font(AppTypography.subheadline)
            .foregroundStyle(AppColors.textSecondary)
    }

    private var headerSubtitle: String {
        let total = charts.count
        return "\(total) chart\(total == 1 ? "" : "s")"
    }

    // MARK: - Matrix layout

    /// Rendered as a sectioned 2D layout. The "other two" axes form the rows
    /// and columns. E.g. for axis=position the rows are stack depths and
    /// columns are facing actions.
    @ViewBuilder
    private var matrix: some View {
        switch axis {
        case .position(let pos):
            depthByFacingMatrix(filter: { $0.spot.position == pos })
        case .depth(let depth):
            positionByFacingMatrix(filter: { $0.spot.stackDepthBB == depth })
        case .facing(let facing):
            positionByDepthMatrix(filter: { $0.spot.facingAction == facing })
        }
    }

    private var charts: [RangeChart] {
        vm.charts.filter { c in
            switch axis {
            case .position(let p): return c.spot.position == p
            case .depth(let d):    return c.spot.stackDepthBB == d
            case .facing(let f):   return c.spot.facingAction == f
            }
        }
    }

    private func depthByFacingMatrix(filter: @escaping (RangeChart) -> Bool) -> some View {
        let depths = StackDepthBucket.allCases.reversed().map(\.bb)
        let facings = FacingAction.allCases
        return matrixBody(rowLabels: depths.map { "\($0) BB" },
                          colLabels: facings.map(\.displayName)) { row, col in
            let depth = depths[row]
            let facing = facings[col]
            return vm.charts.first { c in
                filter(c) && c.spot.stackDepthBB == depth && c.spot.facingAction == facing
            }
        }
    }

    private func positionByFacingMatrix(filter: @escaping (RangeChart) -> Bool) -> some View {
        let positions = TablePosition.nineMaxOrder
        let facings = FacingAction.allCases
        return matrixBody(rowLabels: positions.map(\.displayName),
                          colLabels: facings.map(\.displayName)) { row, col in
            let pos = positions[row]
            let facing = facings[col]
            return vm.charts.first { c in
                filter(c) && c.spot.position == pos && c.spot.facingAction == facing
            }
        }
    }

    private func positionByDepthMatrix(filter: @escaping (RangeChart) -> Bool) -> some View {
        let positions = TablePosition.nineMaxOrder
        let depths = StackDepthBucket.allCases.reversed().map(\.bb)
        return matrixBody(rowLabels: positions.map(\.displayName),
                          colLabels: depths.map { "\($0)" }) { row, col in
            let pos = positions[row]
            let depth = depths[col]
            return vm.charts.first { c in
                filter(c) && c.spot.position == pos && c.spot.stackDepthBB == depth
            }
        }
    }

    /// Generic row × column matrix renderer. `chart(row, col)` returns nil when
    /// the (row, col) combination has no bundled chart — those cells render
    /// as a struck-through "no chart" tile, never silently substituting another.
    private func matrixBody(
        rowLabels: [String],
        colLabels: [String],
        chart: @escaping (Int, Int) -> RangeChart?
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            ForEach(0..<rowLabels.count, id: \.self) { row in
                rowSection(label: rowLabels[row], colLabels: colLabels) { col in
                    chart(row, col)
                }
            }
        }
    }

    private func rowSection(
        label: String,
        colLabels: [String],
        chartProvider: @escaping (Int) -> RangeChart?
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(label)
                .font(AppTypography.bodyBold)
                .foregroundStyle(AppColors.textPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(0..<colLabels.count, id: \.self) { col in
                        cell(chart: chartProvider(col), label: colLabels[col])
                    }
                }
            }
        }
    }

    private func cell(chart: RangeChart?, label: String) -> some View {
        Group {
            if let chart {
                NavigationLink(value: ChartRoute.chart(chart.id)) {
                    cellContent(chart: chart, label: label)
                }
                .buttonStyle(.plain)
            } else {
                cellContent(chart: nil, label: label)
                    .opacity(0.55)
            }
        }
    }

    private func cellContent(chart: RangeChart?, label: String) -> some View {
        VStack(spacing: AppSpacing.xxs) {
            RangeThumbnailView(chart: chart)
                .frame(width: 78, height: 78)
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(chart == nil ? AppColors.textSecondary : AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: 78)
        }
    }

    private var disclaimer: some View {
        Text(AppTheme.fullLegalLine)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, AppSpacing.md)
    }
}
