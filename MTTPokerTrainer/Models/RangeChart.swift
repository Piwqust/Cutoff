import Foundation

/// Decoded representation of a bundled range JSON file.
///
/// Schema (matches `Resources/Ranges/MTT_8max_<depth>bb_<position>_<facing>.json`):
/// ```
/// {
///   "id": "MTT_8max_30bb_UTG_RFI",
///   "stackDepth": 30,
///   "position": "UTG",
///   "tableSize": 8,
///   "antePercent": 12.5,
///   "facingAction": "RFI",
///   "isICM": false,
///   "source": { "type": "demo", "description": "Approximate demo training range. Not solver-verified." },
///   "hands": {
///     "AA":  { "fold": 0.0, "minRaise": 1.0, "raise25x": 0.0, "shove": 0.0, ... },
///     "72o": { "fold": 1.0, "minRaise": 0.0, ... }
///   }
/// }
/// ```
struct RangeChart: Codable, Identifiable, Hashable {
    let id: String
    let stackDepth: Int
    let position: TablePosition
    let tableSize: Int
    let antePercent: Double
    let facingAction: FacingAction
    let isICM: Bool?
    let source: SourcePayload
    let hands: [String: HandFrequencies]

    struct SolverConfig: Codable, Hashable {
        let solverName: String
        let solverVersion: String?
        let iterations: Int?
        let dateGenerated: String?
        let assumptions: String?
    }

    struct SourcePayload: Codable, Hashable {
        enum Kind: String, Codable { case demo, userDefined }
        let type: Kind
        let description: String
        let solver: SolverConfig?

        init(type: Kind, description: String, solver: SolverConfig? = nil) {
            self.type = type
            self.description = description
            self.solver = solver
        }

        var humanLabel: String {
            switch type {
            case .demo:        return "Demo training range"
            case .userDefined: return "User-defined range"
            }
        }

        var fullDisclaimer: String {
            "Demo training range — not solver-verified."
        }
    }

    /// Look up the full frequency distribution for a combo. Unlisted hands are
    /// treated as 100% fold.
    func frequencies(for combo: HandCombo) -> HandFrequencies {
        if let f = hands[combo.notation] { return f }
        return HandFrequencies([.fold: 1.0])
    }

    /// Convenience: dominant action for a combo.
    func dominantAction(for combo: HandCombo) -> PreflopAction {
        frequencies(for: combo).dominantAction
    }

    /// Aggregate set of actions that have nonzero frequency on any combo —
    /// used by the trainer UI to decide which buttons are reachable for this
    /// chart.
    var enabledActions: Set<PreflopAction> {
        var out: Set<PreflopAction> = []
        for f in hands.values {
            for action in PreflopAction.allCases where f[action] > 0 {
                out.insert(action)
            }
        }
        return out
    }

    var trainingSpot: TrainingSpot {
        TrainingSpot(
            position: position,
            stackDepthBB: stackDepth,
            facingAction: facingAction,
            anteType: .bigBlindAnte,
            tableSize: tableSize
        )
    }

    /// Fraction of combos that take each action. Folds are inferred (anything
    /// not listed in `hands` is treated as fold).
    func actionFrequencies() -> [RangeAction: Double] {
        let total = HandCombo.allInMatrixOrder.count
        var counts: [RangeAction: Int] = [:]
        for combo in HandCombo.allInMatrixOrder {
            counts[action(for: combo), default: 0] += 1
        }
        return counts.mapValues { Double($0) / Double(total) }
    }
}
