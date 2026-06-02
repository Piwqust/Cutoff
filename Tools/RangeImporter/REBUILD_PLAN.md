# GTO Range Rebuild Plan

Branch: `feat/gto-range-rebuild`. Goal: a full, correct GTO preflop library
covering every (table size × stack depth × position × scenario), where every
chart passes `validate_ranges.py` and carries honest published-source
provenance.

## Hard rules

1. **No fabricated data, ever.** Ranges are transcribed/extracted from published
   canonical charts. We do **not** write a custom Nash/GTO solver and we do not
   hand-invent frequencies. This is a training app — wrong data actively
   mistrains, so an unsourced chart is worse than a missing one.
2. **Validation-gated.** Nothing enters `Cutoff/Resources/Ranges/` until
   `validate_ranges.py` passes for it (schema + VPIP band + polarity + pushfold).
3. **Provenance required.** Every chart records `source.type: "published"` and a
   `publisher` block (name / product / url / accessedDate / treeParams).
4. **Cross-check VPIP.** Where the source prints exact action %, the extracted
   chart's combo-weighted VPIP must match within ±2pp before acceptance.

## Source → scenario mapping (all free / legal for private study)

| Scenario | Primary free source | Mechanism |
|---|---|---|
| unopened (RFI) | PokerCoaching PDFs; RangeConverter PDFs | `extract_*` → importer |
| vsopen (vs-RFI) | PokerCoaching "Facing RFI" panels (by opener) | `extract_pokercoaching --mode vs-rfi` |
| vs3bet | PokerCoaching / RangeConverter vs-3bet panels | `--mode vs-3bet` |
| vs3betjam | **needs a vs-jam source** (HRC trial / PeakGTO) | call/fold only — NOT a copy of vs3bet |
| squeeze / blinddefense | PokerCoaching BvB + multiway | extract / transcribe |
| pushfold (≤15bb) | PokerCoaching push/fold charts; SnapShove free | transcribe (Nash, canonical) |

100bb packs are gated on PokerCoaching → source 100bb from RangeConverter.

## Current baseline (see `coverage_manifest.json`, regenerate any time)

- **493 OK · 46 BROKEN_clone · 30 BROKEN_polarity · 4 BROKEN_vpip** (573 total)

### Gate-correctness pass (done first — the original "173 broken" was inflated)
The validator itself had two metric bugs that produced ~93 false positives:
1. **Subrange denominator** — `vpip_percent` divided non-fold by *listed*
   combos. Files stored compactly (only played hands listed, trash omitted =
   fold) reported ~100% VPIP. Fixed: denominator is the full 1326-combo deck.
2. **vs3bet metric** — vs3bet/vs3betjam list only the opener's reachable
   *opening* subrange, so non-fold/listed is a continue-frequency (~80-97%),
   not a /1326 VPIP. Removed from VPIP-band (guarded by polarity + duplicate).
3. SB-vs-open band widened to ~10-50% after confirming those charts are
   correct GTO (proper polarity), not corrupt.

The 80 remaining are genuine: 46 fake vs3betjam clones, 30 polarity inversions
(trash playing ~100%, ex-HRC importer bug), 4 thin/corrupt unopened
(`10bb_hj` opens AA=fold(!), etc.).

## Batch order (highest value / lowest risk first)

1. **vs3betjam clones (46)** — definitively wrong (byte-identical to vs3bet).
   Either re-source as true call/fold vs-jam ranges, or remove the variant +
   its drill. Product decision — do not ship clones either way.
2. **BB polarity (30)** — corrupt (trash calling ~100%). HRC source is gone and
   the cribs are corrupted, so these must be **re-sourced** from PokerCoaching
   "Facing RFI" panels, not regenerated.
3. **RFI vpip breaches** — re-extract from PokerCoaching (cleanest chart type).
4. **vsopen / vs3bet vpip breaches** — re-extract by-opener panels.
5. **Backfill missing depths** for parity across 8-max/9-max.

## Tooling

- `scripts/fetch_pokercoaching.sh` — download free source PDFs.
- `scripts/extract_chart.py` — RangeConverter (orange/green/blue on navy).
- `scripts/extract_pokercoaching.py` — PokerCoaching (red/green/white). **Prototype**:
  row-1 RFI ±2-3pp; row-2 + non-RFI layouts need calibration before trust.
- `scripts/hrc_import.py` — HRC export → crib (note: suspected action-index bug;
  audit before reuse — see corrupted BB cribs).
- `scripts/validate_ranges.py` — the acceptance gate. Run `--strict` in CI.
- `coverage_manifest.json` — per-spot status; regenerate to measure progress.
