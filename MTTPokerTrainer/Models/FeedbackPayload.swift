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

/// Everything the feedback overlay renders for a single answered spot.
///
/// Built by each trainer's view model and handed to `FeedbackOverlay`. Keeps
/// the overlay free of action-enum knowledge so preflop and postflop share
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

/// State machine for the post-answer feedback flow.
///
/// Replaces a tangle of booleans (`feedbackVisible`, `tickOutcome`, `tickProgress`,
/// `tickOpacity`, `autoDismissTask`, …) with a single source of truth: at any
/// moment the trainer is either accepting a new answer, briefly affirming a
/// correct one, or holding for the user on a revealed overlay.
enum FeedbackPhase {
    /// Awaiting the user's next action.
    case idle
    /// Correct answer — silent affirmation (haptic + edge tick). The token
    /// distinguishes back-to-back correct answers so an in-flight advance
    /// task can detect cancellation by comparing tokens.
    case silentCorrect(token: UUID)
    /// Close, mistake, or punt — the overlay is up and waits for the user.
    case revealed(FeedbackPayload)
}
