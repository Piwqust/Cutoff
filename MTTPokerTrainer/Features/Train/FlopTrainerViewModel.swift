import Foundation

@MainActor
@Observable
final class FlopTrainerViewModel {
    private(set) var pack: PostflopChartPack?
    private(set) var currentSpot: PostflopSpot?

    var totalAnswered: Int = 0
    var totalScore: Int = 0
    var lastResult: FlopAnswerResult?
    var selectedScenarioFilter: PreflopScenario? = nil
    var selectedTextureFilter: BoardTextureClass? = nil

    private let loader: PostflopLoader

    init(loader: PostflopLoader = .init()) {
        self.loader = loader
    }

    func load() {
        guard pack == nil else { return }
        pack = try? loader.loadPack()
        nextSpot()
    }

    /// Pick a random spot matching active filters.
    func nextSpot() {
        guard let pack else { return }
        let pool = pack.spots.filter { spot in
            (selectedScenarioFilter == nil || spot.scenario == selectedScenarioFilter)
                && (selectedTextureFilter == nil || spot.textureClass == selectedTextureFilter)
        }
        currentSpot = pool.randomElement() ?? pack.spots.randomElement()
        lastResult = nil
    }

    /// Submit the user's answer and score it. The answer is "correct" if it
    /// matches the highest-frequency action in the solution; "close" if it's
    /// within 50% of the top action's frequency; otherwise "mistake".
    func submit(action: PostflopAction) {
        guard let spot = currentSpot else { return }
        let key = action.rawValue
        let chosenFreq = spot.solution[key] ?? 0
        let bestFreq = spot.solution.values.max() ?? 0
        let outcome: AnswerOutcome
        if chosenFreq == bestFreq && bestFreq > 0 {
            outcome = .correct
        } else if chosenFreq >= bestFreq * 0.5 && chosenFreq > 0 {
            outcome = .close
        } else if chosenFreq > 0 {
            outcome = .mistake
        } else {
            outcome = .punt
        }
        let result = FlopAnswerResult(
            spot: spot,
            chosen: action,
            chosenFrequency: chosenFreq,
            bestAction: bestAction(of: spot),
            bestFrequency: bestFreq,
            outcome: outcome
        )
        lastResult = result
        totalAnswered += 1
        totalScore += outcome.score
    }

    private func bestAction(of spot: PostflopSpot) -> PostflopAction {
        let best = spot.solution.max(by: { $0.value < $1.value })?.key ?? "check"
        return PostflopAction(rawValue: best) ?? .check
    }

    // MARK: - Filters

    func setScenario(_ scenario: PreflopScenario?) {
        selectedScenarioFilter = scenario
        nextSpot()
    }

    func setTexture(_ texture: BoardTextureClass?) {
        selectedTextureFilter = texture
        nextSpot()
    }

    var accuracy: Int {
        guard totalAnswered > 0 else { return 0 }
        return Int(round(Double(totalScore) / Double(totalAnswered)))
    }
}

struct FlopAnswerResult {
    let spot: PostflopSpot
    let chosen: PostflopAction
    let chosenFrequency: Double
    let bestAction: PostflopAction
    let bestFrequency: Double
    let outcome: AnswerOutcome
}
