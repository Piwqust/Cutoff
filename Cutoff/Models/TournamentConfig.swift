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

    /// Default profile: 8-max MTT, 25,000 stack at 100/200 = 125 BB.
    /// 8-max is the industry-standard format for modern MTT solver libraries
    /// (RangeConverter, GTO Wizard, DTO, etc.); 9-max charts are derived by
    /// adaptation from the 8-max baseline.
    static let `default` = TournamentConfig(
        startingStack: 25_000,
        smallBlind: 100,
        bigBlind: 200,
        tableSize: 8,
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
