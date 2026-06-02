import SwiftUI

/// Renders the 3-card flop board for the postflop drill.
struct BoardView: View {
    let board: [Card]
    var size: CardView.Size = .regular

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(board) { card in
                CardView(card: card, size: size)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Board: " + board.map { "\($0.rank.rawValue) of \($0.suit)" }.joined(separator: ", "))
    }
}

/// Renders hero's two hole cards.
struct HoleCardsView: View {
    let hand: HoleCards
    var size: CardView.Size = .regular

    var body: some View {
        let label = "Hero hand: \(hand.first.rank.rawValue) of \(hand.first.suit), \(hand.second.rank.rawValue) of \(hand.second.suit)"
        return HStack(spacing: AppSpacing.xs) {
            CardView(card: hand.first, size: size)
            CardView(card: hand.second, size: size)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: AppSpacing.lg) {
            BoardView(board: [Card(notation: "Kc")!, Card(notation: "7d")!, Card(notation: "2s")!])
            HoleCardsView(hand: HoleCards(first: Card(notation: "Ah")!, second: Card(notation: "Kd")!))
        }
    }
}
