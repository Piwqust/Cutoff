import Foundation

/// One cell in the 13×13 matrix view — combo + assigned action.
struct RangeCell: Hashable, Identifiable {
    var id: String { combo.notation }
    let combo: HandCombo
    let action: RangeAction
}
