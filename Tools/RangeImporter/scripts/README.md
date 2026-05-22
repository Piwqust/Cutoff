# RangeImporter / scripts / extract_chart.py

Pixel-based chart extractor — turns a cropped RangeConverter PDF chart panel
(PNG) into the long-form crib CSV that `swift run RangeImporter import`
consumes.

## Why this exists

Manual transcription took ~10 minutes per chart × ~500 charts in the free
RangeConverter MTT pack = ~80 hours. Pixel sampling does the same job in
~1 second per chart, with the chart's stated VPIP% as a built-in sanity
check.

## Accuracy

Measured on the 7 RFI panels of page 3 of the 100bb PDF (2-action charts):

| Position | Stated | Extracted | Δ |
|----------|--------|-----------|---|
| UTG      | 14.72% | 15.99%    | +1.27 |
| UTG1     | 18.74% | 20.29%    | +1.55 |
| LJ (MP)  | 22.38% | 23.83%    | +1.45 |
| HJ       | 27.67% | 26.85%    | −0.82 |
| CO       | 36.09% | 37.56%    | +1.47 |
| BTN      | 53.72% | 52.19%    | −1.53 |

Average absolute error: ~1.3pp. Well within the chart's own "round to
nearest 50%" tolerance band.

**Caveat: 3-action charts (SB unopened, vs-RFI, vs-3bet) are less reliable**
because cells can hold three colours in various split patterns. Use auto
output as a starting point, then eyeball-correct the cells whose action
breakdown looks suspicious.

## Pipeline

```sh
# 1. Render the PDF to PNG.
brew install poppler
pdftoppm -png -r 300 8max_100bb.pdf pages/page

# 2. For each chart panel on each page, crop a single panel at 2× scale.
#    (Layout varies by page; this is the one manual step.)
magick pages/page-03.png -crop 800x1080+5+205 +repage -resize 200% chart_utg.png

# 3. Extract the cell colours into a crib CSV.
cd Tools/RangeImporter
python3 scripts/extract_chart.py \
    --input /tmp/chart_utg.png \
    --slug mtt_8max_100bb_utg_unopened \
    --output crib/ \
    --print-vpip

# 4. Import & derive 9-max as usual.
swift run RangeImporter import --input crib/ --output ../../Cutoff/Resources/Ranges/
swift run RangeImporter derive-9max --input ../../Cutoff/Resources/Ranges/ --output ../../Cutoff/Resources/Ranges/
```

## How it works

1. **Auto-bounds.** Scans the panel image for the first/last rows and
   columns containing any chart-colour pixel (orange/green/blue), and
   detects the gap between the matrix and the colour-legend bar below it.
2. **Cell sampling.** Each of the 13×13 cells is sampled at ~99 pixel
   positions in its inner 80%. Pixels that classify as text (`?`) are
   dropped — the cell background still dominates because the white hand
   notation is only a few pixels wide.
3. **Colour bands.** Hand-tuned RGB thresholds map pixels to R/L/F. Yellow
   panel-title text would alias as orange without the r/g-ratio filter.
4. **Quantisation.** RangeConverter explicitly rounds every cell to one of
   `{0%, 50%, 100%}` per action. We replicate this: any colour with ≥30%
   of the cell area counts as one of the played actions; up to two
   colours qualify per cell.

## Tuning

If a particular chart batch comes back with systematic offsets:

- **VPIP too high** → tighten the 30% threshold in `quantise_to_actions`,
  or narrow the colour bands in `classify_pixel`.
- **VPIP too low** → loosen the threshold, or widen the bands.
- **A row not detected** → check `auto_bounds`; the title text might be
  encroaching on the matrix area. Pass `--bounds x0,y0,x1,y1` manually.

For any extracted crib whose VPIP cross-check is off by > 2pp, open the
panel in an image viewer and reconcile by hand.
