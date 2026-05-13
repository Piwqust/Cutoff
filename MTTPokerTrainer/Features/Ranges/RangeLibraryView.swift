import SwiftUI

/// Level 0 of the Ranges drill-down. Sectioned landing screen — recents,
/// favorites, and browse-by-axis. Tapping a row pushes the appropriate
/// matrix or chart view onto the navigation stack.
struct RangeLibraryView: View {
    @Environment(RangesViewModel.self) private var vm
    @EnvironmentObject private var browsing: RangeBrowsingStore
    @State private var searchQuery: String = ""

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppSpacing.xl) {
                    searchSection
                    if !searchQuery.isEmpty {
                        searchResults
                    } else {
                        recentsSection
                        favoritesSection
                        browseByPositionSection
                        browseByDepthSection
                        browseByScenarioSection
                    }
                    disclaimerFooter
                }
                .padding(.horizontal, AppSpacing.pageHorizontal)
                .padding(.vertical, AppSpacing.lg)
            }
        }
        .navigationTitle("Ranges")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: ChartRoute.self) { route in
            destination(for: route)
        }
    }

    // MARK: - Sections

    private var searchSection: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppColors.textSecondary)
            TextField("Search e.g. \"BTN 100\" or \"squeeze\"", text: $searchQuery)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .foregroundStyle(AppColors.textPrimary)
            if !searchQuery.isEmpty {
                Button { searchQuery = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.chip, style: .continuous)
                .fill(AppColors.cardSurface)
        )
    }

    private var searchResults: some View {
        let results = vm.search(searchQuery)
        return VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader("Search Results", subtitle: "\(results.count) chart\(results.count == 1 ? "" : "s")")
            if results.isEmpty {
                emptyState(message: "No charts match. Try \"BTN 100\" or \"squeeze 40\".")
            } else {
                ForEach(results) { chart in
                    NavigationLink(value: ChartRoute.chart(chart.id)) {
                        ChartRowView(chart: chart, isFavorite: browsing.isFavorite(chart.id))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var recentsSection: some View {
        let recents = browsing.recentChartIDs.compactMap { vm.chart(id: $0) }
        return Group {
            if !recents.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    sectionHeader("Continue practicing")
                    ForEach(recents) { chart in
                        NavigationLink(value: ChartRoute.chart(chart.id)) {
                            ChartRowView(chart: chart, isFavorite: browsing.isFavorite(chart.id))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var favoritesSection: some View {
        let favorites = browsing.favoriteChartIDs.compactMap { vm.chart(id: $0) }
            .sorted { $0.id < $1.id }
        return Group {
            if !favorites.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    sectionHeader("Favorites", subtitle: "\(favorites.count)")
                    ForEach(favorites) { chart in
                        NavigationLink(value: ChartRoute.chart(chart.id)) {
                            ChartRowView(chart: chart, isFavorite: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var browseByPositionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader("Browse by position")
            ForEach(TablePosition.nineMaxOrder) { pos in
                NavigationLink(value: ChartRoute.position(pos)) {
                    AxisRowView(
                        title: pos.displayName,
                        subtitle: positionSubtitle(pos),
                        systemImage: "person.fill"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var browseByDepthSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader("Browse by stack depth")
            ForEach(StackDepthBucket.allCases.reversed()) { bucket in
                NavigationLink(value: ChartRoute.depth(bucket.bb)) {
                    AxisRowView(
                        title: bucket.label,
                        subtitle: bucket.lesson,
                        systemImage: "chart.bar.fill"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var browseByScenarioSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader("Browse by scenario")
            ForEach(FacingAction.allCases) { facing in
                NavigationLink(value: ChartRoute.facing(facing)) {
                    AxisRowView(
                        title: facing.displayName,
                        subtitle: scenarioSubtitle(facing),
                        systemImage: scenarioIcon(facing)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var disclaimerFooter: some View {
        Text(AppTheme.fullLegalLine)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, AppSpacing.md)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, subtitle: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(AppTypography.title3)
                .foregroundStyle(AppColors.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
        }
    }

    private func emptyState(message: String) -> some View {
        Text(message)
            .font(AppTypography.subheadline)
            .foregroundStyle(AppColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .fill(AppColors.cardSurface.opacity(0.6))
            )
    }

    private func positionSubtitle(_ pos: TablePosition) -> String {
        let count = vm.charts(for: pos).count
        return "\(count) chart\(count == 1 ? "" : "s")"
    }

    private func scenarioSubtitle(_ facing: FacingAction) -> String {
        switch facing {
        case .unopened:     return "First-in opening ranges"
        case .vsOpen:       return "Facing an opener"
        case .vs3Bet:       return "After you opened, facing a 3-bet"
        case .squeeze:      return "Open + caller, action on you"
        case .blindDefense: return "SB/BB vs late opens"
        case .pushFold:     return "Short-stack jam-or-fold"
        }
    }

    private func scenarioIcon(_ facing: FacingAction) -> String {
        switch facing {
        case .unopened:     return "arrow.up.right"
        case .vsOpen:       return "arrowshape.turn.up.left.fill"
        case .vs3Bet:       return "arrow.up.right.circle.fill"
        case .squeeze:      return "person.2.circle.fill"
        case .blindDefense: return "shield.fill"
        case .pushFold:     return "flame.fill"
        }
    }

    @ViewBuilder
    private func destination(for route: ChartRoute) -> some View {
        switch route {
        case .chart(let id):
            if let chart = vm.chart(id: id) {
                RangeChartView(chart: chart)
            } else {
                Text("Chart not found.").foregroundStyle(AppColors.textSecondary)
            }
        case .position(let pos):
            RangeMatrixView(axis: .position(pos))
        case .depth(let depth):
            RangeMatrixView(axis: .depth(depth))
        case .facing(let facing):
            RangeMatrixView(axis: .facing(facing))
        }
    }
}

enum ChartRoute: Hashable {
    case chart(String)
    case position(TablePosition)
    case depth(Int)
    case facing(FacingAction)
}

/// A list row showing position/depth/facing + a small thumbnail + favorite star.
struct ChartRowView: View {
    let chart: RangeChart
    let isFavorite: Bool

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            RangeThumbnailView(chart: chart)
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(chart.spot.position.displayName) · \(chart.spot.stackDepthBB) BB")
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
                Text(chart.spot.facingAction.displayName)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            if isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(AppColors.accentLime)
            }
            Image(systemName: "chevron.right")
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(AppColors.cardSurface)
        )
    }
}

/// A list row for an axis browse entry (position / depth / scenario).
struct AxisRowView: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.primaryMint)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppColors.primaryMint.opacity(0.12))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
                Text(subtitle)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(AppColors.cardSurface)
        )
    }
}
