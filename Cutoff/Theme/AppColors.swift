import SwiftUI

/// Semantic color tokens. Every view must use these and never hardcode a color.
///
/// All values are defined in the asset catalog as dark-mode-only color sets and
/// are loaded via `Color("Name", bundle: .main)`. If a token resolves to the
/// default placeholder it means the asset catalog entry is missing — fix the
/// catalog rather than hardcoding a fallback here.
enum AppColors {
    // Backgrounds
    static let backgroundDeep        = Color("BackgroundDeep")
    static let backgroundGreenBlack  = Color("BackgroundGreenBlack")
    static let backgroundSurface     = Color("BackgroundSurface")

    // Cards
    static let cardSurface           = Color("CardSurface")
    static let cardSurfaceGreen      = Color("CardSurfaceGreen")

    // Brand / primary
    static let primaryMint           = Color("PrimaryMint")
    static let primaryEmerald        = Color("PrimaryEmerald")
    static let accentGreen           = Color("AccentGreen")

    // Warm accents
    static let accentPeach           = Color("AccentPeach")
    static let accentCoral           = Color("AccentCoral")
    static let accentLime            = Color("AccentLime")

    // Text + structure
    static let textPrimary           = Color("TextPrimary")
    static let textSecondary         = Color("TextSecondary")
    static let divider               = Color("Divider")
    static let errorSoft             = Color("ErrorSoft")

    // Action map
    static let actionFold            = Color("ActionFold")
    static let actionCall            = Color("ActionCall")
    static let actionRaise           = Color("ActionRaise")
    static let actionThreeBet        = Color("ActionThreeBet")
    static let actionJam             = Color("ActionJam")
}
