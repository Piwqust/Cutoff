import Foundation

/// Language-aware display strings for the enum types whose default `displayName`
/// hard-codes English. Original `displayName` is kept as the English source so
/// SwiftData logs, analytics, and tests don't break.

extension DrillCategory {
    func title(in lang: AppLanguage) -> String {
        switch self {
        case .standardRoutine: return L10n.string(.drillStandardRoutineTitle, in: lang)
        case .firstInJam:      return L10n.string(.drillFirstInJamTitle, in: lang)
        case .reJam:           return L10n.string(.drillReJamTitle, in: lang)
        case .callJam:         return L10n.string(.drillCallJamTitle, in: lang)
        case .stealBlinds:     return L10n.string(.drillStealBlindsTitle, in: lang)
        case .vsManiac:        return L10n.string(.drillVsManiacTitle, in: lang)
        case .mixed:           return L10n.string(.drillMixedTitle, in: lang)
        }
    }

    func subtitle(in lang: AppLanguage) -> String {
        switch self {
        case .standardRoutine: return L10n.string(.drillStandardRoutineSubtitle, in: lang)
        case .firstInJam:      return L10n.string(.drillFirstInJamSubtitle, in: lang)
        case .reJam:           return L10n.string(.drillReJamSubtitle, in: lang)
        case .callJam:         return L10n.string(.drillCallJamSubtitle, in: lang)
        case .stealBlinds:     return L10n.string(.drillStealBlindsSubtitle, in: lang)
        case .vsManiac:        return L10n.string(.drillVsManiacSubtitle, in: lang)
        case .mixed:           return L10n.string(.drillMixedSubtitle, in: lang)
        }
    }
}

extension RangeAction {
    func displayName(in lang: AppLanguage) -> String {
        switch self {
        case .fold:     return L10n.string(.actionFold, in: lang)
        case .call:     return L10n.string(.actionCall, in: lang)
        case .raise:    return L10n.string(.actionRaise, in: lang)
        case .threeBet: return L10n.string(.actionThreeBet, in: lang)
        case .jam:      return L10n.string(.actionJam, in: lang)
        case .mixed:    return L10n.string(.actionMixed, in: lang)
        }
    }
}

extension PreflopAction {
    func displayName(in lang: AppLanguage) -> String {
        switch self {
        case .fold:      return L10n.string(.preflopFold, in: lang)
        case .call:      return L10n.string(.preflopCall, in: lang)
        case .minRaise:  return L10n.string(.preflopMinRaise, in: lang)
        case .raise25x:  return L10n.string(.preflopRaise25x, in: lang)
        case .raise3x:   return L10n.string(.preflopRaise3x, in: lang)
        case .shove:     return L10n.string(.preflopShove, in: lang)
        case .limp:      return L10n.string(.preflopLimp, in: lang)
        case .limpRaise: return L10n.string(.preflopLimpRaise, in: lang)
        }
    }

    func shortLabel(in lang: AppLanguage) -> String {
        // Numeric short labels (2bb / 2.5x / 3x) stay universal across languages.
        switch self {
        case .fold:      return L10n.string(.preflopFold, in: lang)
        case .call:      return L10n.string(.preflopCall, in: lang)
        case .shove:     return L10n.string(.shortJam, in: lang)
        case .limp:      return L10n.string(.preflopLimp, in: lang)
        case .limpRaise: return L10n.string(.shortLRz, in: lang)
        case .minRaise, .raise25x, .raise3x:
            return shortLabel
        }
    }
}

extension PostflopAction {
    func displayName(in lang: AppLanguage) -> String {
        switch self {
        case .check:  return L10n.string(.postActionCheck, in: lang)
        case .bet33:  return L10n.string(.postActionBet33, in: lang)
        case .bet67:  return L10n.string(.postActionBet67, in: lang)
        case .bet100: return L10n.string(.postActionBet100, in: lang)
        case .raise:  return L10n.string(.postActionRaise, in: lang)
        case .fold:   return L10n.string(.postActionFold, in: lang)
        case .call:   return L10n.string(.postActionCall, in: lang)
        case .shove:  return L10n.string(.postActionShove, in: lang)
        }
    }
}

extension FacingAction {
    func displayName(in lang: AppLanguage) -> String {
        switch self {
        case .unopened:     return L10n.string(.facingUnopened, in: lang)
        case .vsOpen:       return L10n.string(.facingVsOpen, in: lang)
        case .vs3Bet:       return L10n.string(.facingVs3Bet, in: lang)
        case .vs3BetJam:    return "\(L10n.string(.facingVs3Bet, in: lang)) jam"
        case .blindDefense: return L10n.string(.facingBlindDefense, in: lang)
        case .squeeze:      return L10n.string(.facingSqueeze, in: lang)
        case .pushFold:     return L10n.string(.facingPushFold, in: lang)
        }
    }

    func headline(in lang: AppLanguage) -> String {
        switch self {
        case .unopened:     return L10n.string(.headlineUnopened, in: lang)
        case .vsOpen:       return L10n.string(.headlineVsOpen, in: lang)
        case .vs3Bet:       return L10n.string(.headlineVs3Bet, in: lang)
        case .vs3BetJam:    return "\(L10n.string(.headlineVs3Bet, in: lang)) jam"
        case .blindDefense: return L10n.string(.headlineBlindDefense, in: lang)
        case .squeeze:      return L10n.string(.headlineSqueeze, in: lang)
        case .pushFold:     return L10n.string(.headlinePushFold, in: lang)
        }
    }
}

extension VillainType {
    func displayName(in lang: AppLanguage) -> String {
        switch self {
        case .standard: return L10n.string(.villainStandard, in: lang)
        case .loose:    return L10n.string(.villainLoose, in: lang)
        case .maniac:   return L10n.string(.villainManiac, in: lang)
        case .nit:      return L10n.string(.villainNit, in: lang)
        }
    }

    func shortNote(in lang: AppLanguage) -> String {
        switch self {
        case .standard: return L10n.string(.villainStandardNote, in: lang)
        case .loose:    return L10n.string(.villainLooseNote, in: lang)
        case .maniac:   return L10n.string(.villainManiacNote, in: lang)
        case .nit:      return L10n.string(.villainNitNote, in: lang)
        }
    }
}

extension HandClass {
    func displayName(in lang: AppLanguage) -> String {
        switch self {
        case .premiumPair:     return L10n.string(.hcPremiumPair, in: lang)
        case .midPair:         return L10n.string(.hcMidPair, in: lang)
        case .smallPair:       return L10n.string(.hcSmallPair, in: lang)
        case .suitedAce:       return L10n.string(.hcSuitedAce, in: lang)
        case .offsuitAce:      return L10n.string(.hcOffsuitAce, in: lang)
        case .suitedBroadway:  return L10n.string(.hcSuitedBroadway, in: lang)
        case .offsuitBroadway: return L10n.string(.hcOffsuitBroadway, in: lang)
        case .suitedKing:      return L10n.string(.hcSuitedKing, in: lang)
        case .suitedQueen:     return L10n.string(.hcSuitedQueen, in: lang)
        case .suitedConnector: return L10n.string(.hcSuitedConnector, in: lang)
        case .suitedGapper:    return L10n.string(.hcSuitedGapper, in: lang)
        case .offsuitJunk:     return L10n.string(.hcOffsuitJunk, in: lang)
        }
    }
}

extension BoardTexture {
    func displayName(in lang: AppLanguage) -> String {
        switch self {
        case .dryRainbow:  return L10n.string(.textureDryRainbow, in: lang)
        case .wetMonotone: return L10n.string(.textureWetMonotone, in: lang)
        case .paired:      return L10n.string(.texturePaired, in: lang)
        case .connected:   return L10n.string(.textureConnected, in: lang)
        case .broadway:    return L10n.string(.textureBroadway, in: lang)
        case .lowScatter:  return L10n.string(.textureLowScatter, in: lang)
        }
    }
}

extension AnteType {
    func displayName(in lang: AppLanguage) -> String {
        switch self {
        case .none:         return L10n.string(.anteNone, in: lang)
        case .classic:      return L10n.string(.anteClassic, in: lang)
        case .bigBlindAnte: return L10n.string(.anteBigBlind, in: lang)
        case .unknown:      return L10n.string(.anteUnknown, in: lang)
        }
    }
}

extension MistakeReason {
    func displayName(in lang: AppLanguage) -> String {
        switch self {
        case .correct:     return L10n.string(.mrCorrect, in: lang)
        case .missedMix:   return L10n.string(.mrMissedMix, in: lang)
        case .tooTight:    return L10n.string(.mrTooTight, in: lang)
        case .tooLoose:    return L10n.string(.mrTooLoose, in: lang)
        case .wrongLine:   return L10n.string(.mrWrongLine, in: lang)
        case .overcommit:  return L10n.string(.mrOvercommit, in: lang)
        case .undercommit: return L10n.string(.mrUndercommit, in: lang)
        }
    }

    func shortLabel(in lang: AppLanguage) -> String {
        switch self {
        case .correct:     return L10n.string(.mrShortCorrect, in: lang)
        case .missedMix:   return L10n.string(.mrShortMix, in: lang)
        case .tooTight:    return L10n.string(.mrShortTight, in: lang)
        case .tooLoose:    return L10n.string(.mrShortLoose, in: lang)
        case .wrongLine:   return L10n.string(.mrShortWrongLine, in: lang)
        case .overcommit:  return L10n.string(.mrShortOver, in: lang)
        case .undercommit: return L10n.string(.mrShortUnder, in: lang)
        }
    }
}

extension AnswerOutcome {
    func headline(in lang: AppLanguage) -> String {
        switch self {
        case .correct: return L10n.string(.outcomeCorrect, in: lang)
        case .close:   return L10n.string(.outcomeAlmost, in: lang)
        case .mistake: return L10n.string(.outcomeMistake, in: lang)
        case .punt:    return L10n.string(.outcomeBigMistake, in: lang)
        }
    }
}

extension ReviewAnalyzer.Scope {
    func label(in lang: AppLanguage) -> String {
        switch self {
        case .last7:  return L10n.string(.scope7d, in: lang)
        case .last30: return L10n.string(.scope30d, in: lang)
        case .all:    return L10n.string(.scopeAll, in: lang)
        }
    }
}
