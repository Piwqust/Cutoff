import Foundation

enum StackDepthBucket: Int, Codable, CaseIterable, Identifiable, Hashable {
    case bb10  = 10
    case bb15  = 15
    case bb20  = 20
    case bb25  = 25
    case bb30  = 30
    case bb40  = 40
    case bb50  = 50
    case bb75  = 75
    case bb100 = 100
    case bb125 = 125

    var id: Int { rawValue }
    var bb: Int { rawValue }
    var label: String { "\(rawValue) BB" }

    /// Lesson one-liner per depth.
    var lesson: String {
        switch self {
        case .bb125: return "Deep. Playability matters."
        case .bb100: return "Standard tournament depth."
        case .bb75:  return "Standard tournament depth."
        case .bb50:  return "Squeeze and 3-bet pressure starts."
        case .bb40:  return "3-bet jam threshold approaching."
        case .bb30:  return "Pressure stack. 3-bet jams appear."
        case .bb25:  return "Reshove math becomes central."
        case .bb20:  return "Reshove spots matter."
        case .bb15:  return "Push/fold discipline."
        case .bb10:  return "Decisions get binary."
        }
    }

    /// Snap an arbitrary BB count to the nearest bucket — used when matching
    /// the user's chosen stack to a bundled range file.
    static func nearest(to bb: Int) -> StackDepthBucket {
        StackDepthBucket.allCases.min(by: { abs($0.bb - bb) < abs($1.bb - bb) }) ?? .bb100
    }
}
