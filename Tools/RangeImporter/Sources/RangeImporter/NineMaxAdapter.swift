import Foundation

/// Rule-based adaptation of an 8-max crib sheet to a 9-max sibling.
///
/// Industry consensus (RangeConverter, GTO Wizard articles, training-site
/// cheat sheets):
///   - 9-max UTG  = 8-max UTG with the weakest ~3% of combos demoted to fold.
///   - 9-max UTG1 ≈ 8-max UTG verbatim.
///   - 9-max LJ/HJ/CO/BTN/SB/BB = 8-max LJ/HJ/CO/BTN/SB/BB verbatim.
///
/// The "tighten UTG" rule is encoded as a per-depth whitelist of combos to
/// demote, picked from the conventional bottom of the early-position range.
/// Combos not in the original UTG opening range are left untouched.
enum NineMaxAdapter {
    /// Hands typically removed from 8-max UTG when adapting down to 9-max UTG.
    /// Pulled from the standard "tighten the bottom" pattern in published
    /// adaptation guides; tuned so total VPIP drops ~3 percentage points
    /// when the source range is in the canonical 14-18% band.
    private static let tightenedFromUTG: Set<String> = [
        "A2s", "A3s",     // weakest suited aces are the first to go
        "K8s", "K7s",     // suited Kings at the bottom
        "98s", "87s", "76s", "65s", "54s",  // suited connectors below T9s
        "JTo", "T9o",     // weakest broadway-ish offsuit
    ]

    /// Given an 8-max sheet at `sourcePosition`, return the crib sheet for the
    /// 9-max sibling at `targetPosition` along with a human-readable
    /// adaptation note.
    static func adapt(eightMax sheet: CribSheet, sourcePosition: ChartSlug.Position, targetPosition: ChartSlug.Position) -> (CribSheet, String) {
        switch targetPosition {
        case .utg where sourcePosition == .utg:
            // Tighten: demote whitelisted combos to 100% fold (i.e. remove).
            let demoted = sheet.entries.filter { !tightenedFromUTG.contains($0.key) }
            return (CribSheet(entries: demoted), "Adapted from 8-max UTG; weakest combos (\(tightenedFromUTG.sorted().joined(separator: ", "))) demoted to fold to reach the 9-max UTG VPIP band.")
        case .utg1 where sourcePosition == .utg:
            return (sheet, "Adapted from 8-max UTG (9-max UTG+1 plays the same role as 8-max UTG).")
        case .lj, .hj, .co, .btn, .sb, .bb:
            // Copy verbatim — seat name has the same meaning.
            return (sheet, "Copied verbatim from 8-max \(sourcePosition.rawValue.uppercased()) (same effective seat in 9-max).")
        default:
            return (sheet, "Adapted from 8-max \(sourcePosition.rawValue.uppercased()).")
        }
    }
}
