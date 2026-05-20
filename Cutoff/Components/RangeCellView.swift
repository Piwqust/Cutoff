import SwiftUI

struct RangeCellView: View {
    let combo: HandCombo
    let frequencies: HandFrequencies
    var isHighlighted: Bool = false

    var body: some View {
        let dominant = frequencies.dominantAction
        let weight = frequencies[dominant]
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(dominant.tint.opacity(dominant == .fold ? 0.35 : max(0.4, 0.4 + 0.6 * weight)))
            Text(combo.notation)
                // Fixed size: 13×13 grid cells are tiny and won't accommodate
                // Dynamic Type growth. `minimumScaleFactor` below handles the
                // long "AKo" / "QJs" cases at large container scales.
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(dominant.prefersDarkForeground ? AppColors.backgroundDeep : AppColors.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .padding(.horizontal, 1)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(isHighlighted ? AppColors.primaryMint : .clear, lineWidth: 2)
        )
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("\(combo.notation): \(dominant.displayName)\(frequencies.isMixed ? ", mixed" : "")")
    }
}

#Preview {
    ZStack {
        AppBackground()
        HStack(spacing: 2) {
            RangeCellView(combo: HandCombo.parse("AA")!, frequencies: HandFrequencies([.minRaise: 1.0]))
            RangeCellView(combo: HandCombo.parse("AKs")!, frequencies: HandFrequencies([.raise3x: 0.6, .call: 0.4]))
            RangeCellView(combo: HandCombo.parse("72o")!, frequencies: HandFrequencies([.fold: 1.0]))
            RangeCellView(combo: HandCombo.parse("88")!, frequencies: HandFrequencies([.shove: 1.0]), isHighlighted: true)
        }
        .frame(width: 240)
    }
}
