import SwiftUI

/// Single import facade for tokens. Views can either reference `AppColors` /
/// `AppSpacing` etc. directly, or use `AppTheme` as a shorthand container in
/// places where it reads more cleanly.
enum AppTheme {
    typealias C = AppColors
    typealias S = AppSpacing
    typealias R = AppRadius
    typealias T = AppTypography
    typealias M = AppMotion

    static let disclaimer = "Educational poker training only. No real-money gambling."
    static let demoDataDisclaimer = "Demo training range — not solver-verified."
    static let fullLegalLine = "Educational poker training only. No real-money gambling. Demo ranges are approximate and not solver-verified."
}
