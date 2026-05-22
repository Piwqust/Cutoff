#!/usr/bin/env python3
"""batch_extract.py — orchestrate end-to-end chart extraction for a stack depth.

For each RangeConverter free-pack PDF (rendered to PNGs at 600 DPI), this
script:
  1. Crops the 7 RFI panels from page 3 (4 top-row + 3 bottom-row layout)
  2. Crops the "vs first-opener" panel from each vs-RFI page
  3. Runs extract_chart.py on every cropped panel
  4. Writes the long-form crib CSVs into the importer crib/ directory

Usage:
    python3 batch_extract.py --depth 60 --pages-dir /tmp/rc_60bb_pages --crib-out Tools/RangeImporter/crib

The PDFs all share the same panel-layout template (verified visually for
10bb, 20bb, 30bb, 60bb, 100bb), so a single set of crop coordinates works
across all stack depths. If a future RangeConverter rev changes layout the
coordinates here can be retuned.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
import tempfile
from pathlib import Path

# Page-3 RFI panel crops at 600 DPI (page is 7017 × 4968 px).
# Top row holds 4 panels (UTG / UTG1 / MP=LJ / HJ).
# Bottom row holds 3 panels (CO / BTN / SB).
# Coordinates are (x, y, w, h) suitable for ImageMagick -crop WxH+X+Y.
RFI_LAYOUT_TOP = {
    "utg":  (50, 95, 1700, 2300),
    "utg1": (1750, 95, 1700, 2300),
    "lj":   (3450, 95, 1700, 2300),   # RangeConverter's "MP" = our "LJ"
    "hj":   (5150, 95, 1700, 2300),
}
RFI_LAYOUT_BOTTOM = {
    "co":  (50, 2400, 2300, 2200),
    "btn": (2400, 2400, 2300, 2200),
    "sb":  (4700, 2400, 2300, 2200),
}

# vs-RFI pages: each defender has its own page in the PDF. Page index per
# defender (1-indexed). Each page's top-left panel is "<defender> vs UTG RFI",
# which is our canonical "vs the earliest possible opener" choice.
#
# 100bb pack and 30bb pack confirmed have this layout. Other depths assumed
# to match — the script will surface inconsistencies via VPIP cross-checks.
VSRFI_PAGE = {
    "utg1": 4,  # page 4 = "EPMP vs RFI"; panel 1 is UTG1 vs UTG
    "lj":   4,  # page 4 panel 2 = MP vs UTG
    "hj":   5,
    "co":   6,
    "btn":  7,
    "sb":   8,
    "bb":   9,
}
# Most defenders' page-1 panel is at (50, 95, 1700, 2200) and is "vs UTG RFI".
# For pages 4 (which holds UTG1 and LJ), we want panels 1 and 2 respectively.
VSRFI_PANEL_AT_X = {
    "utg1": 50,    # panel 1 of page 4
    "lj":   1750,  # panel 2 of page 4
}


def run(cmd: list[str]) -> None:
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"FAILED: {' '.join(cmd)}", file=sys.stderr)
        print(res.stderr, file=sys.stderr)
        sys.exit(res.returncode)


def crop(src: Path, dst: Path, geom: tuple[int, int, int, int]) -> None:
    x, y, w, h = geom
    run(["magick", str(src), "-crop", f"{w}x{h}+{x}+{y}", "+repage", str(dst)])


def extract(panel_png: Path, slug: str, crib_dir: Path, mode: str) -> str:
    """Run extract_chart.py and return its stdout for VPIP logging."""
    script = Path(__file__).parent / "extract_chart.py"
    res = subprocess.run(
        ["python3", str(script),
         "--input", str(panel_png),
         "--slug", slug,
         "--output", str(crib_dir),
         "--mode", mode,
         "--print-vpip"],
        capture_output=True, text=True,
    )
    if res.returncode != 0:
        print(f"FAILED extract: {slug}\n{res.stderr}", file=sys.stderr)
        return ""
    return res.stdout


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--depth", type=int, required=True, help="stack depth in bb")
    p.add_argument("--pages-dir", required=True, help="dir holding page-NN.png")
    p.add_argument("--crib-out", required=True, help="dest dir for CSVs")
    p.add_argument("--skip-sb", action="store_true",
                   help="omit SB RFI (3-action limp chart that the extractor under-counts)")
    p.add_argument("--include-vsrfi", action="store_true",
                   help="also extract canonical-opener vs-RFI panels (one per defender)")
    args = p.parse_args()

    pages_dir = Path(args.pages_dir)
    crib_dir = Path(args.crib_out)
    crib_dir.mkdir(parents=True, exist_ok=True)
    workdir = Path(tempfile.mkdtemp(prefix=f"rcbatch_{args.depth}bb_"))

    page3 = pages_dir / "page-03.png"
    if not page3.exists():
        page3 = pages_dir / "page-3.png"  # 10bb renderer uses 1-digit names
    if not page3.exists():
        print(f"Missing {page3}", file=sys.stderr)
        sys.exit(1)

    print(f"=== {args.depth}bb RFI ===")
    layout = {**RFI_LAYOUT_TOP, **RFI_LAYOUT_BOTTOM}
    for pos, geom in layout.items():
        if args.skip_sb and pos == "sb":
            continue
        panel = workdir / f"rfi_{pos}.png"
        crop(page3, panel, geom)
        slug = f"mtt_8max_{args.depth}bb_{pos}_unopened"
        out = extract(panel, slug, crib_dir, mode="rfi")
        # Surface the VPIP line so the operator can sanity-check.
        for line in out.splitlines():
            if "combos" in line:
                print(f"  {pos}: {line.strip()}")

    if args.include_vsrfi:
        print(f"=== {args.depth}bb vs-RFI (canonical opener: UTG) ===")
        for defender, page_idx in VSRFI_PAGE.items():
            page_png = pages_dir / f"page-{page_idx:02d}.png"
            if not page_png.exists():
                page_png = pages_dir / f"page-{page_idx}.png"
            if not page_png.exists():
                print(f"  [skip] {defender}: no page-{page_idx}")
                continue
            # Default panel position is top-left of the page; UTG1 and LJ are
            # different panels on the shared "EPMP vs RFI" page.
            x = VSRFI_PANEL_AT_X.get(defender, 50)
            panel = workdir / f"vsrfi_{defender}.png"
            crop(page_png, panel, (x, 95, 1700, 2200))
            slug = f"mtt_8max_{args.depth}bb_{defender}_vsopen"
            out = extract(panel, slug, crib_dir, mode="vs-rfi")
            for line in out.splitlines():
                if "combos" in line:
                    print(f"  {defender}: {line.strip()}")


if __name__ == "__main__":
    main()
