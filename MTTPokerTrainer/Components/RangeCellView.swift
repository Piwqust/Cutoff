import SwiftUI

struct RangeCellView: View {
    let combo: HandCombo
    let action: RangeAction
    var isHighlighted: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(action.tint.opacity(action == .fold ? 0.35 : 0.9))
            Text(combo.notation)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(action.prefersDarkForeground ? AppColors.backgroundDeep : AppColors.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .padding(.horizontal, 1)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(isHighlighted ? AppColors.primaryMint : .clear, lineWidth: 2)
        )
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("\(combo.notation): \(action.displayName)")
    }
}

#Preview {
    ZStack {
        AppBackground()
        HStack(spacing: 2) {
            RangeCellView(combo: HandCombo.parse("AA")!, action: .raise)
            RangeCellView(combo: HandCombo.parse("AKs")!, action: .threeBet)
            RangeCellView(combo: HandCombo.parse("72o")!, action: .fold)
            RangeCellView(combo: HandCombo.parse("88")!, action: .jam, isHighlighted: true)
        }
        .frame(width: 240)
    }
}
