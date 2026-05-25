#!/usr/bin/env python3
"""hrc_import.py — convert a HoldemResources Calculator (HRC) export
into the long-form crib CSV format consumed by `swift run RangeImporter
import`.

HRC v3 export layout (zip OR extracted dir):

    settings.json           # tree config — stacks, blinds, ante, ChipEV/ICM
    nodes/0.json            # root decision
    nodes/<id>.json         # one file per decision node in the tree

Each node:
    { "player": <seat>,
      "street": 0,                       # 0 = preflop
      "sequence": [...],                 # actions taken to reach this node
      "actions":  [{"type":"F"|"C"|"R",
                    "amount": <chips>,
                    "node":   <child id>}, ...],
      "hands":    { "AKs": { "weight": 1.0,
                             "played": [freq_a0, freq_a1, ...],
                             "evs":    [ev_a0, ev_a1, ...] }, ... } }

This script walks the tree starting at node 0, finds every preflop
decision node, and emits one crib CSV per node:

    hrc_<n>max_<bb>bb_seat<p>_<seqcode>.csv

with rows  `notation,action,freq`  matching the existing crib schema.

ACTION NAMING
-------------
HRC types map to the crib-CSV vocabulary as follows:

    F                       -> fold
    C                       -> call
    R (amount == stack)     -> jam
    R (otherwise)           -> raise   (or `raise_<sizing>` if multiple
                                        non-allin raises exist at one node)

If a node has more than one non-allin raise size the labels become
`raise_2.3x`, `raise_3x`, ...  Single-raise nodes just say `raise`.

USAGE
-----
    python3 hrc_import.py --input /path/to/HandExport.zip \\
                          --output crib_hrc/ \\
                          [--max-nodes 200] [--root-only]

Add `--print-summary` to see VPIP-style per-node hand counts for sanity
checking against HRC's own range viewer.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import tempfile
import zipfile
from collections import OrderedDict
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple

# Canonical 169-hand ordering (matches the existing crib CSVs).
RANKS = "AKQJT98765432"

def all_hand_codes() -> List[str]:
    out: List[str] = []
    for i, r1 in enumerate(RANKS):
        for j, r2 in enumerate(RANKS):
            if i == j:
                out.append(r1 + r2)              # pair, e.g. "AA"
            elif i < j:
                out.append(r1 + r2 + "s")        # suited, e.g. "AKs"
            else:
                out.append(r2 + r1 + "o")        # offsuit, e.g. "AKo"
    return out

HAND_ORDER = all_hand_codes()
HAND_SET = set(HAND_ORDER)


def load_export(path: Path) -> Tuple[dict, Dict[int, dict]]:
    """Return (settings, nodes_by_id). Accepts a .zip or a directory."""
    if path.is_file() and path.suffix.lower() == ".zip":
        tmp = Path(tempfile.mkdtemp(prefix="hrc_"))
        with zipfile.ZipFile(path) as zf:
            zf.extractall(tmp)
        root = tmp
    elif path.is_dir():
        root = path
    else:
        raise SystemExit(f"input must be a .zip file or directory: {path}")

    settings_path = root / "settings.json"
    if not settings_path.exists():
        raise SystemExit(f"missing settings.json under {root}")
    with settings_path.open() as f:
        settings = json.load(f)

    nodes_dir = root / "nodes"
    if not nodes_dir.is_dir():
        raise SystemExit(f"missing nodes/ directory under {root}")

    nodes: Dict[int, dict] = {}
    for p in nodes_dir.glob("*.json"):
        try:
            nid = int(p.stem)
        except ValueError:
            continue
        with p.open() as f:
            nodes[nid] = json.load(f)
    return settings, nodes


# --------------------------------------------------------------------------- #
# Settings interpretation
# --------------------------------------------------------------------------- #

def describe_settings(s: dict) -> dict:
    """Pull the few fields we care about for filenames + provenance."""
    hd = s.get("handdata", {})
    stacks = hd.get("stacks", [])
    blinds = hd.get("blinds", [0, 0, 0])
    # HRC blind layout (observed): [BB, SB, ante]. BB is element 0.
    bb_chips = blinds[0] if len(blinds) > 0 and blinds[0] > 0 else 1
    n_seats = len(stacks)
    eff_chips = min(stacks) if stacks else 0
    eff_bb = round(eff_chips / bb_chips, 1) if bb_chips else 0
    eqmodel = s.get("eqmodel", {}).get("id", "unknown")
    tree = s.get("treeconfig", {}).get("preflop", {}).get("settings", {})
    # Simple preset emits PREFLOP_SIZES; Advanced preset emits per-position
    # SIZES_OPEN_*, SIZES_3BET_*, etc. Surface either schema for provenance.
    sizes = tree.get("PREFLOP_SIZES")
    if sizes is None:
        advanced_keys = [
            "SIZES_OPEN_OTHERS", "SIZES_OPEN_BU", "SIZES_OPEN_SB",
            "SIZES_OPEN_BB", "SIZES_OPEN_BB_VS_SB",
            "SIZES_3BET_IP", "SIZES_3BET_BB_VS_OTHER", "SIZES_3BET_BB_VS_SB",
            "SIZES_3BET_SB_VS_BB", "SIZES_3BET_SB_VS_OTHER",
            "SIZES_4BET_IP", "SIZES_4BET_OOP",
            "SIZES_5BET_IP", "SIZES_5BET_OOP",
        ]
        sizes = {k: tree[k] for k in advanced_keys if k in tree}
    return {
        "n_seats": n_seats,
        "bb_chips": bb_chips,
        "eff_chips": eff_chips,
        "eff_bb": eff_bb,
        "eqmodel": eqmodel,
        "preflop_sizes": sizes,
        "ante_type": hd.get("anteType", ""),
    }


# --------------------------------------------------------------------------- #
# Action labelling
# --------------------------------------------------------------------------- #

def action_labels(actions: List[dict], stack_chips: int) -> List[str]:
    """Map HRC action types to crib vocabulary, disambiguating multi-raise.

    A raise is treated as "jam" if its amount is at least JAM_THRESHOLD of
    the (full) stack chips. We use 90% rather than exact equality because:
      - SB/BB players have already posted, so a true all-in puts in
        (stack - posted), which is e.g. 99% of stack for the BB.
      - HRC sometimes records the all-in raise size as the player's
        remaining chips (not their starting stack).
    """
    JAM_THRESHOLD = 0.9
    jam_cutoff = stack_chips * JAM_THRESHOLD

    labels: List[str] = []
    nonjam_raise_amounts = sorted(
        {a["amount"] for a in actions
         if a["type"] == "R" and a["amount"] < jam_cutoff}
    )
    for a in actions:
        t = a["type"]
        amt = a.get("amount", 0)
        if t == "F":
            labels.append("fold")
        elif t == "C":
            labels.append("call")
        elif t == "R":
            if amt >= jam_cutoff:
                labels.append("jam")
            elif len(nonjam_raise_amounts) <= 1:
                labels.append("raise")
            else:
                labels.append(f"raise_{amt}")
        else:
            labels.append(f"act_{t}")
    return labels


def seq_code(sequence: List[dict]) -> str:
    """Short ASCII code for a sequence path, used in filenames.

    Example: [{"type":"F"}, {"type":"F"}, {"type":"R","amount":...}]
             -> "FFR"
    Empty sequence (root)  -> "root"
    """
    if not sequence:
        return "root"
    chars = []
    for act in sequence:
        t = act.get("type", "?")
        chars.append(t.upper())
    return "".join(chars)


# --------------------------------------------------------------------------- #
# Per-node export
# --------------------------------------------------------------------------- #

def node_to_rows(node: dict, stack_chips: int) -> Tuple[List[str], List[Tuple[str, str, float]], float]:
    """Convert one HRC node into (labels, csv_rows, vpip_estimate).

    vpip_estimate = weighted fraction of hands that take any action other
    than `fold`. Useful for cross-checking against HRC's range viewer.
    """
    actions = node["actions"]
    labels = action_labels(actions, stack_chips)
    fold_idx = next((i for i, l in enumerate(labels) if l == "fold"), None)

    rows: List[Tuple[str, str, float]] = []
    total_w = 0.0
    voluntary_w = 0.0

    # Iterate in canonical hand order for deterministic output.
    hands = node.get("hands", {})
    for code in HAND_ORDER:
        h = hands.get(code)
        if h is None:
            continue
        played = h.get("played", [])
        weight = float(h.get("weight", 1.0))
        if not played or weight <= 0:
            continue
        total_w += weight

        # Collapse same-labelled actions (rare, but safe).
        agg: "OrderedDict[str, float]" = OrderedDict()
        for label, freq in zip(labels, played):
            if freq <= 0:
                continue
            agg[label] = agg.get(label, 0.0) + float(freq)

        # Track VPIP.
        if fold_idx is not None and fold_idx < len(played):
            voluntary_w += weight * (1.0 - float(played[fold_idx]))
        else:
            voluntary_w += weight  # no fold option => always voluntary

        # Emit rows. Round to 4 dp to keep CSVs compact and stable.
        for label, freq in agg.items():
            rows.append((code, label, round(freq, 4)))

    vpip = (voluntary_w / total_w) if total_w > 0 else 0.0
    return labels, rows, vpip


def write_csv(path: Path, rows: Iterable[Tuple[str, str, float]],
              provenance: List[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w") as f:
        for line in provenance:
            f.write(f"# {line}\n")
        f.write("notation,action,freq\n")
        for code, action, freq in rows:
            # Skip near-zero frequencies (rounding artefacts).
            if freq < 1e-4:
                continue
            f.write(f"{code},{action},{freq}\n")


# --------------------------------------------------------------------------- #
# Canonical 8-max position mapping
# --------------------------------------------------------------------------- #

# HRC seat index → app position name. Action proceeds 0 → 7 preflop.
POSITION_BY_SEAT_8MAX = ["utg", "utg1", "lj", "hj", "co", "btn", "sb", "bb"]


def canonical_8max_specs() -> List[Tuple[str, str, int, List[str]]]:
    """Return (position, facing, seat, sequence_types) tuples for the
    14 charts the app expects per stack depth.

    sequence_types items:
      'F' = fold     'C' = call     'R' = first raise action at this node
    """
    specs: List[Tuple[str, str, int, List[str]]] = []
    # unopened (RFI): seat N reached after N folds. BB has no RFI.
    for seat in range(7):  # UTG..SB
        specs.append((POSITION_BY_SEAT_8MAX[seat], "unopened",
                      seat, ["F"] * seat))
    # vsopen vs UTG open (canonical defender response): UTG raises, then
    # everyone between UTG and the defender folds.
    for seat in range(1, 8):  # UTG1..BB
        specs.append((POSITION_BY_SEAT_8MAX[seat], "vsopen",
                      seat, ["R"] + ["F"] * (seat - 1)))
    return specs


def find_node_by_seq(nodes: Dict[int, dict],
                     seq_types: List[str]) -> Optional[int]:
    """Walk from node 0 following actions whose type matches each entry.
    For 'R', pick the FIRST raise action at each node (typically the
    smaller / non-allin size). Returns None if the path doesn't exist.
    """
    if 0 not in nodes:
        return None
    current = 0
    for t in seq_types:
        node = nodes.get(current)
        if node is None:
            return None
        match = next((a for a in node.get("actions", [])
                      if a.get("type") == t), None)
        if match is None:
            return None
        nxt = match.get("node")
        if not isinstance(nxt, int):
            return None
        current = nxt
    return current


# --------------------------------------------------------------------------- #
# Tree walking
# --------------------------------------------------------------------------- #

def walk_preflop_nodes(nodes: Dict[int, dict]) -> Iterable[int]:
    """Yield ids of preflop decision nodes (street == 0) with at least
    one F/C/R action and a non-empty hand range. Yielded in BFS order
    from node 0.
    """
    if 0 not in nodes:
        return
    seen = set()
    queue = [0]
    while queue:
        nid = queue.pop(0)
        if nid in seen:
            continue
        seen.add(nid)
        n = nodes.get(nid)
        if n is None:
            continue
        if n.get("street", 0) == 0 and n.get("hands") and n.get("actions"):
            yield nid
        for a in n.get("actions", []):
            child = a.get("node")
            if isinstance(child, int) and child not in seen:
                queue.append(child)


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--input", required=True, type=Path,
                    help="HRC export .zip or extracted directory")
    ap.add_argument("--output", required=True, type=Path,
                    help="Output directory for crib CSV files")
    ap.add_argument("--max-nodes", type=int, default=0,
                    help="Stop after N preflop nodes (0 = all)")
    ap.add_argument("--root-only", action="store_true",
                    help="Only export the root node (first decision)")
    ap.add_argument("--print-summary", action="store_true",
                    help="Print per-node VPIP and row counts to stdout")
    ap.add_argument("--prefix", default="hrc",
                    help="Filename prefix (default: hrc)")
    ap.add_argument("--canonical-8max", action="store_true",
                    help="Emit only the 14 canonical 8-max charts named "
                         "mtt_8max_<bb>_<pos>_<unopened|vsopen>.csv")
    args = ap.parse_args()

    settings, nodes = load_export(args.input)
    meta = describe_settings(settings)
    stack_chips = meta["eff_chips"]

    # ---------------- Canonical 8-max mode ---------------- #
    if args.canonical_8max:
        if meta["n_seats"] != 8:
            print(f"WARNING: --canonical-8max expects 8-max solve; got "
                  f"{meta['n_seats']}-handed. Output may be wrong.",
                  file=sys.stderr)

        depth_bb = int(round(meta["eff_bb"]))
        prov_base = [
            f"Generated by hrc_import.py --canonical-8max from {args.input.name}",
            f"HRC tree: {meta['n_seats']}-handed, "
            f"effective {meta['eff_bb']}bb ({stack_chips} chips at {meta['bb_chips']}/bb)",
            f"Equity model: {meta['eqmodel']}, ante: {meta['ante_type']}",
            f"Preflop sizes: {meta['preflop_sizes']}",
        ]

        written = 0
        for pos, facing, seat, seq in canonical_8max_specs():
            nid = find_node_by_seq(nodes, seq)
            if nid is None:
                print(f"  SKIP {pos:<5} {facing:<10} — no node at "
                      f"sequence {seq}", file=sys.stderr)
                continue
            node = nodes[nid]
            # Sanity check: the node's player must equal the seat we expect.
            if node.get("player") != seat:
                print(f"  WARN {pos:<5} {facing:<10} — node {nid} player "
                      f"is {node.get('player')}, expected {seat}",
                      file=sys.stderr)
            labels, rows, vpip = node_to_rows(node, stack_chips)
            if not rows:
                continue
            fname = f"mtt_8max_{depth_bb}bb_{pos}_{facing}.csv"
            out_path = args.output / fname
            prov = prov_base + [
                f"App slot: {pos} {facing} @ {depth_bb}bb",
                f"HRC node: id={nid}, seat={seat}, sequence={seq_code(node.get('sequence', []))}",
                f"Actions at node: {labels}",
                f"VPIP estimate: {vpip*100:.2f}%",
            ]
            write_csv(out_path, rows, prov)
            written += 1
            if args.print_summary:
                print(f"  {fname:<40} VPIP {vpip*100:5.2f}%  rows {len(rows):3d}")
        print(f"Wrote {written} canonical CSVs to {args.output}")
        return 0
    # ------------- End canonical 8-max mode --------------- #

    prov_base = [
        f"Generated by hrc_import.py from {args.input.name}",
        f"HRC tree: {meta['n_seats']}-handed, "
        f"effective {meta['eff_bb']}bb ({stack_chips} chips at {meta['bb_chips']}/bb)",
        f"Equity model: {meta['eqmodel']}, ante: {meta['ante_type']}",
        f"Preflop sizes: {meta['preflop_sizes']}",
    ]

    written = 0
    for nid in walk_preflop_nodes(nodes):
        node = nodes[nid]
        labels, rows, vpip = node_to_rows(node, stack_chips)
        if not rows:
            continue

        sequence = node.get("sequence", [])
        seat = node.get("player", -1)
        code = seq_code(sequence)
        bb_label = f"{int(meta['eff_bb'])}bb" if meta['eff_bb'] == int(meta['eff_bb']) \
                                              else f"{meta['eff_bb']}bb"
        fname = (f"{args.prefix}_{meta['n_seats']}max_{bb_label}"
                 f"_seat{seat}_{code}.csv")
        out_path = args.output / fname

        prov = prov_base + [
            f"Node id: {nid}, seat: {seat}, sequence: {code}",
            f"Actions at node: {labels}",
            f"VPIP estimate: {vpip*100:.2f}%",
        ]
        write_csv(out_path, rows, prov)
        written += 1

        if args.print_summary:
            print(f"  node {nid:>5} seat {seat} seq {code:<10} "
                  f"VPIP {vpip*100:5.1f}%  rows {len(rows):3d}  -> {fname}")

        if args.root_only:
            break
        if args.max_nodes and written >= args.max_nodes:
            break

    print(f"Wrote {written} CSVs to {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
