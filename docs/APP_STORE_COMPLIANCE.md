# App Store Compliance

This document is a checklist the engineer (and any future contributor) reads before adding a feature. The goal: ship a clean educational training app, not a gambling-adjacent app.

## Positioning (must remain true at all times)
- The app is positioned as **educational training**, in the description, in onboarding copy, in Settings, and on the range-detail sheet.
- A persistent disclaimer is present in three independent surfaces: Onboarding, Settings, Range Detail sheet:
  > Educational poker training only. No real-money gambling. Demo ranges are approximate and not solver-verified.

## What the app does NOT do (and must never do without product/legal review)
- ❌ Real-money play or wagering of any kind
- ❌ Play-money "chips" used to gate features or buy in
- ❌ Deposits, withdrawals, top-ups, cashout, or virtual currency purchase
- ❌ Real-player multiplayer or live seating
- ❌ Live-hand assistance (in-play HUD, in-play range suggestion, in-play coach)
- ❌ Card counting tools
- ❌ Loot boxes, scratch-cards, or any randomized reward-with-monetary-value mechanic
- ❌ Tournament leaderboards tied to monetary prizes
- ❌ Casino-style visuals: slot pulls, jackpot meters, gold coins flying, dollar-sign neon

## What the app DOES do (and how to keep those features defensible)
- ✅ Drills preflop decisions on **demo** ranges
- ✅ Teaches stack-depth intuition through bite-sized cards
- ✅ Reviews user's own mistakes against demo correct answers
- ✅ Lets the user adjust an in-app **notional** tournament profile (25,000 chips, 100/200 blinds, 9-max — these are not playable chips, they're just labels used by the training math)

## Apple App Review Guidelines — relevant sections (engineer's reading)

> The numbers below reference the [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) at the time of writing. Always consult the current published version before submission.

### 5.3 — Gambling, Contests, and Lotteries
We are not a gambling app and must clearly look like an educational/training app. Mitigations in place:
- No real-money or virtual currency anywhere.
- No "win/loss" framing on outcomes — outcomes are "Correct", "Close", or "Mistake".
- Persistent educational disclaimer (see above).
- The app does not enable or facilitate any real-money or virtual-currency gambling.

### 5.2 — Intellectual Property
We must not copy:
- The reference app's UI, icons, screenshots, logo, or asset library.
- Paid solver charts (GTO Wizard, DTO, Upswing, Run It Once).
- Any third-party trademarked term ("WSOP", "WPT", brand names of casinos, etc.).
- Copyrighted course material from training sites.

Practical rule: every visual element in this repo is system-provided (SF Symbols, system fonts) or original work. Every range JSON is hand-authored.

### 4.0 — Design / 4.2 Minimum Functionality
The app must do more than show a range chart. MVP scope includes drills, scoring, leak detection, stack-depth lessons, push/fold trainer — collectively meaningful interactive functionality.

### 1.4.3 — Medical / 1.4 Physical Harm
Not applicable, but: we make no claims about real-money outcomes. We are not a betting tipster. The Review tab uses helpful, non-judgemental language and **does not push the user toward real-money poker**.

## Privacy (App Privacy report at submission)

The MVP collects **no** user-identifying data:
- No analytics SDKs.
- No crash reporters that collect PII.
- No account creation.
- No advertising identifier.
- No location, contacts, photos, microphone, or camera access.
- `TournamentConfig` and `QuizResult` are stored locally only.

In the App Privacy form, expected answer: "Data Not Collected". If we add a crash reporter post-MVP, it must be one that doesn't tie crashes to a user ID and must be disclosed appropriately.

## Marketing copy guardrails
Avoid in screenshots, App Store description, keywords:
- "Bet", "wager", "win money", "real money", "live", "casino", "play for real", "free chips".

Prefer:
- "Train", "drill", "practice", "study", "preflop", "tournament", "MTT".

## Submission risk register
| Risk | Likelihood | Mitigation |
|---|---|---|
| Reviewer assumes gambling app from name | Low–Medium | Title says "Trainer"; first-screen disclaimer; no chips/casino visuals |
| Reviewer questions chart data source | Low | All ranges labeled "demo, not solver-verified"; provenance doc shipped |
| Reviewer flags copycat of reference app | Low | Original visual identity; no copied assets; design system documented |
| Reviewer queries IAP that doesn't exist | None | No IAP in MVP |

## Engineer's pre-submission checklist
- [ ] Disclaimer string present in Onboarding, Settings, Range Detail sheet — verified at runtime.
- [ ] No real or virtual currency UI anywhere — grep `"$"`, `"USD"`, `"€"`, `"buy"`, `"deposit"`, `"cashout"`.
- [ ] No casino visuals in `Assets.xcassets` — manual review.
- [ ] All range JSONs in `Resources/Ranges/` have `source.type == "demo"` — verified by `RangeLoaderTests`.
- [ ] App icon does not include coins, jackpots, dollar signs, or slot reels — manual review.
- [ ] Privacy nutrition label set to "Data Not Collected".
- [ ] App description does not contain forbidden marketing words.
