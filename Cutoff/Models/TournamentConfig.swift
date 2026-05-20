import Foundation

struct TournamentConfig: Codable, Hashable {
    var startingStack: Int
    var smallBlind: Int
    var bigBlind: Int
    var tableSize: Int
    var blindLevelDuration: BlindLevelDuration
    var anteType: AnteType
    var currentHeroStack: Int?
    var averageStack: Int?
    var playerLevel: PlayerLevel

    /// Default profile: 9-max MTT, 25,000 stack at 100/200 = 125 BB.
    static let `default` = TournamentConfig(
        startingStack: 25_000,
        smallBlind: 100,
        bigBlind: 200,
        tableSize: 9,
        blindLevelDuration: .fifteen,
        anteType: .unknown,
        currentHeroStack: nil,
        averageStack: nil,
        playerLevel: .amateur
    )

    /// Big-blind count at the start of the tournament.
    var startingBB: Int {
        BBCalculator.bb(stack: startingStack, bigBlind: bigBlind)
    }

    /// Big-blind count for the user's current stack, if set.
    var currentBB: Int? {
        guard let currentHeroStack else { return nil }
        return BBCalculator.bb(stack: currentHeroStack, bigBlind: bigBlind)
    }
}
