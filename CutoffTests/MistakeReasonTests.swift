import XCTest
@testable import Cutoff

final class MistakeReasonTests: XCTestCase {

    func test_dominantAnswerIsCorrect() {
        let f: [RangeAction: Double] = [.raise: 1.0]
        XCTAssertEqual(MistakeReason.classify(userAction: .raise, frequencies: f), .correct)
    }

    func test_minorityLegOfMixIsMissedMix() {
        // 60/40 raise/call — picking call is the minority leg.
        let f: [RangeAction: Double] = [.raise: 0.6, .call: 0.4]
        XCTAssertEqual(MistakeReason.classify(userAction: .call, frequencies: f), .missedMix)
    }

    func test_foldWhenChartWantsPlayIsTooTight() {
        let f: [RangeAction: Double] = [.raise: 1.0]
        XCTAssertEqual(MistakeReason.classify(userAction: .fold, frequencies: f), .tooTight)
    }

    func test_playingWhenChartWantsFoldIsTooLoose() {
        let f: [RangeAction: Double] = [.fold: 1.0]
        XCTAssertEqual(MistakeReason.classify(userAction: .call, frequencies: f), .tooLoose)
        XCTAssertEqual(MistakeReason.classify(userAction: .raise, frequencies: f), .tooLoose)
    }

    func test_jamWhenChartWantsCallIsOvercommit() {
        let f: [RangeAction: Double] = [.call: 1.0]
        XCTAssertEqual(MistakeReason.classify(userAction: .jam, frequencies: f), .overcommit)
    }

    func test_callWhenChartWantsJamIsUndercommit() {
        let f: [RangeAction: Double] = [.jam: 1.0]
        XCTAssertEqual(MistakeReason.classify(userAction: .call, frequencies: f), .undercommit)
    }

    func test_wrongLineFallbackForNonFoldOnFoldDominantSpot() {
        // Chart wants fold (≥0.5) but user played — that's tooLoose, not wrongLine.
        let f: [RangeAction: Double] = [.fold: 0.6, .raise: 0.4]
        XCTAssertEqual(MistakeReason.classify(userAction: .raise, frequencies: f), .missedMix)
    }

    func test_frequencyCollapserMapsPreflopActions() {
        var fine = HandFrequencies()
        fine[.fold] = 0.2
        fine[.minRaise] = 0.5
        fine[.raise25x] = 0.3
        let coarse = FrequencyCollapser.coarse(fine)
        XCTAssertEqual(coarse[.fold] ?? 0, 0.2, accuracy: 0.001)
        XCTAssertEqual(coarse[.raise] ?? 0, 0.8, accuracy: 0.001)
    }
}
