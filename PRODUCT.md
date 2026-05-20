# Product

## Register

product

## Users

**Primary:** an amateur No-Limit Hold'em multi-table tournament player who knows the rules but is leaky preflop, has no consistent push/fold reflex, and won't or can't pay for a paid solver subscription. Uses the app in short, opportunistic windows — on the couch, on transit, between hands of a home game — on an iPhone, usually one-handed, often in dim ambient light.

**Secondary:** a casual home-game player curious about tournament theory who wants a clean way to peek at ranges without it feeling like a spreadsheet.

The job-to-be-done, on any given session: *"give me a fast decision rep, tell me whether I was right, tell me why in plain English, and let me drill the specific thing I'm bad at."*

## Product Purpose

A premium, dark-mode iPhone trainer for preflop NLHE MTT decisions and stack-depth instinct. Bite-sized drills, plainly-labeled approximate ranges, and a leak-review surface that names weaknesses in human language and routes the user back to drilling them. Local-first, no accounts, no real money, no live-table assistance.

Success looks like: a user answers their first decision within 90 seconds of first launch, returns for more than one drill in the first session, and over time develops felt confidence at common spots (open / 3-bet defense / short-stack jam) without ever feeling they're using a "gambling app."

## Brand Personality

Calm, premium, studio-grade. Three words: **disciplined, quiet, expert.**

Closer in feel to Things 3, Linear, Apple Fitness, or a high-end study app than to any gambling product. The mint / emerald / peach palette reads as a quiet study lamp at night — not casino felt, not neon. Voice is direct and respectful: "Folding here loses you EV against this open size," never "Oof! Try again!" Confidence without showmanship. Generosity with breathing room.

## Anti-references

- **Anything casino.** No gold, no red felt, no chips, no jackpots, no neon, no slot-machine motion, no big-win sound effects, no currency anywhere.
- **Solver / GTO software UX.** GTO+, PioSolver, GTO Wizard. Frequency-dense tables, color ramps the user can't yet read, no breathing room. We are not that.
- **Generic SaaS dashboard.** The hero-metric template (huge number + tiny label + four supporting stats + gradient accent). Identical card grids — same-sized cards with icon + heading + text repeated. The Train dashboard especially must not collapse into this.
- **Gamified streak apps.** Duolingo-style mascots, XP, confetti, streak guilt-trips. Progress should be felt, not animated.
- **Spreadsheets.** The 13×13 range grid must read as a learning tool, not a query builder. Filter chips, not a chrome-heavy filter bar.

## Design Principles

1. **Practice what you preach.** An app about disciplined decision-making must itself be disciplined. No clutter, no decoration that doesn't earn its place, no false signals, no chart that the user can't yet read.
2. **Decision-first, then explanation.** Every drill surface puts the decision the user must make front-and-center. Feedback teaches afterward, in plain English. Charts come second to sentences.
3. **Bite-sized over comprehensive.** A session is a 60-second loop. Density is welcome only where it accelerates that loop (range cells, action buttons). Everywhere else: breathing room over information density.
4. **Calm darkness, never casino darkness.** Dark mode is the studio lamp at 11pm, not the felt under a tournament chip. Tints lean green / mint / emerald; never red, never gold, never electric blue.
5. **Trust the player.** Treat the user as a capable amateur. Default to expert affordances (single-tap actions, terse labels) and reserve hand-holding for genuine onboarding moments.

## Accessibility & Inclusion

- WCAG 2.1 AA contrast for all text and action buttons.
- Dynamic Type supported up to `accessibility3` on every primary screen.
- `accessibilityReduceMotion` and `accessibilityReduceTransparency` both honored — glass falls back to solid `cardSurface`, motion falls back to linear 0s.
- Color is never the only signal of state — every action button has a glyph plus a text label.
- VoiceOver reading order on every screen: title → context → primary action.
- One-handed reach: primary actions live in the lower 40% of the screen on every drill surface.
