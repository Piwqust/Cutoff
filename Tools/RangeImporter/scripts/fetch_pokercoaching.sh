#!/usr/bin/env bash
# fetch_pokercoaching.sh — download PokerCoaching's free GTO preflop chart PDFs.
#
# These are public, directly-downloadable S3 assets (no login, no trial clock):
#   https://poker-coaching.s3.amazonaws.com/tools/preflop-charts/<name>.pdf
#
# 8-max MTT format (UTG..SB), color-coded 13x13 grids with exact % printed per
# chart. Solver-derived (Jonathan Little / PokerCoaching). Published "for study";
# this app is private/not-shipped so personal use is fine (see CLAUDE.md).
#
# Usage:  ./fetch_pokercoaching.sh [dest_dir]
set -euo pipefail

DEST="${1:-$(cd "$(dirname "$0")/.." && pwd)/pokercoaching/pdf}"
BASE="https://poker-coaching.s3.amazonaws.com/tools/preflop-charts"
mkdir -p "$DEST"

# Confirmed-available depth packs (100bb is gated -> source 100bb from
# RangeConverter via extract_chart.py instead).
FILES=(
  "15bb-gto-charts.pdf"
  "25bb-gto-charts.pdf"
  "40bb-gto-charts.pdf"
  "75bb-gto-charts.pdf"
  "online-6max-gto-charts.pdf"
  "full-preflop-charts.pdf"
)

for f in "${FILES[@]}"; do
  out="$DEST/$f"
  printf '%-32s ' "$f"
  code=$(curl -fsSL -o "$out" -w '%{http_code}' "$BASE/$f" 2>/dev/null) || code="ERR"
  if [[ "$code" == "200" ]]; then
    echo "OK ($(du -h "$out" | cut -f1))"
  else
    echo "SKIP (HTTP $code — gated or moved)"
    rm -f "$out"
  fi
done
echo "Saved to: $DEST"
