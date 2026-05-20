# Product Plan — Cutoff

## One-line product statement
A premium, dark-mode iPhone app that teaches amateur players the preflop decisions and stack-depth instincts they need to play No-Limit Texas Hold'em **multi-table tournaments** better — using bite-sized drills and clearly-labeled demo ranges. No money. No live assistance. Just practice.

## Target user
- **Primary**: amateur MTT player who knows the rules of NLHE but is leaky preflop, doesn't have a consistent push/fold reflex, and can't afford or doesn't want to pay for a paid solver subscription.
- **Secondary**: a casual home-game player curious about tournament theory.

## Core jobs to be done
1. *Help me decide quickly whether to fold / call / raise / 3-bet / jam in a given preflop spot.*
2. *Help me build intuition for how my decisions change as my stack shrinks from 125 BB to 10 BB.*
3. *Show me where I'm leaking, in plain language, and let me drill that specific weakness.*
4. *Let me browse a clean range chart on my phone without it feeling like a spreadsheet.*

## Tournament defaults (anchor profile)
| Field | Default |
|---|---|
| Format | NLHE MTT |
| Table size | 9-max |
| Starting stack | 25,000 |
| Starting blinds | 100 / 200 |
| Starting BB | **125** |
| Blind level duration | 15 min |
| Ante type | Unknown / not set |

`startingBB = startingStack / bigBlind` must equal **125** for the defaults — verified in `BBCalculatorTests`.

## MVP feature scope
1. **Onboarding** — name the product, set player level, default tournament profile, accept educational disclaimer, jump into training.
2. **Tournament Setup** — let the user adjust stack/blinds/table/level duration/ante and see a live BB summary.
3. **Train Dashboard** — show the current profile, "today's drill" CTA, four mode cards, recent stats.
4. **Preflop Trainer** — drill spots from bundled demo ranges; immediate feedback with a short, human explanation.
5. **Range Grid** — 13×13 hand matrix; filter by position, depth, facing action, ante; tap a cell for detail.
6. **Stack Depth Trainer** — one-card-per-depth overview with a one-line lesson and "drill this" CTA.
7. **Push/Fold Trainer** — short-stack jam/fold reps with a large Jam and Fold button.
8. **Review** — accuracy hero, named leaks ("Too loose UTG", "Overfolding BB"), drill CTA per leak.
9. **Settings** — profile, level, data source, accessibility, legal/educational disclaimer, version.

## Explicit non-goals (MVP)
- No real-time multiplayer tables.
- No real money, play money, "coins", or virtual currency of any kind.
- No live-game hint/coach feature.
- No solver. No equity calculator. No ICM solver.
- No advertising. No IAP.
- No iCloud sync (local-first only).
- No accounts.
- No iPad-optimized layout (works in compatibility mode).
- No localization beyond English (the strings are catalog-ready though).

## Success metrics (informal, for a hypothetical TestFlight cohort)
- First training spot answered within 90 seconds of first launch.
- ≥80% of users complete more than one drill in their first session.
- Self-reported usefulness of leak summaries.

## Risks & mitigations
| Risk | Mitigation |
|---|---|
| App Store rejection as "gambling-adjacent" | Strong educational positioning, no currency, persistent disclaimer, no live assistance, see `APP_STORE_COMPLIANCE.md`. |
| Misinterpreting demo ranges as solver output | Every range JSON + every UI surface that shows a range labels the data as "demo, not solver-verified". |
| Copyright on poker chart data | Only hand-authored approximate ranges ship in the bundle. No paid solver data, ever. See `DATA_PROVENANCE.md`. |
| App feels like a casino | Mint/emerald/peach palette, soft gradients, glass, lots of breathing room — see `DESIGN_RESEARCH.md`. |
