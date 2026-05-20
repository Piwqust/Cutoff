import SwiftUI

/// Pure-SwiftUI rendering of a single playing card. No external imagery.
/// Two card sizes:
///  - `.hero` for the preflop trainer (the user reads the card)
///  - `.compact` for context strips and Range Grid detail sheets
struct PlayingCardView: View {
    enum Suit: String, CaseIterable {
        case spade = "♠", heart = "♥", diamond = "♦", club = "♣"
        // Cards have a white face, so ink must be dark. Spades/clubs use a
        // near-black; hearts/diamonds use a warm peach (instead of casino red).
        var color: Color {
            switch self {
            case .spade, .club:    return Color(red: 0.08, green: 0.10, blue: 0.10)
            case .heart, .diamond: return Color(red: 0.85, green: 0.35, blue: 0.30)
            }
        }
        var symbol: String { rawValue }
    }

    enum Size {
        case hero, compact
        var dimensions: CGSize {
            switch self {
            case .hero: return CGSize(width: 110, height: 156)
            case .compact: return CGSize(width: 56, height: 80)
            }
        }
        var rankFont: Font {
            switch self {
            case .hero: return .system(size: 44, weight: .bold, design: .rounded)
            case .compact: return .system(size: 22, weight: .bold, design: .rounded)
            }
        }
        var suitFont: Font {
            switch self {
            case .hero: return .system(size: 28, weight: .bold)
            case .compact: return .system(size: 14, weight: .bold)
            }
        }
    }

    let rank: String
    let suit: Suit
    var size: Size = .hero

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color.white.opacity(0.97), Color.white.opacity(0.90)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(AppColors.divider.opacity(0.5), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 14, x: 0, y: 8)

            // Top-left rank + suit only. The mirrored bottom-right indicia
            // are intentionally omitted — the spot card design relies on
            // clean card faces, not the traditional double-corner motif.
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rank)
                            .font(size.rankFont)
                            .foregroundStyle(suit.color)
                        Text(suit.symbol)
                            .font(size.suitFont)
                            .foregroundStyle(suit.color)
                    }
                    Spacer()
                }
                Spacer()
            }
            .padding(size == .hero ? 14 : 8)
        }
        .frame(width: size.dimensions.width, height: size.dimensions.height)
        .accessibilityLabel("\(rank) of \(suit.accessibilityName)")
    }
}

private extension PlayingCardView.Suit {
    var accessibilityName: String {
        switch self {
        case .spade: return "spades"
        case .heart: return "hearts"
        case .diamond: return "diamonds"
        case .club: return "clubs"
        }
    }
}

/// Two-card hero display (the user's hole cards). Renders the canonical
/// "A K suited" / "A K offsuit" form for a hand combo.
struct HandCardView: View {
    /// Hand string in poker notation: "AA", "AKs", "AKo", "72o".
    let hand: String
    var size: PlayingCardView.Size = .hero

    var body: some View {
        let (left, right) = cardsForHand(hand)
        HStack(spacing: -16) {
            PlayingCardView(rank: left.rank, suit: left.suit, size: size)
                .rotationEffect(.degrees(-6))
                .zIndex(1)
            PlayingCardView(rank: right.rank, suit: right.suit, size: size)
                .rotationEffect(.degrees(6))
                .offset(y: 4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Hero hand: \(handAccessibilityDescription(hand))")
    }

    private func cardsForHand(_ hand: String) -> (left: (rank: String, suit: PlayingCardView.Suit), right: (rank: String, suit: PlayingCardView.Suit)) {
        guard hand.count >= 2 else {
            return (("?", .spade), ("?", .heart))
        }
        let rank1 = String(hand.first!)
        let rank2 = String(hand.dropFirst().first!)
        if hand.count == 2 {
            // pair like "AA" — use two different suits
            return ((rank1, .spade), (rank2, .heart))
        }
        let suited = hand.hasSuffix("s")
        if suited {
            return ((rank1, .spade), (rank2, .spade))
        } else {
            return ((rank1, .spade), (rank2, .heart))
        }
    }

    private func handAccessibilityDescription(_ hand: String) -> String {
        guard hand.count >= 2 else { return hand }
        let rank1 = String(hand.first!)
        let rank2 = String(hand.dropFirst().first!)
        if hand.count == 2 { return "Pocket \(rank1)s" }
        let modifier = hand.hasSuffix("s") ? "suited" : "offsuit"
        return "\(rank1) \(rank2) \(modifier)"
    }
}

#Preview {
    ZStack {
        AppBackground()
        VStack(spacing: AppSpacing.lg) {
            HandCardView(hand: "AKs")
            HandCardView(hand: "QQ", size: .compact)
            HandCardView(hand: "72o", size: .compact)
        }
    }
}
