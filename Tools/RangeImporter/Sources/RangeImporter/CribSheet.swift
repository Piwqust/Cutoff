import Foundation

/// A parsed long-form crib sheet:
/// ```
/// notation,action,freq
/// AA,raise,1.0
/// A5s,raise,0.5
/// A5s,fold,0.5
/// ```
///
/// Conventions:
/// - Multiple rows per notation = mixed strategy. Frequencies for one hand
///   must sum to 1.0 (within tolerance).
/// - Unmentioned hands default to 100% fold.
/// - Comments start with `#`. Whitespace and blank lines are ignored.
struct CribSheet {
    /// Mapping from canonical hand notation → action-freq vector. Only
    /// nonzero-frequency actions are stored. Missing combos = 100% fold.
    let entries: [String: [String: Double]]

    /// Validation errors discovered while parsing.
    struct ValidationError: Error, CustomStringConvertible {
        let messages: [String]
        var description: String { "Crib sheet failed validation:\n  - " + messages.joined(separator: "\n  - ") }
    }

    /// Parse a CSV string. Throws if validation fails.
    static func parse(_ csv: String, sourceName: String = "<input>") throws -> CribSheet {
        var entries: [String: [String: Double]] = [:]
        var errors: [String] = []

        for (lineNumber, rawLine) in csv.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            // Skip header rows anywhere in the file (multiple `# comment` lines may
            // push it past line 0). A header is any non-comment line that starts
            // with the literal "notation,".
            if line.lowercased().hasPrefix("notation,") { continue }

            let parts = line.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 3 else {
                errors.append("\(sourceName):\(lineNumber + 1): expected 3 columns (notation,action,freq), got \(parts.count)")
                continue
            }
            let notation = parts[0]
            // Match against the action vocabulary case-insensitively, then
            // re-resolve to the canonical rawValue so multi-word actions
            // (`threeBet`) survive lowercasing.
            let actionRaw = parts[1]
            guard let freq = Double(parts[2]) else {
                errors.append("\(sourceName):\(lineNumber + 1): freq '\(parts[2])' is not a number")
                continue
            }
            guard HandClasses.allSet.contains(notation) else {
                errors.append("\(sourceName):\(lineNumber + 1): '\(notation)' is not a canonical hand notation")
                continue
            }
            guard let canonical = CribAction.allCases.first(where: { $0.rawValue.lowercased() == actionRaw.lowercased() }) else {
                errors.append("\(sourceName):\(lineNumber + 1): unknown action '\(actionRaw)'. Allowed: \(CribAction.allCases.map(\.rawValue).joined(separator: ", "))")
                continue
            }
            let action = canonical.rawValue
            guard freq >= 0 && freq <= 1 else {
                errors.append("\(sourceName):\(lineNumber + 1): freq \(freq) must be in [0,1]")
                continue
            }

            var bucket = entries[notation] ?? [:]
            bucket[action, default: 0] += freq
            entries[notation] = bucket
        }

        // Per-hand frequency sum check.
        for (notation, bucket) in entries {
            let sum = bucket.values.reduce(0, +)
            if abs(sum - 1.0) > 0.001 {
                errors.append("\(sourceName): hand '\(notation)' frequencies sum to \(sum), expected 1.0")
            }
        }

        if !errors.isEmpty {
            throw ValidationError(messages: errors)
        }
        return CribSheet(entries: entries)
    }

    /// Number of canonical hands that received a nonzero strategy.
    var coveredHandCount: Int { entries.count }
}

/// Vocabulary accepted in crib sheets. Maps 1:1 to the JSON coarse-action
/// strings recognised by `RangeChart.handFrequenciesAction(for:)`.
enum CribAction: String, CaseIterable {
    case fold
    case call
    case limp
    case raise       // open raise (default open size)
    case threeBet
    case jam         // all-in (shove)
}
