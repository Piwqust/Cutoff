import SwiftUI
import SwiftData

struct ReviewView: View {
    @Query(sort: [SortDescriptor(\QuizResult.createdAt, order: .reverse)])
    private var allResults: [QuizResult]

    @Environment(RangeService.self) private var rangeService

    @State private var scope: ReviewAnalyzer.Scope = .all
    @State private var historyFilter: HistoryFilter = .mistakes
    @State private var deepDiveExpanded: Bool = false
    @State private var selected: QuizResult?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xxl) {
                    if allResults.isEmpty {
                        emptyState
                    } else {
                        scopePicker
                        snapshotSection
                        trendSection
                        deepDiveSection
                        historySection
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.pageHorizontal)
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxl)
            }
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(item: $selected) { row in
            MistakeDetailSheet(row: row)
                .presentationDetents([.fraction(0.7), .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear { rangeService.ensureLoaded() }
    }

    // MARK: - Section eyebrow

    /// Uppercase tracked caption that introduces each section without a card.
    /// Space carries the grouping; the eyebrow is a small editorial marker.
    private func eyebrow(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.caption.weight(.semibold))
            .foregroundStyle(AppColors.textSecondary)
            .textCase(.uppercase)
            .tracking(0.8)
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(AppColors.divider.opacity(0.5))
            .frame(height: 0.5)
    }

    // MARK: - Scope picker

    private var scopePicker: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(ReviewAnalyzer.Scope.allCases) { s in
                FilterChip(title: s.label, isSelected: scope == s) {
                    withAnimation(AppMotion.quick) { scope = s }
                }
            }
            Spacer()
        }
    }

    // MARK: - Snapshot

    private var snapshotSection: some View {
        let snap = ReviewAnalyzer.snapshot(scopedResults)
        return VStack(alignment: .leading, spacing: AppSpacing.md) {
            eyebrow("Last \(snap.total) hand\(snap.total == 1 ? "" : "s")")
            HStack(spacing: AppSpacing.lg) {
                summaryStat("Accuracy", "\(snap.accuracy)%", color: AppColors.primaryMint)
                summaryStat("Mistakes", "\(snap.mistakes)", color: AppColors.accentCoral)
                summaryStat("Close", "\(snap.close)", color: AppColors.accentLime)
                summaryStat("Correct", "\(snap.correct)", color: AppColors.primaryEmerald)
            }
        }
    }

    private func summaryStat(_ label: String, _ value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(AppTypography.numericMedium)
                .foregroundStyle(color)
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Trend

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            eyebrow("Trend")
            AccuracyTrendStrip(trend: ReviewAnalyzer.trend(scopedResults))
        }
    }

    // MARK: - Deep dive

    /// One toggle gates four analysis sections plus the LeakAnalyzer cards.
    /// Collapsed by default each visit. The screen reads as snapshot +
    /// trend until the player explicitly asks for the breakdown.
    private var deepDiveSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            deepDiveToggle
            if deepDiveExpanded {
                VStack(alignment: .leading, spacing: AppSpacing.xxl) {
                    leakSpotsSection
                    heatmapSection
                    handClassSection
                    mistakeReasonsSection
                    leakCardsSection
                }
                .transition(.opacity)
            }
        }
    }

    private var deepDiveToggle: some View {
        Button {
            withAnimation(AppMotion.respecting(reduceMotion, .easeOut(duration: 0.22))) {
                deepDiveExpanded.toggle()
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                eyebrow(deepDiveExpanded ? "Hide deep dive" : "Deep dive")
                Image(systemName: "chevron.down")
                    .font(AppTypography.caption.weight(.bold))
                    .foregroundStyle(AppColors.textSecondary)
                    .rotationEffect(.degrees(deepDiveExpanded ? 180 : 0))
                Spacer(minLength: 0)
            }
            .padding(.vertical, AppSpacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(deepDiveExpanded ? "Hide deep dive" : "Show deep dive")
    }

    // MARK: - Top leak spots

    @ViewBuilder
    private var leakSpotsSection: some View {
        let spots = ReviewAnalyzer.topLeakSpots(scopedResults)
        if !spots.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                eyebrow("Where you leak")
                VStack(spacing: 0) {
                    ForEach(Array(spots.enumerated()), id: \.element.id) { idx, spot in
                        leakSpotRow(spot)
                        if idx < spots.count - 1 { rowDivider }
                    }
                }
            }
        }
    }

    private func leakSpotRow(_ spot: ReviewAnalyzer.LeakSpot) -> some View {
        HStack(alignment: .center, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(spot.position.displayName) · \(spot.bucket.label) · \(spot.facing.displayName)")
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
                Text("\(spot.mistakes) of \(spot.total) wrong")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            Text("\(Int((spot.mistakeRate * 100).rounded()))%")
                .font(AppTypography.numericMedium)
                .foregroundStyle(AppColors.accentCoral)
        }
        .padding(.vertical, AppSpacing.sm)
    }

    // MARK: - Heatmap

    @ViewBuilder
    private var heatmapSection: some View {
        let cells = ReviewAnalyzer.heatmap(scopedResults)
        if cells.count >= 3 {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                eyebrow("Accuracy by spot")
                PositionDepthHeatmap(cells: cells)
            }
        }
    }

    // MARK: - Hand class breakdown

    @ViewBuilder
    private var handClassSection: some View {
        let buckets = ReviewAnalyzer.byHandClass(scopedResults)
        if buckets.count >= 2 {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    eyebrow("By hand class")
                    Spacer()
                    if let worst = buckets.filter({ $0.total >= 3 }).min(by: { $0.accuracy < $1.accuracy }) {
                        Text("Worst: \(worst.label.lowercased())")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.accentCoral)
                    }
                }
                VStack(spacing: AppSpacing.sm) {
                    ForEach(buckets) { b in
                        AccuracyBarRow(
                            label: b.label,
                            total: b.total,
                            accuracy: b.accuracy,
                            systemImage: HandClass(rawValue: b.id)?.systemImage
                        )
                    }
                }
            }
        }
    }

    // MARK: - Mistake reason mix

    @ViewBuilder
    private var mistakeReasonsSection: some View {
        let shares = ReviewAnalyzer.mistakeReasonMix(scopedResults) { id in
            rangeService.chart(byID: id)
        }
        if !shares.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                eyebrow("Mistake reasons")
                VStack(spacing: AppSpacing.sm) {
                    ForEach(shares) { share in
                        HStack {
                            MistakeReasonChip(reason: share.reason)
                            Spacer()
                            Text("\(Int((share.share * 100).rounded()))%")
                                .font(AppTypography.numericSmall)
                                .foregroundStyle(AppColors.textPrimary)
                            Text("· \(share.count)")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Pattern leak cards (LeakAnalyzer)

    /// The one surface that earns a glass card: each LeakCard is a
    /// standalone editorialized object with its own CTA. Inside Deep dive
    /// because the player asked for the breakdown.
    @ViewBuilder
    private var leakCardsSection: some View {
        let leaks = LeakAnalyzer.leaks(from: scopedResults) { id in
            rangeService.chart(byID: id)
        }
        if !leaks.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                eyebrow("Patterns we noticed")
                VStack(spacing: AppSpacing.sm) {
                    ForEach(leaks) { leak in
                        LeakCard(leak: leak)
                    }
                }
            }
        }
    }

    // MARK: - History

    @ViewBuilder
    private var historySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            eyebrow("Review your hands")
            HStack(spacing: AppSpacing.xs) {
                ForEach(HistoryFilter.allCases) { f in
                    FilterChip(title: f.label, isSelected: historyFilter == f) {
                        withAnimation(AppMotion.quick) { historyFilter = f }
                    }
                }
                Spacer(minLength: 0)
            }
            let rows = Array(historyFilter.apply(to: scopedResults).prefix(50))
            if rows.isEmpty {
                Text("Nothing matches this filter yet.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AppSpacing.xl)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { idx, row in
                        Button {
                            selected = row
                        } label: {
                            HistoryRow(row: row)
                        }
                        .buttonStyle(.plain)
                        if idx < rows.count - 1 { rowDivider }
                    }
                }
            }
        }
    }

    // MARK: - Empty state

    /// Kept as glass: a centered hero state on an otherwise empty screen
    /// is the textbook case where a card actually helps anchor the eye.
    private var emptyState: some View {
        GlassCard(padding: AppSpacing.xl) {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "tray")
                    .font(AppTypography.title)
                    .foregroundStyle(AppColors.textSecondary)
                Text("No history yet")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)
                Text("Answer a few drills and your mistakes and patterns will show up here.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Derived

    private var scopedResults: [QuizResult] {
        ReviewAnalyzer.apply(scope: scope, to: allResults)
    }
}

// MARK: - History filter

private enum HistoryFilter: String, CaseIterable, Identifiable {
    case mistakes, close, correct, all
    var id: String { rawValue }
    var label: String {
        switch self {
        case .mistakes: return "Mistakes"
        case .close:    return "Close"
        case .correct:  return "Correct"
        case .all:      return "All"
        }
    }
    func apply(to rows: [QuizResult]) -> [QuizResult] {
        switch self {
        case .mistakes: return rows.filter { $0.outcome == .mistake || $0.outcome == .punt }
        case .close:    return rows.filter { $0.outcome == .close }
        case .correct:  return rows.filter { $0.outcome == .correct }
        case .all:      return rows
        }
    }
}

// MARK: - History row

private struct HistoryRow: View {
    let row: QuizResult

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            outcomeBadge
            VStack(alignment: .leading, spacing: 2) {
                Text(row.combo)
                    .font(AppTypography.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
                Text("\(row.position.displayName) · \(row.stackDepthBB) BB · \(row.facingAction.displayName)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: row.userAction.systemImage)
                        .font(AppTypography.caption.weight(.bold))
                    Text(row.userAction.displayName)
                        .font(AppTypography.caption)
                }
                .foregroundStyle(AppColors.textSecondary)

                HStack(spacing: 4) {
                    Image(systemName: "arrow.right")
                        .font(AppTypography.caption.weight(.bold))
                        .foregroundStyle(AppColors.textSecondary)
                    Text(row.correctAction.displayName)
                        .font(AppTypography.caption)
                        .foregroundStyle(row.correctAction.tint)
                }
            }
        }
        .padding(.vertical, AppSpacing.sm)
        .contentShape(Rectangle())
    }

    private var outcomeBadge: some View {
        let (color, glyph): (Color, String) = {
            switch row.outcome {
            case .correct: return (AppColors.primaryMint, "checkmark")
            case .close:   return (AppColors.accentLime, "circle.lefthalf.filled")
            case .mistake: return (AppColors.accentPeach, "exclamationmark")
            case .punt:    return (AppColors.errorSoft, "xmark")
            }
        }()
        return Image(systemName: glyph)
            .font(AppTypography.subheadline.weight(.bold))
            .foregroundStyle(color)
            .frame(width: 28, height: 28)
            .background(Circle().fill(color.opacity(0.15)))
    }
}
