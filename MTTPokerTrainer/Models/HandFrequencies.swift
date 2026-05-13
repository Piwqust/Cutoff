import Foundation

/// Frequency distribution for one hand across every `PreflopAction`.
///
/// Stored as a flat `[String: Double]` keyed by `PreflopAction.rawValue` so the
/// on-disk JSON stays human-readable. Disabled actions appear with `0.0` rather
/// than being omitted — that way the UI can show every button as either
/// enabled or visibly disabled, never missing.
struct HandFrequencies: Codable, Hashable {
    private(set) var values: [PreflopAction: Double]

    init(_ values: [PreflopAction: Double] = [:]) {
        var clamped: [PreflopAction: Double] = [:]
        for action in PreflopAction.allCases {
            clamped[action] = max(0, min(1, values[action] ?? 0))
        }
        self.values = clamped
    }

    subscript(action: PreflopAction) -> Double {
        get { values[action] ?? 0 }
        set { values[action] = max(0, min(1, newValue)) }
    }

    /// Action with the highest frequency. Ties broken by aggression tier (the
    /// more passive option wins so we don't bias toward jams).
    var dominantAction: PreflopAction {
        let sorted = values.sorted { lhs, rhs in
            if lhs.value != rhs.value { return lhs.value > rhs.value }
            return lhs.key.aggressionTier < rhs.key.aggressionTier
        }
        return sorted.first?.key ?? .fold
    }

    /// True if more than one action has non-trivial frequency (≥ 0.1).
    var isMixed: Bool {
        values.values.filter { $0 >= 0.1 }.count > 1
    }

    /// Sum across all actions. Should be ≈ 1.0 for well-formed spots; we
    /// tolerate small drift but never claim the sum.
    var total: Double { values.values.reduce(0, +) }

    // MARK: - Codable

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode([String: Double].self)
        var out: [PreflopAction: Double] = [:]
        for action in PreflopAction.allCases {
            out[action] = max(0, min(1, raw[action.rawValue] ?? 0))
        }
        self.values = out
    }

    func encode(to encoder: Encoder) throws {
        var dict: [String: Double] = [:]
        for (k, v) in values { dict[k.rawValue] = v }
        var container = encoder.singleValueContainer()
        try container.encode(dict)
    }
}
