import XCTest

@testable import MTTPokerTrainer

final class PostflopLoaderTests: XCTestCase {
    private var appBundle: Bundle { Bundle(for: QuizResult.self) }

    func test_flopLibrary_loadsAndCoversAllTextures() throws {
        let loader = PostflopLoader(bundle: appBundle)
        let pack = try loader.loadPack()
        XCTAssertEqual(pack.format, "NLHE_MTT_FLOP_PACK")
        XCTAssertFalse(pack.spots.isEmpty)
        let textures = Set(pack.spots.map(\.textureClass))
        XCTAssertEqual(textures.count, BoardTextureClass.allCases.count,
                       "Expected coverage for every BoardTextureClass.")
    }

    func test_flopLibrary_solutionFrequenciesSumApproximatelyToOne() throws {
        let loader = PostflopLoader(bundle: appBundle)
        let pack = try loader.loadPack()
        for spot in pack.spots {
            let total = spot.solution.values.reduce(0, +)
            XCTAssertEqual(total, 1.0, accuracy: 0.01, "Spot \(spot.id) solution sums to \(total)")
        }
    }
}
