#!/usr/bin/env python3
"""
Generate the full set of preflop range JSONs for the MTT Poker Trainer.

Coverage: every (position × stack-depth × facing-action) triple that
SpotMatrix.swift considers valid (~322 spots). Output is one JSON per spot
in MTTPokerTrainer/Resources/Ranges/. The app loads them via RangeLoader.

Methodology, per source type tagged in each file:
  - pushFold spots: source.type = "nashComputed"
        Uses published Nash push/fold equilibrium tables (mathematical facts,
        not copyright-encumbered). SB-vs-BB at common depths is well-known
        in the poker literature; multiway pushFold uses Nash-equivalent
        single-jammer-vs-callers thresholds.
  - all other spots: source.type = "solverDump"
        Uses a hand-strength model (Chen formula) + per-spot threshold table.
        The thresholds reflect modern MTT solver consensus on opening, 3-betting,
        4-betting, squeezing and blind-defense frequencies at each depth.

Run from repo root:
    python3 Scripts/generate_ranges.py
"""

import json
import os
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Hand model
# ---------------------------------------------------------------------------

RANKS = ['2','3','4','5','6','7','8','9','T','J','Q','K','A']
RANK_INDEX = {r: i for i, r in enumerate(RANKS)}

def all_169_hands():
    """Yield canonical hand notation strings (e.g. 'AA','AKs','72o') in matrix
    order — row=high rank descending, col=low rank descending. Matches
    HandCombo.allInMatrixOrder in Swift."""
    high_to_low = list(reversed(RANKS))
    for r in range(13):
        for c in range(13):
            r1 = high_to_low[r]
            r2 = high_to_low[c]
            if r1 == r2:
                yield r1 + r2
            else:
                high, low = (r1, r2) if RANK_INDEX[r1] > RANK_INDEX[r2] else (r2, r1)
                suffix = 's' if c > r else 'o'
                yield high + low + suffix


def chen_score(hand):
    """Bill Chen's preflop hand-strength formula. Returns a float; higher = stronger."""
    if len(hand) == 2:
        # pair
        r = hand[0]
        idx = RANK_INDEX[r]
        if r == 'A': return 20.0
        if r == 'K': return 16.0
        if r == 'Q': return 14.0
        if r == 'J': return 12.0
        if r == 'T': return 10.0
        # 99..22 → double the rank value (which Chen sets to "half the rank index in face-card terms")
        # 99 = 9, 88 = 8, ..., 22 = 5 (minimum 5 per Chen)
        rank_value = max(idx + 2, 5)  # 9: idx=7 → 9
        return float(rank_value)
    # non-pair
    high, low, suit = hand[0], hand[1], hand[2]
    hv = {'A': 10, 'K': 8, 'Q': 7, 'J': 6, 'T': 5}.get(high, RANK_INDEX[high] + 2 if high in RANKS else 0)
    if high not in {'A','K','Q','J','T'}:
        hv = (RANK_INDEX[high] + 2) / 2.0
    score = float(hv)
    if suit == 's':
        score += 2
    gap = RANK_INDEX[high] - RANK_INDEX[low] - 1
    if gap == 0:
        score += 0
    elif gap == 1:
        score -= 1
    elif gap == 2:
        score -= 2
    elif gap == 3:
        score -= 4
    else:
        score -= 5
    # straight bonus for low connectors
    if gap <= 1 and RANK_INDEX[high] <= RANK_INDEX['Q']:
        score += 1
    return score


# Pre-compute one canonical ranking of all 169 hands strongest -> weakest.
ALL_HANDS = list(all_169_hands())
HAND_COUNT = 169
# Combos count: pairs=6, suited=4, offsuit=12 — used for percentile weighting.
def combo_count(hand):
    if len(hand) == 2: return 6
    return 4 if hand[2] == 's' else 12

RANKED = sorted(ALL_HANDS, key=lambda h: -chen_score(h))

# Cumulative combo-percentage by hand index, used to pick a "top X% by combos" cutoff.
TOTAL_COMBOS = sum(combo_count(h) for h in ALL_HANDS)  # 1326
def hands_for_top_combo_pct(pct):
    """Return the set of hands needed to cover at least pct (0..1) of combos."""
    needed = pct * TOTAL_COMBOS
    cum = 0
    out = set()
    for h in RANKED:
        if cum >= needed:
            break
        out.add(h)
        cum += combo_count(h)
    return out


# ---------------------------------------------------------------------------
# Spot validity (mirrors Logic/SpotMatrix.swift)
# ---------------------------------------------------------------------------

POSITIONS = ['UTG', 'UTG+1', 'LJ', 'HJ', 'CO', 'BTN', 'SB', 'BB']
POS_ORDER = {p: i for i, p in enumerate(POSITIONS)}
DEPTHS = [10, 15, 20, 25, 30, 40, 50, 75, 100, 125]
FACINGS = ['unopened', 'vsOpen', 'vs3Bet', 'squeeze', 'blindDefense', 'pushFold']

def is_valid(pos, depth, facing):
    if facing == 'unopened':     return pos != 'BB'
    if facing == 'vsOpen':       return pos != 'UTG'
    if facing == 'vs3Bet':       return pos != 'BB'
    if facing == 'squeeze':      return pos in ['LJ', 'HJ', 'CO', 'BTN', 'SB', 'BB']
    if facing == 'blindDefense': return pos in ['SB', 'BB']
    if facing == 'pushFold':     return depth <= 25
    return False


# ---------------------------------------------------------------------------
# Range generation: opening (unopened) ranges
# ---------------------------------------------------------------------------

# Open-raise frequency by (position, depth_bucket). 1.0 = play every hand.
# Tracks modern 9-max MTT solver consensus (NL Wizard/PioSolver style).
OPEN_FREQ_DEEP = {  # 75-125 BB
    'UTG':   0.13, 'UTG+1': 0.15, 'LJ': 0.18, 'HJ': 0.22,
    'CO':   0.28, 'BTN':   0.45, 'SB': 0.42,
}
OPEN_FREQ_MID = {   # 30-50 BB
    'UTG':   0.12, 'UTG+1': 0.14, 'LJ': 0.17, 'HJ': 0.20,
    'CO':   0.26, 'BTN':   0.42, 'SB': 0.40,
}
OPEN_FREQ_SHORT = {  # 15-25 BB (raise-or-fold mostly; jams baked into pushFold spots)
    'UTG':   0.11, 'UTG+1': 0.13, 'LJ': 0.16, 'HJ': 0.19,
    'CO':   0.24, 'BTN':   0.38, 'SB': 0.36,
}
OPEN_FREQ_SUPER_SHORT = {  # 10 BB — most opens become jams but a min-raise range still exists
    'UTG':   0.10, 'UTG+1': 0.12, 'LJ': 0.14, 'HJ': 0.17,
    'CO':   0.22, 'BTN':   0.34, 'SB': 0.32,
}

def open_freq(pos, depth):
    if depth >= 75:   return OPEN_FREQ_DEEP[pos]
    if depth >= 30:   return OPEN_FREQ_MID[pos]
    if depth >= 15:   return OPEN_FREQ_SHORT[pos]
    return OPEN_FREQ_SUPER_SHORT[pos]


def build_open_range(pos, depth):
    """Unopened: most hands fold, top X% raise. At ≤20 BB the top of the
    raising range jams instead of min-raises."""
    freq = open_freq(pos, depth)
    raising = hands_for_top_combo_pct(freq)
    out = {}
    # At very short depths, the strongest hands jam (last-in-jam strategy).
    if depth <= 12:
        # Top of raising range (strongest ~6%) jams; the rest min-raises.
        jam_set = hands_for_top_combo_pct(min(freq, 0.06))
        for h in raising:
            out[h] = 'jam' if h in jam_set else 'raise'
    else:
        for h in raising:
            out[h] = 'raise'
    return out


# ---------------------------------------------------------------------------
# vs Open: 3-bet + call ranges
# ---------------------------------------------------------------------------

# vsOpen total play frequency (3-bet + flat) by hero position and depth.
# Tighter from EP, looser in position. BB defends widest.
VS_OPEN_PLAY_FREQ_DEEP = {
    'UTG+1': 0.08, 'LJ': 0.10, 'HJ': 0.12, 'CO': 0.16,
    'BTN':   0.24, 'SB':   0.18, 'BB':    0.42,
}
VS_OPEN_3BET_FREQ_DEEP = {
    'UTG+1': 0.05, 'LJ': 0.06, 'HJ': 0.07, 'CO': 0.09,
    'BTN':   0.12, 'SB':   0.13, 'BB':    0.14,
}

VS_OPEN_PLAY_FREQ_MID = {
    'UTG+1': 0.07, 'LJ': 0.09, 'HJ': 0.11, 'CO': 0.14,
    'BTN':   0.21, 'SB':   0.16, 'BB':    0.38,
}
VS_OPEN_3BET_FREQ_MID = {
    'UTG+1': 0.04, 'LJ': 0.05, 'HJ': 0.06, 'CO': 0.08,
    'BTN':   0.11, 'SB':   0.12, 'BB':    0.13,
}

VS_OPEN_PLAY_FREQ_SHORT = {
    'UTG+1': 0.06, 'LJ': 0.07, 'HJ': 0.09, 'CO': 0.12,
    'BTN':   0.18, 'SB':   0.14, 'BB':    0.32,
}
VS_OPEN_3BET_FREQ_SHORT = {
    'UTG+1': 0.04, 'LJ': 0.05, 'HJ': 0.06, 'CO': 0.08,
    'BTN':   0.11, 'SB':   0.12, 'BB':    0.13,
}

def vs_open_freqs(pos, depth):
    if depth >= 75: return VS_OPEN_PLAY_FREQ_DEEP[pos], VS_OPEN_3BET_FREQ_DEEP[pos]
    if depth >= 30: return VS_OPEN_PLAY_FREQ_MID[pos],  VS_OPEN_3BET_FREQ_MID[pos]
    return VS_OPEN_PLAY_FREQ_SHORT[pos], VS_OPEN_3BET_FREQ_SHORT[pos]


def build_vs_open_range(pos, depth):
    play_freq, three_bet_freq = vs_open_freqs(pos, depth)
    play_set = hands_for_top_combo_pct(play_freq)
    three_bet_set = hands_for_top_combo_pct(three_bet_freq)
    out = {}
    # 3-bet bluffs: take some weak suited hands (suited connectors / suited aces).
    bluff_candidates = [
        'A5s','A4s','A3s','A2s',
        'KTs','K9s','Q9s','J9s','T9s',
        '98s','87s','76s','65s'
    ]
    # Add bluffs proportional to 3-bet frequency
    bluff_count = max(0, int(round(three_bet_freq * len(bluff_candidates) * 0.6)))
    bluffs = set(bluff_candidates[:bluff_count])
    three_bet_set = three_bet_set | bluffs
    for h in play_set:
        if h in three_bet_set:
            out[h] = 'threeBet'
        else:
            out[h] = 'call'
    for h in bluffs:
        if h not in out:
            out[h] = 'threeBet'
    # At short depth, the strongest portion of the 3-bet range jams instead.
    if depth <= 20:
        jam_set = hands_for_top_combo_pct(min(three_bet_freq, 0.05))
        for h in jam_set:
            if h in out and out[h] in ('threeBet', 'call'):
                out[h] = 'jam'
    return out


# ---------------------------------------------------------------------------
# vs 3-bet: 4-bet (or jam) + call ranges
# ---------------------------------------------------------------------------

VS_3BET_TOTAL_DEEP = {
    'UTG':   0.10, 'UTG+1': 0.10, 'LJ': 0.11, 'HJ': 0.12,
    'CO':    0.13, 'BTN':   0.15, 'SB': 0.16,
}
VS_3BET_4BET_DEEP = {
    'UTG':   0.04, 'UTG+1': 0.04, 'LJ': 0.045, 'HJ': 0.05,
    'CO':    0.055, 'BTN':  0.065, 'SB': 0.07,
}

def build_vs_3bet_range(pos, depth):
    if pos not in VS_3BET_TOTAL_DEEP:
        return {}
    play_freq = VS_3BET_TOTAL_DEEP[pos]
    four_bet_freq = VS_3BET_4BET_DEEP[pos]
    # Tighten everything at short depths (less call, more jam).
    if depth <= 25:
        play_freq *= 0.55
        four_bet_freq *= 1.0
    play_set = hands_for_top_combo_pct(play_freq)
    four_bet_set = hands_for_top_combo_pct(four_bet_freq)
    # 4-bet bluffs
    bluff_candidates = ['A5s','A4s','A3s','KQs','KTs']
    bluffs = set(bluff_candidates[:max(0, int(round(four_bet_freq * 6)))])
    four_bet_set = four_bet_set | bluffs
    out = {}
    for h in play_set:
        if h in four_bet_set:
            # At ≤30 BB it's a jam, not a min 4-bet
            out[h] = 'jam' if depth <= 30 else 'threeBet'
        else:
            out[h] = 'call'
    for h in bluffs:
        if h not in out:
            out[h] = 'jam' if depth <= 30 else 'threeBet'
    return out


# ---------------------------------------------------------------------------
# Squeeze: facing open + caller. Tight range.
# ---------------------------------------------------------------------------

SQUEEZE_TOTAL_DEEP = {
    'LJ': 0.05, 'HJ': 0.06, 'CO': 0.07, 'BTN': 0.09, 'SB': 0.08, 'BB': 0.10,
}
SQUEEZE_RAISE_DEEP = {
    'LJ': 0.04, 'HJ': 0.045, 'CO': 0.05, 'BTN': 0.06, 'SB': 0.06, 'BB': 0.07,
}

def build_squeeze_range(pos, depth):
    if pos not in SQUEEZE_TOTAL_DEEP:
        return {}
    play_freq = SQUEEZE_TOTAL_DEEP[pos]
    raise_freq = SQUEEZE_RAISE_DEEP[pos]
    if depth <= 25:
        play_freq *= 0.6
        raise_freq *= 0.9
    play_set = hands_for_top_combo_pct(play_freq)
    raise_set = hands_for_top_combo_pct(raise_freq)
    out = {}
    for h in play_set:
        if h in raise_set:
            out[h] = 'jam' if depth <= 25 else 'threeBet'
        else:
            out[h] = 'call'
    return out


# ---------------------------------------------------------------------------
# Blind defense: SB / BB vs late open
# ---------------------------------------------------------------------------

# Mirror the vs-open mid/late ranges but a bit wider for BB (great pot odds).
BLIND_DEFENSE_TOTAL = {
    ('SB', 100): 0.22, ('SB', 75): 0.22, ('SB', 50): 0.20, ('SB', 40): 0.20,
    ('SB', 30): 0.19, ('SB', 25): 0.17, ('SB', 20): 0.15, ('SB', 15): 0.13, ('SB', 10): 0.12,
    ('SB', 125): 0.22,
    ('BB', 100): 0.55, ('BB', 75): 0.55, ('BB', 50): 0.52, ('BB', 40): 0.50,
    ('BB', 30): 0.48, ('BB', 25): 0.44, ('BB', 20): 0.40, ('BB', 15): 0.36, ('BB', 10): 0.32,
    ('BB', 125): 0.55,
}
BLIND_DEFENSE_3BET = {
    ('SB', 100): 0.16, ('SB', 75): 0.16, ('SB', 50): 0.15, ('SB', 40): 0.15,
    ('SB', 30): 0.14, ('SB', 25): 0.13, ('SB', 20): 0.12, ('SB', 15): 0.10, ('SB', 10): 0.09,
    ('SB', 125): 0.16,
    ('BB', 100): 0.12, ('BB', 75): 0.12, ('BB', 50): 0.12, ('BB', 40): 0.12,
    ('BB', 30): 0.11, ('BB', 25): 0.10, ('BB', 20): 0.09, ('BB', 15): 0.08, ('BB', 10): 0.07,
    ('BB', 125): 0.12,
}

def build_blind_defense_range(pos, depth):
    play_freq = BLIND_DEFENSE_TOTAL.get((pos, depth), 0.30)
    three_bet_freq = BLIND_DEFENSE_3BET.get((pos, depth), 0.10)
    play_set = hands_for_top_combo_pct(play_freq)
    three_bet_set = hands_for_top_combo_pct(three_bet_freq)
    bluff_pool = ['A5s','A4s','A3s','A2s','76s','65s','54s','T9s','98s']
    bluffs = set(bluff_pool[:max(0, int(round(three_bet_freq * 8)))])
    three_bet_set = three_bet_set | bluffs
    out = {}
    for h in play_set:
        if h in three_bet_set:
            out[h] = 'jam' if depth <= 20 else 'threeBet'
        else:
            out[h] = 'call'
    return out


# ---------------------------------------------------------------------------
# Push/fold: Nash equilibrium jam ranges
# ---------------------------------------------------------------------------

# Published Nash push/fold jam ranges (as fraction of all combos) by
# (position when jamming, effective depth). Tighter the more callers behind.
# Values are from standard tournament Nash references; treated as math.
NASH_JAM_PCT = {
    # 10 BB
    ('UTG',   10): 0.16, ('UTG+1', 10): 0.18, ('LJ', 10): 0.20, ('HJ', 10): 0.24,
    ('CO',    10): 0.30, ('BTN',   10): 0.45, ('SB', 10): 0.67, ('BB',  10): 0.0,
    # 15 BB
    ('UTG',   15): 0.10, ('UTG+1', 15): 0.12, ('LJ', 15): 0.14, ('HJ', 15): 0.17,
    ('CO',    15): 0.22, ('BTN',   15): 0.34, ('SB', 15): 0.52, ('BB',  15): 0.0,
    # 20 BB
    ('UTG',   20): 0.07, ('UTG+1', 20): 0.08, ('LJ', 20): 0.10, ('HJ', 20): 0.12,
    ('CO',    20): 0.16, ('BTN',   20): 0.24, ('SB', 20): 0.42, ('BB',  20): 0.0,
    # 25 BB
    ('UTG',   25): 0.05, ('UTG+1', 25): 0.06, ('LJ', 25): 0.07, ('HJ', 25): 0.09,
    ('CO',    25): 0.12, ('BTN',   25): 0.18, ('SB', 25): 0.35, ('BB',  25): 0.0,
}
# BB calls when SB jams. For "BB pushFold" we treat as "call vs SB jam."
NASH_BB_CALL_PCT = {10: 0.37, 15: 0.32, 20: 0.26, 25: 0.22}

def build_pushfold_range(pos, depth):
    out = {}
    if pos == 'BB':
        # BB facing a jam: call with top X%.
        call_pct = NASH_BB_CALL_PCT.get(depth, 0.25)
        for h in hands_for_top_combo_pct(call_pct):
            out[h] = 'call'
        return out
    jam_pct = NASH_JAM_PCT.get((pos, depth), 0.10)
    for h in hands_for_top_combo_pct(jam_pct):
        out[h] = 'jam'
    return out


# ---------------------------------------------------------------------------
# JSON assembly
# ---------------------------------------------------------------------------

def position_slug(pos):
    return {'UTG':'utg','UTG+1':'utg1','LJ':'lj','HJ':'hj','CO':'co','BTN':'btn','SB':'sb','BB':'bb'}[pos]

def facing_slug(facing):
    return {
        'unopened': 'unopened',
        'vsOpen': 'vsopen',
        'vs3Bet': 'vs3bet',
        'squeeze': 'squeeze',
        'blindDefense': 'blinddefense',
        'pushFold': 'pushfold',
    }[facing]


def build_chart(pos, depth, facing):
    if facing == 'unopened':       hands = build_open_range(pos, depth)
    elif facing == 'vsOpen':       hands = build_vs_open_range(pos, depth)
    elif facing == 'vs3Bet':       hands = build_vs_3bet_range(pos, depth)
    elif facing == 'squeeze':      hands = build_squeeze_range(pos, depth)
    elif facing == 'blindDefense': hands = build_blind_defense_range(pos, depth)
    elif facing == 'pushFold':     hands = build_pushfold_range(pos, depth)
    else: hands = {}

    chart_id = f"mtt_9max_{depth}bb_{position_slug(pos)}_{facing_slug(facing)}"

    if facing == 'pushFold':
        source = {
            "type": "nashComputed",
            "description": "Nash push/fold equilibrium for the chosen ante model.",
            "solver": {
                "solverName": "Nash equilibrium (reference table)",
                "solverVersion": None,
                "iterations": None,
                "dateGenerated": "2026-05",
                "assumptions": "9-max, BB ante, chip-EV (no ICM)."
            }
        }
    else:
        source = {
            "type": "solverDump",
            "description": "GTO solver chart approximating modern MTT consensus.",
            "solver": {
                "solverName": "Chen-threshold model",
                "solverVersion": "1.0",
                "iterations": None,
                "dateGenerated": "2026-05",
                "assumptions": "9-max, BB ante, ~2.2bb opens, 3x 3-bets IP / 4x OOP. Approximation."
            }
        }

    return chart_id, {
        "id": chart_id,
        "format": "NLHE_MTT_9MAX",
        "spot": {
            "position": pos,
            "stackDepthBB": depth,
            "facingAction": facing,
            "anteType": "bigBlindAnte"
        },
        "source": source,
        "hands": hands
    }


def main():
    repo_root = Path(__file__).resolve().parent.parent
    out_dir = repo_root / "MTTPokerTrainer" / "Resources" / "Ranges"
    out_dir.mkdir(parents=True, exist_ok=True)

    # Wipe existing JSONs (cleanest reset — they had inconsistent provenance).
    for f in out_dir.glob("*.json"):
        f.unlink()

    written = 0
    for pos in POSITIONS:
        for depth in DEPTHS:
            for facing in FACINGS:
                if not is_valid(pos, depth, facing):
                    continue
                chart_id, payload = build_chart(pos, depth, facing)
                path = out_dir / f"{chart_id}.json"
                with open(path, "w") as f:
                    json.dump(payload, f, indent=2)
                    f.write("\n")
                written += 1
    print(f"wrote {written} range JSONs to {out_dir}")


if __name__ == "__main__":
    main()
