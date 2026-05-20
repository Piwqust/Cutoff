# Cutoff

A calm, studio-grade iPhone trainer for No-Limit Texas Hold'em **multi-table tournament** preflop decisions. Built in SwiftUI for iOS 17+, dark-mode forced, Liquid Glass on iOS 18.

> Educational training only. No real money, no play money, no live-table assistance. Bundled ranges are approximate demo data — not solver output.

---

## Screens

<p align="center">
  <img src="docs/screenshots/02_train_dashboard.png" alt="Train dashboard" width="32%" />
  <img src="docs/screenshots/05_preflop_trainer_new.png" alt="Preflop trainer drill" width="32%" />
  <img src="docs/screenshots/03_ranges.png" alt="13×13 range grid" width="32%" />
</p>
<p align="center">
  <img src="docs/screenshots/04_review.png" alt="Leak review" width="32%" />
  <img src="docs/screenshots/07_stack_depth.png" alt="Stack-depth lessons" width="32%" />
  <img src="docs/screenshots/01_onboarding.png" alt="Onboarding" width="32%" />
</p>

---

## What it is

- **Preflop drills** — 9-max MTT spots, one decision per card, immediate feedback in plain English.
- **Stack-depth lessons** — discrete buckets at 125 / 75 / 50 / 30 / 20 / 15 / 10 BB so the player builds depth-specific instinct.
- **Push/fold trainer** — short-stack jam ranges from every position.
- **13×13 range browser** — filter by position, depth, and action; tap a cell to see the mixed-strategy frequencies.
- **Leak review** — names the player's recurring mistakes in human language ("you over-defend the BB vs UTG opens at 30bb") and routes back to drilling them.
- **Standard routine** — a single tap pulls a random mix of preflop spots across positions and depths for a balanced rep.

## What it isn't

- Not a gambling app — no real money, no play money, no buy-ins, no chips.
- Not a live-table assistant — no in-hand coaching, no opponent profiling.
- Not a solver — bundled ranges are approximate demo data, not GTO output.

## Design principles

1. **Decision-first, explanation second.** The action the player must take is always front-and-center; the *why* comes after they commit.
2. **Bite-sized over comprehensive.** A session is a 60-second loop. Density is welcome only where it accelerates that loop.
3. **Calm darkness, never casino darkness.** Mint / emerald / peach on a deep neutral — a studio lamp at 11pm, never felt under a tournament chip.
4. **Tokens only.** `AppColors`, `AppSpacing` (8-pt grid), `AppRadius`, `AppTypography`, `AppMotion`, `AppGlass`. No hardcoded values.
5. **Accessibility is non-negotiable.** WCAG 2.1 AA contrast, Dynamic Type up to `accessibility3`, `reduceMotion`/`reduceTransparency` honored, color is never the only signal.

## Stack

- SwiftUI + MVVM with `@Observable`
- `SwiftData` for `QuizResult` / `TrainingSession`, `UserDefaults` for config
- JSON ranges in `Cutoff/Resources/Ranges/` (schema v2 with provenance)
- No backend, no third-party dependencies
- Liquid Glass `@available(iOS 18, *)` with `.ultraThinMaterial` fallback

Layout:

```
Cutoff/
├── Theme/          design tokens
├── Components/     PrimaryButton, glass surfaces, range grid cells…
├── Models/         Hand, Spot, Range, StackDepthBucket…
├── Logic/          EquityCalculator, Scorer, LeakAnalyzer, SpotGenerator
├── Persistence/    SwiftData stores
├── Features/       Onboarding, Train, Ranges, Review, Settings
└── Resources/Ranges/  bundled JSONL ranges
```

## Build

Requires Xcode 17+ and `xcodegen` (`brew install xcodegen`).

```sh
xcodegen generate
open Cutoff.xcodeproj
```

Or from the command line:

```sh
xcodebuild -project Cutoff.xcodeproj \
  -scheme Cutoff \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build test
```

## Range data

The repo ships an ingest pipeline (`Scripts/` + `tools/`) that converts external sources — currently PokerBench and PHH hand-history files — into the v2 range JSONL the app loads. Each spot carries a `source` and `provenance` field so the app can label cells as approximate vs. canonical. See [`docs/DATA_PROVENANCE.md`](docs/DATA_PROVENANCE.md).

## Documentation

| File | What it covers |
| --- | --- |
| [`docs/PRODUCT_PLAN.md`](docs/PRODUCT_PLAN.md) | Product spec, users, MVP scope |
| [`docs/UX_RESEARCH.md`](docs/UX_RESEARCH.md) | Mobile UX principles applied |
| [`docs/DESIGN_RESEARCH.md`](docs/DESIGN_RESEARCH.md) | Apple HIG + Liquid Glass notes |
| [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md) | Tokens, components, rules |
| [`docs/DATA_PROVENANCE.md`](docs/DATA_PROVENANCE.md) | Where the bundled ranges come from |
| [`docs/APP_STORE_COMPLIANCE.md`](docs/APP_STORE_COMPLIANCE.md) | Review-risk checklist |
| [`docs/IMPLEMENTATION_PLAN.md`](docs/IMPLEMENTATION_PLAN.md) | Phased build order |
| [`CLAUDE.md`](CLAUDE.md) | Engineering & compliance ground rules |

## Status

Private, in active development. Not on the App Store.
