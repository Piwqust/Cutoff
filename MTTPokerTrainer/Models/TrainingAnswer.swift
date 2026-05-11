import Foundation

/// Outcome category awarded to a single answer.
enum AnswerOutcome: String, Codable, Hashable {
    case correct       // exact match
    case close         // strategically close (e.g. raise vs 3-bet on a marginal hand)
    case mistake       // wrong but not catastrophic
    case punt          // catastrophic (e.g. jamming 72o)

    var headline: String {
        switch self {
        case .correct: return "Correct"
        case .close:   return "Close"
        case .mistake: return "Mistake"
        case .punt:    return "Big mistake"
        }
    }

    var score: Int {
        switch self {
        case .correct: return 100
        case .close:   return 70
        case .mistake: return 30
        case .punt:    return 0
        }
    }
}

struct TrainingAnswer: Hashable {
    let combo: HandCombo
    let spot: TrainingSpot
    let userAction: RangeAction
    let correctAction: RangeAction
    let outcome: AnswerOutcome
    let timestamp: Date
}
