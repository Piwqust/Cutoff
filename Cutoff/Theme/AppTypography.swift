import SwiftUI

enum AppTypography {
    static let largeTitle  = Font.largeTitle.weight(.bold)
    static let title       = Font.title.weight(.semibold)
    static let title2      = Font.title2.weight(.semibold)
    static let title3      = Font.title3.weight(.semibold)
    static let headline    = Font.headline
    static let body        = Font.body
    static let bodyBold    = Font.body.weight(.semibold)
    static let subheadline = Font.subheadline.weight(.medium)
    static let footnote    = Font.footnote
    static let caption     = Font.caption
    static let caption2    = Font.caption2

    /// Small monospaced readout for raw range shorthand / poker codes.
    static let monoCaption = Font.system(size: 11, weight: .medium, design: .monospaced)

    /// Hero splash — the single biggest readout on a screen (e.g., the
    /// tournament summary's "125" BB count). Scales with Dynamic Type via
    /// `.largeTitle` text style.
    static let numericHero: Font = {
        Font.system(.largeTitle, design: .rounded).weight(.bold).monospacedDigit()
    }()

    /// Big, stable readouts like "125 BB" or "25,000".
    static let numericLarge: Font = {
        Font.system(.title, design: .rounded).weight(.bold).monospacedDigit()
    }()

    /// Medium readouts on stat cards.
    static let numericMedium: Font = {
        Font.system(.headline, design: .rounded).weight(.semibold).monospacedDigit()
    }()

    /// Compact readouts for chips and table cells.
    static let numericSmall: Font = {
        Font.system(.subheadline, design: .rounded).weight(.medium).monospacedDigit()
    }()
}
