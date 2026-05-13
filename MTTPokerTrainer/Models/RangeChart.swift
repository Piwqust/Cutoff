import Foundation

/// Decoded representation of a bundled or imported range JSON file.
struct RangeChart: Codable, Identifiable, Hashable {
    let id: String
    let format: String
    let spot: SpotPayload
    let source: SourcePayload
    let hands: [String: RangeAction]

    struct SpotPayload: Codable, Hashable {
        let position: TablePosition
        let stackDepthBB: Int
        let facingAction: FacingAction
        let anteType: AnteType
    }

    struct SolverConfig: Codable, Hashable {
        let solverName: String
        let solverVersion: String?
        let iterations: Int?
        let dateGenerated: String?
        let assumptions: String?
    }

    struct SourcePayload: Codable, Hashable {
        /// Provenance of the chart. Decoded permissively so legacy `gto`
        /// values still parse — they're treated as `solverDump`.
        enum Kind: String, Codable {
            case nashComputed
            case solverDump
            case demoHandAuthored
            case userImported

            init(from decoder: Decoder) throws {
                let raw = try decoder.singleValueContainer().decode(String.self)
                if let direct = Kind(rawValue: raw) {
                    self = direct
                    return
                }
                // Legacy aliases from earlier schema iterations.
                switch raw {
                case "gto":         self = .solverDump
                case "demo":        self = .demoHandAuthored
                case "userDefined": self = .userImported
                case "imported":    self = .userImported
                case "nash":        self = .nashComputed
                default:
                    throw DecodingError.dataCorruptedError(
                        in: try decoder.singleValueContainer(),
                        debugDescription: "Unknown range source kind: \(raw)"
                    )
                }
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
            case .nashComputed:      return "Nash equilibrium"
            case .solverDump:        return "GTO solver chart"
            case .demoHandAuthored:  return "Hand-authored approximation"
            case .userImported:      return "Imported range"
            }
        }

        var fullDisclaimer: String {
            switch type {
            case .nashComputed:
                return "Nash push/fold equilibrium — mathematically computed for the chosen ante model."
            case .solverDump:
                if let s = solver {
                    var parts = [s.solverName]
                    if let v = s.solverVersion { parts.append("v\(v)") }
                    if let i = s.iterations { parts.append("\(i) iter") }
                    return "Solved with " + parts.joined(separator: " ") + "."
                }
                return "GTO solver chart."
            case .demoHandAuthored:
                return "Hand-authored approximation — not solver-verified."
            case .userImported:
                return "Imported range — provenance set by you."
            }
        }
    }

    /// Looks up the action for a given combo's notation. Unlisted hands are
    /// treated as fold (the explicit "default fold" convention).
    func action(for combo: HandCombo) -> RangeAction {
        hands[combo.notation] ?? .fold
    }

    var trainingSpot: TrainingSpot {
        TrainingSpot(
            position: spot.position,
            stackDepthBB: spot.stackDepthBB,
            facingAction: spot.facingAction,
            anteType: spot.anteType,
            tableSize: 9
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
