#!/usr/bin/env python3
"""extract_chart.py — pixel-extract a RangeConverter chart into a crib CSV.

The free RangeConverter MTT PDFs render each spot as a 13x13 grid where cell
colour encodes the action:
  - orange  →  raise (or 3-bet / 4-bet on vs-RFI / vs-3bet charts)
  - green   →  call / limp
  - blue    →  fold

Cells split half-orange/half-blue (etc.) encode a 50/50 mix per the source's
"round to nearest 50%" convention.

This script reads an already-cropped chart PNG (a single panel, one position,
one facing), classifies every cell by pixel-sampling, and emits the canonical
long-form CSV consumed by `swift run RangeImporter import`.

Workflow:
  1. Render a PDF page to PNG with `pdftoppm -png -r 300`.
  2. Crop each chart panel and resize 2x with ImageMagick.
  3. Run this script: `extract_chart.py --input chart.png --slug mtt_8max_100bb_co_unopened --output crib/`

The grid bounds are hardcoded for the 1600x2160 cropped/2x format used by the
existing `/tmp/rc_full/*_big.png` pipeline. Pass --bounds to override.
"""

from __future__ import annotations

import argparse
import sys
from collections import Counter
from pathlib import Path

from PIL import Image

# Default grid bounds — matrix area inside a 1600x2160 cropped+2x chart panel.
DEFAULT_BOUNDS = (5, 275, 1535, 1855)  # x0, y0, x1, y1
RANKS = list("AKQJT98765432")


def classify_pixel(px: tuple[int, int, int]) -> str:
    """Map a single pixel to {R, L, F, ?}.

    Bands tuned from RangeConverter PDFs at 300 DPI + 200% magick resize.

    Orange (raise) vs yellow (panel title): both have r>180 with low blue.
    Discriminate by r/g ratio — orange's r/g is well above 1.5.

    Fold (blue) cells come in two shades on the same page: a bright blue for
    common folds and a darker navy for the deepest-fold cells (visually
    indistinguishable from the page background). Match both. We avoid
    confusing dark navy with the true page background by requiring b > 1.5 × g
    (which holds for both fold shades but not for the (r≈g≈b) page edges).
    """
    r, g, b = px
    if r > 180 and 90 < g < 145 and b < 70 and r / max(g, 1) >= 1.5:
        return "R"  # raise (orange)
    if r < 110 and 120 < g < 170 and 80 < b < 135:
        return "L"  # limp / call (green)
    if r < 70 and 80 < g < 145 and 100 < b < 175:
        return "F"  # fold (bright blue)
    # Dark-navy fold variant. Restricted to r<55 to avoid eating gray text.
    if r < 55 and 35 < g < 95 and 60 < b < 140 and b > g and (b - g) >= 20:
        return "F"
    return "?"  # text, border, antialiasing


def hand_at(row: int, col: int) -> str:
    """Canonical hand notation for a matrix cell."""
    if row == col:
        return f"{RANKS[row]}{RANKS[col]}"
    if row < col:
        return f"{RANKS[row]}{RANKS[col]}s"
    return f"{RANKS[col]}{RANKS[row]}o"


def classify_cell_proportions(im: Image.Image, cx: float, cy: float, cell_w: float, cell_h: float) -> dict[str, float]:
    """Return action → fraction-of-cell-area for a cell.

    Samples a dense grid inside the cell (avoiding the outer border and any
    central text glyph), classifies each pixel, and returns the proportion
    of non-text pixels assigned to each action. Mix encoding then becomes a
    matter of bucketing: ≥80% one colour → pure; 30%–70% split → 50/50 mix;
    intermediate → coverage-weighted call.

    We deliberately sample both inner-third zones plus the cell's outer
    border buffer area so that 50/50 mixes (which split the cell left/right,
    diagonally, or as decorative stripes) are detected regardless of split
    direction.
    """
    cnt: Counter[str] = Counter()
    # Dense sample across the inner 80% of the cell. Pixels that fall on the
    # central hand-notation glyph classify as '?' and are dropped — the cell
    # background still dominates the count when the text is a few pixels wide.
    # Skipping any vertical band entirely (e.g. only sampling top/bottom)
    # misses chart cells whose mix is split horizontally (left orange / right
    # green), so we cover the full vertical range and let '?' filtering handle
    # the text.
    for ox in (-0.42, -0.34, -0.26, -0.18, -0.10, 0.0, 0.10, 0.18, 0.26, 0.34, 0.42):
        for oy in (-0.40, -0.30, -0.20, -0.10, 0.0, 0.10, 0.20, 0.30, 0.40):
            x = int(cx + ox * cell_w)
            y = int(cy + oy * cell_h)
            cls = classify_pixel(im.getpixel((x, y)))
            if cls != "?":
                cnt[cls] += 1
    total = sum(cnt.values())
    if total == 0:
        return {}
    return {k: v / total for k, v in cnt.items()}


def auto_bounds(im: Image.Image) -> tuple[int, int, int, int]:
    """Locate the chart-matrix rectangle by finding the first/last rows and
    columns that contain any chart-colour pixels.

    Chart panels in the RangeConverter PDF sit on a dark-navy page background.
    The matrix occupies a contiguous block of cells whose colours are one of
    R/L/F. We find that block by scanning each row and column and looking
    for any pixel that classifies as R, L, or F.
    """
    w, h = im.size

    def row_has_chart_colour(y: int) -> bool:
        for x in range(0, w, 6):
            if classify_pixel(im.getpixel((x, y))) != "?":
                return True
        return False

    def col_has_chart_colour(x: int) -> bool:
        for y in range(0, h, 6):
            if classify_pixel(im.getpixel((x, y))) != "?":
                return True
        return False

    # Find first/last rows.
    y0 = next((y for y in range(h) if row_has_chart_colour(y)), 0)
    y1 = next((y for y in range(h - 1, -1, -1) if row_has_chart_colour(y)), h - 1)

    # The chart's legend bar sits below the matrix on its own line and is also
    # made of chart colours. The matrix and legend are separated by a navy
    # gap of ~30-80 pixels. We walk down from y0 and treat a sustained gap
    # of ≥40 consecutive background rows as the end of the matrix. Short
    # gaps (e.g., a single all-fold matrix row whose text dominates the
    # 6-pixel column sample) are NOT counted as the matrix end.
    # Walk down from y0 to y1 keeping the last row that had any chart colour.
    # A short gap (1 row of all-fold cells whose text dominates) doesn't end
    # the matrix; only a sustained background gap of ≥120 px does.
    matrix_y1 = y1
    last_chart_y = y0
    GAP_THRESHOLD = 120
    in_chart = True
    for y in range(y0, y1 + 1):
        is_chart = row_has_chart_colour(y)
        if is_chart:
            last_chart_y = y
            in_chart = True
        elif in_chart:
            gap = 0
            k = 1
            while k < GAP_THRESHOLD + 10 and y + k < h and not row_has_chart_colour(y + k):
                gap += 1
                k += 1
            if gap >= GAP_THRESHOLD:
                matrix_y1 = last_chart_y
                break
            in_chart = False
    if matrix_y1 == y1:
        matrix_y1 = last_chart_y

    # Horizontal bounds across the matrix area — take the widest x-range
    # observed across many y-slices, so we're robust to rows whose left or
    # right cells happen to be all-text-on-fold and produce no chart pixels
    # at the slice's extremes.
    x0 = w
    x1 = 0
    span = matrix_y1 - y0
    for frac in (0.05, 0.20, 0.35, 0.50, 0.65, 0.80, 0.95):
        y_probe = y0 + int(frac * span)
        for x in range(w):
            if classify_pixel(im.getpixel((x, y_probe))) != "?":
                x0 = min(x0, x)
                break
        for x in range(w - 1, -1, -1):
            if classify_pixel(im.getpixel((x, y_probe))) != "?":
                x1 = max(x1, x)
                break

    # Add a tiny inward padding so the very edge anti-aliasing doesn't bias
    # half-cell sampling.
    return x0, y0, x1 + 1, matrix_y1 + 1


def classify_chart(image_path: Path, bounds=None) -> list[list[tuple]]:
    """Return a 13×13 grid of (hand, action_proportions) tuples.

    action_proportions is a dict {action_letter: fraction} per cell.
    """
    im = Image.open(image_path).convert("RGB")
    if bounds is None:
        bounds = auto_bounds(im)
    x0, y0, x1, y1 = bounds
    cell_w = (x1 - x0) / 13.0
    cell_h = (y1 - y0) / 13.0
    matrix = []
    for r in range(13):
        row = []
        for c in range(13):
            cx = x0 + (c + 0.5) * cell_w
            cy = y0 + (r + 0.5) * cell_h
            props = classify_cell_proportions(im, cx, cy, cell_w, cell_h)
            row.append((hand_at(r, c), props))
        matrix.append(row)
    return matrix


def quantise_to_actions(props: dict[str, float], action_map: dict[str, str]) -> list[tuple[str, float]]:
    """Round per-cell proportions to nearest 50% per the source's convention.

    RangeConverter's free PDFs explicitly state: "the frequency of an action
    for each hand combo is rounded to the nearest 50%". So each cell's true
    strategy is one of {fold-only, action-only, 50/50 split}. We re-quantise
    by checking each detected colour's proportion:
      - ≥ 50%  → counts as one of the actions
      - 25–50% → also counts as one of the actions (rounds up to 50/50)
      - < 25%  → noise / bleed; ignore

    The output is then either one action at freq=1.0 (if exactly one
    qualifies) or two actions at freq=0.5 each (if two qualify). If three
    colours each clear 25%, we treat the cell as a 50/50 mix between the top
    two — there's no 3-way 1/3 split in the source vocabulary.
    """
    if not props:
        return []  # default fold (handled by absence)
    # Threshold tuned against the 7 page-3 RFI charts: ≥30% is the sweet spot
    # that excludes 1-2% antialiasing noise while still catching genuine
    # 50/50 mix cells (which sample at ~35-50% per colour depending on text
    # coverage).
    qualifying = sorted(
        ((k, v) for k, v in props.items() if k in action_map and v >= 0.30),
        key=lambda kv: -kv[1],
    )
    if not qualifying:
        return []
    if len(qualifying) == 1:
        return [(action_map[qualifying[0][0]], 1.0)]
    return [
        (action_map[qualifying[0][0]], 0.5),
        (action_map[qualifying[1][0]], 0.5),
    ]


# Vocabulary mappings selected per chart type — see `--mode` on the CLI.
# The colour roles are constant (R=orange, L=green, F=blue) but their poker
# meaning differs by chart context.
ACTION_MAP_RFI = {"R": "raise", "F": "fold", "L": "limp"}     # opening chart
ACTION_MAP_VS_RFI = {"R": "threeBet", "L": "call", "F": "fold"}  # defending vs open
ACTION_MAP_VS_3BET = {"R": "raise", "L": "call", "F": "fold"}    # opener facing 3-bet

ACTION_MAPS = {
    "rfi": ACTION_MAP_RFI,
    "vs-rfi": ACTION_MAP_VS_RFI,
    "vs-3bet": ACTION_MAP_VS_3BET,
}

# Legacy alias retained for older callers / docstrings.
ACTION_MAP_2WAY = ACTION_MAP_RFI


def vpip_combos(matrix, action_map) -> dict[str, float]:
    """Sum combo-weighted action frequencies across the matrix.

    Quantises each cell's proportions to nearest 50% then accumulates by
    canonical combo weight (pair=6, suited=4, offsuit=12).
    """
    weights = {"pair": 6, "suited": 4, "offsuit": 12}
    totals: dict[str, float] = {}
    for r in range(13):
        for c in range(13):
            _hand, props = matrix[r][c]
            if r == c:
                kind = "pair"
            elif r < c:
                kind = "suited"
            else:
                kind = "offsuit"
            for action, freq in quantise_to_actions(props, action_map):
                totals[action] = totals.get(action, 0) + freq * weights[kind]
    return totals


def write_crib(matrix, slug: str, out_path: Path, action_map=None, source_note=""):
    action_map = action_map or ACTION_MAP_2WAY
    lines = [
        f"# Auto-extracted from RangeConverter PDF for {slug}",
        f"# Source: rangeconverter.com/free-poker-charts (free MTT pack)",
    ]
    if source_note:
        lines.append(f"# {source_note}")
    lines.append("notation,action,freq")
    for r in range(13):
        for c in range(13):
            hand, props = matrix[r][c]
            for action, freq in quantise_to_actions(props, action_map):
                lines.append(f"{hand},{action},{freq}")
    out_path.write_text("\n".join(lines) + "\n")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--input", required=True, help="cropped 1600x2160 chart PNG")
    p.add_argument("--slug", required=True, help="chart slug, e.g. mtt_8max_100bb_co_unopened")
    p.add_argument("--output", required=True, help="output directory for the crib CSV")
    p.add_argument("--mode", choices=list(ACTION_MAPS), default="rfi",
                   help="chart type: rfi (default, fold/limp/raise) | vs-rfi (fold/call/3bet) | vs-3bet (fold/call/raise)")
    p.add_argument("--bounds", help="override grid bounds as 'x0,y0,x1,y1'")
    p.add_argument("--print-matrix", action="store_true", help="also print the classified matrix")
    p.add_argument("--print-vpip", action="store_true", help="print combo-weighted action frequencies for sanity check")
    args = p.parse_args()

    bounds = None
    if args.bounds:
        bounds = tuple(int(x) for x in args.bounds.split(","))

    action_map = ACTION_MAPS[args.mode]
    matrix = classify_chart(Path(args.input), bounds)

    if args.print_matrix:
        for row in matrix:
            cells = []
            for _hand, props in row:
                acts = quantise_to_actions(props, action_map)
                if not acts:
                    cells.append("F")
                elif len(acts) == 1:
                    cells.append(acts[0][0][0].upper())
                else:
                    cells.append(acts[0][0][0].upper() + "/" + acts[1][0][0].upper())
            print(" ".join(c.center(3) for c in cells))

    out_dir = Path(args.output)
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{args.slug}.csv"
    note = f"Auto-extracted via pixel sampling ({args.mode}). Verify against stated VPIP."
    write_crib(matrix, args.slug, out_path, action_map=action_map, source_note=note)
    print(f"[ok] {out_path}")

    if args.print_vpip:
        totals = vpip_combos(matrix, action_map)
        total_combos = 1326
        print("Action breakdown (combo-weighted):")
        for action, combos in totals.items():
            print(f"  {action}: {combos:.1f} combos ({100 * combos / total_combos:.2f}%)")


if __name__ == "__main__":
    main()
