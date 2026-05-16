import SwiftUI
import SwiftData

struct ReviewView: View {
    @Query(sort: [SortDescriptor(\QuizResult.createdAt, order: .reverse)])
    private var allResults: [QuizResult]

    @Environment(RangeService.self) private var rangeService

    @State private var scope: ReviewAnalyzer.Scope = .all
    @State private var historyFilter: HistoryFilter = .mistakes
    @State private var selected: QuizResult?

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    if allResults.isEmpty {
                        emptyState
                    } else {
                        scopePicker
                        snapshotCard
                        AccuracyTrendStrip(trend: ReviewAnalyzer.trend(scopedResults))
                        leakSpotsSection
                        heatmapSection
                        handClassSection
                        mistakeReasonsSection
                        leakCardsSection
                        historySection
                    }
                }
                .padding(.horizontal, AppSpacing.pageHorizontal)
                .padding(.vertical, AppSpacing.lg)
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

    private var snapshotCard: some View {
        let snap = ReviewAnalyzer.snapshot(scopedResults)
        return GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Last \(snap.total) hand\(snap.total == 1 ? "" : "s")")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                HStack(spacing: AppSpacing.md) {
                    summaryStat("Accuracy", "\(snap.accuracy)%", color: AppColors.primaryMint)
                    summaryStat("Mistakes", "\(snap.mistakes)", color: AppColors.accentCoral)
                    summaryStat("Close", "\(snap.close)", color: AppColors.accentLime)
                    summaryStat("Correct", "\(snap.correct)", color: AppColors.primaryEmerald)
                }
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

    // MARK: - Top leak spots

    @ViewBuilder
    private var leakSpotsSection: some View {
        let spots = ReviewAnalyzer.topLeakSpots(scopedResults)
        if !spots.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Where you leak")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)
                VStack(spacing: AppSpacing.xs) {
                    ForEach(spots) { spot in
                        leakSpotRow(spot)
                    }
                }
            }
        }
    }

    private func leakSpotRow(_ spot: ReviewAnalyzer.LeakSpot) -> some View {
        GlassCard(padding: AppSpacing.md) {
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
        }
    }

    // MARK: - Heatmap

    @ViewBuilder
    private var heatmapSection: some View {
        let cells = ReviewAnalyzer.heatmap(scopedResults)
        if cells.count >= 3 {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Accuracy by spot")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)
                GlassCard(padding: AppSpacing.md) {
                    PositionDepthHeatmap(cells: cells)
                }
            }
        }
    }

    // MARK: - Hand class breakdown

    @ViewBuilder
    private var handClassSection: some View {
        let buckets = ReviewAnalyzer.byHandClass(scopedResults)
        if buckets.count >= 2 {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("By hand class")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    if let worst = buckets.filter({ $0.total >= 3 }).min(by: { $0.accuracy < $1.accuracy }) {
                        Text("Worst: \(worst.label.lowercased())")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.accentCoral)
                    }
                }
                GlassCard(padding: AppSpacing.md) {
                    VStack(spacing: AppSpacing.xs) {
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
    }

    // MARK: - Mistake reason mix

    @ViewBuilder
    private var mistakeReasonsSection: some View {
        let shares = ReviewAnalyzer.mistakeReasonMix(scopedResults) { id in
            rangeService.chart(byID: id)
        }
        if !shares.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Mistake reasons")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)
                GlassCard(padding: AppSpacing.md) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
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
    }

    // MARK: - Pattern leak cards (LeakAnalyzer)

    @ViewBuilder
    private var leakCardsSection: some View {
        let leaks = LeakAnalyzer.leaks(from: scopedResults) { id in
            rangeService.chart(byID: id)
        }
        if !leaks.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Patterns we noticed")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)
                ForEach(leaks) { leak in
                    LeakCard(leak: leak)
                }
            }
        }
    }

    // MARK: - History

    @ViewBuilder
    private var historySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Review your hands")
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.textPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(HistoryFilter.allCases) { f in
                        FilterChip(title: f.label, isSelected: historyFilter == f) {
                            withAnimation(AppMotion.quick) { historyFilter = f }
                        }
                    }
                }
            }
            let rows = historyFilter.apply(to: scopedResults).prefix(50)
            if rows.isEmpty {
                Text("Nothing matches this filter yet.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AppSpacing.xl)
            } else {
                VStack(spacing: AppSpacing.xs) {
                    ForEach(Array(rows)) { row in
                        Button {
                            selected = row
                        } label: {
                            HistoryRow(row: row)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        GlassCard(padding: AppSpacing.xl) {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "tray")
                    .font(.system(size: 32))
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
        GlassCard(padding: AppSpacing.md) {
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
                            .font(.system(size: 11, weight: .bold))
                        Text(row.userAction.displayName)
                            .font(AppTypography.caption)
                    }
                    .foregroundStyle(AppColors.textSecondary)

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppColors.textSecondary)
                        Text(row.correctAction.displayName)
                            .font(AppTypography.caption)
                            .foregroundStyle(row.correctAction.tint)
                    }
                }
            }
        }
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
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(color)
            .frame(width: 28, height: 28)
            .background(Circle().fill(color.opacity(0.15)))
    }
}
