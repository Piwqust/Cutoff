# UX Research

> Note on sources: this build runs in a sandbox where outbound web search may be unavailable. Where I cite external bodies of work below, the references are to publicly-known guidance that I am applying from training, not freshly fetched. If a user wants direct citations they should verify against the named sources.

## Core principles applied

### 1. Minimize cognitive load (Nielsen Norman Group — mobile UX)
Mobile users have less attention and worse posture than desktop users. We:
- show one big primary action per screen ("Start training", "Drill this depth", "Next hand"),
- defer secondary actions ("Customize tournament", "View range") to lower visual weight,
- limit visible chips/filters to what the user can scan in one glance.

### 2. Progressive disclosure (HIG — clarity)
The Train Dashboard does **not** expose every stat. The Range Grid does **not** show every filter at once — common ones are visible, advanced ones live behind a sheet. Explanations on the preflop quiz are 1–2 sentences, with the longer "Why?" tucked behind disclosure.

### 3. One-handed iPhone reach (HIG — layout)
Primary actions sit near the bottom 40% of the screen, where the thumb can reach without re-gripping. The "Next hand" CTA in the feedback sheet is anchored to a safe-area-respecting bottom. Tab bar (Train · Ranges · Review · Settings) is system standard so it benefits from system thumb ergonomics.

### 4. Tap-target sizing (HIG — accessibility)
Apple recommends a minimum hit target of 44×44 pt. We exceed it deliberately for training actions: `ActionButton` is 56 pt tall, `PrimaryButton` is 56 pt tall, range cells are at least 26 pt with the full row tap-bound to a detail sheet on touch-up.

### 5. Immediate feedback after every decision (NN/g — feedback)
The preflop quiz answer animates in ≤ 250 ms after the tap. The feedback contains: outcome label (Correct / Close / Mistake), the best answer, and a one-line explanation. No long page reload, no modal.

### 6. Reduce friction in onboarding (NN/g — onboarding)
- No account creation.
- No permission prompts.
- Three taps maximum from cold launch to the first quiz hand.
- The user can change the tournament profile later — defaults are good.

### 7. Plain-language UX writing (HIG — voice & tone)
Beginner/amateur copy avoids solver jargon. We say "Best answer" rather than "GTO equilibrium", "Close" rather than "EV-adjacent", "Mistake" rather than "−EV punt". The "Why?" panel explains a hand in concrete terms ("Too weak from early position at 9-max") rather than theoretical ones.

## Applied to this trainer

### Trainer loop
*Tap action → see correct answer → read 1-line reason → tap Next hand.*
Each turn should be under 5 seconds for a confident player. The screen never asks the user to read more than two sentences to continue.

### Range grid on iPhone
A 13×13 grid is a known UX problem on iPhone — 169 cells in a 4-inch wide viewport. We:
- use the safe horizontal padding (`AppSpacing.lg`) and let the grid fill the rest,
- size each cell to roughly screen-width / 13 ≈ 26 pt (above the minimum legible cell size),
- pin the filter chips above the grid so context never scrolls away,
- on tap, open a half-height bottom sheet with the action, the spot meta, and the demo-data label.

### Mistake review
- Each leak is named in plain English ("Too loose UTG", "Overfolding BB").
- We avoid shame language; the tone is "here's the next thing to practice".
- Each leak card carries a severity bar (low/medium/high) and one CTA.

### Empty states
- First-time Review shows: "Train a few hands and we'll start spotting your leaks."
- First-time Mistakes Drill shows: "Nothing to review yet."
- Empty states use the same `GlassCard` style — they're not punishments.

## Anti-patterns we explicitly avoid
- Spinning wheels, jackpot meters, slot-machine animations.
- Modal dialogs to confirm benign actions.
- Onboarding carousels of 5+ slides.
- "Streak shaming" — a missed-day streak counter is opt-in only if implemented at all.
- Tooltips and coach marks that block the UI.

## A11y UX considerations
- Every interactive element has a VoiceOver label that describes its meaning, not its shape: "Raise. Hero hand A K suited from cutoff".
- Color-coded actions also carry a text label and a glyph, so the user is not depending on color alone.
- The disclaimer "Educational poker training only. No real-money gambling." is read by VoiceOver on the screens that show it (Onboarding, Settings, Range detail).
- Dynamic Type is supported up to the `accessibility3` size class on primary screens; we clamp beyond that to prevent layout breakage but maintain readability.
- Reduce Motion: card entrance and press scale animations collapse to `none`. Hand-card flip becomes an instant swap.
- Reduce Transparency: glass surfaces become opaque `CardSurface` — see `DESIGN_RESEARCH.md`.
