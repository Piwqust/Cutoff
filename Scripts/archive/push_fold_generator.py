#!/usr/bin/env python3
"""
push_fold_generator.py
======================
Generate Nash equilibrium push/fold MTT preflop range JSON files for the
MTT Poker Trainer iOS app.

Phase 1 scope: push/fold, stack ≤ 20 BB, Nash chip-EV ICM-free approximation.

Run from the MTT TR/ directory:
    python3 push_fold_generator.py
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Set

# ---------------------------------------------------------------------------
# Output directory (relative to this script's location)
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).parent
OUTPUT_DIR = SCRIPT_DIR / "MTTPokerTrainer" / "Resources" / "Ranges"

# ---------------------------------------------------------------------------
# All 169 canonical hand strings, ordered from strongest to weakest
# for push/fold purposes.
# ---------------------------------------------------------------------------
RANKS = ["A", "K", "Q", "J", "T", "9", "8", "7", "6", "5", "4", "3", "2"]
RANK_IDX = {r: i for i, r in enumerate(RANKS)}  # A=0 … 2=12


def _rank(r: str) -> int:
    return RANK_IDX[r]


# Build HAND_ORDER:  pairs (AA…22), then suited (AKs…32s), then offsuit (AKo…32o)
# Within suited/offsuit we use the canonical "higher rank first" ordering with
# the same block structure that poker trainers traditionally use:
#   AKs, AQs, AJs, ATs, A9s … A2s  (A-x suited block)
#   KQs, KJs, KTs … K2s            (K-x suited block)
#   … down to 32s
# Then same pattern for offsuit.


def _build_hand_order() -> List[str]:
    order: List[str] = []

    # --- Pairs: AA down to 22 ---
    for r in RANKS:
        order.append(f"{r}{r}")

    # --- Suited hands: iterate high card A→2, then low card (high-1)→2 ---
    for i, hi in enumerate(RANKS):
        for j in range(i + 1, len(RANKS)):
            lo = RANKS[j]
            order.append(f"{hi}{lo}s")

    # --- Offsuit hands: same traversal ---
    for i, hi in enumerate(RANKS):
        for j in range(i + 1, len(RANKS)):
            lo = RANKS[j]
            order.append(f"{hi}{lo}o")

    return order


HAND_ORDER: List[str] = _build_hand_order()
HAND_SET: Set[str] = set(HAND_ORDER)
HAND_RANK: Dict[str, int] = {h: i for i, h in enumerate(HAND_ORDER)}

assert len(HAND_ORDER) == 169, f"Expected 169 hands, got {len(HAND_ORDER)}"

# ---------------------------------------------------------------------------
# Helper: expand a range spec written in the shorthand used in the docstring.
# e.g. "AKs-A2s" → {AKs, AQs, AJs, ATs, A9s, A8s, A7s, A6s, A5s, A4s, A3s, A2s}
#      "AA-55"   → {AA, KK, QQ, JJ, TT, 99, 88, 77, 66, 55}
#      "KQo-K9o" → {KQo, KJo, KTo, K9o}
# ---------------------------------------------------------------------------


def _expand_token(token: str) -> Set[str]:
    """Expand a single hand token or range token into a set of hand strings."""
    token = token.strip()
    if not token:
        return set()

    if "-" in token:
        # Range like AA-55, AKs-A2s, KQo-K9o, QJs-Q8s, JTs-J8s …
        parts = token.split("-", 1)
        lo_tok = parts[1].strip()
        hi_tok = parts[0].strip()
        return _expand_range(hi_tok, lo_tok)
    else:
        assert token in HAND_SET, f"Unknown hand: {token!r}"
        return {token}


def _expand_range(hi: str, lo: str) -> Set[str]:
    """
    Expand a contiguous range of hands.
    hi is the stronger hand, lo is the weaker hand (both in HAND_ORDER).
    Both must share the same 'type' (pair / suited / offsuit) and the same
    high card for non-pair ranges.
    """
    hi_idx = HAND_RANK[hi]
    lo_idx = HAND_RANK[lo]
    assert hi_idx <= lo_idx, (
        f"Range direction error: {hi} (#{hi_idx}) > {lo} (#{lo_idx})"
    )

    result = set()
    for hand in HAND_ORDER[hi_idx : lo_idx + 1]:
        # Verify same category/high-card so we don't accidentally cross blocks
        result.add(hand)

    # Sanity: all hands should share the same suffix (pair / s / o)
    # and — for non-pairs — the same high card.
    suffix = hi[-1] if not hi[0] == hi[1] else ""
    if suffix in ("s", "o"):
        hi_card = hi[0]
        for h in result:
            if h[-1] != suffix or h[0] != hi_card:
                raise ValueError(
                    f"Range {hi}-{lo} crossed a block boundary at {h!r}. "
                    "Split into separate tokens."
                )

    return result


def parse_hand_list(spec_tokens: List[str]) -> Set[str]:
    """
    Given a list of tokens (individual hands or dash-ranges), return the
    full set of hands.
    """
    result: Set[str] = set()
    for tok in spec_tokens:
        result |= _expand_token(tok)
    return result


# ---------------------------------------------------------------------------
# Anchor range definitions
# Each entry is (stack_bb, set_of_hands_that_jam_or_call)
# We define anchors for every position; intermediate stacks are interpolated.
# ---------------------------------------------------------------------------


# Shorthand builder
def H(*tokens: str) -> Set[str]:
    return parse_hand_list(list(tokens))


# -- All 169 hands (used for 5 BB everywhere) --
ALL_169: Set[str] = set(HAND_ORDER)

# ============================================================
# PUSH ANCHOR TABLES  {position: [(stack, hand_set), ...]}
# ============================================================

PUSH_ANCHORS: Dict[str, List[tuple]] = {
    # ---- BTN ----
    "BTN": [
        (5, ALL_169),
        (
            7,
            H(
                "AA-22",
                "AKs-A2s",
                "KQs-K2s",
                "QJs-Q2s",
                "JTs-J2s",
                "T9s-T2s",
                "98s-93s",
                "87s-83s",
                "76s-73s",
                "65s-63s",
                "54s-53s",
                "43s",
                "32s",
                "AKo-A2o",
                "KQo-K2o",
                "QJo-Q9o",
                "JTo-J9o",
                "T9o-T8o",
                "98o-97o",
                "87o-86o",
                "76o",
                "65o",
            ),
        ),
        (
            10,
            H(
                "AA-22",
                "AKs-A2s",
                "KQs-K6s",
                "QJs-Q8s",
                "JTs-J8s",
                "T9s-T8s",
                "98s-97s",
                "87s-86s",
                "76s",
                "65s",
                "AKo-A3o",
                "KQo-K9o",
                "QJo-QTo",
                "JTo",
                "T9o",
            ),
        ),
        (
            15,
            H(
                "AA-22",
                "AKs-A2s",
                "KQs-K9s",
                "QJs-Q9s",
                "JTs-J9s",
                "T9s",
                "98s",
                "87s",
                "AKo-A7o",
                "KQo-KJo",
                "QJo",
            ),
        ),
        (
            20,
            H(
                "AA-55",
                "AKs-A2s",
                "KQs-KTs",
                "QJs-QTs",
                "JTs",
                "AKo-A9o",
                "KQo",
            ),
        ),
    ],
    # ---- CO ----
    "CO": [
        (5, ALL_169),
        (
            7,
            H(
                "AA-22",
                "AKs-A2s",
                "KQs-K4s",
                "QJs-Q7s",
                "JTs-J8s",
                "T9s-T8s",
                "98s-97s",
                "87s-86s",
                "76s-75s",
                "65s-64s",
                "54s",
                "AKo-A2o",
                "KQo-KTo",
                "QJo-Q9o",
                "JTo-J9o",
                "T9o",
            ),
        ),
        (
            10,
            H(
                "AA-22",
                "AKs-A2s",
                "KQs-K8s",
                "QJs-Q9s",
                "JTs-J9s",
                "T9s",
                "98s",
                "87s",
                "76s",
                "AKo-A5o",
                "KQo-KTo",
                "QJo-QTo",
                "JTo",
            ),
        ),
        (
            15,
            H(
                "AA-55",
                "AKs-A2s",
                "KQs-KTs",
                "QJs-Q9s",
                "JTs",
                "T9s",
                "AKo-A8o",
                "KQo-KJo",
            ),
        ),
        (
            20,
            H(
                "AA-77",
                "AKs-A2s",
                "KQs-KJs",
                "QJs",
                "AKo-ATo",
                "KQo",
            ),
        ),
    ],
    # ---- HJ ----
    "HJ": [
        (5, ALL_169),
        (
            7,
            H(
                "AA-22",
                "AKs-A2s",
                "KQs-K5s",
                "QJs-Q8s",
                "JTs-J8s",
                "T9s",
                "98s",
                "87s",
                "76s",
                "65s",
                "AKo-A2o",
                "KQo-K9o",
                "QJo-QTo",
                "JTo-J9o",
                "T9o",
            ),
        ),
        (
            10,
            H(
                "AA-22",
                "AKs-A2s",
                "KQs-K9s",
                "QJs-QTs",
                "JTs-J9s",
                "T9s",
                "98s",
                "AKo-A6o",
                "KQo-KJo",
                "QJo",
            ),
        ),
        (
            15,
            H(
                "AA-66",
                "AKs-A2s",
                "KQs-KJs",
                "QJs",
                "JTs",
                "AKo-A9o",
                "KQo",
            ),
        ),
        (
            20,
            H(
                "AA-88",
                "AKs-A4s",
                "KQs",
                "AKo-AJo",
            ),
        ),
    ],
    # ---- UTG ----
    "UTG": [
        (5, ALL_169),
        (
            7,
            H(
                "AA-22",
                "AKs-A2s",
                "KQs-K6s",
                "QJs-Q9s",
                "JTs-J9s",
                "T9s",
                "98s",
                "87s",
                "76s",
                "AKo-A2o",
                "KQo-K9o",
                "QJo",
                "JTo",
            ),
        ),
        (
            10,
            H(
                "AA-33",
                "AKs-A2s",
                "KQs-KTs",
                "QJs-QTs",
                "JTs",
                "AKo-A7o",
                "KQo-KJo",
            ),
        ),
        (
            15,
            H(
                "AA-77",
                "AKs-A3s",
                "KQs",
                "AKo-ATo",
            ),
        ),
        (
            20,
            H(
                "AA-99",
                "AKs-ATs",
                "AKo-AQo",
            ),
        ),
    ],
    # ---- SB ----
    "SB": [
        (5, ALL_169),
        (
            7,
            H(  # same as BTN 7BB
                "AA-22",
                "AKs-A2s",
                "KQs-K2s",
                "QJs-Q2s",
                "JTs-J2s",
                "T9s-T2s",
                "98s-93s",
                "87s-83s",
                "76s-73s",
                "65s-63s",
                "54s-53s",
                "43s",
                "32s",
                "AKo-A2o",
                "KQo-K2o",
                "QJo-Q9o",
                "JTo-J9o",
                "T9o-T8o",
                "98o-97o",
                "87o-86o",
                "76o",
                "65o",
            ),
        ),
        (
            10,
            H(
                "AA-22",
                "AKs-A2s",
                "KQs-K5s",
                "QJs-Q8s",
                "JTs-J8s",
                "T9s-T7s",
                "98s-97s",
                "87s-85s",
                "76s-74s",
                "65s-63s",
                "54s",
                "43s",
                "AKo-A2o",
                "KQo-K8o",
                "QJo-Q9o",
                "JTo-J8o",
                "T9o-T8o",
                "98o-97o",
                "87o",
            ),
        ),
        (
            15,
            H(
                "AA-22",
                "AKs-A2s",
                "KQs-K8s",
                "QJs-Q9s",
                "JTs-J8s",
                "T9s",
                "98s",
                "87s",
                "AKo-A3o",
                "KQo-KTo",
                "QJo-QTo",
                "JTo",
            ),
        ),
        (
            20,
            H(
                "AA-33",
                "AKs-A2s",
                "KQs-K9s",
                "QJs-QTs",
                "JTs",
                "T9s",
                "98s",
                "AKo-A7o",
                "KQo-KJo",
                "QJo",
            ),
        ),
    ],
}

# ============================================================
# BB CALL ANCHOR TABLES  {vs_position: [(stack, hand_set), ...]}
# ============================================================

CALL_ANCHORS: Dict[str, List[tuple]] = {
    # BB call vs UTG
    "UTG": [
        (
            5,
            H(
                "AA-22",
                "AKs-A2s",
                "KQs-K3s",
                "QJs-Q5s",
                "JTs-J7s",
                "T9s-T7s",
                "98s-97s",
                "87s",
                "AKo-A2o",
                "KQo-K8o",
                "QJo-QTo",
                "JTo",
            ),
        ),
        (
            10,
            H(
                "AA-44",
                "AKs-A2s",
                "KQs-KTs",
                "QJs-QTs",
                "JTs",
                "AKo-A9o",
                "KQo-KJo",
            ),
        ),
        (
            15,
            H(
                "AA-77",
                "AKs-A5s",
                "KQs",
                "AKo-AJo",
            ),
        ),
        (
            20,
            H(
                "AA-99",
                "AKs-ATs",
                "KQs",
                "AKo-AQo",
            ),
        ),
    ],
    # BB call vs HJ
    "HJ": [
        (
            5,
            H(  # same as vs UTG 5BB (~50%)
                "AA-22",
                "AKs-A2s",
                "KQs-K3s",
                "QJs-Q5s",
                "JTs-J7s",
                "T9s-T7s",
                "98s-97s",
                "87s",
                "AKo-A2o",
                "KQo-K8o",
                "QJo-QTo",
                "JTo",
            ),
        ),
        (
            10,
            H(
                "AA-33",
                "AKs-A2s",
                "KQs-KTs",
                "QJs",
                "JTs",
                "T9s",
                "AKo-A8o",
                "KQo-KJo",
            ),
        ),
        (
            15,
            H(
                "AA-66",
                "AKs-A4s",
                "KQs-KJs",
                "QJs",
                "AKo-ATo",
                "KQo",
            ),
        ),
        (
            20,
            H(
                "AA-88",
                "AKs-A9s",
                "KQs",
                "AKo-AJo",
            ),
        ),
    ],
    # BB call vs CO
    "CO": [
        (
            5,
            H(  # ~55%
                "AA-22",
                "AKs-A2s",
                "KQs-K2s",
                "QJs-Q4s",
                "JTs-J6s",
                "T9s-T6s",
                "98s-96s",
                "87s-85s",
                "76s-74s",
                "65s-63s",
                "54s",
                "43s",
                "AKo-A2o",
                "KQo-K7o",
                "QJo-Q9o",
                "JTo-J9o",
                "T9o-T8o",
                "98o",
            ),
        ),
        (
            10,
            H(
                "AA-22",
                "AKs-A2s",
                "KQs-KJs",
                "QJs-QTs",
                "JTs",
                "T9s",
                "AKo-A7o",
                "KQo-KTo",
            ),
        ),
        (
            15,
            H(
                "AA-55",
                "AKs-A3s",
                "KQs-KTs",
                "QJs",
                "JTs",
                "AKo-A9o",
                "KQo",
            ),
        ),
        (
            20,
            H(
                "AA-77",
                "AKs-A7s",
                "KQs-KJs",
                "AKo-AJo",
                "KQo",
            ),
        ),
    ],
    # BB call vs BTN
    "BTN": [
        (
            5,
            H(  # ~60%
                "AA-22",
                "AKs-A2s",
                "KQs-K2s",
                "QJs-Q3s",
                "JTs-J5s",
                "T9s-T5s",
                "98s-95s",
                "87s-84s",
                "76s-73s",
                "65s-62s",
                "54s-52s",
                "43s-42s",
                "32s",
                "AKo-A2o",
                "KQo-K6o",
                "QJo-Q8o",
                "JTo-J8o",
                "T9o-T7o",
                "98o-96o",
                "87o-85o",
            ),
        ),
        (
            10,
            H(
                "AA-22",
                "AKs-A2s",
                "KQs-K9s",
                "QJs-Q9s",
                "JTs-J9s",
                "T9s",
                "98s",
                "AKo-A6o",
                "KQo-KTo",
                "QJo",
            ),
        ),
        (
            15,
            H(
                "AA-44",
                "AKs-A2s",
                "KQs-KJs",
                "QJs-QTs",
                "JTs",
                "T9s",
                "AKo-ATo",
                "KQo-KJo",
            ),
        ),
        (
            20,
            H(
                "AA-66",
                "AKs-A9s",
                "KQs-KTs",
                "QJs",
                "AKo-AJo",
                "KQo",
            ),
        ),
    ],
    # BB call vs SB (HU)
    "SB": [
        (
            5,
            H(  # ~65%
                "AA-22",
                "AKs-A2s",
                "KQs-K2s",
                "QJs-Q2s",
                "JTs-J3s",
                "T9s-T4s",
                "98s-94s",
                "87s-83s",
                "76s-72s",
                "65s-62s",
                "54s-52s",
                "43s-42s",
                "32s",
                "AKo-A2o",
                "KQo-K5o",
                "QJo-Q7o",
                "JTo-J7o",
                "T9o-T6o",
                "98o-95o",
                "87o-84o",
                "76o-73o",
            ),
        ),
        (
            10,
            H(
                "AA-22",
                "AKs-A2s",
                "KQs-K7s",
                "QJs-Q8s",
                "JTs-J8s",
                "T9s-T7s",
                "98s-96s",
                "87s-85s",
                "76s",
                "65s",
                "AKo-A2o",
                "KQo-K9o",
                "QJo-Q9o",
                "JTo",
                "T9o",
            ),
        ),
        (
            15,
            H(
                "AA-33",
                "AKs-A2s",
                "KQs-KTs",
                "QJs-QTs",
                "JTs-J9s",
                "T9s",
                "98s",
                "AKo-A7o",
                "KQo-KJo",
                "QJo",
            ),
        ),
        (
            20,
            H(
                "AA-55",
                "AKs-A4s",
                "KQs-KJs",
                "QJs",
                "JTs",
                "AKo-A9o",
                "KQo-KJo",
            ),
        ),
    ],
}

# ---------------------------------------------------------------------------
# Stack sizes to generate
# ---------------------------------------------------------------------------
STACK_SIZES = [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 17, 20]


# ---------------------------------------------------------------------------
# Interpolation
# ---------------------------------------------------------------------------


def _interpolate_hands(stack: int, anchors: List[tuple]) -> Set[str]:
    """
    Return the jam/call hand set for `stack` BB by linearly interpolating
    the range percentage between the two surrounding anchor stacks and then
    taking the top-N hands from HAND_ORDER.
    """
    stacks_a = [s for s, _ in anchors]

    # Exact anchor match
    for s, hands in anchors:
        if s == stack:
            return set(hands)

    # Out of range: clamp to nearest anchor
    if stack < stacks_a[0]:
        return set(anchors[0][1])
    if stack > stacks_a[-1]:
        return set(anchors[-1][1])

    # Find bounding anchors
    lo_s, lo_h = anchors[0]
    hi_s, hi_h = anchors[-1]
    for i in range(len(anchors) - 1):
        a_s, a_h = anchors[i]
        b_s, b_h = anchors[i + 1]
        if a_s <= stack <= b_s:
            lo_s, lo_h = a_s, a_h
            hi_s, hi_h = b_s, b_h
            break

    # Compute percentages at bounding anchors
    lo_pct = len(lo_h) / 169.0
    hi_pct = len(hi_h) / 169.0

    # Linear interpolation
    t = (stack - lo_s) / (hi_s - lo_s)
    interp_pct = lo_pct + t * (hi_pct - lo_pct)
    n = max(1, round(interp_pct * 169))

    # Take the top-n hands from HAND_ORDER
    return set(HAND_ORDER[:n])


# ---------------------------------------------------------------------------
# JSON file construction
# ---------------------------------------------------------------------------

SOURCE_META = {
    "type": "userDefined",
    "description": (
        "Nash equilibrium push/fold range. "
        "ICM-free chip-EV Nash approximation. Not solver-verified."
    ),
}


def _hands_dict(hand_set: Set[str], action: str) -> Dict[str, str]:
    """Return ordered dict of hands → action for the JSON `hands` field."""
    return {h: action for h in HAND_ORDER if h in hand_set}


def build_push_json(position: str, stack: int, hand_set: Set[str]) -> dict:
    pos_lower = position.lower()
    file_id = f"mtt_9max_{stack}bb_{pos_lower}_pushfold_v2"
    return {
        "id": file_id,
        "format": "NLHE_MTT_9MAX",
        "spot": {
            "position": position,
            "stackDepthBB": stack,
            "facingAction": "pushFold",
            "anteType": "bigBlindAnte",
        },
        "source": SOURCE_META,
        "hands": _hands_dict(hand_set, "jam"),
    }


def build_call_json(vs_position: str, stack: int, hand_set: Set[str]) -> dict:
    # Villain position is encoded in the file ID and source description.
    # SpotPayload in Swift has no villainPosition field, so we must NOT add
    # extra keys — JSONDecoder with default settings will reject unknown keys
    # if the struct uses strict decoding.
    file_id = f"mtt_9max_{stack}bb_bb_vs_{vs_position.lower()}_pushfold_v2"
    return {
        "id": file_id,
        "format": "NLHE_MTT_9MAX",
        "spot": {
            "position": "BB",
            "stackDepthBB": stack,
            "facingAction": "blindDefense",
            "anteType": "bigBlindAnte",
        },
        "source": {
            "type": "userDefined",
            "description": (
                f"Nash equilibrium BB calling range vs {vs_position} jam. "
                "ICM-free chip-EV Nash approximation. Not solver-verified."
            ),
        },
        "hands": _hands_dict(hand_set, "call"),
    }


# ---------------------------------------------------------------------------
# File naming
# ---------------------------------------------------------------------------


def push_filename(position: str, stack: int) -> str:
    return f"mtt_9max_{stack}bb_{position.lower()}_pushfold_v2.json"


def call_filename(vs_position: str, stack: int) -> str:
    return f"mtt_9max_{stack}bb_bb_vs_{vs_position.lower()}_pushfold_v2.json"


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    written: List[str] = []
    deleted: List[str] = []

    # ── 1. Write push ranges ──────────────────────────────────────────────
    for position, anchors in PUSH_ANCHORS.items():
        for stack in STACK_SIZES:
            hand_set = _interpolate_hands(stack, anchors)
            data = build_push_json(position, stack, hand_set)
            fname = push_filename(position, stack)
            fpath = OUTPUT_DIR / fname
            fpath.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
            written.append(fname)
            print(f"  ✓ {fname}  ({len(hand_set)}/169 hands)")

    # ── 2. Write BB call ranges ───────────────────────────────────────────
    for vs_pos, anchors in CALL_ANCHORS.items():
        for stack in STACK_SIZES:
            hand_set = _interpolate_hands(stack, anchors)
            data = build_call_json(vs_pos, stack, hand_set)
            fname = call_filename(vs_pos, stack)
            fpath = OUTPUT_DIR / fname
            fpath.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
            written.append(fname)
            print(f"  ✓ {fname}  ({len(hand_set)}/169 hands)")

    # ── 3. Delete old *pushfold*demo_v1.json files ────────────────────────
    for old in OUTPUT_DIR.glob("*pushfold*demo_v1.json"):
        old.unlink()
        deleted.append(old.name)
        print(f"  🗑  Deleted old file: {old.name}")

    # ── 4. Summary ────────────────────────────────────────────────────────
    print()
    print("=" * 60)
    print(f"Push/fold ranges written : {len(written)}")
    print(f"Old demo files deleted   : {len(deleted)}")
    print(f"Output directory         : {OUTPUT_DIR.resolve()}")
    print("=" * 60)


if __name__ == "__main__":
    main()
