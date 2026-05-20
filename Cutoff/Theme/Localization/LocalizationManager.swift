import Foundation
import Observation

/// Source of truth for the user's selected in-app language. Persists to
/// UserDefaults and is injected into the view tree via `.environment(...)`
/// so SwiftUI re-renders when the language flips.
@MainActor
@Observable
final class LocalizationManager {
    /// Shared instance used by call sites that can't take the env (model enums,
    /// pure-Swift logic). Views should prefer the injected environment object
    /// so observation tracking fires on language changes.
    static let shared = LocalizationManager()

    private static let storageKey = "appLanguage"

    var language: AppLanguage {
        didSet {
            guard language != oldValue else { return }
            UserDefaults.standard.set(language.rawValue, forKey: Self.storageKey)
        }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.storageKey)
        self.language = raw.flatMap(AppLanguage.init(rawValue:)) ?? .english
    }

    /// Look up a static key in the active language. Falls back to English when
    /// a key isn't translated (so partial coverage degrades gracefully).
    func t(_ key: L10n.Key) -> String {
        L10n.string(key, in: language)
    }
}
