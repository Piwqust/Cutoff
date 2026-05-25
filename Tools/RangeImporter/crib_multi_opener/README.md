# Multi-opener vsopen CSVs

Reference data for **future** multi-opener app integration. Each file is one
specific `(defender, opener)` pair — e.g. `mtt_8max_30bb_btn_vsopen_co.csv`
is BTN's defense range when CO has opened (and everyone between CO and BTN
folded).

Filename convention:
```
mtt_8max_<depth>bb_<defender>_vsopen_<opener>.csv
```

There are 28 unique (defender, opener) pairs per depth (defender ∈ UTG1..BB,
opener ∈ {seats earlier than defender}) × 6 stack depths (100, 60, 50, 40,
30, 20 bb) = **168 files**.

## Why they live here and not in `crib/`

These do **not** feed `swift run RangeImporter import`. The Swift importer's
`ChartSlug.parse` (see `Sources/RangeImporter/Filename.swift`) requires a
filename split into exactly five `_`-separated parts:

```
mtt_<size>max_<depth>bb_<position>_<facing>
```

A multi-opener filename has six parts (`..._vsopen_co`) and the `Facing`
enum has no `vsopen_co` case. Until the app side adds per-opener facings
(or a separate "opener" axis), these files would just be skipped silently.

Rather than half-integrate, the data lives here as audit-able CSVs so:
1. You can read the per-opener differences manually (see the
   per-opener VPIP matrix in `git show 35a178d` for a sample).
2. Future PR can wire them up cleanly when product direction is decided.

## How much do per-opener ranges actually differ?

Quick illustration at **30 bb**, defender VPIP (combo-weighted):

| Defender | vs UTG | vs UTG1 | vs LJ | vs HJ | vs CO | vs BTN | vs SB |
|---|---|---|---|---|---|---|---|
| UTG1 | 11.0% | — | — | — | — | — | — |
| LJ | 11.2% | 11.0% | — | — | — | — | — |
| HJ | 9.7% | 9.8% | 10.4% | — | — | — | — |
| CO | 9.3% | 9.8% | 10.7% | 12.2% | — | — | — |
| BTN | 9.4% | 10.7% | 12.0% | 13.8% | **14.6%** | — | — |
| SB | 43.5% | 45.3% | 47.8% | 45.7% | 46.5% | 37.2% | — |
| BB | 100.0% | 100.0% | 100.0% | 100.0% | 100.0% | 100.0% | 99.9% |

(BB's "100%" is the SB/BB voluntary-action inflation discussed in the
60bb/100bb commit messages — BB calling/raising/checking dominates.
The actual defense-strength differences are visible inside the per-hand
frequencies.)

**Key takeaway**: BTN's defense range is ~50% wider vs CO than vs UTG.
That's a meaningful real-world gap — but the current single-`vsopen`
chart per defender collapses it to one number.

## Regenerating

```sh
for zip in 100bb_v2 060bb 050bb 040bb 030bb 020bb; do
  python3 Tools/RangeImporter/scripts/hrc_import.py \
    --input ~/Downloads/hrc_8max_chipev_${zip}.zip \
    --output Tools/RangeImporter/crib_multi_opener/ \
    --multi-opener-8max
done
```

## Future work — Swift integration

Tasks to do when adopting:
1. Add `FacingAction` cases like `.vsOpenUTG`, `.vsOpenCO` (or a richer
   model: `case vsOpen(opener: TablePosition)`).
2. Extend `Filename.swift::ChartSlug.parse` to accept 6-part stems.
3. Update the 8 exhaustive switches over `FacingAction` (see
   `Cutoff/Logic/SpotMatrix.swift`, `RangesViewModel.swift`,
   `DrillTrainerView.swift`, `TrainDashboardView.swift`,
   `SpotGenerator.swift`, `TrainingSpot.swift::isValid`,
   `PokerTableSnapshot.swift::actionAhead`).
4. Decide on app behavior when an opener is not explicitly known
   (fall back to the canonical `vsopen`).
5. Update `RangeService.bestChart(...)` signature to accept an opener
   position parameter.
