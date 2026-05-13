import Foundation
import SwiftData

@MainActor
@Observable
final class PostflopDrillViewModel {
    private(set) var spots: [PostflopSpot] = []
    private(set) var currentSpot: PostflopSpot?
    private(set) var lastOutcome: AnswerOutcome?
    private(set) var lastExplanation: String = ""
    private(set) var hasAnswered: Bool = false

    private var rng = SystemRandomNumberGenerator()
    private let loader: PostflopLoader
    var modelContext: ModelContext?

    init(loader: PostflopLoader = .init()) {
        self.loader = loader
    }

    func load() {
        if spots.isEmpty {
            spots = (try? loader.loadAll()) ?? []
        }
        next()
    }

    func next() {
        guard let spot = spots.randomElement(using: &rng) else { return }
        currentSpot = spot
        lastOutcome = nil
        lastExplanation = ""
        hasAnswered = false
    }

    var correctAction: PostflopAction {
        currentSpot?.dominantAction ?? .fold
    }

    func submit(_ userAction: PostflopAction) {
        guard !hasAnswered, let spot = currentSpot else { return }
        let outcome = PostflopScorer.evaluate(user: userAction, spot: spot)
        lastOutcome = outcome
        lastExplanation = spot.explanation
        hasAnswered = true

        if let modelContext {
            let row = PostflopResult(spotID: spot.id, userAction: userAction, outcome: outcome)
            modelContext.insert(row)
            try? modelContext.save()
        }
    }

    /// Test-only seam mirroring the preflop VM.
    func injectSpotsForTesting(_ replacement: [PostflopSpot]) {
        spots = replacement
        currentSpot = replacement.first
    }
}
