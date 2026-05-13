import SwiftUI
import SwiftData

struct ReviewView: View {
    @Query(sort: \QuizResult.createdAt, order: .reverse)
    private var allResults: [QuizResult]

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    if allResults.isEmpty {
                        emptyState
                    } else {
                        let leaks = LeakAnalyzer.leaks(from: allResults)
                        if leaks.isEmpty {
                            noLeaksState
                        } else {
                            ForEach(leaks) { leak in
                                leakCard(for: leak)
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
                Text("No data yet")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)
                Text("Train some hands to see your leaks here.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var noLeaksState: some View {
        GlassCard(tint: AppColors.cardSurfaceGreen, padding: AppSpacing.xl) {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(AppColors.primaryMint)
                Text("Looking good")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)
                Text("We haven't detected any major recurring leaks. Keep training to build a larger sample size.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
