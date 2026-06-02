import Foundation

enum StackDepthBucket: Int, Codable, CaseIterable, Identifiable, Hashable {
    // Buckets mirror the depths the bundled poker.academy library is scraped
    // at (CE-Symmetric: 10–100bb). Secondary facings that only exist at legacy
    // depths (e.g. 75/125bb blind-defense) snap to the nearest bucket.
    case bb10  = 10
    case bb15  = 15
    case bb20  = 20
    case bb25  = 25
    case bb30  = 30
    case bb35  = 35
    case bb40  = 40
    case bb50  = 50
    case bb60  = 60
    case bb70  = 70
    case bb80  = 80
    case bb100 = 100

    var id: Int { rawValue }
    var bb: Int { rawValue }
    var label: String { "\(rawValue) BB" }

    /// Lesson one-liner per depth.
    var lesson: String {
        switch self {
        case .bb100: return "Standard tournament depth."
        case .bb80:  return "Deep. Postflop playability matters."
        case .bb70:  return "Deep-ish. Full preflop tree in play."
        case .bb60:  return "Comfortable depth; 3-bet pots stay deep."
        case .bb50:  return "Squeeze and 3-bet pressure starts."
        case .bb40:  return "3-bet jam threshold approaching."
        case .bb35:  return "Re-jam and 3-bet-jam spots open up."
        case .bb30:  return "Pressure stack. 3-bet jams appear."
        case .bb25:  return "Reshove math becomes central."
        case .bb20:  return "Reshove spots matter."
        case .bb15:  return "Push/fold discipline."
        case .bb10:  return "Decisions get binary."
        }
    }

    /// Snap an arbitrary BB count to the nearest bucket — used when matching
    /// the user's chosen stack to a bundled range file.
    ///
    /// **Tie-breaking:** when an input is exactly midway between two buckets
    /// (e.g. 17 BB sits between 15 and 20), the smaller bucket wins because
    /// `min(by:)` keeps the first element on a strict `<` comparator. For an
    /// MTT trainer this is the conservative choice — when in doubt, train
    /// the shorter-stack chart, which has a higher cost-of-error.
    static func nearest(to bb: Int) -> StackDepthBucket {
        StackDepthBucket.allCases.min(by: { abs($0.bb - bb) < abs($1.bb - bb) }) ?? .bb100
    }
}
