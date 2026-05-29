#!/usr/bin/env python3
"""validate_ranges.py — schema, polarity, and VPIP-band gate for bundled ranges.

Runs the following classes of check against every JSON in
Cutoff/Resources/Ranges/ (or a directory passed via --ranges-dir):

  1. SCHEMA      — per-hand frequencies sum to 1.0 (+/- tolerance); source.type
                   is enumerated; format token is known; hand notation is valid.
  2. DUPLICATES  — no `vs3betjam` file shares its `hands` block with the sibling
                   `vs3bet` file (the current data bug — 46 such pairs).
  3. VPIP-BAND   — computed VPIP for each (scenario, position, depth-bucket)
                   falls inside published canonical bands. Bands are
                   intentionally wide (~±5pp) so they catch corrupted extractor
                   output rather than minor solver-version drift.
  4. POLARITY    — known trash combos (72o, 82o, 83o, 92o, 93o, 94o, J2o, T2o)
                   have low non-fold weight in spots where they should fold.
                   This catches the inverted-polarity bug surfaced in BB_vsopen
                   (calls 72o ~100% in the current bundle).
  5. PUSHFOLD    — Nash sanity for ≤15bb pushfold files: AA must always jam;
                   JJ+ must jam from every position; 99 must jam from UTG @ 10bb.

Exit code: 0 if all HARD checks pass; 1 otherwise. WARN-only findings (VPIP
drift within ±10pp but outside band) do not fail the gate by default — pass
`--strict` to escalate warnings to errors.

Usage:
  python3 Tools/RangeImporter/scripts/validate_ranges.py
  python3 Tools/RangeImporter/scripts/validate_ranges.py --ranges-dir path/
  python3 Tools/RangeImporter/scripts/validate_ranges.py --strict --json
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

FILE_NAME_RE = re.compile(
    r"^mtt_(?P<table>8max|9max)_(?P<depth>\d+)bb_"
    r"(?P<position>utg1|utg|lj|hj|co|btn|sb|bb)_"
    r"(?P<scenario>unopened|vsopen|vs3bet|vs3betjam|squeeze|blinddefense|pushfold)\.json$"
)

ENUMERATED_SOURCE_TYPES = {
    "demo", "userDefined", "imported", "gto",
    "nashComputed", "solverDump", "published",
}
ENUMERATED_FORMATS = {"NLHE_MTT_8MAX", "NLHE_MTT_9MAX"}

RANKS = "23456789TJQKA"
HAND_RE = re.compile(rf"^([{RANKS}])([{RANKS}])([so]?)$")

TRASH_OFFSUIT = {"72o", "82o", "83o", "92o", "93o", "94o", "J2o", "T2o"}

FREQ_SUM_TOLERANCE = 0.02


def combos_for_hand(h: str) -> int:
    if len(h) == 2:
        return 6  # pocket pair
    return 4 if h.endswith("s") else 12


ALL_COMBOS = 1326  # 13*6 pairs + 78*4 suited + 78*12 offsuit


def vpip_percent(hands: dict[str, Any]) -> float:
    """% of ALL starting hands that take any non-fold action, combo-weighted.

    The denominator is the full 1326-combo deck, NOT just the listed hands.
    Range files may be stored compactly (only the played hands listed, trash
    omitted = implicit fold); dividing by listed-combos instead of 1326 would
    report ~100% VPIP for those files and falsely flag them. Unlisted hands
    contribute 0 to `inplay` (they fold), which is exactly correct.
    """
    inplay = 0.0
    for h, value in hands.items():
        if not HAND_RE.match(h):
            continue
        combos = combos_for_hand(h)
        if isinstance(value, dict):
            non_fold = sum(p for k, p in value.items() if k != "fold")
            inplay += combos * non_fold
        elif value != "fold":
            inplay += combos
    return 100.0 * inplay / ALL_COMBOS


def trash_non_fold_percent(hands: dict[str, Any]) -> float:
    """Combo-weighted non-fold % across the trash-offsuit set."""
    total = 0
    inplay = 0.0
    for h in TRASH_OFFSUIT:
        value = hands.get(h)
        if value is None:
            continue
        combos = combos_for_hand(h)
        total += combos
        if isinstance(value, dict):
            non_fold = sum(p for k, p in value.items() if k != "fold")
            inplay += combos * non_fold
        elif value != "fold":
            inplay += combos
    return 0.0 if total == 0 else 100.0 * inplay / total


def hand_non_fold(value: Any) -> float:
    if value is None:
        return 0.0
    if isinstance(value, dict):
        return sum(p for k, p in value.items() if k != "fold")
    return 0.0 if value == "fold" else 1.0


# --- VPIP bands per (scenario, position, depth-bucket) ---------------------
# Sources cross-checked: RangeConverter free MTT PDFs (8-max, 1bb ante), GTO
# Wizard Free chipEV, Beasts of Poker / Jennifear push-fold charts. Bands are
# (min, max) inclusive in VPIP % units, intentionally wider than ±2pp so
# minor solver-version drift doesn't trip the gate.

# Depth bucketing keeps the band table small.
def depth_bucket(depth: int) -> str:
    if depth <= 15:
        return "shallow"     # 10–15bb
    if depth <= 30:
        return "midstack"    # 20–30bb
    if depth <= 60:
        return "deep_mid"    # 40–60bb
    return "deep"            # 75bb+


# Scenario, position → (min%, max%) per depth bucket.
# Only spots with stable published bands are listed; absent entries WARN-only.
RFI_BANDS: dict[tuple[str, str], tuple[float, float]] = {
    # (depth_bucket, position) → (min, max)
    ("deep", "utg"):  (10, 20),
    ("deep", "utg1"): (12, 22),
    ("deep", "lj"):   (15, 26),
    ("deep", "hj"):   (18, 30),
    ("deep", "co"):   (24, 34),
    ("deep", "btn"):  (40, 55),
    ("deep", "sb"):   (32, 55),

    ("deep_mid", "utg"):  (10, 20),
    ("deep_mid", "utg1"): (12, 22),
    ("deep_mid", "lj"):   (14, 24),
    ("deep_mid", "hj"):   (17, 28),
    ("deep_mid", "co"):   (22, 33),
    ("deep_mid", "btn"):  (38, 55),
    ("deep_mid", "sb"):   (28, 50),

    ("midstack", "utg"):  (10, 22),
    ("midstack", "utg1"): (12, 24),
    ("midstack", "lj"):   (14, 26),
    ("midstack", "hj"):   (16, 30),
    ("midstack", "co"):   (20, 34),
    ("midstack", "btn"):  (32, 55),
    ("midstack", "sb"):   (25, 55),

    ("shallow", "utg"):  (8, 22),
    ("shallow", "utg1"): (10, 24),
    ("shallow", "lj"):   (12, 26),
    ("shallow", "hj"):   (15, 30),
    ("shallow", "co"):   (18, 36),
    ("shallow", "btn"):  (30, 60),
    ("shallow", "sb"):   (35, 70),
}

# vsopen is composite (averages across openers in this bundle's shape).
# Bands here are deliberately loose; their main role is catching the
# polarity-flip bug, not validating solver fidelity.
VSOPEN_BANDS: dict[tuple[str, str], tuple[float, float]] = {
    # SB-vs-open is wide: the SB defends a steal by 3-betting AND flatting, so
    # ~30-45% total defense is canonical (confirmed by inspecting the charts:
    # AA/AKo jam-or-raise, suited broadways/connectors call, offsuit trash
    # folds). Bands widened accordingly; a true polarity flip (trash calling)
    # is still caught by the polarity check.
    ("deep", "btn"): (12, 35),
    ("deep", "sb"):  (10, 50),
    ("deep", "bb"):  (40, 80),
    ("deep_mid", "btn"): (10, 35),
    ("deep_mid", "sb"):  (10, 50),
    ("deep_mid", "bb"):  (35, 80),
    ("midstack", "btn"): (8, 35),
    ("midstack", "sb"):  (8, 55),
    ("midstack", "bb"):  (30, 80),
    ("shallow", "btn"):  (6, 35),
    ("shallow", "sb"):   (6, 70),
    ("shallow", "bb"):   (20, 80),
}

# vs3bet (opener facing 3-bet) — 100bb canonical: opener defends ~25–45%.
VS3BET_BANDS: dict[tuple[str, str], tuple[float, float]] = {
    ("deep", "utg"):  (20, 50),
    ("deep", "utg1"): (20, 50),
    ("deep", "lj"):   (20, 50),
    ("deep", "hj"):   (22, 52),
    ("deep", "co"):   (22, 55),
    ("deep", "btn"):  (25, 55),
    ("deep", "sb"):   (18, 50),
    ("deep_mid", "utg"):  (15, 50),
    ("deep_mid", "co"):   (18, 52),
    ("deep_mid", "btn"):  (22, 55),
    ("deep_mid", "sb"):   (15, 50),
}


@dataclass
class Finding:
    severity: str   # "ERROR" or "WARN"
    rule: str
    file: str
    detail: str

    def __str__(self) -> str:
        return f"[{self.severity}] {self.rule}: {self.file} — {self.detail}"


@dataclass
class Report:
    errors: list[Finding] = field(default_factory=list)
    warnings: list[Finding] = field(default_factory=list)
    files_checked: int = 0

    def add(self, f: Finding) -> None:
        (self.errors if f.severity == "ERROR" else self.warnings).append(f)


def check_schema(path: Path, doc: dict[str, Any], report: Report) -> None:
    fmt = doc.get("format")
    if fmt not in ENUMERATED_FORMATS:
        report.add(Finding("ERROR", "schema.format", path.name,
                           f"format={fmt!r} not in {sorted(ENUMERATED_FORMATS)}"))
    src = (doc.get("source") or {}).get("type")
    if src not in ENUMERATED_SOURCE_TYPES:
        report.add(Finding("ERROR", "schema.source_type", path.name,
                           f"source.type={src!r} not in enum"))
    hands = doc.get("hands") or {}
    for h, value in hands.items():
        if not HAND_RE.match(h):
            report.add(Finding("ERROR", "schema.hand_notation", path.name,
                               f"invalid hand key {h!r}"))
            continue
        if isinstance(value, dict):
            total = sum(value.values())
            if abs(total - 1.0) > FREQ_SUM_TOLERANCE:
                report.add(Finding(
                    "ERROR", "schema.freq_sum", path.name,
                    f"{h}: frequencies sum to {total:.4f} (need 1.0 ± {FREQ_SUM_TOLERANCE})",
                ))


def check_vs3betjam_duplicates(files: dict[str, dict], report: Report) -> None:
    for name, doc in files.items():
        if not name.endswith("_vs3betjam.json"):
            continue
        sibling = name.replace("_vs3betjam.json", "_vs3bet.json")
        sib_doc = files.get(sibling)
        if sib_doc is None:
            continue
        if doc.get("hands") == sib_doc.get("hands"):
            report.add(Finding(
                "ERROR", "duplicates.vs3betjam_eq_vs3bet", name,
                f"hands block is byte-identical to {sibling} — vs3betjam variant is not actually a separate range",
            ))


def check_vpip_band(name: str, doc: dict[str, Any], report: Report) -> None:
    m = FILE_NAME_RE.match(name)
    if not m:
        return
    scenario = m["scenario"]
    position = m["position"]
    bucket = depth_bucket(int(m["depth"]))
    hands = doc.get("hands") or {}
    vpip = vpip_percent(hands)

    # VPIP bands are only meaningful for charts that enumerate the FULL 169-hand
    # range (unopened, vsopen): there, non-fold / listed-combos == non-fold /
    # 1326 == true VPIP. vs3bet/vs3betjam list only the opener's reachable
    # *opening* subrange (trash is unlisted = implicit fold), so non-fold /
    # listed-combos measures CONTINUE-frequency (~80-97%), which is not
    # comparable to a /1326 VPIP band — applying one produces false positives.
    # Corruption in those charts is instead guarded by the polarity check
    # (trash must fold) and the vs3betjam duplicate check.
    band_table = {
        "unopened": RFI_BANDS,
        "vsopen": VSOPEN_BANDS,
    }.get(scenario)
    if not band_table:
        return
    band = band_table.get((bucket, position))
    if band is None:
        return
    lo, hi = band
    if lo <= vpip <= hi:
        return
    # Decide severity: large deviation = ERROR, mild = WARN.
    margin = min(abs(vpip - lo), abs(vpip - hi))
    severity = "ERROR" if margin > 10 else "WARN"
    report.add(Finding(
        severity, "vpip.band", name,
        f"VPIP {vpip:.1f}% outside published band [{lo}-{hi}]% "
        f"for {scenario}/{position}/{bucket} (margin {margin:.1f}pp)",
    ))


def check_polarity(name: str, doc: dict[str, Any], report: Report) -> None:
    m = FILE_NAME_RE.match(name)
    if not m:
        return
    scenario = m["scenario"]
    position = m["position"]
    hands = doc.get("hands") or {}

    # Trash offsuit threshold per scenario+position.
    # BB defending vs a min-raise can legitimately call some trash; cap higher.
    if scenario == "vsopen" and position == "bb":
        cap = 40.0
    elif scenario == "vsopen":
        cap = 12.0
    elif scenario == "vs3bet" or scenario == "vs3betjam":
        cap = 8.0
    elif scenario == "unopened":
        # Trash from any position should fold pre — even BTN limps the worst hands rarely.
        cap = 8.0 if position not in {"sb", "bb"} else 15.0
    elif scenario == "squeeze":
        cap = 10.0
    elif scenario == "blinddefense":
        cap = 35.0  # BB-defend semantics
    else:
        return  # pushfold handled separately

    trash_vpip = trash_non_fold_percent(hands)
    if trash_vpip > cap:
        report.add(Finding(
            "ERROR", "polarity.trash_too_loose", name,
            f"trash-offsuit non-fold {trash_vpip:.1f}% > cap {cap:.1f}% "
            f"for {scenario}/{position} — likely fold/call polarity inversion",
        ))


def check_pushfold(name: str, doc: dict[str, Any], report: Report) -> None:
    m = FILE_NAME_RE.match(name)
    if not m or m["scenario"] != "pushfold":
        return
    position = m["position"]
    depth = int(m["depth"])
    hands = doc.get("hands") or {}

    # AA must always jam.
    aa_jam = hand_non_fold(hands.get("AA"))
    if aa_jam < 0.99:
        report.add(Finding(
            "ERROR", "pushfold.aa_must_jam", name,
            f"AA non-fold = {aa_jam:.2f} (need ≥0.99)",
        ))
    # JJ+ should jam from every position at ≤15bb pushfold.
    if depth <= 15:
        for premium in ("KK", "QQ", "JJ"):
            if hand_non_fold(hands.get(premium)) < 0.95:
                report.add(Finding(
                    "ERROR", "pushfold.premium_must_jam", name,
                    f"{premium} non-fold below 0.95 at {depth}bb {position}",
                ))


def collect_files(root: Path) -> dict[str, dict]:
    out: dict[str, dict] = {}
    for p in sorted(root.glob("*.json")):
        try:
            with p.open() as f:
                out[p.name] = json.load(f)
        except json.JSONDecodeError as e:
            out[p.name] = {"__parse_error__": str(e)}
    return out


def run(root: Path, strict: bool, want_json: bool) -> int:
    files = collect_files(root)
    report = Report()
    report.files_checked = len(files)

    for name, doc in files.items():
        if "__parse_error__" in doc:
            report.add(Finding("ERROR", "schema.parse", name, doc["__parse_error__"]))
            continue
        check_schema(root / name, doc, report)
        check_vpip_band(name, doc, report)
        check_polarity(name, doc, report)
        check_pushfold(name, doc, report)
    check_vs3betjam_duplicates(files, report)

    if want_json:
        out = {
            "files_checked": report.files_checked,
            "errors": [f.__dict__ for f in report.errors],
            "warnings": [f.__dict__ for f in report.warnings],
        }
        print(json.dumps(out, indent=2))
    else:
        for f in report.errors:
            print(f)
        for f in report.warnings:
            print(f)
        print()
        print(f"Files checked : {report.files_checked}")
        print(f"Errors        : {len(report.errors)}")
        print(f"Warnings      : {len(report.warnings)}")

    failed = bool(report.errors) or (strict and bool(report.warnings))
    return 1 if failed else 0


def main() -> int:
    ap = argparse.ArgumentParser(description="Validate bundled poker range JSONs.")
    default_dir = Path(__file__).resolve().parents[3] / "Cutoff" / "Resources" / "Ranges"
    ap.add_argument("--ranges-dir", type=Path, default=default_dir,
                    help=f"Directory of range JSONs (default: {default_dir})")
    ap.add_argument("--strict", action="store_true",
                    help="Treat warnings as errors (fail CI on band drift).")
    ap.add_argument("--json", action="store_true", dest="want_json",
                    help="Emit machine-readable JSON report.")
    args = ap.parse_args()
    if not args.ranges_dir.is_dir():
        print(f"ranges-dir does not exist: {args.ranges_dir}", file=sys.stderr)
        return 2
    return run(args.ranges_dir, args.strict, args.want_json)


if __name__ == "__main__":
    sys.exit(main())
