# Design Research

> Sources note: outbound web search may not be available in this sandbox. References below are to public Apple guidance (Human Interface Guidelines, SwiftUI documentation, WCAG) applied from training. If verification is desired, the named documents are the source of truth.

## Apple HIG findings (applied)

### Clarity
- Use system fonts (SF) and the system font scale. Big titles for screen identity, semibold for important values, regular body for explanation, footnote for legal text.
- High-contrast text on dark surfaces. We use near-white (`TextPrimary` #F5F7F6) for primary text and a muted gray-green (`TextSecondary` #9DB0A8) for supporting text. Both clear WCAG AA on `BackgroundDeep` and `CardSurface`.

### Deference
- Chrome stays out of the way of content. The tab bar uses native `TabView`. Navigation uses `NavigationStack`. No custom rotating carousels.

### Depth
- Liquid Glass and gentle gradient backgrounds establish depth without becoming decoration. The hero card on the Train Dashboard sits visibly on top of the background; the disclaimer footnote sits visibly behind it. Depth is used to signal hierarchy, not whimsy.

## Liquid Glass (iOS 18+) — when to use it

Liquid Glass is the new system-level material that bends, reacts to motion, and tints content beneath it. Per Apple guidance:

**Use glass for**:
- Floating panels that overlay primary content (hero cards, the preflop feedback sheet)
- Sticky filter chips above scrolling content (Range Grid filter row)
- Tab/navigation surfaces (system handles this for us via `TabView`)
- Compact stat cards on the Train Dashboard

**Do NOT use glass for**:
- Large opaque content surfaces (the 13×13 grid background, long reading content)
- Text that needs to remain readable over busy imagery — glass tints but does not protect contrast
- Stacked glass-on-glass (creates muddy contrast and visual confusion)
- Decoration without semantic purpose

### Implementation strategy
`AppGlass.glassBackground()` is the single entry point. Internally it:
1. Reads `\.accessibilityReduceTransparency` — if **on**, returns a solid `CardSurface` rounded rect, no glass at all.
2. Else, on iOS 18+, applies the new `Glass` effect (when API is available at compile-time and runtime).
3. Else falls back to `.ultraThinMaterial`.

This protects users from low-contrast situations regardless of OS version.

## SwiftUI native components — preferred over custom

| Need | We use | Avoid |
|---|---|---|
| Tabs | `TabView` | Custom segmented bar |
| Push navigation | `NavigationStack` + `.navigationDestination` | Custom routers |
| Forms with mixed content | `Form` (inside Tournament Setup) | Hand-rolled VStack-of-rows |
| Segmented choice | `Picker(...).pickerStyle(.segmented)` | Custom capsule rows |
| Modals | `.sheet` and `.fullScreenCover` | Custom transitions |
| Half-sheet | `.presentationDetents([.fraction(0.4), .large])` | Custom drag handles |

We layer our design tokens on top of these system components — colors, radii, spacing, glass — without replacing the components themselves.

## Dark UI readability
- Pure-black backgrounds can crush near-black UI elements; we use `BackgroundDeep` `#050807` and `BackgroundGreenBlack` `#07110D` rather than `#000000` so that subtle elevation reads.
- We never put `TextSecondary` on top of `BackgroundDeep` alone for primary content — supporting text always sits on a `CardSurface` for AA contrast.
- Action color tokens (Call/Raise/3-bet/Jam) are always paired with a label and an icon so color is never the only differentiator.

## Typography hierarchy
- `largeTitle` for screen titles ("Train tournament poker.")
- `title2` for section headers
- `headline` for card titles
- `body` for primary text
- `subheadline` for context chips
- `footnote` for disclaimers
- `caption` for fine print on Settings rows

Numbers (`125 BB`, `25,000`) use `.monospacedDigit()` and `.fontWeight(.semibold)` for stable layout when values change.

## Spacing
- 8-pt base grid, with values 4/8/12/16/20/24/32/40/56 used semantically.
- Horizontal page padding: 20 pt.
- Vertical between cards: 16 pt; inside a card: 12–16 pt.

## Motion
- Defaults to `.smooth(duration: 0.28)` for view transitions and `.spring(response: 0.35, dampingFraction: 0.85)` for card entrances.
- Press scale: `0.97`.
- All animations are wrapped in a `\.accessibilityReduceMotion` check; reduced motion swaps to `.linear(duration: 0)` or no animation at all.

## Why this app must not look like a casino
The App Store reviewer's first impression must read "study tool" not "play tool". Concretely:
- **Palette**: mint + emerald + peach + lime on near-black. No gold, no red, no neon dollar signs.
- **Iconography**: SF Symbols only (suit, chart, list). No coins, no chips on the dashboard.
- **Motion**: subtle and goal-directed (a card flip when a new hand is dealt). No confetti, no spinning, no slot-machine pulls.
- **Copy**: "Train" not "Play". "Spot" not "Hand played for real". "Best answer" not "win".
- **Disclaimers**: the educational disclaimer is visible on three independent screens (Onboarding, Settings, Range detail).

## Accessibility checklist (HIG + WCAG 2.1 AA)
| Check | Mechanism |
|---|---|
| Dynamic Type | All text uses semantic styles; primary screens clamp at `accessibility3`. |
| VoiceOver labels | Every `Button`, `Toggle`, and tap-bound view has `.accessibilityLabel(...)`. |
| Reduce Motion | Wrappers in `AppMotion` short-circuit when `\.accessibilityReduceMotion` is `true`. |
| Reduce Transparency | `AppGlass` falls back to solid surfaces. |
| Color independence | Action colors are paired with a label + glyph. |
| Contrast | Text/background pairings checked against WCAG AA (4.5:1) on dark surfaces. |
| Tap targets | All interactive elements ≥ 44×44 pt; primary actions 56 pt. |
| Focus | We never auto-focus a search field or a text field on appear; we never block user input behind a long animation. |
