import Foundation
import SwiftUI

/// Lightweight `UserDefaults`-backed store for the tournament profile and the
/// "has onboarded" flag. Exposed as an `@Observable` object so views can react.
@MainActor
@Observable
final class ConfigStore {
    private let defaults: UserDefaults

    private(set) var config: TournamentConfig
    var hasOnboarded: Bool {
        didSet { defaults.set(hasOnboarded, forKey: Keys.hasOnboarded) }
    }

    enum Keys {
        static let config       = "tournamentConfig.v1"
        static let hasOnboarded = "hasOnboarded.v1"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Keys.config),
           let decoded = try? JSONDecoder().decode(TournamentConfig.self, from: data) {
            self.config = decoded
        } else {
            self.config = .default
        }
        self.hasOnboarded = defaults.bool(forKey: Keys.hasOnboarded)
    }

    func update(_ mutate: (inout TournamentConfig) -> Void) {
        var c = config
        mutate(&c)
        config = c
        if let data = try? JSONEncoder().encode(c) {
            defaults.set(data, forKey: Keys.config)
        }
    }

    func resetForTesting() {
        defaults.removeObject(forKey: Keys.config)
        defaults.removeObject(forKey: Keys.hasOnboarded)
        config = .default
        hasOnboarded = false
    }
}
