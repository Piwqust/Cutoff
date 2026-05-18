#!/usr/bin/env python3
"""
open_raise_generator.py
=======================
Generates GTO-approximation open-raise (RFI) MTT preflop range JSON files
for the MTT Poker Trainer iOS app.

Output directory: MTTPokerTrainer/Resources/Ranges/
File naming    : mtt_9max_{stack}bb_{position_lower}_open_v2.json

Run from MTT TR/ directory:
    python3 open_raise_generator.py

Stdlib only. Python 3.9+.
"""

from __future__ import annotations

import json
import os
import pathlib

# ---------------------------------------------------------------------------
# 1. Canonical hand order (169 hands, strongest → weakest for RFI purposes)
# ---------------------------------------------------------------------------

HAND_ORDER: list[str] = [
    # Pairs (AA → 22)
    "AA",
    "KK",
    "QQ",
    "JJ",
    "TT",
    "99",
    "88",
    "77",
    "66",
    "55",
    "44",
    "33",
    "22",
    # Suited aces
    "AKs",
    "AQs",
    "AJs",
    "ATs",
    "A9s",
    "A8s",
    "A7s",
    "A6s",
    "A5s",
    "A4s",
    "A3s",
    "A2s",
    # Suited kings
    "KQs",
    "KJs",
    "KTs",
    "K9s",
    "K8s",
    "K7s",
    "K6s",
    "K5s",
    "K4s",
    "K3s",
    "K2s",
    # Suited queens
    "QJs",
    "QTs",
    "Q9s",
    "Q8s",
    "Q7s",
    "Q6s",
    "Q5s",
    "Q4s",
    "Q3s",
    "Q2s",
    # Suited jacks
    "JTs",
    "J9s",
    "J8s",
    "J7s",
    "J6s",
    "J5s",
    "J4s",
    "J3s",
    "J2s",
    # Suited tens
    "T9s",
    "T8s",
    "T7s",
    "T6s",
    "T5s",
    "T4s",
    "T3s",
    "T2s",
    # Suited nines
    "98s",
    "97s",
    "96s",
    "95s",
    "94s",
    "93s",
    "92s",
    # Suited eights
    "87s",
    "86s",
    "85s",
    "84s",
    "83s",
    "82s",
    # Suited sevens
    "76s",
    "75s",
    "74s",
    "73s",
    "72s",
    # Suited sixes
    "65s",
    "64s",
    "63s",
    "62s",
    # Suited fives
    "54s",
    "53s",
    "52s",
    # Suited fours
    "43s",
    "42s",
    # Suited threes
    "32s",
    # Offsuit aces
    "AKo",
    "AQo",
    "AJo",
    "ATo",
    "A9o",
    "A8o",
    "A7o",
    "A6o",
    "A5o",
    "A4o",
    "A3o",
    "A2o",
    # Offsuit kings
    "KQo",
    "KJo",
    "KTo",
    "K9o",
    "K8o",
    "K7o",
    "K6o",
    "K5o",
    "K4o",
    "K3o",
    "K2o",
    # Offsuit queens
    "QJo",
    "QTo",
    "Q9o",
    "Q8o",
    "Q7o",
    "Q6o",
    "Q5o",
    "Q4o",
    "Q3o",
    "Q2o",
    # Offsuit jacks
    "JTo",
    "J9o",
    "J8o",
    "J7o",
    "J6o",
    "J5o",
    "J4o",
    "J3o",
    "J2o",
    # Offsuit tens
    "T9o",
    "T8o",
    "T7o",
    "T6o",
    "T5o",
    "T4o",
    "T3o",
    "T2o",
    # Offsuit nines
    "98o",
    "97o",
    "96o",
    "95o",
    "94o",
    "93o",
    "92o",
    # Offsuit eights
    "87o",
    "86o",
    "85o",
    "84o",
    "83o",
    "82o",
    # Offsuit sevens
    "76o",
    "75o",
    "74o",
    "73o",
    "72o",
    # Offsuit sixes
    "65o",
    "64o",
    "63o",
    "62o",
    # Offsuit fives
    "54o",
    "53o",
    "52o",
    # Offsuit fours
    "43o",
    "42o",
    # Offsuit threes
    "32o",
]

assert len(HAND_ORDER) == 169, f"HAND_ORDER has {len(HAND_ORDER)} hands, expected 169"

# ---------------------------------------------------------------------------
# 2. RFI percentage anchors  dict[position] -> dict[stack_bb] -> pct (float)
#
#    Anchors are at 25, 50, 100, 150 BB.
#    30 / 40 / 75 / 125 are interpolated linearly between neighbors.
#    150 BB uses the same percentages as 100 BB (GTO-approx plateau above 100 BB).
# ---------------------------------------------------------------------------

OPEN_ANCHORS: dict[str, dict[int, float]] = {
    "BTN": {25: 34.0, 50: 42.0, 100: 47.0, 150: 47.0},
    "SB": {25: 30.0, 50: 38.0, 100: 42.0, 150: 42.0},
    "CO": {25: 22.0, 50: 27.0, 100: 30.0, 150: 30.0},
    "HJ": {25: 15.0, 50: 19.0, 100: 21.0, 150: 21.0},
    "UTG": {25: 10.0, 50: 13.0, 100: 15.0, 150: 15.0},
}

# Target stack sizes (BB) to generate files for.
STACK_SIZES: list[int] = [25, 30, 40, 50, 75, 100, 125, 150]

# Positions (in canonical MTT order).
POSITIONS: list[str] = ["UTG", "HJ", "CO", "BTN", "SB"]

# ---------------------------------------------------------------------------
# 3. Helpers
# ---------------------------------------------------------------------------


def interpolate_pct(position: str, stack_bb: int) -> float:
    """
    Linearly interpolate (or extrapolate-clamp) the RFI percentage for the
    given position and stack depth using the anchor table.
    """
    anchors = OPEN_ANCHORS[position]
    sorted_stacks = sorted(anchors.keys())

    # Exact hit
    if stack_bb in anchors:
        return anchors[stack_bb]

    # Below lowest anchor → clamp to lowest
    if stack_bb < sorted_stacks[0]:
        return anchors[sorted_stacks[0]]

    # Above highest anchor → clamp to highest
    if stack_bb > sorted_stacks[-1]:
        return anchors[sorted_stacks[-1]]

    # Find bracketing anchors and lerp
    lo, hi = sorted_stacks[0], sorted_stacks[-1]
    for i in range(len(sorted_stacks) - 1):
        a, b = sorted_stacks[i], sorted_stacks[i + 1]
        if a <= stack_bb <= b:
            lo, hi = a, b
            break

    lo_pct = anchors[lo]
    hi_pct = anchors[hi]
    t = (stack_bb - lo) / (hi - lo)
    return lo_pct + t * (hi_pct - lo_pct)


def hands_for(position: str, stack_bb: int) -> dict[str, str]:
    """
    Return the "hands" dict (hand → "raise") for the given position and stack.
    Takes the top-N hands from HAND_ORDER where N = round(169 * pct / 100).
    """
    pct = interpolate_pct(position, stack_bb)
    n = round(169 * pct / 100)
    n = max(0, min(n, 169))
    selected = HAND_ORDER[:n]
    return {hand: "raise" for hand in selected}


def file_id(position: str, stack_bb: int) -> str:
    return f"mtt_9max_{stack_bb}bb_{position.lower()}_open_v2"


def build_range_json(position: str, stack_bb: int) -> dict:
    return {
        "id": file_id(position, stack_bb),
        "format": "NLHE_MTT_9MAX",
        "spot": {
            "position": position,
            "stackDepthBB": stack_bb,
            "facingAction": "unopened",
            "anteType": "bigBlindAnte",
        },
        "source": {
            "type": "userDefined",
            "description": (
                "GTO-approximation open-raise range (RFI). "
                "Standard MTT open-raising frequencies. Not solver-verified."
            ),
        },
        "hands": hands_for(position, stack_bb),
    }


# ---------------------------------------------------------------------------
# 4. Main
# ---------------------------------------------------------------------------


def main() -> None:
    script_dir = pathlib.Path(__file__).parent.resolve()
    output_dir = script_dir / "MTTPokerTrainer" / "Resources" / "Ranges"
    output_dir.mkdir(parents=True, exist_ok=True)

    # ---- Delete old *open*_demo_v1.json files --------------------------------
    deleted: list[str] = []
    for old_file in output_dir.glob("*open*demo_v1.json"):
        old_file.unlink()
        deleted.append(old_file.name)

    if deleted:
        print("Deleted old demo-v1 open files:")
        for name in sorted(deleted):
            print(f"  - {name}")
        print()

    # ---- Write new v2 files --------------------------------------------------
    written: list[str] = []
    for position in POSITIONS:
        for stack_bb in STACK_SIZES:
            data = build_range_json(position, stack_bb)
            filename = f"{file_id(position, stack_bb)}.json"
            out_path = output_dir / filename

            with out_path.open("w", encoding="utf-8") as fh:
                json.dump(data, fh, indent=2, ensure_ascii=False)
                fh.write("\n")  # POSIX trailing newline

            pct = interpolate_pct(position, stack_bb)
            n = len(data["hands"])
            written.append((filename, pct, n))

    # ---- Summary -------------------------------------------------------------
    print(f"Written {len(written)} RFI range files to:")
    print(f"  {output_dir}")
    print()
    print(f"{'File':<48}  {'% RFI':>6}  {'Hands':>5}")
    print("-" * 64)
    for filename, pct, n in written:
        print(f"  {filename:<46}  {pct:>5.1f}%  {n:>5}")

    print()
    print("Done.")


if __name__ == "__main__":
    main()
