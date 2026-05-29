#!/usr/bin/env python3
"""extract_pokercoaching.py — pixel-extract PokerCoaching free GTO chart PDFs.

STATUS: PROTOTYPE / NOT TRUSTWORTHY FOR BUNDLE. With phase-fit box detection
some panels extract spot-on (±0.5pp of printed VPIP) but others — especially
colour-dense wide ranges (BTN/CO/SB) — are 30-45% off, because PokerCoaching's
white-background charts lose their grey gridlines between adjacent coloured
cells and the lattice fit degrades. Per-panel reliability is not good enough for
a training app. Use assisted transcription (read the chart + printed VPIP/combo
count as a checksum) for canonical data; keep this only as an extraction aid
whose every output must be VPIP-validated before acceptance.


PokerCoaching's free preflop chart PDFs
(https://poker-coaching.s3.amazonaws.com/tools/preflop-charts/<depth>bb-gto-charts.pdf)
render each spot as a 13x13 grid on a WHITE page. Cell fill encodes the action:

  - red    -> raise (or 3-bet / 4-bet on facing charts)
  - green  -> call / limp
  - white  -> fold
  - grey   -> cell border / gridline (structure, not an action)
  - dark   -> the hand-notation glyph text

This differs from RangeConverter (orange/green/blue on navy) so it needs its
own classifier; the architecture mirrors `extract_chart.py` (find box ->
sample cells -> quantise -> emit crib CSV / VPIP).

Each PDF page holds several panels in a regular row/column layout. This script
extracts ONE panel given an (x0,y0,x1,y1) panel crop window; the box-finder
then locks the 13x13 matrix inside that window by testing alignments against
the grey lattice and picking the one whose cell centres are cleanest.

Workflow:
  1. pdftoppm -png -r 200 <depth>bb.pdf page
  2. extract_pokercoaching.py --input page-2.png --window 56,300,548,900 \
       --slug mtt_8max_40bb_utg_unopened --mode rfi --output crib/ --print-vpip
"""

from __future__ import annotations

import argparse
from collections import Counter
from pathlib import Path

from PIL import Image

RANKS = list("AKQJT98765432")
WEIGHTS = {"pair": 6, "suited": 4, "offsuit": 12}


def classify_pixel(px: tuple[int, int, int]) -> str:
    """Map a pixel to {R(red/raise), G(green/call), W(white/fold), ?(border/text)}."""
    r, g, b = px
    mx, mn = max(px), min(px)
    if r > 215 and g > 215 and b > 215:
        return "W"  # white fold cell (== page background)
    if r - g > 35 and r - b > 35 and r > 120:
        return "R"  # red raise
    if g - r > 18 and g - b > 8 and g > 110:
        return "G"  # green call
    # grey gridlines (low saturation, mid brightness) and dark text -> structure
    return "?"


def hand_at(row: int, col: int) -> str:
    if row == col:
        return f"{RANKS[row]}{RANKS[col]}"
    if row < col:
        return f"{RANKS[row]}{RANKS[col]}s"
    return f"{RANKS[col]}{RANKS[row]}o"


def cell_props(im: Image.Image, cx: float, cy: float, cw: float, ch: float) -> dict[str, float]:
    """Action proportions for one cell, sampling the inner area (text drops as '?')."""
    cnt: Counter[str] = Counter()
    for ox in (-0.40, -0.30, -0.20, -0.10, 0.0, 0.10, 0.20, 0.30, 0.40):
        for oy in (-0.40, -0.30, -0.20, -0.10, 0.0, 0.10, 0.20, 0.30, 0.40):
            x = int(cx + ox * cw)
            y = int(cy + oy * ch)
            if 0 <= x < im.width and 0 <= y < im.height:
                c = classify_pixel(im.getpixel((x, y)))
                if c != "?":
                    cnt[c] += 1
    total = sum(cnt.values())
    return {k: v / total for k, v in cnt.items()} if total else {}


def _grey_lattice(im: Image.Image, win):
    """Return (xs, ys) projections of grey gridline pixels inside the window."""
    x0, y0, x1, y1 = win
    px = im.load()
    xs = [0] * (x1 - x0)
    ys = [0] * (y1 - y0)
    for j, y in enumerate(range(y0, y1)):
        for i, x in enumerate(range(x0, x1)):
            r, g, b = px[x, y]
            if abs(r - g) <= 16 and abs(g - b) <= 16 and 120 <= min(r, g, b) and max(r, g, b) <= 212:
                xs[i] += 1
                ys[j] += 1
    return xs, ys


def _peaks(proj: list[int]) -> list[int]:
    """Cluster-centre indices of strong gridline spikes in a 1-D projection."""
    if not proj:
        return []
    th = max(max(proj) * 0.33, 4)
    on = [i for i, v in enumerate(proj) if v > th]
    out, cluster = [], []
    for i in on:
        if cluster and i - cluster[-1] > 4:
            out.append(sum(cluster) // len(cluster))
            cluster = []
        cluster.append(i)
    if cluster:
        out.append(sum(cluster) // len(cluster))
    return out


def _fit_axis(proj: list[int], lo: int) -> tuple[int, float]:
    """Phase-fit a 14-line lattice to gridline peaks. Returns (origin_abs, pitch).

    pitch = median consecutive gap (filtered to plausible 30-45 px cell size);
    origin = the candidate phase that lands the most detected peaks on lattice
    nodes. Robust to a faint boundary line or strong interior lines (the bug
    that shifted the box 2 cells down).
    """
    pk = _peaks(proj)
    if len(pk) < 3:
        return lo, 37.5
    gaps = sorted(pk[i + 1] - pk[i] for i in range(len(pk) - 1))
    plausible = [g for g in gaps if 30 <= g <= 45]
    pitch = float(plausible[len(plausible) // 2]) if plausible else 37.5
    # Try every detected peak as a possible lattice node; score by how many
    # peaks fall near origin + k*pitch. Best origin = lowest well-scoring phase.
    best_origin, best_score = pk[0], -1
    for cand in pk:
        for k0 in range(0, 14):
            origin = cand - k0 * pitch
            if origin < -pitch * 0.5:
                continue
            score = sum(1 for p in pk
                        if min(abs(p - (origin + n * pitch)) for n in range(14)) <= 3)
            if score > best_score or (score == best_score and origin < best_origin):
                best_score, best_origin = score, origin
    return int(round(lo + best_origin)), pitch


def find_box(im: Image.Image, win) -> tuple[int, int, int, int]:
    """Lock the 13x13 matrix inside the window via phase-fit of the grey lattice.

    The matrix is a regular grey lattice of 14 lines per axis; the legend bars
    below it are solid colour with no internal grid. We fit the lattice phase +
    pitch on each axis and index exactly 13 cells from the origin — structurally
    excluding the legend and surviving colour-dense panels.
    """
    x0, y0, x1, y1 = win
    xs, ys = _grey_lattice(im, win)
    if not xs or not ys or max(xs) < 6 or max(ys) < 6:
        return win
    ox, px = _fit_axis(xs, x0)
    oy, py = _fit_axis(ys, y0)
    return ox, oy, int(round(ox + 13 * px)), int(round(oy + 13 * py))


def classify(im: Image.Image, box) -> list[list[tuple]]:
    x0, y0, x1, y1 = box
    cw = (x1 - x0) / 13.0
    ch = (y1 - y0) / 13.0
    grid = []
    for r in range(13):
        row = []
        for c in range(13):
            cx = x0 + (c + 0.5) * cw
            cy = y0 + (r + 0.5) * ch
            row.append((hand_at(r, c), cell_props(im, cx, cy, cw, ch)))
        grid.append(row)
    return grid


# Colour role -> poker action, per chart context.
ACTION_MAPS = {
    "rfi":     {"R": "raise", "G": "limp", "W": "fold"},
    "vs-rfi":  {"R": "threeBet", "G": "call", "W": "fold"},
    "vs-3bet": {"R": "raise", "G": "call", "W": "fold"},
}


def quantise(props, amap):
    """Round to nearest 50% (PokerCoaching implementable charts are pure or 50/50)."""
    if not props:
        return [("fold", 1.0)]
    q = sorted(((k, v) for k, v in props.items() if k in amap and v >= 0.30),
               key=lambda kv: -kv[1])
    if not q:
        return [("fold", 1.0)]
    if len(q) == 1:
        return [(amap[q[0][0]], 1.0)]
    return [(amap[q[0][0]], 0.5), (amap[q[1][0]], 0.5)]


def vpip(grid, amap) -> dict[str, float]:
    totals: dict[str, float] = {}
    for r in range(13):
        for c in range(13):
            kind = "pair" if r == c else ("suited" if r < c else "offsuit")
            for action, freq in quantise(grid[r][c][1], amap):
                totals[action] = totals.get(action, 0) + freq * WEIGHTS[kind]
    return totals


def write_crib(grid, slug, out_path, amap, note):
    lines = [
        f"# Auto-extracted from PokerCoaching free GTO PDF for {slug}",
        "# Source: poker-coaching.s3.amazonaws.com/tools/preflop-charts/ (free)",
    ]
    if note:
        lines.append(f"# {note}")
    lines.append("notation,action,freq")
    for r in range(13):
        for c in range(13):
            hand, props = grid[r][c]
            for action, freq in quantise(props, amap):
                if action == "fold" and freq == 1.0:
                    continue  # fold is the implicit default; keep CSV compact
                lines.append(f"{hand},{action},{freq}")
    out_path.write_text("\n".join(lines) + "\n")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--input", required=True, help="rendered page PNG")
    p.add_argument("--window", required=True, help="panel crop 'x0,y0,x1,y1' (generous; box auto-locks inside)")
    p.add_argument("--slug", required=True)
    p.add_argument("--output", required=True)
    p.add_argument("--mode", choices=list(ACTION_MAPS), default="rfi")
    p.add_argument("--box", help="override matrix box 'x0,y0,x1,y1' (skip auto-lock)")
    p.add_argument("--print-matrix", action="store_true")
    p.add_argument("--print-vpip", action="store_true")
    args = p.parse_args()

    im = Image.open(args.input).convert("RGB")
    win = tuple(int(v) for v in args.window.split(","))
    box = tuple(int(v) for v in args.box.split(",")) if args.box else find_box(im, win)
    amap = ACTION_MAPS[args.mode]
    grid = classify(im, box)

    if args.print_matrix:
        print(f"box={box}")
        for row in grid:
            cells = []
            for _h, props in row:
                acts = quantise(props, amap)
                if len(acts) == 1:
                    cells.append(acts[0][0][0].upper())
                else:
                    cells.append(acts[0][0][0].upper() + "/" + acts[1][0][0].upper())
            print(" ".join(c.center(3) for c in cells))

    out_dir = Path(args.output)
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{args.slug}.csv"
    write_crib(grid, args.slug, out_path, amap, f"pixel-extracted ({args.mode}); verify vs stated VPIP")
    print(f"[ok] {out_path}")

    if args.print_vpip:
        totals = vpip(grid, amap)
        print("Action breakdown (combo-weighted, /1326):")
        for a, combos in sorted(totals.items(), key=lambda kv: -kv[1]):
            print(f"  {a}: {combos:.0f} combos ({100*combos/1326:.1f}%)")


if __name__ == "__main__":
    main()
