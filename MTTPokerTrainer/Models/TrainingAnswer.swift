import Foundation

/// Outcome category awarded to a single answer.
enum AnswerOutcome: String, Codable, Hashable {
    case correct       // dominant action
    case close         // mixed-strategy neighbor (action with non-trivial weight)
    case mistake       // present but rare, or far from dominant action
    case punt          // freq 0 and aggression-tier-far from dominant

    var headline: String {
        switch self {
        case .correct: return "Correct"
        case .close:   return "Almost"
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
    let userAction: PreflopAction
    let correctAction: PreflopAction
    let outcome: AnswerOutcome
    let timestamp: Date
}
