import SwiftUI

/// Renders a combo notation like "K2s+" as a small white badge inline
struct ComboView: View {
    let combo: String
    var size: CardView.Size = .regular

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.3), radius: 2, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.2), lineWidth: 1)
                )
            
            Text(combo)
                .font(.system(size: size.rankSize + 1, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black)
                .padding(.horizontal, 4)
        }
        // Make width dynamic based on content, but ensure min width is same as a card
        .frame(minWidth: size.width, idealHeight: size.height, maxHeight: size.height)
        .fixedSize(horizontal: true, vertical: true)
        .accessibilityLabel("\(combo) combo")
    }
}

#Preview {
    ZStack {
        AppBackground()
        HStack {
            ComboView(combo: "K2s+", size: .inline)
            ComboView(combo: "AA", size: .inline)
        }
    }
}
