import Foundation

enum PlayerLevel: String, Codable, CaseIterable, Identifiable, Hashable {
    case beginner, amateur, advanced

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }

    var subtitle: String {
        switch self {
        case .beginner: return "Learning the basics."
        case .amateur:  return "Knows the rules, building instincts."
        case .advanced: return "Comfortable; sharpening leaks."
        }
    }
}
