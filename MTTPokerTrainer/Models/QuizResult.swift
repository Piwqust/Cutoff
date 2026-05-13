import Foundation
import SwiftData

/// Per-answer SwiftData record. Used to build aggregated stats and the Review tab.
@Model
final class QuizResult {
    @Attribute(.unique) var id: UUID
    var createdAt: Date

    var combo: String           // e.g. "AKs"
    var positionRaw: String     // TablePosition.rawValue
    var stackDepthBB: Int
    var facingActionRaw: String // FacingAction.rawValue
    var anteTypeRaw: String     // AnteType.rawValue
    var rangeChartID: String

    var userActionRaw: String
    var correctActionRaw: String
    var outcomeRaw: String
    var score: Int

    init(
        combo: String,
        position: TablePosition,
        stackDepthBB: Int,
        facingAction: FacingAction,
        anteType: AnteType,
        rangeChartID: String,
        userAction: PreflopAction,
        correctAction: PreflopAction,
        outcome: AnswerOutcome
    ) {
        self.id = UUID()
        self.createdAt = .now
        self.combo = combo
        self.positionRaw = position.rawValue
        self.stackDepthBB = stackDepthBB
        self.facingActionRaw = facingAction.rawValue
        self.anteTypeRaw = anteType.rawValue
        self.rangeChartID = rangeChartID
        self.userActionRaw = userAction.rawValue
        self.correctActionRaw = correctAction.rawValue
        self.outcomeRaw = outcome.rawValue
        self.score = outcome.score
    }

    var position: TablePosition { TablePosition(rawValue: positionRaw) ?? .utg }
    var facingAction: FacingAction { FacingAction(rawValue: facingActionRaw) ?? .rfi }
    var outcome: AnswerOutcome { AnswerOutcome(rawValue: outcomeRaw) ?? .mistake }
    var userAction: PreflopAction { PreflopAction(rawValue: userActionRaw) ?? .fold }
    var correctAction: PreflopAction { PreflopAction(rawValue: correctActionRaw) ?? .fold }
}
