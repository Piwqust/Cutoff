import Foundation

enum TrainingMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case preflop, stackDepth, pushFold, mistakes
    var id: String { rawValue }

    var title: String {
        switch self {
        case .preflop:    return "Preflop Trainer"
        case .stackDepth: return "Stack Depth"
        case .pushFold:   return "Push / Fold"
        case .mistakes:   return "Mistakes Review"
        }
    }

    var subtitle: String {
        switch self {
        case .preflop:    return "Drill 9-max preflop spots"
        case .stackDepth: return "How strategy shifts with depth"
        case .pushFold:   return "Short-stack jam practice"
        case .mistakes:   return "Replay your recent slips"
        }
    }

    var systemImage: String {
        switch self {
        case .preflop:    return "rectangle.grid.3x2.fill"
        case .stackDepth: return "chart.bar.fill"
        case .pushFold:   return "flame.fill"
        case .mistakes:   return "exclamationmark.bubble.fill"
        }
    }
}
