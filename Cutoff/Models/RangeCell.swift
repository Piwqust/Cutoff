import Foundation

/// One cell in the 13×13 matrix view — combo + its frequency distribution.
struct RangeCell: Hashable, Identifiable {
    var id: String { combo.notation }
    let combo: HandCombo
    let frequencies: HandFrequencies

    /// Action to color the cell with — picks whichever has the highest weight.
    var dominantAction: PreflopAction { frequencies.dominantAction }
}
