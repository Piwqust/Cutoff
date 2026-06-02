# RangeImporter

A small Swift Package CLI that turns long-form CSV crib sheets into the
canonical Cutoff range JSON format, and derives 9-max ranges from an 8-max
baseline via the published industry adaptation rule.

This tool exists because **no public solver publishes 9-max 100bb MTT GTO
ranges**. The industry standard is 8-max with 1bb (12.5%) big-blind ante,
distributed as PDF chart packs (RangeConverter, GTO Wizard library, etc.).
We transcribe those charts here rather than fabricate solver output.

## Build & test

```sh
cd Tools/RangeImporter
swift build
swift test       # 11 tests
```

## Usage

### Import crib sheets → canonical JSON

```sh
swift run RangeImporter import \
  --input crib/ \
  --output ../../Cutoff/Resources/Ranges/
```

- `--input` may be a single `.csv` file or a directory.
- Filenames drive the slug: `mtt_<size>max_<depth>bb_<position>_<facing>.csv`.

### Derive 9-max from 8-max source

```sh
swift run RangeImporter derive-9max \
  --input ../../Cutoff/Resources/Ranges/ \
  --output ../../Cutoff/Resources/Ranges/
```

This reads every `mtt_8max_*.json` and writes the corresponding `mtt_9max_*`
sibling. Adaptation rule (`NineMaxAdapter.swift`):

| 8-max source | 9-max target(s) | Action |
|--------------|-----------------|--------|
| UTG | UTG (9-max) | Demote ~3% bottom combos (`A2s`, `A3s`, `K7s`, `K8s`, `98s`, `87s`, `76s`, `65s`, `54s`, `JTo`, `T9o`) to fold |
| UTG | UTG+1 (9-max) | Copy verbatim |
| LJ / HJ / CO / BTN / SB / BB | same seat (9-max) | Copy verbatim |

The adaptation note is recorded in `source.solver.assumptions` of each
emitted 9-max file so the provenance is auditable.

## Why a CSV step

The RangeConverter PDFs contain PNG matrices — no machine-readable export.
Transcription is manual. CSV makes it diff-friendly, validates as you go
(frequency sums must equal 1.0, hand notations must be canonical, action
vocabulary is closed), and keeps the JSON emission a one-shot mechanical
step.

## Adding a crib sheet

1. Create `crib/mtt_8max_100bb_co_unopened.csv`.
2. Add one row per nonzero-frequency leg:
   ```
   notation,action,freq
   AA,raise,1.0
   A5s,raise,0.5
   A5s,fold,0.5
   ```
3. Hands not listed default to 100% fold.
4. Run `swift run RangeImporter import --input crib/ --output ../../Cutoff/Resources/Ranges/`.
5. Run `xcodegen generate && xcodebuild test` from the repo root.

## Outside the app target

`Tools/` lives outside the xcodegen `Cutoff/` and `CutoffTests/` source roots,
so this package is **not** compiled into the iOS app or its test bundle.
