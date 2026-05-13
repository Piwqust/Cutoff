import Foundation

enum PostflopLoaderError: Error, LocalizedError {
    case bundleResourceMissing
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .bundleResourceMissing: return "postflop_spots.json not found in bundle"
        case .decodingFailed(let err): return "Failed to decode postflop spots: \(err.localizedDescription)"
        }
    }
}

/// Loads the bundled postflop seed spots.
struct PostflopLoader {
    let bundle: Bundle
    let resourceName: String

    init(bundle: Bundle = .main, resourceName: String = "postflop_spots") {
        self.bundle = bundle
        self.resourceName = resourceName
    }

    func loadAll() throws -> [PostflopSpot] {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw PostflopLoaderError.bundleResourceMissing
        }
        let data = try Data(contentsOf: url)
        do {
            return try JSONDecoder().decode([PostflopSpot].self, from: data)
        } catch {
            throw PostflopLoaderError.decodingFailed(error)
        }
    }
}
