import SwiftUI

/// Action-erased view of a poker action — collapses `RangeAction` and
/// `PostflopAction` into one renderable shape so the feedback overlay can
/// be shared by both trainers.
struct ActionDescriptor {
    let displayName: String
    let systemImage: String
    let tint: Color
    let prefersDarkForeground: Bool
    /// Fold's tint is muted; promote its body text to the primary foreground
    /// so it doesn't read as faded against a dark glass surface.
    let isFold: Bool
}

extension ActionDescriptor {
    init(_ action: RangeAction) {
        self.init(
            displayName: action.displayName,
            systemImage: action.systemImage,
            tint: action.tint,
            prefersDarkForeground: action.prefersDarkForeground,
            isFold: action == .fold
        )
    }

    init(_ action: PostflopAction) {
        self.init(
            displayName: action.displayName,
            systemImage: action.systemImage,
            tint: action.tint,
            prefersDarkForeground: action.prefersDarkForeground,
            isFold: action == .fold
        )
    }
}

/// Everything the feedback sheet renders for a single answered spot.
///
/// Built by each trainer's view model and handed to `FeedbackSheet`. Keeps
/// the sheet free of action-enum knowledge so preflop and postflop share
/// the same view.
struct FeedbackPayload {
    let outcome: AnswerOutcome
    let userAction: ActionDescriptor
    let correctAction: ActionDescriptor
    /// One-line summary of what the chart wants (frequencies if mixed).
    /// Never starts with the action name — that information is already
    /// conveyed by `correctAction`.
    let verdict: String
    /// Multi-paragraph teaching copy. Empty for postflop (which carries a
    /// single line in `verdict`).
    let paragraphs: [String]
    /// Direction-of-error chip. `nil` for postflop spots.
    let mistakeReason: MistakeReason?
    /// Combos in the same hand class that take the same chart line — rendered
    /// as small `HandCardView` chips. Empty for postflop.
    let siblingHands: [HandCombo]
}

/// Identifiable wrapper so `FeedbackPayload` can drive `.sheet(item:)`.
/// Building a fresh wrapper per submit guarantees the system treats each
/// answer as a new presentation even when two consecutive payloads happen to
/// be structurally identical.
struct IdentifiedFeedback: Identifiable {
    let id = UUID()
    let payload: FeedbackPayload
}
