# RangeConverter 8-max crib sheets

This directory holds the long-form CSV transcriptions of the RangeConverter
free PDF set (8-max MTT, 1bb ante / 12.5%, 2.5x open tree).

## Filename convention

```
mtt_<tableSize>max_<depth>bb_<position>_<facing>.csv
```

- `tableSize`: `8` for the canonical RangeConverter baseline; `9` is generated
  by `RangeImporter derive-9max` and should not be hand-edited.
- `depth`: `100`, `80`, `60`, `50`, `40`, `30`, `20`, `10`
- `position`: `utg`, `utg1`, `lj`, `hj`, `co`, `btn`, `sb`, `bb` (8-max omits `utg1`; UTG+1 in 9-max is derived from 8-max UTG)
- `facing`: `unopened` (RFI), `vsopen` (vs RFI), `vs3bet`

## Row format

```
notation,action,freq
AA,raise,1.0
A5s,raise,0.5
A5s,fold,0.5
```

- One row per nonzero-frequency leg of the strategy.
- Frequencies for a given notation must sum to `1.0`.
- Hands not listed are treated as **100% fold** by the JSON decoder.
- Valid actions: `fold`, `call`, `limp`, `raise`, `threeBet`, `jam`.

## Running the importer

```sh
cd Tools/RangeImporter
swift run RangeImporter import \
  --input crib/ \
  --output ../../Cutoff/Resources/Ranges/

# Then regenerate the 9-max library from the 8-max source:
swift run RangeImporter derive-9max \
  --input ../../Cutoff/Resources/Ranges/ \
  --output ../../Cutoff/Resources/Ranges/
```

## Why we can't auto-fill this

The RangeConverter PDFs are PNG charts inside a PDF — there is no machine-
readable export. The numbers must be transcribed by reading the published
chart for each spot. This tool exists to make that transcription mechanical
and validated (frequency sums, hand-notation legality, file naming).
