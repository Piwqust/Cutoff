# MTT Poker Trainer

Educational iPhone training app for No-Limit Texas Hold'em **multi-table tournaments**. Built in SwiftUI for iOS 17+.

> Educational poker training only. No real-money gambling. Demo ranges are approximate and not solver-verified.

## What it is
- Preflop decision drills (9-max MTT)
- Stack-depth lessons (125 / 75 / 50 / 30 / 20 / 15 / 10 BB)
- Push/fold trainer for short stacks
- 13×13 range grid browser with filter chips
- Mistake / leak review

## What it isn't
- Not a gambling app — no real money, no play money, no buy-ins
- Not a live-table assistant — no in-hand coaching, no opponent profiling
- Not a solver — bundled ranges are **approximate demo data**, not GTO output

## Build
Requires Xcode 17+ and `xcodegen` (`brew install xcodegen`).

```sh
xcodegen generate
open MTTPokerTrainer.xcodeproj
```

Or from the command line:
```sh
xcodebuild -project MTTPokerTrainer.xcodeproj \
  -scheme MTTPokerTrainer \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build test
```

## Documentation
- `docs/PRODUCT_PLAN.md` — product spec & MVP scope
- `docs/UX_RESEARCH.md` — mobile UX principles applied
- `docs/DESIGN_RESEARCH.md` — Apple HIG + Liquid Glass notes
- `docs/DESIGN_SYSTEM.md` — tokens, components, rules
- `docs/DATA_PROVENANCE.md` — how the demo ranges are sourced
- `docs/APP_STORE_COMPLIANCE.md` — review-risk checklist
- `docs/IMPLEMENTATION_PLAN.md` — phased build order
- `CLAUDE.md` — engineering & compliance ground rules
