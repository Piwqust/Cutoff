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
///   "source": { "type": "solverDump", "description": "Solver-verified MTT preflop range." },
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
        let citation: String?
    }

    struct SourcePayload: Codable, Hashable {
        enum Kind: String, Codable {
            case demo, userDefined, imported, gto, nashComputed, solverDump

            init(from decoder: Decoder) throws {
                let raw = try decoder.singleValueContainer().decode(String.self)
                self = Kind(rawValue: raw) ?? .demo
            }
        }
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
            case .demo:         return "Training range"
            case .userDefined:  return "User-defined range"
            case .imported:     return "Imported range"
            case .gto:          return "Solver-verified range"
            case .nashComputed: return "Nash-equilibrium range"
            case .solverDump:   return "Solver-verified range"
            }
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

    /// Alias preferred by trainer/UI code that wants the bundled `(position,
    /// depth, facing)` triple as one value.
    var spot: TrainingSpot { trainingSpot }

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

    /// Coarse action for a combo: derived from the dominant `PreflopAction`.
    func action(for combo: HandCombo) -> RangeAction {
        let freq = frequencies(for: combo)
        let nonzero = PreflopAction.allCases.filter { freq[$0] > 0 }
        if nonzero.count > 1 { return .mixed }
        return RangeAction(freq.dominantAction)
    }

    // MARK: - Codable

    /// Stored-property keys for the flat schema (MTT_8max_*). Also used to
    /// detect the nested-spot schema via `.spot` / `.format` keys.
    private enum CodingKeys: String, CodingKey {
        case id, stackDepth, position, tableSize, antePercent, facingAction, isICM, source, hands
        case spot, format
    }

    private struct NestedSpot: Decodable {
        let position: TablePosition
        let stackDepthBB: Int
        let facingAction: FacingAction
        let anteType: AnteType?
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)

        if c.contains(.spot) {
            // Nested-spot schema (gto_demo_*, mtt_9max_*).
            let spot = try c.decode(NestedSpot.self, forKey: .spot)
            self.position = spot.position
            self.stackDepth = spot.stackDepthBB
            self.facingAction = spot.facingAction
            let fmt = (try? c.decodeIfPresent(String.self, forKey: .format)) ?? ""
            self.tableSize = fmt.contains("8MAX") ? 8 : 9
            self.antePercent = (try? c.decodeIfPresent(Double.self, forKey: .antePercent)) ?? 12.5
            self.isICM = try c.decodeIfPresent(Bool.self, forKey: .isICM)

            self.source = try c.decode(SourcePayload.self, forKey: .source)

            let raw = Self.decodeNestedHands(container: c)
            self.hands = Self.padToAllCombos(raw)
        } else {
            // Flat schema (MTT_8max_*).
            self.stackDepth = try c.decode(Int.self, forKey: .stackDepth)
            self.position = try c.decode(TablePosition.self, forKey: .position)
            self.tableSize = try c.decode(Int.self, forKey: .tableSize)
            self.antePercent = try c.decode(Double.self, forKey: .antePercent)
            self.facingAction = try c.decode(FacingAction.self, forKey: .facingAction)
            self.isICM = try c.decodeIfPresent(Bool.self, forKey: .isICM)
            self.source = try c.decode(SourcePayload.self, forKey: .source)
            self.hands = try c.decode([String: HandFrequencies].self, forKey: .hands)
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(stackDepth, forKey: .stackDepth)
        try c.encode(position, forKey: .position)
        try c.encode(tableSize, forKey: .tableSize)
        try c.encode(antePercent, forKey: .antePercent)
        try c.encode(facingAction, forKey: .facingAction)
        try c.encodeIfPresent(isICM, forKey: .isICM)
        try c.encode(source, forKey: .source)
        try c.encode(hands, forKey: .hands)
    }

    /// Nested-schema hand values can be either fine-grained `HandFrequencies`
    /// dicts (rare) or coarse-action strings like `"call"` / `"threeBet"` /
    /// `"jam"`. Try the rich shape first, fall back to the string shape.
    private static func decodeNestedHands(container c: KeyedDecodingContainer<CodingKeys>) -> [String: HandFrequencies] {
        if let rich = try? c.decode([String: HandFrequencies].self, forKey: .hands) {
            return rich
        }
        if let coarse = try? c.decode([String: String].self, forKey: .hands) {
            var out: [String: HandFrequencies] = [:]
            for (notation, raw) in coarse {
                out[notation] = HandFrequencies([handFrequenciesAction(for: raw): 1.0])
            }
            return out
        }
        return [:]
    }

    /// Map a coarse-action string from the nested JSON schema to its
    /// best-matching fine-grained `PreflopAction`.
    private static func handFrequenciesAction(for raw: String) -> PreflopAction {
        switch raw {
        case "fold":     return .fold
        case "call":     return .call
        case "limp":     return .limp
        case "raise":    return .raise25x
        case "threeBet": return .raise3x
        case "jam":      return .shove
        default:         return .fold
        }
    }

    /// Ensure every one of the 169 canonical hand notations is present.
    /// Unlisted hands are filled as 100% fold — matching `frequencies(for:)`'s
    /// implicit fallback and satisfying the "169 hands per chart" invariant
    /// tested in `RangeLoaderTests`.
    private static func padToAllCombos(_ partial: [String: HandFrequencies]) -> [String: HandFrequencies] {
        var out = partial
        let foldOnly = HandFrequencies([.fold: 1.0])
        for combo in HandCombo.allInMatrixOrder where out[combo.notation] == nil {
            out[combo.notation] = foldOnly
        }
        return out
    }
}
