import SwiftUI

/// 13×13 hand matrix laid out edge-to-edge in the parent's width.
struct RangeGridView: View {
    let chart: RangeChart?
    @Binding var activePayload: RangeDetailPayload?

    private let cols = Array(repeating: GridItem(.flexible(), spacing: 2), count: 13)

    var body: some View {
        LazyVGrid(columns: cols, spacing: 2) {
            ForEach(HandCombo.allInMatrixOrder, id: \.notation) { combo in
                let freqs: HandFrequencies = chart?.frequencies(for: combo) ?? HandFrequencies([.fold: 1.0])
                Button {
                    if let chart = chart {
                        activePayload = RangeDetailPayload(combo: combo, frequencies: freqs, chart: chart)
                    }
                } label: {
                    RangeCellView(combo: combo, frequencies: freqs)
                }
                .buttonStyle(.plain)
                .popover(isPresented: Binding(
                    get: { activePayload?.combo == combo },
                    set: { if !$0 && activePayload?.combo == combo { activePayload = nil } }
                )) {
                    if let payload = activePayload, payload.combo == combo {
                        RangeDetailSheet(payload: payload)
                            .presentationCompactAdaptation(.popover)
                    }
                }
            }
        }
    }
}

struct RangeLegendView: View {
    private let legendActions: [PreflopAction] = [.fold, .call, .minRaise, .raise25x, .raise3x, .shove]

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(legendActions, id: \.self) { action in
                HStack(spacing: 4) {
                    Circle().fill(action.tint).frame(width: 10, height: 10)
                    Text(action.shortLabel)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: AppSpacing.md) {
            RangeGridView(chart: nil, activePayload: .constant(nil))
                .padding(.horizontal, AppSpacing.pageHorizontal)
            RangeLegendView()
        }
    }
}
