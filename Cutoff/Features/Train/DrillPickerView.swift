import SwiftUI

/// Lets the user narrow down which spots to drill before launching a
/// `PreflopTrainerView`. Any dimension left unchecked means "all values".
struct DrillPickerView: View {
    @Environment(RangeService.self) private var rangeService
    @Environment(LocalizationManager.self) private var l10n

    @State private var selectedPositions: Set<TablePosition> = []
    @State private var selectedDepths: Set<StackDepthBucket> = []
    @State private var selectedFacings: Set<FacingAction> = []

    private var activeFilter: TrainingFilter {
        TrainingFilter(
            positions: selectedPositions.isEmpty ? nil : selectedPositions,
            depthBuckets: selectedDepths.isEmpty ? nil : selectedDepths,
            facingActions: selectedFacings.isEmpty ? nil : selectedFacings
        )
    }

    private var matchingCount: Int {
        rangeService.charts(matching: activeFilter).count
    }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    filterSection(
                        title: l10n.t(.position),
                        systemImage: "person.fill",
                        items: rangeService.availablePositions,
                        selected: $selectedPositions,
                        label: { $0.displayName }
                    )
                    filterSection(
                        title: l10n.t(.stackDepth),
                        systemImage: "chart.bar.fill",
                        items: rangeService.availableDepthBuckets.reversed(),
                        selected: $selectedDepths,
                        label: { $0.label }
                    )
                    filterSection(
                        title: l10n.t(.scenario),
                        systemImage: "arrow.triangle.branch",
                        items: rangeService.availableFacingActions,
                        selected: $selectedFacings,
                        label: { $0.displayName(in: l10n.language) }
                    )

                    matchSummary
                    startButton
                }
                .padding(.horizontal, AppSpacing.pageHorizontal)
                .padding(.vertical, AppSpacing.lg)
            }
        }
        .navigationTitle(l10n.t(.buildADrill))
        .navigationBarTitleDisplayMode(.inline)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .onAppear { rangeService.ensureLoaded() }
    }

    // MARK: - Subviews

    private func filterSection<T: Hashable>(
        title: String,
        systemImage: String,
        items: [T],
        selected: Binding<Set<T>>,
        label: @escaping (T) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: systemImage)
                    .font(AppTypography.footnote.weight(.semibold))
                    .foregroundStyle(AppColors.primaryMint)
                Text(title)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                if !selected.wrappedValue.isEmpty {
                    Button(l10n.t(.clear)) { selected.wrappedValue.removeAll() }
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(items, id: \.self) { item in
                        let isSelected = selected.wrappedValue.contains(item)
                        FilterChip(title: label(item), isSelected: isSelected) {
                            if isSelected {
                                selected.wrappedValue.remove(item)
                            } else {
                                selected.wrappedValue.insert(item)
                            }
                        }
                    }
                }
            }
        }
    }

    private var matchSummary: some View {
        GlassCard(padding: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.rangesAvailable(matchingCount, in: l10n.language))
                        .font(AppTypography.bodyBold)
                        .foregroundStyle(matchingCount == 0 ? AppColors.errorSoft : AppColors.textPrimary)
                    if let summary = activeFilter.localizedSummary(in: l10n.language) {
                        Text(summary)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(2)
                    } else {
                        Text(l10n.t(.allPositionsAllDepthsAllScenarios))
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                Spacer()
                if matchingCount > 0 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.primaryMint)
                        .font(AppTypography.title3)
                }
            }
        }
    }

    private var startButton: some View {
        NavigationLink {
            DrillTrainerView(category: .mixed)
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Text(l10n.t(.startDrill))
                    .font(AppTypography.headline)
                Image(systemName: "arrow.right")
                    .font(AppTypography.footnote.weight(.bold))
            }
            .foregroundStyle(matchingCount == 0 ? AppColors.textSecondary : AppColors.backgroundDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(
                Capsule().fill(matchingCount == 0 ? AppColors.cardSurface : AppColors.primaryMint)
            )
        }
        .disabled(matchingCount == 0)
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { DrillPickerView() }
        .environment(RangeService())
        .environment(LocalizationManager())
}
