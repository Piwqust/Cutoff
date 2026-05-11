import XCTest
@testable import MTTPokerTrainer

final class TournamentConfigTests: XCTestCase {
    func test_defaultIs9MaxMTTAt125BB() {
        let c = TournamentConfig.default
        XCTAssertEqual(c.startingStack, 25_000)
        XCTAssertEqual(c.smallBlind, 100)
        XCTAssertEqual(c.bigBlind, 200)
        XCTAssertEqual(c.tableSize, 9)
        XCTAssertEqual(c.startingBB, 125)
        XCTAssertEqual(c.blindLevelDuration, .fifteen)
        XCTAssertEqual(c.anteType, .unknown)
    }

    func test_currentBB_isNilWhenStackUnset() {
        XCTAssertNil(TournamentConfig.default.currentBB)
    }

    func test_currentBB_computesFromHeroStack() {
        var c = TournamentConfig.default
        c.currentHeroStack = 18_000
        XCTAssertEqual(c.currentBB, 90) // 18000 / 200
    }

    func test_codableRoundTrip() throws {
        var c = TournamentConfig.default
        c.anteType = .bigBlindAnte
        c.playerLevel = .advanced
        let data = try JSONEncoder().encode(c)
        let back = try JSONDecoder().decode(TournamentConfig.self, from: data)
        XCTAssertEqual(back, c)
    }
}
