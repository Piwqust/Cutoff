import SwiftUI

/// Single playing card rendered with rank + SF Symbol suit.
///
/// No third-party card images. Red suits use `actionRaise`-warm and black
/// suits use `textPrimary` — neutral mint/teal palette to keep the look away
/// from casino visuals (no slot-machine red/black).
struct CardView: View {
    let card: Card
    var size: Size = .regular

    enum Size {
        case regular, compact, inline
        var width: CGFloat {
            switch self {
            case .regular: return 56
            case .compact: return 38
            case .inline: return 22
            }
        }
        var height: CGFloat {
            switch self {
            case .regular: return 76
            case .compact: return 52
            case .inline: return 32
            }
        }
        var rankSize: CGFloat {
            switch self {
            case .regular: return 22
            case .compact: return 14
            case .inline: return 11
            }
        }
        var suitSize: CGFloat {
            switch self {
            case .regular: return 20
            case .compact: return 12
            case .inline: return 9
            }
        }
    }

    private var foreground: Color {
        card.suit.isRed ? AppColors.accentCoral : AppColors.textPrimary
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .fill(AppColors.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                        .strokeBorder(AppColors.divider.opacity(0.6), lineWidth: 1)
                )
            VStack(spacing: 2) {
                Text(card.rank.rawValue)
                    .font(.system(size: size.rankSize, weight: .bold, design: .rounded))
                    .foregroundStyle(foreground)
                Image(systemName: card.suit.sfSymbol)
                    .font(.system(size: size.suitSize, weight: .semibold))
                    .foregroundStyle(foreground)
            }
        }
        .frame(width: size.width, height: size.height)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        "\(card.rank.rawValue) of \(card.suit)"
    }
}

#Preview {
    ZStack {
        AppBackground()
        HStack(spacing: AppSpacing.xs) {
            CardView(card: Card(notation: "Ah")!)
            CardView(card: Card(notation: "Kd")!)
            CardView(card: Card(notation: "Qs")!)
            CardView(card: Card(notation: "Jc")!)
        }
    }
}
