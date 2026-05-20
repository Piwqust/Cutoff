import Foundation
import os.log

private let rangeLog = Logger(subsystem: "com.cutoff.app", category: "RangeLoader")

enum RangeLoaderError: Error, LocalizedError {
    case fileNotFound(String)
    case decodingFailed(String, Error)
    case noChartsFound

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let name):     return "Range file not found: \(name)"
        case .decodingFailed(let n, _):   return "Failed to decode range JSON: \(n)"
        case .noChartsFound:              return "No range files in bundle."
        }
    }
}

/// Loads `RangeChart` JSON files bundled in `Resources/Ranges/`.
struct RangeLoader {
    let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    /// Load all bundled charts. Sorted by id for determinism.
    func loadAll() throws -> [RangeChart] {
        // Resources are flattened by Xcode's resource phase, so we search the
        // bundle root for *.json files and filter to those that decode as a
        // RangeChart. This keeps adding new range files a zero-config affair.
        guard let urls = bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) else {
            throw RangeLoaderError.noChartsFound
        }

        let decoder = JSONDecoder()
        var charts: [RangeChart] = []
        var decodeFailures = 0
        for url in urls {
            let data: Data
            do { data = try Data(contentsOf: url) }
            catch {
                rangeLog.error("range read failed: \(url.lastPathComponent, privacy: .public) — \(String(describing: error), privacy: .public)")
                continue
            }
            do {
                let chart = try decoder.decode(RangeChart.self, from: data)
                charts.append(chart)
            } catch {
                // Surface the failure: silent try? once masked all 370 charts
                // failing to decode. The loop still keeps going — one bad
                // file shouldn't take the whole library down — but the next
                // run will scream in the console.
                decodeFailures += 1
                rangeLog.error("range decode failed: \(url.lastPathComponent, privacy: .public) — \(String(describing: error), privacy: .public)")
            }
        }
        if decodeFailures > 0 {
            rangeLog.error("range loader skipped \(decodeFailures, privacy: .public) bundled files due to decode errors")
        }
        charts.sort { $0.id < $1.id }
        if charts.isEmpty { throw RangeLoaderError.noChartsFound }
        return charts
    }

    /// Find the chart that best matches a target spot. Falls back to nearest
    /// stack-depth bucket for the same position+facingAction.
    func chart(matching position: TablePosition, depthBB: Int, facing: FacingAction, in charts: [RangeChart]) -> RangeChart? {
        let candidates = charts.filter { $0.position == position && $0.facingAction == facing }
        guard !candidates.isEmpty else { return nil }
        return candidates.min(by: { abs($0.stackDepth - depthBB) < abs($1.stackDepth - depthBB) })
    }
}
