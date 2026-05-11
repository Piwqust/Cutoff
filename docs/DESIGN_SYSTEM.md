# Design System

A small token set, used everywhere. No view should hardcode a color, spacing, radius, or animation curve.

## Color tokens (asset catalog + `AppColors`)

| Token | Hex | Role |
|---|---|---|
| `backgroundDeep` | `#050807` | App root background, root gradient base |
| `backgroundGreenBlack` | `#07110D` | Gradient mid-stop |
| `backgroundSurface` | `#0B1612` | Below-card surface where glass doesn't apply |
| `cardSurface` | `#171A1D` | Solid card fallback for Reduce Transparency |
| `cardSurfaceGreen` | `#14201B` | Tinted card surface for "today's drill" hero |
| `primaryMint` | `#65F2B0` | Primary CTA fill, Raise action |
| `primaryEmerald` | `#42E89C` | Primary CTA pressed / gradient stop |
| `accentGreen` | `#22C97A` | Success indicators, profile chip |
| `accentPeach` | `#FF9A7A` | Warm secondary accent |
| `accentCoral` | `#F6B08A` | Jam action |
| `accentLime` | `#DDFB7A` | 3-bet action |
| `textPrimary` | `#F5F7F6` | Primary text |
| `textSecondary` | `#9DB0A8` | Supporting text |
| `divider` | `rgba(255,255,255,0.08)` | 1-pt hairlines |
| `errorSoft` | `#E07A7A` | Validation / Mistake hint (soft, not harsh casino red) |

**Action color map** (must be paired with label + glyph):
| Action | Token |
|---|---|
| Fold | `actionFold` (#2A2F33) |
| Call | `actionCall` (#6FB8E0) |
| Raise | `actionRaise` (= primaryMint) |
| 3-bet | `actionThreeBet` (= accentLime) |
| Jam | `actionJam` (= accentCoral) |
| Mixed | gradient mint→lime |

## Typography (`AppTypography`)
| Style | SwiftUI | Weight | Use |
|---|---|---|---|
| `largeTitle` | `.largeTitle` | bold | Screen titles |
| `title2` | `.title2` | semibold | Section headers |
| `headline` | `.headline` | semibold | Card titles |
| `body` | `.body` | regular | Primary text |
| `subheadline` | `.subheadline` | medium | Context chips |
| `footnote` | `.footnote` | regular | Disclaimers |
| `caption` | `.caption` | regular | Settings fine print |
| `numericLarge` | `.system(.title, design: .rounded).monospacedDigit()` | bold | Large stack/BB readouts |
| `numericMedium` | `.system(.headline, design: .rounded).monospacedDigit()` | semibold | Stat values |

Dynamic Type respected via `.dynamicTypeSize(...DynamicTypeSize.accessibility3)` on data-dense screens.

## Spacing (`AppSpacing`)
| Token | pt |
|---|---|
| `xxs` | 4 |
| `xs` | 8 |
| `sm` | 12 |
| `md` | 16 |
| `lg` | 20 |
| `xl` | 24 |
| `xxl` | 32 |
| `xxxl` | 40 |
| `huge` | 56 |

Horizontal page padding: `lg` (20). Card inner padding: `md`–`lg`. Section gap: `md`.

## Radius (`AppRadius`)
| Token | pt | Use |
|---|---|---|
| `chip` | 12 | filter chips |
| `button` | 28 | capsule on 56-pt buttons (effectively half-height) |
| `card` | 24 | regular cards |
| `hero` | 32 | hero cards |
| `sheet` | 28 | bottom sheets |

## Shadow / elevation
No drop shadows. We rely on glass blur, gradients, and `divider` hairlines for elevation cues. This keeps the dark UI from getting muddy.

## Glass / Material (`AppGlass`)
A single modifier:

```swift
.glassBackground(cornerRadius: AppRadius.card)
```

Resolves in order:
1. If `\.accessibilityReduceTransparency` is `true` → solid `CardSurface`, rounded.
2. If `@available(iOS 18, *)` → uses the new `Glass` material.
3. Else → `.ultraThinMaterial` inside a `RoundedRectangle`.

Layering rule: at most **one** glass surface in a vertical stack. Glass on glass is forbidden.

## Motion (`AppMotion`)
| Token | Curve | Duration |
|---|---|---|
| `quick` | `.easeOut` | 0.18 s |
| `standard` | `.smooth` | 0.28 s |
| `entrance` | `.spring(response: 0.35, dampingFraction: 0.85)` | — |
| `press` | scale 0.97 | 0.12 s |

`AppMotion.respectReducedMotion(curve)` returns `.linear(duration: 0)` when the user has Reduce Motion on.

## Components

### `AppBackground`
Root background; gradient `backgroundDeep → backgroundGreenBlack → backgroundSurface`, with a soft radial mint glow at the top-left at 6% opacity. Drift animation is removed under Reduce Motion.

### `GlassCard`
A container with `AppGlass` background, `AppRadius.card`, padding `AppSpacing.lg`, optional title + trailing accessory.

### `PrimaryButton`
Capsule, height 56, `primaryMint` fill, `backgroundDeep` foreground for AA contrast on the mint. Press scale via `AppMotion.press`.

### `SecondaryButton`
Capsule, height 56, transparent fill, `divider` 1-pt border, `textPrimary` foreground. Becomes the glass-outline variant on a non-glass background.

### `ActionButton`
56-pt capsule, action color fill, dark foreground, glyph + label. Used for Fold/Call/Raise/3-bet/Jam.

### `StatCard`
Compact `GlassCard` with a small label, large numeric value, optional trend hint.

### `TrainingModeCard`
Wider rounded card with an SF symbol, title, subtitle, and trailing chevron.

### `FilterChip`
Capsule, `chip` radius, two states: selected (mint fill, dark text) and unselected (glass with `divider` border, `textSecondary` text).

### `HandCardView`
Two stylized playing cards rendered in pure SwiftUI shapes (no external imagery). Uses red/black ink with mint pips. Front-faced; flippable for Reduce Motion users via an instant swap.

### `RangeGridView` / `RangeCellView`
13×13 `LazyVGrid`. Each cell is a tappable square coloured by `RangeAction`. Sticky filter row above.

### `FeedbackSheet`
Bottom sheet at `.presentationDetents([.fraction(0.4), .medium])`. Header (Correct/Close/Mistake), bestAnswer chip, explanation, "Next hand" mint CTA.

### `LeakCard`
Glass card with title (plain English), severity bar (`actionFold` → `accentCoral`), short description, "Drill this" CTA.

### `TournamentSummaryCard`
Hero card on Onboarding / Dashboard: 25,000 / 100·200 / 125 BB / 9-max in `numericLarge` with labels.

## Iconography
- SF Symbols only.
- Suit glyphs from SF Symbols (`suit.heart.fill` etc) for non-decoration only — primarily on `HandCardView`.
- No custom illustrations of chips, coins, or jackpots. No third-party icon sets.

## Accessibility rules
- Every interactive view must have an `.accessibilityLabel` describing meaning.
- Every action button has a glyph + a text label.
- Color is never the only signal of state.
- Dynamic Type supported up to `accessibility3` on every primary screen.
- VoiceOver reading order: title → context → primary action.
- Reduce Motion + Reduce Transparency obeyed through `AppMotion` and `AppGlass`.

## What this system intentionally lacks
- No drop shadows.
- No bespoke animation curves outside `AppMotion`.
- No custom navigation bar.
- No skeuomorphic poker chips, felt textures, neon, or gold.
