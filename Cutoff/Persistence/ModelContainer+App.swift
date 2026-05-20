import Foundation
import SwiftData

enum AppModelContainer {
    static func make() -> ModelContainer {
        let schema = Schema([QuizResult.self, TrainingSession.self, PostflopDrillSession.self, PostflopResult.self])
        let config = ModelConfiguration("Cutoff", schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Fall back to an in-memory container so the app never refuses to launch.
            let fallback = ModelConfiguration(isStoredInMemoryOnly: true)
            // swiftlint:disable:next force_try
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }
}
