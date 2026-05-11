# CLAUDE.md — MTT Poker Trainer

## Project purpose
**MTT Poker Trainer** is an iPhone-only SwiftUI app for **educational** No-Limit Texas Hold'em MTT (multi-table tournament) training, aimed at amateur players. Users drill preflop decisions, learn how stack depth changes strategy, and review their leaks against locally-bundled demo training ranges.

This is **not** a gambling app. It is **not** a casino app. It is **not** a real-money or play-money poker app. There is no live-table assistance. There is no multiplayer. There is no currency, no deposits, no withdrawals, no cashout. All chip values shown are notional stack sizes used purely to teach tournament strategy.

## Build & test
This project is generated from `project.yml` using **xcodegen** (Homebrew: `brew install xcodegen`).

```sh
# (Re)generate Xcode project
xcodegen generate

# Build (Debug, iPhone simulator)
xcodebuild -project MTTPokerTrainer.xcodeproj \
  -scheme MTTPokerTrainer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build

# Run unit tests
xcodebuild -project MTTPokerTrainer.xcodeproj \
  -scheme MTTPokerTrainer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  test
```

Toolchain verified at scaffold time: Xcode 26.4.1, Swift 5.10, iOS 17.0 minimum deployment, iOS 26 SDK present.

Screenshots (after a successful boot + install):
```sh
xcrun simctl boot "iPhone 17"
xcrun simctl io booted screenshot docs/screenshots/<name>.png
```

## Architecture
- **SwiftUI** + lightweight MVVM. ViewModels are `@Observable` (iOS 17+) or `ObservableObject`.
- **Local-first**: `UserDefaults` for `TournamentConfig` and the onboarding flag; `SwiftData` for `QuizResult` and `TrainingSession`. JSON resource files in `MTTPokerTrainer/Resources/Ranges/` for demo training ranges.
- **No backend, no third-party dependencies.**
- Source layout:
  - `Theme/` — semantic design tokens
  - `Components/` — reusable SwiftUI views
  - `Models/` — pure data
  - `Logic/` — pure functions (scoring, parsing, BB math, spot generation)
  - `Persistence/` — `ConfigStore`, `ModelContainer`
  - `Features/<Area>/` — screen + viewmodel pairs
  - `Resources/Ranges/` — JSON demo ranges

## Design system rules
- **Tokens only.** Never hardcode colors, spacings, or radii inside views. Use `AppColors`, `AppSpacing`, `AppRadius`, `AppTypography`, `AppMotion`, `AppGlass`.
- **Dark UI** by default; the app forces `UIUserInterfaceStyle = Dark`.
- **Liquid Glass** via `AppGlass.glassBackground()` — gated `@available(iOS 18, *)`, with `.ultraThinMaterial` fallback. Always check `\.accessibilityReduceTransparency` and fall back to solid `CardSurface` when reduced.
- **Motion** via `AppMotion`; press scale `0.97`. Respect `\.accessibilityReduceMotion`.
- **Typography**: SF system, `.dynamicTypeSize(...DynamicTypeSize.accessibility3)` upper bound on dense screens.
- **Spacing**: 8-pt scale (`AppSpacing`). Default horizontal padding: `AppSpacing.lg` (20).
- **Components**: one clear primary action per screen; capsule (`PrimaryButton`) for primaries; glass outline (`SecondaryButton`) for secondaries.
- **Action color map**: Fold = muted, Call = teal/blue, Raise = mint, 3-bet = lime, Jam = coral, Mixed = gradient.

## App Store compliance constraints
The reviewer must read these as **product-level invariants**:
- Educational training only. The string "Educational poker training only. No real-money gambling." must remain visible on Onboarding, Settings, and the range-detail sheet.
- No real or virtual currency, no chips with monetary value, no buy-in flow, no deposits, no withdrawals, no cashout.
- No multiplayer, no live-table seating, no live-hand assistance, no in-play hint/coach feature.
- No casino visuals (slot machines, coins, jackpots, neon dollar signs, gold/red casino palette).
- No advertising and no IAP in MVP.
- No copyrighted poker assets, charts, or screenshots from any third party — including GTO Wizard, DTO, Run It Once, Upswing, or any paid solver dataset.

## Poker data constraints
- All bundled ranges live in `MTTPokerTrainer/Resources/Ranges/*.json` and are **hand-authored approximations**.
- Each range JSON **must** include `"source": { "type": "demo", "description": "Approximate demo training range. Not solver-verified." }`.
- The user-facing UI must label demo ranges as "Demo training range — not solver-verified" wherever a range, action, or explanation is shown.
- If we later support user-imported ranges, they must be labeled `"source.type": "user-defined"` and never relabeled as solver-verified.

## Educational-only mantra
> Educational poker training only. No real-money gambling. Demo ranges are approximate and not solver-verified.

## Preserve functionality
The project was initialized empty; there is no prior functionality to preserve. From this commit onward: do not delete or break working features without explicit user instruction. Refactors that change behavior require a corresponding update to relevant tests in `MTTPokerTrainerTests/`.
