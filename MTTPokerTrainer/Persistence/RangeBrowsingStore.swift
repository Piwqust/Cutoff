import Foundation

/// Lightweight UserDefaults-backed store for the Ranges tab's "Continue
/// practicing" recents and starred favorites. Both lists are capped — recents
/// at 5, favorites unbounded but capped at 60 to keep the UI sane.
@MainActor
final class RangeBrowsingStore: ObservableObject {
    @Published private(set) var recentChartIDs: [String] = []
    @Published private(set) var favoriteChartIDs: Set<String> = []

    private let defaults: UserDefaults
    private let recentKey = "RangeBrowsingStore.recent"
    private let favoritesKey = "RangeBrowsingStore.favorites"
    private let recentLimit = 5
    private let favoritesLimit = 60

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.recentChartIDs = (defaults.array(forKey: recentKey) as? [String]) ?? []
        let fav = (defaults.array(forKey: favoritesKey) as? [String]) ?? []
        self.favoriteChartIDs = Set(fav)
    }

    func markVisited(_ chartID: String) {
        var list = recentChartIDs.filter { $0 != chartID }
        list.insert(chartID, at: 0)
        if list.count > recentLimit { list = Array(list.prefix(recentLimit)) }
        recentChartIDs = list
        defaults.set(list, forKey: recentKey)
    }

    func isFavorite(_ chartID: String) -> Bool {
        favoriteChartIDs.contains(chartID)
    }

    func toggleFavorite(_ chartID: String) {
        if favoriteChartIDs.contains(chartID) {
            favoriteChartIDs.remove(chartID)
        } else if favoriteChartIDs.count < favoritesLimit {
            favoriteChartIDs.insert(chartID)
        }
        defaults.set(Array(favoriteChartIDs), forKey: favoritesKey)
    }
}
