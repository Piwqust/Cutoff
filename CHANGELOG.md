# Changelog

All notable changes to **Cutoff** are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project aims to adhere to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Versions before `0.1.0` were tracked only in commit history; this file begins
the maintained changelog.

## [Unreleased]

## [0.1.0] — 2026-06-02

First release with a maintained changelog. This release consolidates the entire
preflop range-library rebuild and adds a new in-app Strategy guide. It is the
result of merging the `feat/poker-academy-import` line (43 commits) into `main`.

### Added

- **Strategy tab.** A new fourth tab (`map.fill`) presenting a structured,
  chapter-based MTT preflop strategy guide.
  - Chapter list (`StrategyGuideView`) with detail pages
    (`StrategyChapterDetailView`) and a reusable component library
    (`StrategyComponents`) — callout cards, range snippets, exploit notes.
  - Per-chapter **progress tracking** that reacts to read state.
  - Fitzgerald-style exploit sections; paging implemented with `ScrollView`.
  - **Russian-only gate**: the guide content ships in Russian. When the app
    language is English the tab shows a "not supported" notice rather than
    untranslated text.
- **Rebuilt 8-max preflop range library** — ~1,930 bundled chart JSONs covering
  RFI, vs-open (per individual opponent position), and vs-3bet (per opponent),
  across 12 stack depths.
  - Each chart carries `source` provenance (publisher, product, URL, solver
    assumptions) and a `spot` block (position, opponent position, facing action,
    stack depth, ante type), so the app can label and match charts precisely.
  - Ranges sourced from published community charts (RangeConverter / poker.academy
    free charts), ChipEV with a big-blind ante, frequencies rounded per source.
- **RangeImporter CLI** (`Tools/RangeImporter/`) — a Swift package that converts
  crib-sheet CSVs into the bundled range JSON schema: `CribSheet`, `HandClasses`,
  `Emitter`, `Filename`, `NineMaxAdapter`, plus `RangeImporterTests` and rebuild
  docs.
- **poker.academy scraping pipeline** (`Tools/RangeImporter/scripts/`,
  `staging/poker_academy_charts/`) — bulk scraper (`scrape_all_ranges.py`,
  `full_harvest.js`) with label-based opponent-position clicking and robust
  retry/cell-matching.
- **`validate_ranges.py` CI gate** for bundled range JSONs.
- **Published-source support** in the data model (`SourcePayload`, `Publisher`,
  `SolverConfig`) with coverage in `PublishedSourceTests`.

### Changed

- **Default format is now 8-max** (was 9-max). `TournamentConfig` defaults to an
  8-max MTT at 125 BB; 9-max charts are derived from the 8-max baseline by
  adaptation (`NineMaxAdapter`). 8-max matches modern solver libraries
  (RangeConverter, GTO Wizard, DTO).
- **Stack-depth buckets** adapted to the rebuilt library: 10, 15, 20, 25, 30, 35,
  40, 50, 60, 70, 80, 100 BB (CE-Symmetric 10–100 BB). Legacy-only facings snap
  to the nearest bucket.
- **Settings moved out of the tab bar** into the Strategy screen — Settings is
  now opened from within `StrategyGuideView` instead of occupying its own tab.
- **Range matching is opponent-aware.** `RangeLoader` filters by opponent
  position with a nearest-opponent fallback, and derives chart metadata from the
  filename when needed. `SpotMatrix`, `RangeChart`, and `TrainingSpot` gained an
  `opponentPosition` dimension.
- **Range views/components** updated for the opponent dimension: `RangeExplorerView`,
  `RangesView`/`RangesViewModel`, `RangeCellView`, `RangeGridView`,
  `PokerTableView`, `PokerTableSnapshot`.
- 100 BB re-solved with the Advanced preset to match the 30–60 BB methodology;
  20–60 BB scraped ranges replaced with HRC-derived solver output for the
  canonical baseline.

### Fixed

- **All charts rendering as fold** — removed a bare-string emit shortcut in the
  importer `Emitter`.
- **Emitter pure-action shortcut** was emitting crib vocabulary instead of
  `PreflopAction` keys.
- **`validate_ranges` gate** metric bugs that over-reported corruption
  (203 → 106 false errors; true corruption was 80 files).
- Strategy guide **deduplication and correctness** fixes.

### Removed

- Removed the dedicated **Settings tab** from the tab bar (now reachable inside
  the Strategy screen).
- Dropped the gamification "rings" from the Strategy guide in favor of the
  reactive progress model.

[Unreleased]: https://github.com/Piwqust/Cutoff/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Piwqust/Cutoff/releases/tag/v0.1.0
