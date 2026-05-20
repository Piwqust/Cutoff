import Foundation
import SwiftData

@Model
final class TrainingSession {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var modeRaw: String       // TrainingMode.rawValue
    var handsAnswered: Int
    var totalScore: Int

    init(mode: TrainingMode) {
        self.id = UUID()
        self.startedAt = .now
        self.endedAt = nil
        self.modeRaw = mode.rawValue
        self.handsAnswered = 0
        self.totalScore = 0
    }

    var mode: TrainingMode { TrainingMode(rawValue: modeRaw) ?? .preflop }
    var averageScore: Double {
        handsAnswered == 0 ? 0 : Double(totalScore) / Double(handsAnswered)
    }
}
