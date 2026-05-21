import Foundation

/// Publisher metadata applied to every chart written by the importer.
/// Hard-coded for RangeConverter's free 8-max set because every PDF in that
/// pack shares the same tree parameters. Override per-chart later if needed.
struct PublisherMetadata {
    var name: String
    var product: String
    var url: String
    var accessedDate: String  // ISO yyyy-MM-dd
    var treeParams: String
    var assumptions: String

    static let rangeConverter8maxMTT = PublisherMetadata(
        name: "RangeConverter",
        product: "Free Poker Charts — 8 max 1bb ante MTT GTO Ranges",
        url: "https://rangeconverter.com/free-poker-charts",
        accessedDate: Self.isoToday(),
        treeParams: "2.5x open, 3.5x 3bet IP, 4.5x 3bet OOP, 2.3x 4bet IP, 2.75x 4bet OOP, SB vs BB 3.2bb",
        assumptions: "Frequencies rounded to nearest 25% per source. ChipEV (non-ICM). 1bb (12.5%) big-blind ante."
    )

    private static func isoToday() -> String {
        let fmt = DateFormatter()
        fmt.calendar = Calendar(identifier: .iso8601)
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(identifier: "UTC")
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }
}

/// Serialises a `CribSheet` + `ChartSlug` to canonical Cutoff range JSON.
struct Emitter {
    let publisher: PublisherMetadata
    /// Extra prose appended to the `assumptions` field. Used by the 9-max
    /// derivation step to mark adaptation provenance.
    let extraAssumption: String?

    init(publisher: PublisherMetadata, extraAssumption: String? = nil) {
        self.publisher = publisher
        self.extraAssumption = extraAssumption
    }

    func emit(slug: ChartSlug, sheet: CribSheet) throws -> Data {
        // Build the hand map: each notation → either a string (pure coarse
        // action) or an object (mixed frequencies). Pure-fold hands are
        // omitted; RangeChart's decoder treats absence as 100% fold.
        var hands: [String: Any] = [:]
        for (notation, bucket) in sheet.entries {
            // Strip near-zero entries before deciding shape.
            let cleaned = bucket.filter { $0.value > 0.001 }
            if cleaned.isEmpty { continue }
            if cleaned.count == 1, let only = cleaned.first, abs(only.value - 1.0) < 0.001 {
                // Pure action — emit as string for diff-friendliness.
                hands[notation] = only.key
            } else {
                // Mixed — emit object with full-name PreflopAction keys.
                var obj: [String: Double] = [:]
                for (action, freq) in cleaned {
                    obj[Self.preflopActionKey(forCoarse: action)] = freq
                }
                hands[notation] = obj
            }
        }

        let publisherDict: [String: Any] = [
            "name": publisher.name,
            "product": publisher.product,
            "url": publisher.url,
            "accessedDate": publisher.accessedDate,
            "treeParams": publisher.treeParams,
        ]

        var assumptions = publisher.assumptions
        if let extra = extraAssumption {
            assumptions = "\(assumptions) \(extra)"
        }

        let description: String
        if extraAssumption != nil {
            description = "Adapted from RangeConverter 8-max baseline."
        } else {
            description = "RangeConverter free PDF — \(slug.tableSize)-max \(slug.depthBB)bb 1bb ante (12.5%)."
        }

        let source: [String: Any] = [
            "type": "published",
            "description": description,
            "publisher": publisherDict,
            "solver": ["assumptions": assumptions],
        ]

        let root: [String: Any] = [
            "id": slug.id,
            "format": slug.format,
            "spot": [
                "position": slug.position.jsonValue,
                "stackDepthBB": slug.depthBB,
                "facingAction": slug.facing.jsonValue,
                "anteType": "bigBlindAnte",
            ],
            "source": source,
            "hands": hands,
        ]

        return try JSONSerialization.data(
            withJSONObject: root,
            options: [.prettyPrinted, .sortedKeys]
        )
    }

    /// Map a coarse crib action vocabulary entry to the PreflopAction enum
    /// rawValue expected inside HandFrequencies dictionaries in the JSON.
    static func preflopActionKey(forCoarse action: String) -> String {
        switch action {
        case "fold":     return "fold"
        case "call":     return "call"
        case "limp":     return "limp"
        case "raise":    return "raise25x"
        case "threeBet": return "raise3x"
        case "jam":      return "shove"
        default:         return action
        }
    }
}
