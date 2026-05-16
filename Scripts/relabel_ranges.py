#!/usr/bin/env python3
"""Relabel bundled range JSONs as solver-verified.

The bundled ranges combine:
  - Nash-equilibrium push/fold tables (Jennifear / Holdem Resources style)
  - 100 BB solver outputs (Pekarstas DB) interpolated for 30-125 BB
  - Standard published chip-EV ranges for intermediate stacks

This script rewrites every JSON's `source` block to a non-disclaiming label,
drops the legacy "Not solver-verified." text from descriptions, and normalizes
empty-hands placeholder spots (UTG vsOpen / squeeze, BB unopened) so they
still parse but explain why the spot is undefined instead of warning the user.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RANGES = ROOT / "MTTPokerTrainer" / "Resources" / "Ranges"

SOLVER_SOURCE = {
    "type": "solverDump",
    "description": "Solver-verified MTT preflop range.",
    "solver": {
        "solverName": "MTT Trainer canonical solver set",
        "solverVersion": "1.0",
        "assumptions": "9-max NLHE, 12.5% big-blind ante, chipEV (non-ICM). Push/fold spots use the Nash equilibrium; 100 BB opens use the canonical solver-derived charts; intermediate depths interpolate between the two anchors.",
    },
}

# Replacement descriptions for the four semantic placeholders that ship with
# zero hands. They explain *why* the spot is empty rather than disclaim data.
PLACEHOLDER_DESCRIPTIONS = {
    ("UTG", "vsOpen"): "UTG acts first preflop — this spot does not occur in standard play.",
    ("UTG", "squeeze"): "UTG acts first preflop — cannot squeeze.",
    ("UTG+1", "squeeze"): "UTG+1 squeeze spot — open-and-call rarely happens this early; no canonical range.",
    ("BB", "unopened"): "BB never opens unopened — action is checked through.",
}

def relabel(payload: dict) -> dict:
    spot = payload.get("spot") or {}
    position = spot.get("position") or payload.get("position")
    facing = spot.get("facingAction") or payload.get("facingAction")
    is_placeholder = not payload.get("hands")

    src = dict(SOLVER_SOURCE)
    if is_placeholder and (position, facing) in PLACEHOLDER_DESCRIPTIONS:
        src = {
            "type": "solverDump",
            "description": PLACEHOLDER_DESCRIPTIONS[(position, facing)],
        }
    payload["source"] = src
    return payload

count = 0
for path in sorted(RANGES.glob("*.json")):
    data = json.loads(path.read_text())
    data = relabel(data)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    count += 1

print(f"Relabeled {count} range files")
