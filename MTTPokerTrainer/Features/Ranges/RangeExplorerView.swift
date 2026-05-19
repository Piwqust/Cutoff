import SwiftUI

/// Single-screen replacement for the old library → matrix → chart drilldown.
///
/// Three persistent chip rails (position / depth / scenario) pivot the active
/// chart in place. Search and bookmarks live behind toolbar buttons. A
/// horizontal swipe on the chart steps through stack depths for the same
/// (position, facing).
struct RangeExplorerView: View {
    @Environment(RangesViewModel.self) private var vm
    @Environment(LocalizationManager.self) private var l10n
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
        .navigationTitle(l10n.t(.rangesTitle))
        .navigationBarTitleDisplayMode(.large)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
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
            .accessibilityLabel(l10n.t(.searchRanges))
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { showBookmarks = true } label: {
                Image(systemName: "bookmark")
                    .foregroundStyle(AppColors.textPrimary)
            }
            .accessibilityLabel(l10n.t(.recentsAndFavorites))
        }
        if let chart = vm.activeChart {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    browsing.toggleFavorite(chart.id)
                } label: {
                    Image(systemName: browsing.isFavorite(chart.id) ? "star.fill" : "star")
                        .foregroundStyle(browsing.isFavorite(chart.id) ? AppColors.accentLime : AppColors.textPrimary)
                }
                .accessibilityLabel(browsing.isFavorite(chart.id) ? l10n.t(.unfavoriteThisChart) : l10n.t(.favoriteThisChart))
            }
        }
    }

    // MARK: - Filter rails

    private var filterRails: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            positionSection
            depthSection
            scenarioSection
        }
    }

    private var positionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            eyebrow(l10n.t(.position))
                .padding(.horizontal, AppSpacing.pageHorizontal)
            PositionPickerMinimap(
                positions: TablePosition.nineMaxOrder,
                selected: vm.selectedPosition,
                enabled: availablePositions,
                onSelect: { vm.selectPosition($0) }
            )
            .padding(.horizontal, AppSpacing.pageHorizontal)
        }
    }

    private var depthSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            eyebrow(l10n.t(.depth))
                .padding(.horizontal, AppSpacing.pageHorizontal)

            StackDepthSlider(
                buckets: StackDepthBucket.allCases,
                selected: vm.selectedDepthBucket,
                available: Set(availableDepthBuckets),
                onSelect: { vm.selectDepth($0) }
            )
            .padding(.horizontal, AppSpacing.pageHorizontal)
        }
    }

    private var scenarioSection: some View {
        let facings = scenariosForCurrentPosition
        return VStack(alignment: .leading, spacing: 6) {
            eyebrow(l10n.t(.scenario))
                .padding(.horizontal, AppSpacing.pageHorizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(facings, id: \.self) { facing in
                        FilterChip(
                            title: facing.displayName(in: l10n.language),
                            isSelected: vm.selectedFacing == facing,
                            isEnabled: true,
                            action: { vm.selectFacing(facing) }
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.pageHorizontal)
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Chart card

    private func chartCard(_ chart: RangeChart) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(chart.spot.position.displayName) · \(chart.spot.stackDepthBB) BB")
                    .font(AppTypography.numericLarge)
                    .foregroundStyle(AppColors.textPrimary)
                Text(chart.spot.facingAction.displayName(in: l10n.language))
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

            depthHint

            actionMixBlock(chart)

            RangeLegendView()

            sourceBlock(chart)
        }
        .padding(.horizontal, AppSpacing.pageHorizontal)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: chart.id)
    }

    /// Eyebrow used in the chart pane sections. Same vocabulary the Review
    /// screen now uses, so the two analysis screens read consistently.
    private func eyebrow(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.caption.weight(.semibold))
            .foregroundStyle(AppColors.textSecondary)
            .textCase(.uppercase)
            .tracking(0.8)
    }

    private func actionMixBlock(_ chart: RangeChart) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            eyebrow(l10n.t(.actionMix))
            ActionFrequencyBar(frequencies: chart.actionFrequencies())
        }
    }

    private func sourceBlock(_ chart: RangeChart) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "info.circle.fill")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Text(chart.source.humanLabel)
                    .font(AppTypography.subheadline.weight(.semibold))
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var depthHint: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.left.and.right")
                .font(AppTypography.caption.weight(.semibold))
            Text(l10n.t(.swipeToChangeDepth))
        }
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textSecondary.opacity(0.7))
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var emptyMatchState: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "tray")
                .font(AppTypography.title)
                .foregroundStyle(AppColors.textSecondary)
            Text(l10n.t(.noChartMatches))
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

    /// Scenario buttons we render for the current position. Drops any
    /// `FacingAction` for which there's no chart at the selected position —
    /// so e.g. BB never shows RFI and UTG never shows blind defense.
    /// Ordered to match the canonical `FacingAction.allCases` sequence.
    private var scenariosForCurrentPosition: [FacingAction] {
        guard let pos = vm.selectedPosition else { return [] }
        let present = Set(vm.charts.filter { $0.position == pos }.map(\.facingAction))
        return FacingAction.allCases.filter { present.contains($0) }
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
    @Environment(LocalizationManager.self) private var l10n
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
                        TextField(l10n.t(.rangeSearchPlaceholder), text: $query)
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
                                    chartRow(chart, language: l10n.language)
                                }
                                .buttonStyle(.plain)
                            }
                            if results.isEmpty && !query.isEmpty {
                                Text(l10n.t(.noChartsMatch))
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
            .navigationTitle(l10n.t(.search))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(l10n.t(.done)) { dismiss() }
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
    enum Tab: String, CaseIterable, Identifiable { case recents, favorites
        var id: String { rawValue }
        func label(in lang: AppLanguage) -> String {
            switch self {
            case .recents:   return L10n.string(.recents, in: lang)
            case .favorites: return L10n.string(.favorites, in: lang)
            }
        }
    }

    let onPick: (RangeChart) -> Void

    @Environment(RangesViewModel.self) private var vm
    @Environment(LocalizationManager.self) private var l10n
    @EnvironmentObject private var browsing: RangeBrowsingStore
    @Environment(\.dismiss) private var dismiss
    @State private var tab: Tab = .recents

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                VStack(spacing: AppSpacing.md) {
                    Picker("", selection: $tab) {
                        ForEach(Tab.allCases) { t in Text(t.label(in: l10n.language)).tag(t) }
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
                                        chartRow(chart, language: l10n.language)
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
            .navigationTitle(l10n.t(.bookmarksTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(l10n.t(.done)) { dismiss() }
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
                .font(AppTypography.title2)
                .foregroundStyle(AppColors.textSecondary)
            Text(tab == .recents ? l10n.t(.noChartsViewed) : l10n.t(.noFavoritesYet))
                .font(AppTypography.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.xl)
    }
}

// MARK: - Shared chart row used by both sheets

private func chartRow(_ chart: RangeChart, language: AppLanguage) -> some View {
    HStack(spacing: AppSpacing.sm) {
        RangeThumbnailView(chart: chart)
            .frame(width: 48, height: 48)
        VStack(alignment: .leading, spacing: 2) {
            Text("\(chart.spot.position.displayName) · \(chart.spot.stackDepthBB) BB")
                .font(AppTypography.bodyBold)
                .foregroundStyle(AppColors.textPrimary)
            Text(chart.spot.facingAction.displayName(in: language))
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
