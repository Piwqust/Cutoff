import XCTest
@testable import Cutoff

/// Covers the parsing/localization helpers on `StrategyChapter` that the
/// Strategy detail view relies on to split the 📖 hand example into its own
/// card and to render localized category tags.
final class StrategyModelTests: XCTestCase {

    private var activeGuide: WeeklyGuide { StrategyStore.activeGuide }
    private var archiveGuide: WeeklyGuide { StrategyStore.allGuides.last! }

    private func chapter(_ id: Int, in guide: WeeklyGuide) -> StrategyChapter {
        guide.chapters.first { $0.id == id }!
    }

    // MARK: - whyScenario

    func test_whyScenario_splitsTitleAndBody_withoutMarker() {
        // Pot-odds chapter (id 5) ships a 📖 worked example in every register.
        let ch = chapter(5, in: activeGuide)
        let scenario = ch.whyScenario(for: .russian)

        XCTAssertNotNil(scenario)
        XCTAssertFalse(scenario!.title.contains("📖"), "Title must not carry the marker")
        XCTAssertFalse(scenario!.title.hasSuffix(":"), "Trailing colon should be trimmed")
        XCTAssertFalse(scenario!.body.isEmpty)
        XCTAssertFalse(scenario!.body.contains("📖"))
    }

    func test_whyReason_excludesScenario() {
        let ch = chapter(5, in: activeGuide)
        let reason = ch.whyReason(for: .russian)

        XCTAssertFalse(reason.contains("📖"))
        XCTAssertFalse(reason.isEmpty)
        // The reason is strictly shorter than the full why (scenario removed).
        XCTAssertLessThan(reason.count, ch.why(for: .russian).count)
    }

    func test_whyScenario_nilWhenNoExample() {
        // Archive-week chapters have no 📖 scenario.
        let ch = chapter(1, in: archiveGuide)
        XCTAssertNil(ch.whyScenario(for: .russian))
        XCTAssertEqual(ch.whyReason(for: .russian), ch.why(for: .russian))
    }

    // MARK: - localizedTag

    func test_localizedTag_translatesForRussian() {
        let preflop = chapter(1, in: activeGuide) // tag == "Preflop"
        XCTAssertEqual(preflop.localizedTag(for: .russian), "Префлоп")
        XCTAssertEqual(preflop.localizedTag(for: .russianGenZ), "Префлоп")
    }

    func test_localizedTag_keepsCanonicalEnglish() {
        let preflop = chapter(1, in: activeGuide)
        XCTAssertEqual(preflop.localizedTag(for: .english), "Preflop")
    }

    // MARK: - RangeParser handles the (wider) Nash jam shorthand

    func test_rangeParser_offsuitPlusExpands() {
        let aces = RangeParser.parse("A2o+")
        XCTAssertTrue(aces.contains("A2o"))
        XCTAssertTrue(aces.contains("ATo"))
        XCTAssertTrue(aces.contains("AKo"))
        XCTAssertFalse(aces.contains("AA"))   // "+" on offsuit must not pull in the pair
        XCTAssertFalse(aces.contains("A2s"))
        XCTAssertEqual(aces.count, 12)         // A2o..AKo
    }

    func test_rangeParser_singleCombosParse() {
        // Tokens newly used by the Nash ranges: lone offsuit + lone suited.
        XCTAssertEqual(RangeParser.parse("76o, T9o, 54s"), ["76o", "T9o", "54s"])
    }

    func test_rangeParser_wideSBJamCoverage() {
        // The 12bb SB Nash jam is ~72% — confirm nothing is silently dropped.
        let sb = "22+, A2s+, A2o+, K2s+, K2o+, Q2s+, Q2o+, J2s+, J5o+, T2s+, T6o+, 93s+, 96o+, 84s+, 86o+, 74s+, 76o, 63s+, 65o, 53s+, 43s"
        let parsed = RangeParser.parse(sb)
        XCTAssertGreaterThan(parsed.count, 100) // ~72% of the 169 hand classes
        for hand in ["AA", "A2o", "K2o", "Q2o", "43s", "65o"] {
            XCTAssertTrue(parsed.contains(hand), "Wide SB jam should contain \(hand)")
        }
    }
}
