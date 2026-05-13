#!/usr/bin/env python3
"""
Generate postflop ("flop") training spots for the MTT Poker Trainer.

We don't ship a full solver; instead we author a compact library of flop
decision spots covering the strategically meaningful axes:
  - preflop scenario (SRP-IP, SRP-OOP, 3BP-IP, 3BP-OOP)
  - stack depth (40 / 75 / 125 BB)
  - flop texture class (9 classes from BoardTextureClass.swift)
  - decision point (preflop raiser facing flop, caller facing c-bet)

That's 4 × 3 × 9 × 2 = 216 spots. Each spot encodes:
  - canonical example board for the texture
  - action history up to the decision
  - available actions
  - frequency-weighted solver-consensus solution (e.g. "bet33 0.7, check 0.3")
  - one-sentence coaching note

Output: MTTPokerTrainer/Resources/Postflop/flop_library.json
"""

import json
from pathlib import Path

# ---------------------------------------------------------------------------
# Canonical example boards per texture class
# ---------------------------------------------------------------------------

EXAMPLE_BOARDS = {
    'dry_high':       'Ks7d2c',
    'dry_low':        '832c4h6s'[:6],   # actually 8d3c2h-like, see below
    'wet_connected':  'Th9s8d',
    'monotone':       'KsTs5s',
    'two_tone':       'Qh7h2c',
    'paired_high':    'Kh7d7s',
    'paired_low':     '5h5s2d',
    'broadway_heavy': 'AhKsJc',
    'middle_mixed':   'Td8c5h',
}
# fix dry_low manually (need 3 cards: low, disconnected, rainbow)
EXAMPLE_BOARDS['dry_low'] = '8d3c2h'

SCENARIOS = [
    ('srp_ip',       'SRP, in position',         'BTN opened 2.2x, BB called'),
    ('srp_oop',      'SRP, out of position',     'CO opened 2.2x, BB called'),
    ('3bp_ip',       '3-bet pot, in position',   'BTN opened 2.2x, BB 3-bet to 9bb, BTN called'),
    ('3bp_oop',      '3-bet pot, out of position', 'CO opened 2.2x, BTN 3-bet to 7bb, CO called'),
]

DEPTHS = [40, 75, 125]
TEXTURES = list(EXAMPLE_BOARDS.keys())


# ---------------------------------------------------------------------------
# Decision logic — frequency-weighted "solver consensus" solutions
# ---------------------------------------------------------------------------

# Each entry is (texture, decision_point) → {action: freq} for SRP IP raiser facing flop.
# Hand-authored to approximate modern GTO consensus.

CBET_SRP_IP = {
    'dry_high':       {'bet33': 0.85, 'check': 0.15},
    'dry_low':        {'bet33': 0.55, 'check': 0.45},
    'wet_connected':  {'bet33': 0.45, 'bet66': 0.10, 'check': 0.45},
    'monotone':       {'check': 0.65, 'bet33': 0.35},
    'two_tone':       {'bet33': 0.70, 'check': 0.30},
    'paired_high':    {'bet33': 0.55, 'check': 0.45},
    'paired_low':     {'bet33': 0.75, 'check': 0.25},
    'broadway_heavy': {'bet33': 0.80, 'check': 0.20},
    'middle_mixed':   {'bet33': 0.50, 'check': 0.50},
}

# SRP OOP — c-bet less, range advantage smaller out of position
CBET_SRP_OOP = {
    'dry_high':       {'bet33': 0.70, 'check': 0.30},
    'dry_low':        {'check': 0.65, 'bet33': 0.35},
    'wet_connected':  {'check': 0.70, 'bet33': 0.30},
    'monotone':       {'check': 0.80, 'bet33': 0.20},
    'two_tone':       {'bet33': 0.55, 'check': 0.45},
    'paired_high':    {'check': 0.55, 'bet33': 0.45},
    'paired_low':     {'bet33': 0.60, 'check': 0.40},
    'broadway_heavy': {'bet33': 0.70, 'check': 0.30},
    'middle_mixed':   {'check': 0.55, 'bet33': 0.45},
}

# 3-bet pot in position — bigger c-bet sizings, range much more concentrated
CBET_3BP_IP = {
    'dry_high':       {'bet33': 0.90, 'bet66': 0.05, 'check': 0.05},
    'dry_low':        {'bet33': 0.70, 'check': 0.30},
    'wet_connected':  {'bet33': 0.30, 'bet66': 0.15, 'check': 0.55},
    'monotone':       {'check': 0.70, 'bet33': 0.30},
    'two_tone':       {'bet33': 0.75, 'check': 0.25},
    'paired_high':    {'bet33': 0.55, 'check': 0.45},
    'paired_low':     {'bet33': 0.75, 'check': 0.25},
    'broadway_heavy': {'bet33': 0.85, 'check': 0.15},
    'middle_mixed':   {'bet33': 0.55, 'check': 0.45},
}

CBET_3BP_OOP = {
    'dry_high':       {'bet33': 0.80, 'check': 0.20},
    'dry_low':        {'check': 0.60, 'bet33': 0.40},
    'wet_connected':  {'check': 0.65, 'bet33': 0.35},
    'monotone':       {'check': 0.80, 'bet33': 0.20},
    'two_tone':       {'bet33': 0.65, 'check': 0.35},
    'paired_high':    {'check': 0.55, 'bet33': 0.45},
    'paired_low':     {'bet33': 0.65, 'check': 0.35},
    'broadway_heavy': {'bet33': 0.75, 'check': 0.25},
    'middle_mixed':   {'check': 0.55, 'bet33': 0.45},
}

CBET_BY_SCENARIO = {
    'srp_ip':   CBET_SRP_IP,
    'srp_oop':  CBET_SRP_OOP,
    '3bp_ip':   CBET_3BP_IP,
    '3bp_oop':  CBET_3BP_OOP,
}

# Caller facing 1/3 pot c-bet: defend frequencies (call + raise vs fold)
DEFEND_VS_CBET = {
    'dry_high':       {'call': 0.55, 'fold': 0.40, 'raise': 0.05},
    'dry_low':        {'call': 0.70, 'fold': 0.20, 'raise': 0.10},
    'wet_connected':  {'call': 0.65, 'fold': 0.20, 'raise': 0.15},
    'monotone':       {'call': 0.50, 'fold': 0.40, 'raise': 0.10},
    'two_tone':       {'call': 0.60, 'fold': 0.30, 'raise': 0.10},
    'paired_high':    {'call': 0.55, 'fold': 0.40, 'raise': 0.05},
    'paired_low':     {'call': 0.65, 'fold': 0.30, 'raise': 0.05},
    'broadway_heavy': {'call': 0.50, 'fold': 0.45, 'raise': 0.05},
    'middle_mixed':   {'call': 0.60, 'fold': 0.30, 'raise': 0.10},
}

# Coaching notes per texture (one liner)
COACHING = {
    'dry_high':       "The preflop raiser's range hits top pair more often. C-bet small and often.",
    'dry_low':        "Caller's range catches up here. Mix in checks — not a pure range bet board.",
    'wet_connected':  "Both ranges have many made hands and draws. Bet smaller, check more — range advantage is thinner.",
    'monotone':       "Flushes already exist; bare overpairs lose value. Check more.",
    'two_tone':       "Strong c-bet board — preflop raiser benefits from charging draws.",
    'paired_high':    "Most ranges miss; check more often. When betting, size small for thin value.",
    'paired_low':     "Range advantage flop. Pairs and overcards dominate. Bet small for cheap protection.",
    'broadway_heavy': "Hits the preflop raiser's range hard. C-bet aggressively.",
    'middle_mixed':   "Most-balanced texture — mix bet/check evenly.",
}


def expand_history(scenario_history, depth, texture, decision='cbet'):
    base = [f"Effective stack: {depth} BB", scenario_history]
    board = EXAMPLE_BOARDS[texture]
    base.append(f"Flop: {format_board(board)}")
    if decision == 'cbet':
        base.append("Action on the preflop raiser.")
    elif decision == 'vs_cbet':
        base.append("Preflop raiser bets 1/3 pot. Action on you.")
    return base


def format_board(notation):
    """'Ks7d2c' → 'K♠ 7♦ 2♣'."""
    suits = {'c':'♣','d':'♦','h':'♥','s':'♠'}
    parts = []
    for i in range(0, len(notation), 2):
        r, s = notation[i], notation[i+1]
        parts.append(r + suits[s])
    return ' '.join(parts)


def make_spot(scenario_key, scenario_name, scenario_history, depth, texture, decision):
    spot_id = f"flop_{scenario_key}_{depth}bb_{texture}_{decision}"
    if decision == 'cbet':
        solution = CBET_BY_SCENARIO[scenario_key][texture]
        available = ['bet33', 'bet66', 'check']
    else:
        solution = DEFEND_VS_CBET[texture]
        available = ['call', 'fold', 'raise']
    return {
        "id": spot_id,
        "scenario": scenario_key,
        "stackDepthBB": depth,
        "textureClass": texture,
        "sampleBoard": EXAMPLE_BOARDS[texture],
        "history": expand_history(scenario_history, depth, texture, decision),
        "availableActions": available,
        "solution": solution,
        "coachingNote": COACHING[texture]
    }


def main():
    repo_root = Path(__file__).resolve().parent.parent
    out_dir = repo_root / "MTTPokerTrainer" / "Resources" / "Postflop"
    out_dir.mkdir(parents=True, exist_ok=True)

    spots = []
    for scenario_key, scenario_name, history in SCENARIOS:
        for depth in DEPTHS:
            for texture in TEXTURES:
                spots.append(make_spot(scenario_key, scenario_name, history, depth, texture, 'cbet'))
                spots.append(make_spot(scenario_key, scenario_name, history, depth, texture, 'vs_cbet'))

    pack = {
        "format": "NLHE_MTT_FLOP_PACK",
        "version": "1.0",
        "generatedAt": "2026-05",
        "source": {
            "type": "solverDump",
            "solverName": "Hand-authored flop consensus table",
            "assumptions": "9-max MTT, BB ante, ~2.2bb opens, 3x 3-bets IP / 4x OOP. Single-bet, single-raiser scenarios. Frequencies approximate modern GTO consensus per texture.",
            "description": "Compact flop training library covering 4 preflop scenarios × 3 depths × 9 board textures × 2 decision points."
        },
        "spots": spots
    }

    out = out_dir / "flop_library.json"
    with open(out, "w") as f:
        json.dump(pack, f, indent=2)
        f.write("\n")
    print(f"wrote {len(spots)} spots to {out}")


if __name__ == "__main__":
    main()
