import SwiftUI

struct RangeCellView: View {
    let combo: HandCombo
    let frequencies: HandFrequencies
    var isHighlighted: Bool = false

    var body: some View {
        let dominant = frequencies.dominantAction
        let actions = PreflopAction.allCases.sorted { $0.aggressionTier > $1.aggressionTier }
        
        ZStack {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(actions, id: \.self) { action in
                        let w = frequencies[action]
                        if w > 0 {
                            action.tint
                                .frame(width: geo.size.width * w)
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            
            Text(combo.notation)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(frequencies.isMixed ? Color.white : (dominant.prefersDarkForeground ? AppColors.backgroundDeep : AppColors.textPrimary))
                .padding(.horizontal, frequencies.isMixed ? 2.5 : 0)
                .padding(.vertical, frequencies.isMixed ? 1.0 : 0)
                .background(frequencies.isMixed ? Capsule().fill(Color.black.opacity(0.45)) : Capsule().fill(Color.clear))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
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
