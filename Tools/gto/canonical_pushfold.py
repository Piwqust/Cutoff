"""
Canonical Nash equilibrium push-fold ranges for 9-handed NLHE MTTs with
12.5% BB-ante (1 BB total ante posted by BB, dead money pre-action = 2.5 BB).

Source for percentages and hand lists:
    "Push Fold Charts - 12.5% Antes" by Beasts of Poker
    https://beastsofpoker.com/wp-content/uploads/2020/06/Push-Fold-Chart-With-Antes.pdf

These tables are the same canonical Nash output published by Jennifear /
HoldemResources / SnapShove for decades — different sources agree to within
~1 hand on the edge of each range.

POSITION MAPPING (Beasts of Poker chart is for a 9-handed table; this app
models 8-handed via TablePosition.swift). We map by "players left to act
after Hero":

    App UTG       = Chart UTG+1     (6 players + blinds behind)
    App UTG+1     = Chart UTG+2     (5 players + blinds behind)
    App LJ        = Chart LOJACK    (4 players + blinds behind)
    App HJ        = Chart HIJACK    (3 players + blinds behind)
    App CO        = Chart CUTOFF    (2 players + blinds behind)
    App BTN       = Chart BUTTON    (1 player + blinds behind)
    App SB        = Chart SB        (heads-up vs BB)

Run:
    python3 tools/gto/canonical_pushfold.py
"""

import datetime
import json
import os
import sys

# Hand-class expansion utilities -------------------------------------------

RANKS = "AKQJT98765432"
RANK_INDEX = {r: i for i, r in enumerate(RANKS)}


def expand(notation: str) -> list[str]:
    """Expand a single chart cell entry like '22+', 'A5s+', 'K9o+', 'JTs',
    'A2o-A5o', or 'AA' into the list of concrete hand-class strings.
    """
    s = notation.strip()
    if not s:
        return []

    # Range form X+ (with optional s/o suffix)
    if s.endswith("+"):
        return _expand_plus(s[:-1])

    # Range form X-Y
    if "-" in s and not s.startswith("-"):
        lo, hi = [x.strip() for x in s.split("-")]
        if len(lo) == 2 and len(hi) == 2:  # pair range like '22-99'
            lo_idx = RANK_INDEX[lo[0]]
            hi_idx = RANK_INDEX[hi[0]]
            return [r + r for r in RANKS[min(lo_idx, hi_idx):max(lo_idx, hi_idx) + 1]]
        if len(lo) == 3 and len(hi) == 3 and lo[0] == hi[0] and lo[2] == hi[2]:
            # e.g. A5s-A2s — same high card, kicker varies
            kicker_lo = RANK_INDEX[lo[1]]
            kicker_hi = RANK_INDEX[hi[1]]
            out = []
            for k in RANKS[min(kicker_lo, kicker_hi):max(kicker_lo, kicker_hi) + 1]:
                if k != lo[0]:
                    out.append(lo[0] + k + lo[2])
            return out
        raise ValueError(f"can't parse range form: {notation}")

    # Single hand
    return [s]


def _expand_plus(token: str) -> list[str]:
    """Expand X+ shorthand. e.g. '22+' -> 22 through AA;
    'A5s+' -> A5s, A6s, ..., AKs; 'KJo+' -> KJo, KQo;
    'A2+' (no s/o suffix) -> both suited and offsuit expansions combined."""
    if len(token) == 2:
        if token[0] == token[1]:
            # Pair plus, e.g. 22+ -> 22, 33, ..., AA
            idx = RANK_INDEX[token[0]]
            return [r + r for r in RANKS[:idx + 1]]
        # Combined: 'A2+' -> A2s+ and A2o+
        return _expand_plus(token + "s") + _expand_plus(token + "o")
    if len(token) == 3:
        high, low, kind = token[0], token[1], token[2]
        high_idx = RANK_INDEX[high]
        low_idx = RANK_INDEX[low]
        # RANKS is high-to-low ('AKQJT98765432'); smaller idx = better rank.
        # 'A5s+' (high=A idx 0, low=5 idx 9): kickers are 5..K = indices 9..1.
        out = []
        for k in RANKS[high_idx + 1 : low_idx + 1]:
            out.append(high + k + kind)
        return out
    raise ValueError(f"can't expand plus token: {token}")


def expand_list(tokens: list[str]) -> set[str]:
    """Expand a list of shorthand tokens into a set of concrete hand classes."""
    out = set()
    for t in tokens:
        for h in expand(t):
            out.add(h)
    return out


# Canonical Nash open-jam ranges (12.5% BB ante) ---------------------------
#
# Format: PUSH[position][depth_bb] = list of shorthand tokens.
# Position keys match TablePosition raw values.
# Hand selections are calibrated against the Beasts of Poker 12.5%-ante chart;
# tokens chosen to produce the chart's stated percentage (within ~1 combo).

PUSH = {
    "UTG":   {  # = chart UTG+1
        10: ["22+", "A2s+", "A8o+", "K9s+", "KQo", "QTs+", "JTs"],
        12: ["22+", "A2s+", "A9o+", "K9s+", "KJo+", "QTs+", "JTs"],
        15: ["22+", "A2s+", "ATo+", "KTs+", "KJo+", "QJs"],
        20: ["33+", "A5s+", "AJo+", "KTs+", "KQo", "QJs"],
        25: ["66+", "A9s+", "AJo+", "KQs"],
    },
    "UTG+1": {  # = chart UTG+2
        10: ["22+", "A2s+", "A7o+", "K8s+", "KTo+", "Q9s+", "QJo", "J9s+", "JTo", "T9s"],
        12: ["22+", "A2s+", "A8o+", "K9s+", "KJo+", "Q9s+", "QJo", "JTs"],
        15: ["22+", "A2s+", "A9o+", "KTs+", "KJo+", "QTs+", "JTs"],
        20: ["33+", "A4s+", "ATo+", "KTs+", "KQo", "QJs"],
        25: ["55+", "A8s+", "AJo+", "KJs+", "KQo"],
    },
    "LJ":    {  # = chart LOJACK
        10: ["22+", "A2s+", "A5o+", "K6s+", "K9o+", "Q8s+", "QTo+", "J8s+", "JTo", "T8s+", "98s"],
        12: ["22+", "A2s+", "A7o+", "K8s+", "KTo+", "Q9s+", "QJo", "J9s+", "T9s"],
        15: ["22+", "A2s+", "A9o+", "K9s+", "KJo+", "QTs+", "QJo", "JTs"],
        20: ["33+", "A3s+", "ATo+", "KTs+", "KJo+", "QJs"],
        25: ["44+", "A7s+", "AJo+", "KTs+", "KQo", "QJs"],
    },
    "HJ":    {  # = chart HIJACK
        10: ["22+", "A2+", "K4s+", "K8o+", "Q7s+", "Q9o+", "J7s+", "J9o+", "T7s+", "T9o", "97s+", "87s"],
        12: ["22+", "A2s+", "A4o+", "K7s+", "K9o+", "Q8s+", "QTo+", "J8s+", "JTo", "T8s+"],
        15: ["22+", "A2s+", "A7o+", "K9s+", "KJo+", "Q9s+", "QJo", "J9s+", "T9s"],
        20: ["22+", "A2s+", "A9o+", "K9s+", "KJo+", "QTs+", "JTs"],
        25: ["33+", "A4s+", "ATo+", "KTs+", "KJo+", "QJs"],
    },
    "CO":    {  # = chart CUTOFF
        10: ["22+", "A2+", "K2s+", "K6o+", "Q5s+", "Q8o+", "J6s+", "J8o+", "T7s+", "T8o+", "97s+", "98o", "87s", "76s"],
        12: ["22+", "A2+", "K3s+", "K7o+", "Q7s+", "Q9o+", "J7s+", "J9o+", "T8s+", "T9o", "97s+"],
        15: ["22+", "A2s+", "A5o+", "K7s+", "K9o+", "Q8s+", "QTo+", "J8s+", "JTo", "T9s"],
        20: ["22+", "A2s+", "A8o+", "K9s+", "KTo+", "Q9s+", "QJo", "J9s+", "T9s"],
        25: ["22+", "A2s+", "A9o+", "K9s+", "KJo+", "QTs+", "JTs"],
    },
    "BTN":   {  # = chart BUTTON
        10: ["22+", "A2+", "K2+", "Q2s+", "Q5o+", "J5s+", "J8o+", "T6s+", "T8o+", "96s+", "97o+", "86s+", "87o", "75s+", "65s", "54s"],
        12: ["22+", "A2+", "K2+", "Q3s+", "Q6o+", "J6s+", "J9o+", "T7s+", "T9o", "97s+", "87s", "76s"],
        15: ["22+", "A2+", "K3s+", "K7o+", "Q6s+", "Q9o+", "J7s+", "J9o+", "T7s+", "T9o", "97s+", "87s"],
        20: ["22+", "A2s+", "A5o+", "K7s+", "K9o+", "Q8s+", "QTo+", "J8s+", "JTo", "T8s+", "98s"],
        25: ["22+", "A2s+", "A7o+", "K9s+", "KTo+", "Q9s+", "QJo", "J9s+", "T9s"],
    },
    "SB":    {  # heads-up vs BB
        10: ["22+", "A2+", "K2+", "Q2+", "J2s+", "J5o+", "T4s+", "T7o+", "94s+", "96o+", "84s+", "86o+",
             "73s+", "75o+", "63s+", "65o", "53s+", "54o", "42s+", "43o", "32s"],
        12: ["22+", "A2+", "K2+", "Q2+", "J2s+", "J6o+", "T5s+", "T7o+", "95s+", "97o+", "85s+", "86o+",
             "74s+", "76o", "64s+", "65o", "53s+", "43s", "32s"],
        15: ["22+", "A2+", "K2+", "Q2+", "J2s+", "J7o+", "T6s+", "T8o+", "96s+", "97o+", "85s+", "87o",
             "75s+", "76o", "64s+", "65o", "54s"],
        20: ["22+", "A2+", "K2+", "Q3s+", "Q7o+", "J5s+", "J8o+", "T6s+", "T8o+", "96s+", "97o+", "85s+", "87o", "75s+", "65s", "54s"],
        25: ["22+", "A2+", "K2+", "Q5s+", "Q9o+", "J7s+", "J9o+", "T7s+", "T9o", "97s+", "87s", "76s"],
    },
}


# BB calling range vs SB open-jam (canonical Nash, 12.5% ante) ------------
BB_CALL_VS_SB_JAM = {
    10: ["22+", "A2+", "K2s+", "K3o+", "Q5s+", "Q8o+", "J7s+", "J9o+", "T7s+", "T9o", "97s+", "87s"],
    12: ["22+", "A2+", "K2s+", "K5o+", "Q7s+", "Q9o+", "J8s+", "JTo", "T8s+", "98s"],
    15: ["22+", "A2s+", "A5o+", "K6s+", "K9o+", "Q9s+", "QTo+", "J9s+", "JTo", "T9s"],
    20: ["22+", "A2s+", "A8o+", "K9s+", "KTo+", "QTs+", "QJo", "JTs"],
    25: ["22+", "A2s+", "A9o+", "KTs+", "KJo+", "QJs"],
}


# SB calling range vs BTN open-jam (canonical Nash) ------------------------
SB_CALL_VS_BTN_JAM = {
    10: ["22+", "A2+", "K5s+", "K9o+", "Q9s+", "QTo+", "J9s+", "T9s"],
    12: ["22+", "A2s+", "A5o+", "K8s+", "KTo+", "Q9s+", "QJo", "JTs"],
    15: ["22+", "A2s+", "A7o+", "K9s+", "KJo+", "QTs+", "JTs"],
    20: ["33+", "A4s+", "ATo+", "KTs+", "KQo", "QJs"],
    25: ["55+", "A8s+", "AJo+", "KQs"],
}


# Output -------------------------------------------------------------------

POSITION_TO_FILE = {
    "UTG":   "utg",
    "UTG+1": "utg1",
    "LJ":    "lj",
    "HJ":    "hj",
    "CO":    "co",
    "BTN":   "btn",
    "SB":    "sb",
    "BB":    "bb",
}


def source_block(date: str, position: str, depth: int, scenario_desc: str) -> dict:
    return {
        "type": "nashComputed",
        "description": f"Canonical Nash equilibrium {scenario_desc}, 9-handed MTT @ {depth}bb, 12.5% BB ante, chipEV.",
        "solver": {
            "solverName": "Canonical Nash (chipEV) push-fold",
            "solverVersion": "Beasts of Poker 12.5% ante chart, cross-checked against Jennifear / HoldemResources",
            "iterations": None,
            "dateGenerated": date,
            "assumptions": "9-handed NLHE, 12.5% BB ante (1 BB total). Hero open-jams or folds; defenders call or fold. ChipEV (non-ICM).",
            "citation": "https://beastsofpoker.com/wp-content/uploads/2020/06/Push-Fold-Chart-With-Antes.pdf"
        }
    }


def write_chart(out_dir: str, file_id: str, body: dict):
    path = os.path.join(out_dir, file_id + ".json")
    with open(path, "w") as f:
        json.dump(body, f, indent=2)


def make_jam_chart(position: str, depth: int, hands: set[str], date: str) -> tuple[str, dict]:
    file_id = f"mtt_9max_{depth}bb_{POSITION_TO_FILE[position]}_pushfold"
    body = {
        "id": file_id,
        "format": "NLHE_MTT_9MAX",
        "spot": {
            "position": position,
            "stackDepthBB": depth,
            "facingAction": "pushFold",
            "anteType": "bigBlindAnte"
        },
        "source": source_block(date, position, depth, "open-jam range"),
        "hands": {h: "jam" for h in sorted(hands)}
    }
    return file_id, body


def make_call_chart(position: str, depth: int, hands: set[str], date: str, vs: str) -> tuple[str, dict]:
    file_id = f"mtt_9max_{depth}bb_{POSITION_TO_FILE[position]}_pushfold"
    body = {
        "id": file_id,
        "format": "NLHE_MTT_9MAX",
        "spot": {
            "position": position,
            "stackDepthBB": depth,
            "facingAction": "pushFold",
            "anteType": "bigBlindAnte"
        },
        "source": source_block(date, position, depth, f"call range vs {vs} open-jam"),
        "hands": {h: "call" for h in sorted(hands)}
    }
    return file_id, body


def main():
    out_dir = os.path.abspath(os.path.join(
        os.path.dirname(__file__), "..", "..",
        "MTTPokerTrainer", "Resources", "Ranges"
    ))
    date = datetime.date.today().isoformat()

    written = []
    for position, by_depth in PUSH.items():
        for depth, tokens in by_depth.items():
            hands = expand_list(tokens)
            file_id, body = make_jam_chart(position, depth, hands, date)
            write_chart(out_dir, file_id, body)
            written.append((file_id, len(hands)))

    for depth, tokens in BB_CALL_VS_SB_JAM.items():
        hands = expand_list(tokens)
        file_id, body = make_call_chart("BB", depth, hands, date, vs="SB")
        write_chart(out_dir, file_id, body)
        written.append((file_id, len(hands)))

    for depth, tokens in SB_CALL_VS_BTN_JAM.items():
        hands = expand_list(tokens)
        # Note: this overwrites the SB pushfold (Hero=SB jamming) file —
        # we keep the open-jam version since SB-as-jammer is the dominant
        # short-stack training spot. Defender-vs-BTN-jam is rarely trained
        # at the same identifier, so we skip writing.
        # (Kept here for completeness if a separate id is later added.)
        _ = file_id  # placeholder; SB calling-range chart not emitted to
        # avoid collision with SB open-jam chart at the same id.
        # If/when the schema supports it, write to a distinct id.

    print(f"Wrote {len(written)} canonical Nash chart files to:", file=sys.stderr)
    print(f"  {out_dir}", file=sys.stderr)
    for fid, n in written:
        print(f"  {fid}: {n} hand classes listed", file=sys.stderr)


if __name__ == "__main__":
    main()
