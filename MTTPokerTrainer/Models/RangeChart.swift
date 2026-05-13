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

    struct SourcePayload: Codable, Hashable {
        enum Kind: String, Codable {
            case demo
            case userDefined
            case imported
            case gto
        }
        let type: Kind
        let description: String

        var humanLabel: String {
            switch type {
            case .demo:        return "Demo training range"
            case .userDefined: return "Nash / GTO range"
            case .imported:    return "Imported range"
            case .gto:         return "GTO approximation"
            }
        }

        var fullDisclaimer: String {
            switch type {
            case .demo:        return "Demo training range — not solver-verified."
            case .userDefined: return "Nash / GTO approximation range — not solver-verified."
            case .imported:    return "Imported range — provenance set by you."
            case .gto:         return "GTO approximation — not solver-verified."
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
}
