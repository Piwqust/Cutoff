import SwiftUI

/// Single-screen replacement for the old library → matrix → chart drilldown.
///
/// Three persistent chip rails (position / depth / scenario) pivot the active
/// chart in place. Search and bookmarks live behind toolbar buttons. A
/// horizontal swipe on the chart steps through stack depths for the same
/// (position, facing).
struct RangeExplorerView: View {
    @Environment(RangesViewModel.self) private var vm
    @EnvironmentObject private var browsing: RangeBrowsingStore

    @State private var handDetail: RangeDetailPayload?
    @State private var showSearch = false
    @State private var showBookmarks = false
    @State private var swipeOffset: CGFloat = 0

    var body: some View {
        ZStack {
            AppBackground()

            if vm.charts.isEmpty {
                ProgressView()
                    .tint(AppColors.textSecondary)
            } else if let chart = vm.activeChart {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        filterRails
                        chartCard(chart)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, AppSpacing.md)
                }
            } else {
                emptyMatchState
            }
        }
        .navigationTitle("Ranges")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbar }
        .sheet(isPresented: $showSearch) {
            RangeSearchSheet(onPick: applyPickedChart)
                .environment(vm)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showBookmarks) {
            RangeBookmarksSheet(onPick: applyPickedChart)
                .environment(vm)
                .environmentObject(browsing)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $handDetail) { payload in
            RangeDetailSheet(payload: payload)
                .presentationDetents([.fraction(0.45), .medium])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            if let id = vm.activeChart?.id { browsing.markVisited(id) }
        }
        .onChange(of: vm.activeChart?.id) { _, new in
            if let new { browsing.markVisited(new) }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showSearch = true } label: {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppColors.textPrimary)
            }
            .accessibilityLabel("Search ranges")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { showBookmarks = true } label: {
                Image(systemName: "bookmark")
                    .foregroundStyle(AppColors.textPrimary)
            }
            .accessibilityLabel("Recents and favorites")
        }
        if let chart = vm.activeChart {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    browsing.toggleFavorite(chart.id)
                } label: {
                    Image(systemName: browsing.isFavorite(chart.id) ? "star.fill" : "star")
                        .foregroundStyle(browsing.isFavorite(chart.id) ? AppColors.accentLime : AppColors.textPrimary)
                }
                .accessibilityLabel(browsing.isFavorite(chart.id) ? "Unfavorite this chart" : "Favorite this chart")
            }
        }
    }

    // MARK: - Filter rails

    private var filterRails: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            chipRail(label: "Position", items: TablePosition.nineMaxOrder) { pos in
                ChipModel(
                    title: pos.displayName,
                    isSelected: vm.selectedPosition == pos,
                    isEnabled: availablePositions.contains(pos),
                    onTap: { vm.selectPosition(pos) }
                )
            }
            chipRail(label: "Depth", items: StackDepthBucket.allCases) { bucket in
                ChipModel(
                    title: "\(bucket.bb)",
                    isSelected: vm.selectedDepthBucket == bucket,
                    isEnabled: availableDepthBuckets.contains(bucket),
                    onTap: { vm.selectDepth(bucket) }
                )
            }
            chipRail(label: "Scenario", items: FacingAction.allCases) { facing in
                ChipModel(
                    title: facing.displayName,
                    isSelected: vm.selectedFacing == facing,
                    isEnabled: availableFacings.contains(facing),
                    onTap: { vm.selectFacing(facing) }
                )
            }
        }
    }

    private struct ChipModel {
        let title: String
        let isSelected: Bool
        let isEnabled: Bool
        let onTap: () -> Void
    }

    private func chipRail<Item: Hashable>(
        label: String,
        items: [Item],
        model: @escaping (Item) -> ChipModel
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, AppSpacing.pageHorizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(items, id: \.self) { item in
                        let m = model(item)
                        FilterChip(title: m.title, isSelected: m.isSelected, isEnabled: m.isEnabled, action: m.onTap)
                    }
                }
                .padding(.horizontal, AppSpacing.pageHorizontal)
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Chart card

    private func chartCard(_ chart: RangeChart) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(chart.spot.position.displayName) · \(chart.spot.stackDepthBB) BB")
                    .font(AppTypography.numericLarge)
                    .foregroundStyle(AppColors.textPrimary)
                Text(chart.spot.facingAction.displayName)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
            }

            RangeGridView(chart: chart) { combo, _ in
                handDetail = RangeDetailPayload(
                    combo: combo,
                    frequencies: chart.frequencies(for: combo),
                    chart: chart
                )
            }
            .id(chart.id) // re-render on chart change for crisper transitions
            .offset(x: swipeOffset)
            .gesture(depthSwipeGesture)

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

            RangeLegendView()

            sourceCard(chart)

            depthHint
        }
        .padding(.horizontal, AppSpacing.pageHorizontal)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: chart.id)
    }

    private func sourceCard(_ chart: RangeChart) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(AppColors.textSecondary)
                Text(chart.source.humanLabel)
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
            }
            Text(chart.source.description)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            if let solver = chart.source.solver {
                if let assumptions = solver.assumptions {
                    Text(assumptions)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                HStack(spacing: 4) {
                    Text(solver.solverName)
                    if let version = solver.solverVersion { Text("· v\(version)") }
                    if let date = solver.dateGenerated { Text("· \(date)") }
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                if let citation = solver.citation, !citation.isEmpty {
                    Text(citation)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                }
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(AppColors.cardSurface.opacity(0.6))
        )
    }

    private var depthHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "hand.draw")
            Text("Swipe the chart left/right to change stack depth.")
        }
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textSecondary)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var emptyMatchState: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundStyle(AppColors.textSecondary)
            Text("No chart matches these filters.")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Depth swipe

    private var depthSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 24)
            .onChanged { value in
                if abs(value.translation.width) > abs(value.translation.height) {
                    swipeOffset = value.translation.width / 4
                }
            }
            .onEnded { value in
                let dx = value.translation.width
                withAnimation(.easeOut(duration: 0.15)) { swipeOffset = 0 }
                guard abs(dx) > 60, abs(dx) > abs(value.translation.height) else { return }
                stepDepth(forward: dx < 0)
            }
    }

    private func stepDepth(forward: Bool) {
        let buckets = availableDepthBuckets
        guard !buckets.isEmpty,
              let current = vm.selectedDepthBucket,
              let idx = buckets.firstIndex(of: current) else { return }
        let next = forward ? idx + 1 : idx - 1
        guard buckets.indices.contains(next) else { return }
        vm.selectDepth(buckets[next])
    }

    // MARK: - Availability helpers

    private var availablePositions: Set<TablePosition> {
        Set(vm.charts.map(\.position))
    }

    private var availableDepthBuckets: [StackDepthBucket] {
        let present = Set(vm.charts.map { StackDepthBucket.nearest(to: $0.stackDepth) })
        return StackDepthBucket.allCases.filter { present.contains($0) }
    }

    private var availableFacings: Set<FacingAction> {
        Set(vm.charts.map(\.facingAction))
    }

    // MARK: - Sheet callbacks

    private func applyPickedChart(_ chart: RangeChart) {
        vm.selectPosition(chart.position)
        vm.selectDepth(StackDepthBucket.nearest(to: chart.stackDepth))
        vm.selectFacing(chart.facingAction)
        showSearch = false
        showBookmarks = false
    }
}

// MARK: - Search sheet

struct RangeSearchSheet: View {
    let onPick: (RangeChart) -> Void

    @Environment(RangesViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppColors.textSecondary)
                        TextField("e.g. \"BTN 100\" or \"squeeze\"", text: $query)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .foregroundStyle(AppColors.textPrimary)
                            .focused($fieldFocused)
                        if !query.isEmpty {
                            Button { query = "" } label: {
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

                    ScrollView {
                        LazyVStack(spacing: AppSpacing.xs) {
                            ForEach(results) { chart in
                                Button { onPick(chart) } label: {
                                    chartRow(chart)
                                }
                                .buttonStyle(.plain)
                            }
                            if results.isEmpty && !query.isEmpty {
                                Text("No charts match.")
                                    .font(AppTypography.subheadline)
                                    .foregroundStyle(AppColors.textSecondary)
                                    .padding(.top, AppSpacing.lg)
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.pageHorizontal)
                .padding(.top, AppSpacing.md)
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppColors.textPrimary)
                }
            }
            .onAppear { fieldFocused = true }
        }
    }

    private var results: [RangeChart] {
        query.isEmpty ? Array(vm.charts.prefix(20)) : vm.search(query)
    }
}

// MARK: - Bookmarks sheet

struct RangeBookmarksSheet: View {
    enum Tab: String, CaseIterable, Identifiable { case recents = "Recents", favorites = "Favorites"
        var id: String { rawValue }
    }

    let onPick: (RangeChart) -> Void

    @Environment(RangesViewModel.self) private var vm
    @EnvironmentObject private var browsing: RangeBrowsingStore
    @Environment(\.dismiss) private var dismiss
    @State private var tab: Tab = .recents

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                VStack(spacing: AppSpacing.md) {
                    Picker("", selection: $tab) {
                        ForEach(Tab.allCases) { t in Text(t.rawValue).tag(t) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, AppSpacing.pageHorizontal)

                    ScrollView {
                        LazyVStack(spacing: AppSpacing.xs) {
                            if charts.isEmpty {
                                emptyState
                            } else {
                                ForEach(charts) { chart in
                                    Button { onPick(chart) } label: {
                                        chartRow(chart)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.pageHorizontal)
                    }
                }
                .padding(.top, AppSpacing.md)
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppColors.textPrimary)
                }
            }
        }
    }

    private var charts: [RangeChart] {
        switch tab {
        case .recents:
            return browsing.recentChartIDs.compactMap { vm.chart(id: $0) }
        case .favorites:
            return browsing.favoriteChartIDs.compactMap { vm.chart(id: $0) }
                .sorted { $0.id < $1.id }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: tab == .recents ? "clock" : "star")
                .font(.system(size: 28))
                .foregroundStyle(AppColors.textSecondary)
            Text(tab == .recents ? "No charts viewed yet." : "No favorites yet — tap the star on a chart.")
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.xl)
    }
}

// MARK: - Shared chart row used by both sheets

private func chartRow(_ chart: RangeChart) -> some View {
    HStack(spacing: AppSpacing.sm) {
        RangeThumbnailView(chart: chart)
            .frame(width: 48, height: 48)
        VStack(alignment: .leading, spacing: 2) {
            Text("\(chart.spot.position.displayName) · \(chart.spot.stackDepthBB) BB")
                .font(AppTypography.bodyBold)
                .foregroundStyle(AppColors.textPrimary)
            Text(chart.spot.facingAction.displayName)
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
