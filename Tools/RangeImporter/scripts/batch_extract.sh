#!/usr/bin/env bash
# batch_extract.sh — convenience driver around extract_chart.py.
#
# Given a directory of cropped chart PNGs, run pixel extraction on every one
# in the directory. Chart mode (rfi / vs-rfi / vs-3bet) and slug prefix are
# passed once; the slug per file is `<prefix>_<stem>` where <stem> comes from
# the PNG filename.
#
# Usage:
#   batch_extract.sh <png_dir> <mode> <slug_prefix> <out_dir>
#
# Example:
#   ./batch_extract.sh /tmp/rc_page3/ rfi mtt_8max_100bb crib/
#   ./batch_extract.sh /tmp/rc_page5/ vs-rfi mtt_8max_100bb_hj_vsopen crib/
set -euo pipefail

PNG_DIR=${1:?png_dir}
MODE=${2:?mode (rfi | vs-rfi | vs-3bet)}
PREFIX=${3:?slug_prefix}
OUT_DIR=${4:?out_dir}

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$OUT_DIR"

for png in "$PNG_DIR"/*.png; do
  stem=$(basename "$png" .png)
  slug="${PREFIX}_${stem}"
  python3 "$SCRIPT_DIR/extract_chart.py" \
    --input "$png" \
    --slug "$slug" \
    --output "$OUT_DIR" \
    --mode "$MODE" \
    --print-vpip
  echo
done
