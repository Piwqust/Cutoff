import SwiftUI

struct LeakCard: View {
    let title: String
    let detail: String
    /// 0 = mild, 1 = major
    let severity: Double
    var drillTitle: String = "Drill this"
    var spot: TrainingSpot? = nil
    let onDrill: () -> Void

    init(
        title: String,
        detail: String,
        severity: Double,
        drillTitle: String = "Drill this",
        spot: TrainingSpot? = nil,
        onDrill: @escaping () -> Void
    ) {
        self.title = title
        self.detail = detail
        self.severity = severity
        self.drillTitle = drillTitle
        self.spot = spot
        self.onDrill = onDrill
    }

    var body: some View {
        GlassCard(cornerRadius: AppRadius.card) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text(title)
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    severityChip
                }
                Text(detail)
                    .font(AppTypography.subheadline)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let spot {
                    PokerTableView(snapshot: .from(spot: spot), size: .compact)
                        .frame(maxWidth: 200)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                severityBar
                Button(action: onDrill) {
                    HStack(spacing: AppSpacing.xxs) {
                        Text(drillTitle)
                            .font(AppTypography.subheadline)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(AppColors.primaryMint)
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Leak: \(title). \(detail). Severity \(severityWord).")
        .accessibilityAction(named: drillTitle, onDrill)
    }

    private var severityChip: some View {
        Text(severityWord)
            .font(AppTypography.caption)
            .foregroundStyle(severityColor)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, 4)
            .background(Capsule().fill(severityColor.opacity(0.12)))
    }

    private var severityBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(AppColors.divider).frame(height: 6)
                Capsule()
                    .fill(LinearGradient(
                        colors: [AppColors.accentGreen, AppColors.accentLime, AppColors.accentCoral],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: max(8, geo.size.width * severity.clamped01), height: 6)
            }
        }
        .frame(height: 6)
    }

    private var severityColor: Color {
        switch severity {
        case ..<0.34: return AppColors.accentGreen
        case ..<0.67: return AppColors.accentLime
        default:      return AppColors.accentCoral
        }
    }

    private var severityWord: String {
        switch severity {
        case ..<0.34: return "Mild"
        case ..<0.67: return "Moderate"
        default:      return "Major"
        }
    }
}

extension LeakCard {
    /// Convenience initializer for `Leak` rows produced by `LeakAnalyzer`.
    /// Renders the suggested drill spot as a compact table diagram when present.
    init(leak: Leak, onDrill: @escaping () -> Void = {}) {
        let spot = leak.suggestedSpot.map { suggestion in
            TrainingSpot(
                position: suggestion.position,
                stackDepthBB: suggestion.depthBB,
                facingAction: suggestion.facingAction,
                anteType: .bigBlindAnte,
                tableSize: 9
            )
        }
        self.init(
            title: leak.title,
            detail: leak.detail,
            severity: leak.severity,
            drillTitle: "Drill this",
            spot: spot,
            onDrill: onDrill
        )
    }
}

private extension Double {
    var clamped01: Double { Swift.min(1, Swift.max(0, self)) }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: AppSpacing.sm) {
            LeakCard(title: "Too loose UTG", detail: "Opening too many suited offsuits from early position at 9-max.", severity: 0.8, onDrill: {})
            LeakCard(title: "Overfolding BB", detail: "You're folding to small button opens too often.", severity: 0.4, onDrill: {})
        }
        .padding()
    }
}
