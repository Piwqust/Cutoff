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
}
