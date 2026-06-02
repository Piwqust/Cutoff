import SwiftUI

/// Renders a combo notation like "K2s+" with overlapping mini cards and a category badge
struct ComboView: View {
    let combo: String
    var size: CardView.Size = .regular

    var body: some View {
        let cleanStr = combo.replacingOccurrences(of: "+", with: "")
        let hasPlus = combo.hasSuffix("+")
        let parsed = HandCombo.parse(cleanStr)
        
        if let comboParsed = parsed {
            HStack(spacing: 2) {
                // The two ranks overlapping
                HStack(spacing: -6) {
                    rankCard(comboParsed.highRank.rawValue)
                    rankCard(comboParsed.lowRank.rawValue)
                }
                
                // The modifier badge
                let modifier = (comboParsed.category == .suited ? "s" : (comboParsed.category == .offsuit ? "o" : "")) + (hasPlus ? "+" : "")
                if !modifier.isEmpty {
                    Text(modifier)
                        .font(.system(size: size.rankSize + 1, weight: .bold, design: .rounded))
                        .foregroundStyle(categoryColor(comboParsed.category))
                }
            }
            .fixedSize(horizontal: true, vertical: true)
            .accessibilityLabel("\(combo) combo")
        } else {
            // Fallback to text
            Text(combo)
                .font(.system(size: size.rankSize + 1, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
        }
    }
    
    @ViewBuilder
    private func rankCard(_ rank: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.3), radius: 1, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.2), lineWidth: 0.5)
                )
            Text(rank)
                .font(.system(size: size.rankSize + 1, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black)
        }
        .frame(width: size.height * 0.8, height: size.height) // Make rank cards vertical rectangles
    }
    
    private func categoryColor(_ cat: HandCombo.Category) -> Color {
        switch cat {
        case .pair: return AppColors.primaryMint
        case .suited: return AppColors.accentLime
        case .offsuit: return AppColors.accentPeach
        }
    }
}

#Preview {
    ZStack {
        AppBackground()
        HStack {
            ComboView(combo: "K2s+", size: .inline)
            ComboView(combo: "AA", size: .inline)
            ComboView(combo: "A3o+", size: .inline)
            ComboView(combo: "22+", size: .inline)
        }
    }
}
