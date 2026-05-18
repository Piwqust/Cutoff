import Foundation

/// Pure aggregator over `[QuizResult]` that powers the Review tab's dashboard.
/// Stateless — every function returns a fresh struct, no caching. Keeps the
/// view code declarative.
enum ReviewAnalyzer {

    // MARK: - Snapshot

    struct Snapshot: Hashable {
        let total: Int
        let correct: Int
        let close: Int
        let mistakes: Int   // mistake + punt combined
        let accuracy: Int   // 0...100 (avg score)

        static let empty = Snapshot(total: 0, correct: 0, close: 0, mistakes: 0, accuracy: 0)
    }

    static func snapshot(_ results: [QuizResult]) -> Snapshot {
        guard !results.isEmpty else { return .empty }
        let correct = results.lazy.filter { $0.outcome == .correct }.count
        let close = results.lazy.filter { $0.outcome == .close }.count
        let mistakes = results.lazy.filter { $0.outcome == .mistake || $0.outcome == .punt }.count
        let avg = Double(results.map(\.score).reduce(0, +)) / Double(results.count)
        return Snapshot(
            total: results.count,
            correct: correct,
            close: close,
            mistakes: mistakes,
            accuracy: Int(avg.rounded())
        )
    }

    // MARK: - Trend

    struct Trend: Hashable {
        let last7Accuracy: Int?
        let last30Accuracy: Int?
        let deltaPct: Int           // last7 - last30
        let dailyBuckets: [Double]  // last 14 days, oldest → newest, 0...1 accuracy, NaN = no data
    }

    static func trend(_ results: [QuizResult], now: Date = .now) -> Trend {
        let cal = Calendar.current
        func acc(within days: Int) -> Int? {
            guard let cutoff = cal.date(byAdding: .day, value: -days, to: now) else { return nil }
            let slice = results.filter { $0.createdAt >= cutoff }
            guard !slice.isEmpty else { return nil }
            return snapshot(slice).accuracy
        }
        let last7 = acc(within: 7)
        let last30 = acc(within: 30)
        let delta = (last7 ?? 0) - (last30 ?? 0)

        var buckets: [Double] = Array(repeating: .nan, count: 14)
        for offset in 0..<14 {
            guard
                let dayStart = cal.date(byAdding: .day, value: -(13 - offset), to: cal.startOfDay(for: now)),
                let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)
            else { continue }
            let slice = results.filter { $0.createdAt >= dayStart && $0.createdAt < dayEnd }
            if slice.isEmpty { continue }
            buckets[offset] = Double(snapshot(slice).accuracy) / 100.0
        }

        return Trend(
            last7Accuracy: last7,
            last30Accuracy: last30,
            deltaPct: delta,
            dailyBuckets: buckets
        )
    }

    // MARK: - Breakdowns

    struct AccuracyBucket: Identifiable, Hashable {
        let id: String
        let label: String
        let total: Int
        let accuracy: Int   // 0...100
        let mistakes: Int
    }

    static func byPosition(_ results: [QuizResult]) -> [AccuracyBucket] {
        TablePosition.nineMaxOrder.compactMap { pos in
            let slice = results.filter { $0.position == pos }
            guard !slice.isEmpty else { return nil }
            let snap = snapshot(slice)
            return AccuracyBucket(
                id: pos.rawValue,
                label: pos.displayName,
                total: snap.total,
                accuracy: snap.accuracy,
                mistakes: snap.mistakes
            )
        }
    }

    static func byDepth(_ results: [QuizResult]) -> [AccuracyBucket] {
        StackDepthBucket.allCases.compactMap { bucket in
            let slice = results.filter { StackDepthBucket.nearest(to: $0.stackDepthBB) == bucket }
            guard !slice.isEmpty else { return nil }
            let snap = snapshot(slice)
            return AccuracyBucket(
                id: "\(bucket.bb)",
                label: bucket.label,
                total: snap.total,
                accuracy: snap.accuracy,
                mistakes: snap.mistakes
            )
        }
    }

    static func byFacingAction(_ results: [QuizResult]) -> [AccuracyBucket] {
        FacingAction.allCases.compactMap { facing in
            let slice = results.filter { $0.facingAction == facing }
            guard !slice.isEmpty else { return nil }
            let snap = snapshot(slice)
            return AccuracyBucket(
                id: facing.rawValue,
                label: facing.displayName,
                total: snap.total,
                accuracy: snap.accuracy,
                mistakes: snap.mistakes
            )
        }
    }

    static func byHandClass(_ results: [QuizResult]) -> [AccuracyBucket] {
        var byClass: [HandClass: [QuizResult]] = [:]
        for row in results {
            guard let combo = HandCombo.parse(row.combo) else { continue }
            byClass[HandClass.of(combo), default: []].append(row)
        }
        return HandClass.allCases.compactMap { hc in
            guard let slice = byClass[hc], !slice.isEmpty else { return nil }
            let snap = snapshot(slice)
            return AccuracyBucket(
                id: hc.rawValue,
                label: hc.displayName,
                total: snap.total,
                accuracy: snap.accuracy,
                mistakes: snap.mistakes
            )
        }
    }

    // MARK: - Mistake-reason mix

    struct ReasonShare: Identifiable, Hashable {
        let id: String
        let reason: MistakeReason
        let count: Int
        let share: Double  // 0...1
    }

    /// Distribution of mistake reasons over results that count as mistakes.
    /// Requires a chart-resolver closure (typically `service.chart(byID:)`) so
    /// the analyzer can reconstruct frequencies for the played combo.
    static func mistakeReasonMix(
        _ results: [QuizResult],
        chartByID: (String) -> RangeChart?
    ) -> [ReasonShare] {
        let bad = results.filter { $0.outcome == .mistake || $0.outcome == .punt }
        guard !bad.isEmpty else { return [] }

        var counts: [MistakeReason: Int] = [:]
        for row in bad {
            let reason = classify(row: row, chartByID: chartByID)
            counts[reason, default: 0] += 1
        }
        let total = Double(bad.count)
        return counts
            .sorted { $0.value > $1.value }
            .map { reason, count in
                ReasonShare(
                    id: reason.rawValue,
                    reason: reason,
                    count: count,
                    share: Double(count) / total
                )
            }
    }

    static func classify(row: QuizResult, chartByID: (String) -> RangeChart?) -> MistakeReason {
        guard
            let chart = chartByID(row.rangeChartID),
            let combo = HandCombo.parse(row.combo)
        else {
            // Without chart context, infer purely from action distance.
            if row.userAction == row.correctAction { return .correct }
            let userT = row.userAction.aggressionTier
            let chartT = row.correctAction.aggressionTier
            if row.userAction == .fold && row.correctAction != .fold { return .tooTight }
            if row.userAction != .fold && row.correctAction == .fold { return .tooLoose }
            if userT > chartT { return .overcommit }
            if userT < chartT { return .undercommit }
            return .wrongLine
        }
        let freqs = FrequencyCollapser.coarse(chart.frequencies(for: combo))
        return MistakeReason.classify(userAction: row.userAction, frequencies: freqs)
    }

    // MARK: - Heatmap

    struct HeatCell: Identifiable, Hashable {
        let id: String
        let position: TablePosition
        let bucket: StackDepthBucket
        let total: Int
        let accuracy: Int   // 0...100
    }

    static func heatmap(_ results: [QuizResult]) -> [HeatCell] {
        var cells: [HeatCell] = []
        for pos in TablePosition.nineMaxOrder {
            for bucket in StackDepthBucket.allCases {
                let slice = results.filter {
                    $0.position == pos && StackDepthBucket.nearest(to: $0.stackDepthBB) == bucket
                }
                if slice.isEmpty { continue }
                let snap = snapshot(slice)
                cells.append(HeatCell(
                    id: "\(pos.rawValue)_\(bucket.bb)",
                    position: pos,
                    bucket: bucket,
                    total: snap.total,
                    accuracy: snap.accuracy
                ))
            }
        }
        return cells
    }

    // MARK: - Top leak spots

    struct LeakSpot: Identifiable, Hashable {
        let id: String
        let position: TablePosition
        let bucket: StackDepthBucket
        let facing: FacingAction
        let total: Int
        let mistakes: Int
        let mistakeRate: Double  // 0...1
    }

    static func topLeakSpots(_ results: [QuizResult], minSample: Int = 4, limit: Int = 5) -> [LeakSpot] {
        var grouped: [String: [QuizResult]] = [:]
        for row in results {
            let bucket = StackDepthBucket.nearest(to: row.stackDepthBB)
            let key = "\(row.position.rawValue)_\(bucket.bb)_\(row.facingAction.rawValue)"
            grouped[key, default: []].append(row)
        }
        var out: [LeakSpot] = []
        for (key, slice) in grouped where slice.count >= minSample {
            let mistakes = slice.filter { $0.outcome == .mistake || $0.outcome == .punt }.count
            guard mistakes > 0, let row = slice.first else { continue }
            let bucket = StackDepthBucket.nearest(to: row.stackDepthBB)
            out.append(LeakSpot(
                id: key,
                position: row.position,
                bucket: bucket,
                facing: row.facingAction,
                total: slice.count,
                mistakes: mistakes,
                mistakeRate: Double(mistakes) / Double(slice.count)
            ))
        }
        return out
            .sorted { $0.mistakeRate > $1.mistakeRate }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Time scope

    enum Scope: String, CaseIterable, Identifiable, Hashable {
        case last7
        case last30
        case all

        var id: String { rawValue }
        var label: String {
            switch self {
            case .last7:  return "7d"
            case .last30: return "30d"
            case .all:    return "All"
            }
        }
    }

    static func apply(scope: Scope, to results: [QuizResult], now: Date = .now) -> [QuizResult] {
        let cal = Calendar.current
        switch scope {
        case .last7:
            guard let cutoff = cal.date(byAdding: .day, value: -7, to: now) else { return results }
            return results.filter { $0.createdAt >= cutoff }
        case .last30:
            guard let cutoff = cal.date(byAdding: .day, value: -30, to: now) else { return results }
            return results.filter { $0.createdAt >= cutoff }
        case .all:
            return results
        }
    }
}
