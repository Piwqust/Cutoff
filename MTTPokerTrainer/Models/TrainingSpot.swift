import Foundation

enum FacingAction: String, Codable, CaseIterable, Identifiable, Hashable {
    case unopened      // first in
    case vsOpen        // facing an opener
    case vs3Bet        // facing a 3-bet
    case blindDefense  // BB defending vs an open
    case squeeze       // facing open + caller
    case pushFold      // short-stack push/fold spot

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .unopened:     return "Unopened"
        case .vsOpen:       return "vs Open"
        case .vs3Bet:       return "vs 3-bet"
        case .blindDefense: return "Blind Defense"
        case .squeeze:      return "Squeeze"
        case .pushFold:     return "Push/Fold"
        }
    }
}

struct TrainingSpot: Hashable, Codable, Identifiable {
    var id: String { "\(position.rawValue)_\(stackDepthBB)_\(facingAction.rawValue)" }
    let position: TablePosition
    let stackDepthBB: Int
    let facingAction: FacingAction
    let anteType: AnteType
    let tableSize: Int

    var summary: String {
        "\(position.displayName) · \(stackDepthBB) BB · \(facingAction.displayName)"
    }
}
