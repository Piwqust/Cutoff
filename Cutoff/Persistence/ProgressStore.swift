import Foundation
import SwiftUI

/// A simple, durable progress system designed to motivate repeated training.
///
/// - **Rating**: an ELO-flavored number per drill category. Starts at 1000.
///   Moves up on correct/close answers, down on mistakes/punts. Bounded
///   [200, 2400] so a streak of bad days can't sink the user past recovery.
/// - **XP / Level**: total XP accumulates with every answer scored. Level is
///   a square-root curve so early levels feel fast and later ones earn out.
/// - **Streak**: consecutive calendar days with at least one answered hand.
@MainActor
@Observable
final class ProgressStore {
    private let defaults: UserDefaults

    private(set) var totalXP: Int
    private(set) var ratings: [String: Int]   // DrillCategory.rawValue → rating
    private(set) var streakDays: Int
    private(set) var lastTrainDay: Date?

    private enum Keys {
        static let xp        = "progress.totalXP.v1"
        static let ratings   = "progress.ratings.v1"
        static let streak    = "progress.streakDays.v1"
        static let lastDay   = "progress.lastTrainDay.v1"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.totalXP = defaults.integer(forKey: Keys.xp)
        if let data = defaults.data(forKey: Keys.ratings),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            self.ratings = decoded
        } else {
            self.ratings = [:]
        }
        self.streakDays = defaults.integer(forKey: Keys.streak)
        self.lastTrainDay = defaults.object(forKey: Keys.lastDay) as? Date
    }

    // MARK: - Public API

    func record(outcome: AnswerOutcome, in category: DrillCategory, at date: Date = .now) {
        applyRating(outcome: outcome, category: category)
        totalXP += xpDelta(for: outcome)
        bumpStreak(now: date)
        persist()
    }

    func rating(for category: DrillCategory) -> Int {
        ratings[category.rawValue] ?? 1000
    }

    var level: Int {
        // Level n requires n^2 * 50 XP. Level 1 at 0 XP, level 2 at 50, level 3 at 200, level 4 at 450…
        Int(Double(totalXP / 50).squareRoot().rounded(.down)) + 1
    }

    /// XP needed to reach the next level (from the current XP).
    var xpToNextLevel: Int {
        let nextLevel = level + 1
        let nextThreshold = (nextLevel - 1) * (nextLevel - 1) * 50
        return max(1, nextThreshold - totalXP)
    }

    /// 0…1 progress toward the next level.
    var levelProgress: Double {
        let curThreshold = (level - 1) * (level - 1) * 50
        let nextThreshold = level * level * 50
        let span = max(1, nextThreshold - curThreshold)
        return Double(totalXP - curThreshold) / Double(span)
    }

    /// Title shown next to the level number.
    var rank: String {
        switch level {
        case ..<3:   return "Recruit"
        case ..<6:   return "Grinder"
        case ..<10:  return "Sharp"
        case ..<16:  return "Crusher"
        default:     return "MTT Pro"
        }
    }

    func resetForTesting() {
        totalXP = 0
        ratings = [:]
        streakDays = 0
        lastTrainDay = nil
        persist()
    }

    // MARK: - Internals

    private func applyRating(outcome: AnswerOutcome, category: DrillCategory) {
        let current = ratings[category.rawValue] ?? 1000
        let delta: Int
        switch outcome {
        case .correct: delta = 16
        case .close:   delta = 4
        case .mistake: delta = -10
        case .punt:    delta = -22
        }
        ratings[category.rawValue] = min(2400, max(200, current + delta))
    }

    private func xpDelta(for outcome: AnswerOutcome) -> Int {
        switch outcome {
        case .correct: return 10
        case .close:   return 5
        case .mistake: return 2
        case .punt:    return 1
        }
    }

    private func bumpStreak(now: Date) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        guard let last = lastTrainDay.map({ cal.startOfDay(for: $0) }) else {
            streakDays = 1
            lastTrainDay = today
            return
        }
        if cal.isDate(last, inSameDayAs: today) { return }
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        if cal.isDate(last, inSameDayAs: yesterday) {
            streakDays += 1
        } else {
            streakDays = 1
        }
        lastTrainDay = today
    }

    private func persist() {
        defaults.set(totalXP, forKey: Keys.xp)
        if let data = try? JSONEncoder().encode(ratings) {
            defaults.set(data, forKey: Keys.ratings)
        }
        defaults.set(streakDays, forKey: Keys.streak)
        defaults.set(lastTrainDay, forKey: Keys.lastDay)
    }
}
