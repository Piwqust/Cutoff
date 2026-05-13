import SwiftUI
import SwiftData

struct ReviewView: View {
    @Query(sort: [SortDescriptor(\QuizResult.createdAt, order: .reverse)])
    private var allResults: [QuizResult]

    @State private var filter: ReviewFilter = .mistakes
    @State private var selected: QuizResult?

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    if allResults.isEmpty {
                        emptyState
                    } else {
                        let leaks = LeakAnalyzer.leaks(from: allResults)
                        if leaks.isEmpty {
                            noLeaksState
                        } else {
                            ForEach(leaks) { leak in
                                LeakCard(
                                    title: leak.title,
                                    detail: leak.detail,
                                    severity: leak.severity,
                                    onDrill: {}
                                )
                            }
                        }
                    }

                    Text(AppTheme.fullLegalLine)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xl)
                }
                .padding(.horizontal, AppSpacing.pageHorizontal)
                .padding(.vertical, AppSpacing.lg)
            }
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(item: $selected) { row in
            ReviewDetailSheet(row: row)
                .presentationDetents([.fraction(0.5), .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Leak cards

    @ViewBuilder
    private func leakCard(for leak: Leak) -> some View {
        if let spot = leak.suggestedSpot {
            let filter = TrainingFilter(
                positions: [spot.position],
                depthBuckets: [StackDepthBucket.nearest(to: spot.depthBB)],
                facingActions: [spot.facingAction]
            )
            NavigationLink {
                PreflopTrainerView(filter: filter)
            } label: {
                LeakCard(
                    title: leak.title,
                    detail: leak.detail,
                    severity: leak.severity,
                    drillTitle: "Drill this",
                    onDrill: {}
                )
            }
            .buttonStyle(.plain)
        } else {
            LeakCard(
                title: leak.title,
                detail: leak.detail,
                severity: leak.severity,
                onDrill: {}
            )
        }
    }

    // MARK: - Empty / no-leak states

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

    private var summaryCard: some View {
        let total = allResults.count
        let mistakes = allResults.filter { $0.outcome == .mistake || $0.outcome == .punt }.count
        let close = allResults.filter { $0.outcome == .close }.count
        let correct = allResults.filter { $0.outcome == .correct }.count
        let acc = total == 0 ? 0 : Int(round(Double(allResults.map(\.score).reduce(0, +)) / Double(total)))
        return GlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Last \(total) hand\(total == 1 ? "" : "s")")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                HStack(spacing: AppSpacing.md) {
                    summaryStat("Accuracy", "\(acc)%", color: AppColors.primaryMint)
                    summaryStat("Mistakes", "\(mistakes)", color: AppColors.accentCoral)
                    summaryStat("Close", "\(close)", color: AppColors.accentLime)
                    summaryStat("Correct", "\(correct)", color: AppColors.primaryEmerald)
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

    private var leaksSection: some View {
        let leaks = LeakAnalyzer.leaks(from: allResults)
        return Group {
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
    }

    private var filterRow: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("History")
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.textPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(ReviewFilter.allCases) { f in
                        FilterChip(title: f.label, isSelected: filter == f) {
                            withAnimation(AppMotion.quick) { filter = f }
                        }
                    }
                }
            }
        }
    }

    private var filteredResults: [QuizResult] {
        filter.apply(to: allResults)
    }

    private var historyList: some View {
        let list = Array(filteredResults.prefix(50))
        return VStack(spacing: AppSpacing.xs) {
            if list.isEmpty {
                Text("Nothing matches this filter yet.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AppSpacing.xl)
            } else {
                ForEach(list) { row in
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

private enum ReviewFilter: String, CaseIterable, Identifiable {
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

private struct ReviewDetailSheet: View {
    let row: QuizResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(spacing: AppSpacing.sm) {
                    HandCardView(hand: row.combo, size: .compact)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(row.combo)
                            .font(AppTypography.numericLarge)
                            .foregroundStyle(AppColors.textPrimary)
                        Text("\(row.position.displayName) · \(row.stackDepthBB) BB · \(row.facingAction.displayName)")
                            .font(AppTypography.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }

                HStack(spacing: AppSpacing.sm) {
                    actionPill(label: "You", action: row.userAction)
                    Image(systemName: "arrow.right")
                        .foregroundStyle(AppColors.textSecondary)
                    actionPill(label: "Best", action: row.correctAction)
                    Spacer()
                    outcomeChip
                }

                if !row.explanation.isEmpty {
                    Text(row.explanation)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 6) {
                    Image(systemName: row.category.systemImage)
                    Text(row.category.title)
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)

                Spacer(minLength: AppSpacing.lg)
                Text(AppTheme.fullLegalLine)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(AppSpacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppColors.cardSurface.ignoresSafeArea())
    }

    private func actionPill(label: String, action: RangeAction) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
            HStack(spacing: 4) {
                Image(systemName: action.systemImage)
                    .font(.system(size: 11, weight: .bold))
                Text(action.displayName)
                    .font(AppTypography.bodyBold)
            }
            .foregroundStyle(action.prefersDarkForeground ? AppColors.backgroundDeep : AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 4)
            .background(Capsule().fill(action.tint))
        }
    }

    private var outcomeChip: some View {
        Text(row.outcome.headline)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 4)
            .background(Capsule().fill(AppColors.cardSurfaceGreen))
    }
}
