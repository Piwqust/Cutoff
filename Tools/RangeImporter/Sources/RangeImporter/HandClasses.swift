import Foundation

/// The 169 canonical preflop hand notations, in the order that mirrors the
/// 13×13 matrix RangeConverter / GTO Wizard / etc. use (pairs on the diagonal,
/// suited above-right of the diagonal, off-suit below-left).
///
/// Order is row-major from AA in the top-left to 22 in the bottom-right.
enum HandClasses {
    static let ranks: [Character] = ["A", "K", "Q", "J", "T", "9", "8", "7", "6", "5", "4", "3", "2"]

    /// All 169 canonical notations, e.g. "AA", "AKs", "AKo", ..., "22".
    static let all: [String] = {
        var out: [String] = []
        for (i, r1) in ranks.enumerated() {
            for (j, r2) in ranks.enumerated() {
                if i == j {
                    out.append("\(r1)\(r2)")
                } else if i < j {
                    out.append("\(r1)\(r2)s")
                } else {
                    out.append("\(r2)\(r1)o")
                }
            }
        }
        return out
    }()

    static let allSet: Set<String> = Set(all)
}
