import Foundation

enum BBCalculator {
    /// Big-blind count for a stack. Returns 0 if `bigBlind <= 0` (defensive).
    static func bb(stack: Int, bigBlind: Int) -> Int {
        guard bigBlind > 0 else { return 0 }
        return stack / bigBlind
    }
}
