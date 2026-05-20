import Foundation

/// Hand-strength buckets used to group mistakes and to drive the strategic-context
/// templates in `MistakeExplainer`. Derived purely from the combo's notation.
enum HandClass: String, CaseIterable, Identifiable, Hashable, Codable {
    case premiumPair        // QQ+
    case midPair            // 88–JJ
    case smallPair          // 22–77
    case suitedAce          // Axs
    case offsuitAce         // Axo
    case suitedBroadway     // KQs, KJs, KTs, QJs, QTs, JTs
    case offsuitBroadway    // KQo, KJo, KTo, QJo, QTo, JTo
    case suitedKing         // K9s and below (already excludes broadway)
    case suitedQueen        // Q9s and below
    case suitedConnector    // 0-gap suited like T9s..54s
    case suitedGapper       // 1–2 gap suited like J9s, 86s
    case offsuitJunk        // everything else

    var id: String { rawValue }

    /// Coarser family axis used as the explanation-template key.
    enum Family: String, Hashable {
        case pair
        case ace
        case broadway
        case suitedConnector
        case suitedOther
        case junk
    }

    var family: Family {
        switch self {
        case .premiumPair, .midPair, .smallPair:        return .pair
        case .suitedAce, .offsuitAce:                   return .ace
        case .suitedBroadway, .offsuitBroadway:         return .broadway
        case .suitedConnector, .suitedGapper:           return .suitedConnector
        case .suitedKing, .suitedQueen:                 return .suitedOther
        case .offsuitJunk:                              return .junk
        }
    }

    var displayName: String {
        switch self {
        case .premiumPair:      return "Premium pairs"
        case .midPair:          return "Mid pairs"
        case .smallPair:        return "Small pairs"
        case .suitedAce:        return "Suited aces"
        case .offsuitAce:       return "Offsuit aces"
        case .suitedBroadway:   return "Suited broadway"
        case .offsuitBroadway:  return "Offsuit broadway"
        case .suitedKing:       return "Suited kings"
        case .suitedQueen:      return "Suited queens"
        case .suitedConnector:  return "Suited connectors"
        case .suitedGapper:     return "Suited gappers"
        case .offsuitJunk:      return "Offsuit junk"
        }
    }

    var systemImage: String {
        switch self {
        case .premiumPair, .midPair, .smallPair:    return "rectangle.stack.fill"
        case .suitedAce, .offsuitAce:               return "a.circle.fill"
        case .suitedBroadway, .offsuitBroadway:     return "crown.fill"
        case .suitedKing, .suitedQueen:             return "k.circle.fill"
        case .suitedConnector, .suitedGapper:       return "link"
        case .offsuitJunk:                          return "questionmark.diamond"
        }
    }

    /// Classify a `HandCombo` into a `HandClass`.
    static func of(_ combo: HandCombo) -> HandClass {
        switch combo.category {
        case .pair:
            switch combo.highRank {
            case .queen, .king, .ace:                return .premiumPair
            case .eight, .nine, .ten, .jack:         return .midPair
            default:                                 return .smallPair
            }
        case .suited:
            if combo.highRank == .ace { return .suitedAce }
            let hi = combo.highRank, lo = combo.lowRank
            if isBroadway(hi: hi, lo: lo) { return .suitedBroadway }
            let gap = hi.sortValue - lo.sortValue
            if gap == 1 { return .suitedConnector }
            if gap == 2 || gap == 3 { return .suitedGapper }
            if hi == .king { return .suitedKing }
            if hi == .queen { return .suitedQueen }
            return .suitedGapper
        case .offsuit:
            if combo.highRank == .ace { return .offsuitAce }
            if isBroadway(hi: combo.highRank, lo: combo.lowRank) { return .offsuitBroadway }
            return .offsuitJunk
        }
    }

    private static func isBroadway(hi: HandCombo.Rank, lo: HandCombo.Rank) -> Bool {
        let broadway: Set<HandCombo.Rank> = [.ten, .jack, .queen, .king, .ace]
        return broadway.contains(hi) && broadway.contains(lo)
    }
}
