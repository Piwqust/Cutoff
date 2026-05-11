import SwiftUI

enum AppMotion {
    static let quick:    Animation = .easeOut(duration: 0.18)
    static let standard: Animation = .smooth(duration: 0.28)
    static let entrance: Animation = .spring(response: 0.35, dampingFraction: 0.85)
    static let pressed:  CGFloat   = 0.97
    static let pressedDuration: Double = 0.12

    /// Returns the given animation, or a zero-duration linear animation if the
    /// user has Reduce Motion enabled. Use this everywhere we animate.
    static func respecting(_ reduceMotion: Bool, _ animation: Animation) -> Animation {
        reduceMotion ? .linear(duration: 0) : animation
    }
}
