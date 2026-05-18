import SwiftUI

/// Deep-dive sheet shown when the user taps an answer in the Review history
/// list. Reconstructs the chart context for the spot and walks the user
/// through *why* the correct action is correct.
struct MistakeDetailSheet: View {
    let row: QuizResult
    @Environment(RangeService.self) private var rangeService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header
                actionLine
                if let chart, let combo {
                    GlassCard(padding: AppSpacing.lg) {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Frequencies")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                            FrequencyDistributionView(
                                frequencies: FrequencyCollapser.coarse(chart.frequencies(for: combo)),
                                userAction: row.userAction
                            )
                        }
                    }
                }
                explanationCard
                if let chart, let combo {
                    GlassCard(padding: AppSpacing.lg) {
                        SiblingHandsRow(
                            chart: chart,
                            focusCombo: combo,
                            expectedAction: row.correctAction
                        )
                    }
                }
                footer
            }
            .padding(.horizontal, AppSpacing.pageHorizontal)
            .padding(.vertical, AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppColors.backgroundDeep.ignoresSafeArea())
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: AppSpacing.sm) {
            HandCardView(hand: row.combo, size: .compact)
            VStack(alignment: .leading, spacing: 4) {
                Text(row.combo)
                    .font(AppTypography.numericLarge)
                    .foregroundStyle(AppColors.textPrimary)
                Text("\(row.position.displayName) · \(row.stackDepthBB) BB · \(row.facingAction.displayName)")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                if let combo {
                    Text(HandClass.of(combo).displayName)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Action line

    private var actionLine: some View {
        HStack(spacing: AppSpacing.sm) {
            actionPill(label: "YOU", action: row.userAction)
            Image(systemName: "arrow.right")
                .foregroundStyle(AppColors.textSecondary)
            actionPill(label: "CHART", action: row.correctAction)
            Spacer(minLength: AppSpacing.xs)
            MistakeReasonChip(reason: explanation.mistakeReason)
        }
    }

    private func actionPill(label: String, action: RangeAction) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(AppTypography.caption.weight(.heavy))
                .tracking(0.9)
                .foregroundStyle(AppColors.textSecondary)
            HStack(spacing: 4) {
                Image(systemName: action.systemImage)
                    .font(AppTypography.caption.weight(.bold))
                Text(action.displayName)
                    .font(AppTypography.bodyBold)
            }
            .foregroundStyle(action.prefersDarkForeground ? AppColors.backgroundDeep : AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 4)
            .background(Capsule().fill(action.tint))
        }
    }

    // MARK: - Explanation

    private var explanationCard: some View {
        GlassCard(padding: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Why")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                ForEach(Array(explanation.paragraphs.enumerated()), id: \.offset) { _, text in
                    Text(text)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: AppSpacing.sm) {
            PrimaryButton(title: "Drill this spot", systemImage: "target") {
                dismiss()
                // Routing is shallow — the dashboard's "Drill" entry points handle the actual filter.
            }
        }
    }

    // MARK: - Derived

    private var chart: RangeChart? {
        rangeService.chart(byID: row.rangeChartID)
            ?? rangeService.bestChart(
                position: row.position,
                depthBB: row.stackDepthBB,
                facing: row.facingAction
            )
    }

    private var combo: HandCombo? {
        HandCombo.parse(row.combo)
    }

    private var explanation: MistakeExplainer.Explanation {
        MistakeExplainer.explain(result: row, chart: chart)
    }
}
