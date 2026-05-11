import Foundation

enum AnteType: String, Codable, CaseIterable, Identifiable, Hashable {
    case none           // no ante in play
    case classic        // every player antes each hand
    case bigBlindAnte   // BB player antes for the whole table
    case unknown        // not yet set / variable

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none:         return "No ante"
        case .classic:      return "Classic ante"
        case .bigBlindAnte: return "Big Blind ante"
        case .unknown:      return "Not set"
        }
    }
}
