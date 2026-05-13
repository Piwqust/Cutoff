import Foundation

enum PostflopLoaderError: Error, LocalizedError {
    case notFound
    case decodeFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notFound: return "Flop library JSON not bundled."
        case .decodeFailed(let e): return "Flop library decode error: \(e.localizedDescription)"
        }
    }
}

/// Loads the bundled `flop_library.json` and exposes typed queries.
struct PostflopLoader {
    let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func loadPack() throws -> PostflopChartPack {
        guard let url = bundle.url(forResource: "flop_library", withExtension: "json") else {
            throw PostflopLoaderError.notFound
        }
        let data = try Data(contentsOf: url)
        do {
            return try JSONDecoder().decode(PostflopChartPack.self, from: data)
        } catch {
            throw PostflopLoaderError.decodeFailed(error)
        }
    }
}
