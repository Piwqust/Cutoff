# CLAUDE.md — MTT Poker Trainer

iPhone SwiftUI app for NLHE MTT preflop training. **Private — not shipped. Any materials (third-party charts, solver data) may be used freely.**

build & test on simulator & commit after every change

## Build
```sh
xcodegen generate
xcodebuild -project MTTPokerTrainer.xcodeproj -scheme MTTPokerTrainer \
  -destination 'platform=iOS Simulator,name=iPhone 17' build   # or `test`
```
iOS 17+, Swift 5.10, Xcode 26.

## Stack
SwiftUI + MVVM (`@Observable`). `UserDefaults` for config, `SwiftData` for `QuizResult`/`TrainingSession`, JSON ranges in `Resources/Ranges/`. No backend, no deps.

Layout: `Theme/`, `Components/`, `Models/`, `Logic/`, `Persistence/`, `Features/<Area>/`, `Resources/Ranges/`.

## Design
- **Tokens only** — `AppColors`, `AppSpacing` (8-pt, default `lg`/20), `AppRadius`, `AppTypography`, `AppMotion`, `AppGlass`. Never hardcode.
- Dark UI forced. Liquid Glass `@available(iOS 18, *)` with `.ultraThinMaterial` fallback; honor `accessibilityReduceTransparency`/`Motion`.
- `PrimaryButton` (capsule) / `SecondaryButton` (glass). Press scale `0.97`.
- Actions: Fold=muted, Call=teal, Raise=mint, 3-bet=lime, Jam=coral, Mixed=gradient.

Don't break working features without instruction; update `MTTPokerTrainerTests/` for behavior changes.
