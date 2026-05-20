import Foundation

/// User-selectable in-app languages. Russian Gen Z is not a real iOS locale —
/// it's a stylistic variant exposed only through the in-app picker.
enum AppLanguage: String, CaseIterable, Identifiable, Hashable {
    case english     = "en"
    case russian     = "ru"
    case russianGenZ = "ru-genz"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:     return "English"
        case .russian:     return "Русский"
        case .russianGenZ: return "Русский (Gen Z)"
        }
    }
}
