import XCTest
@testable import MTTPokerTrainer

final class PostflopLoaderTests: XCTestCase {
    private var appBundle: Bundle { Bundle(for: QuizResult.self) }

    func test_loadsAllBundledSpots() throws {
        let spots = try PostflopLoader(bundle: appBundle).loadAll()
        XCTAssertGreaterThanOrEqual(spots.count, 30, "Expected the 30-spot seed set, found \(spots.count)")
    }

    func test_everySpotHasAtLeastOneNonZeroCorrectAction() throws {
        let spots = try PostflopLoader(bundle: appBundle).loadAll()
        for spot in spots {
            let total = spot.correctActions.values.reduce(0, +)
            XCTAssertGreaterThan(total, 0, "Spot \(spot.id) has no correct actions defined")
        }
    }

    func test_everySpotIsDemoLabeled() throws {
        let spots = try PostflopLoader(bundle: appBundle).loadAll()
        for spot in spots {
            XCTAssertEqual(spot.source.type, .demo)
            XCTAssertTrue(spot.source.description.lowercased().contains("not solver-verified"))
        }
    }

    func test_seedCoversEveryBoardTexture() throws {
        let spots = try PostflopLoader(bundle: appBundle).loadAll()
        let textures = Set(spots.map(\.boardTexture))
        for texture in BoardTexture.allCases {
            XCTAssertTrue(textures.contains(texture), "Seed missing texture \(texture.rawValue)")
        }
    }

    func test_seedReachesEveryPostflopAction() throws {
        let spots = try PostflopLoader(bundle: appBundle).loadAll()
        var seen: Set<PostflopAction> = []
        for spot in spots {
            for action in PostflopAction.allCases where spot.frequency(for: action) > 0 {
                seen.insert(action)
            }
        }
        for action in PostflopAction.allCases {
            XCTAssertTrue(seen.contains(action), "PostflopAction.\(action.rawValue) is unreachable in seed data")
        }
    }
}
