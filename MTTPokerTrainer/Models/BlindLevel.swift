import Foundation

enum BlindLevelDuration: Int, Codable, CaseIterable, Identifiable, Hashable {
    case ten = 10, fifteen = 15, twenty = 20
    var id: Int { rawValue }
    var minutes: Int { rawValue }
    var label: String { "\(rawValue) min" }
}

struct BlindLevel: Codable, Hashable, Identifiable {
    var smallBlind: Int
    var bigBlind: Int
    var ante: Int

    var id: String { "\(smallBlind)/\(bigBlind)/\(ante)" }

    static let starting = BlindLevel(smallBlind: 100, bigBlind: 200, ante: 0)
}
