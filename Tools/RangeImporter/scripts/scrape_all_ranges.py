#!/usr/bin/env python3
"""
scrape_all_ranges.py — unattended poker.academy → Cutoff range scraper (v3).

Drives the active Google Chrome tab (which must be on a poker.academy
tournament chart page) entirely through AppleScript JavaScript injection. No
clicking pixels, no fixed sleeps: every wait POLLS the live DOM until the grid
is loaded and stable, so it is both fast and robust to network jitter.

DOM model (reverse-engineered 2026-06, CE-Symmetric pack — see
poker_academy_extract.js for the gory details):
  * Each hand tile's strategy is encoded as 4 width-proportional colour
    segments. Colours map to actions: red=All-in, orange=Raise, teal=Limp/Call,
    grey=Fold. Extraction lives in poker_academy_extract.js.
  * vsOpen / vs3Bet grids are EMPTY until an opponent position is selected, so
    we click the opponent (anchored on the "Opponent's position" text label)
    and poll until the grid populates.

App schema reality: Cutoff keys every range by (position, depth, facing) ONLY —
there is no opener dimension (see Cutoff/Logic/ChartCatalog.swift). So each
(depth, hero, facing) maps to ONE canonical opponent. Convention here:
"closest raiser" — vsOpen hero faces the opponent one seat ahead; vs3Bet opener
faces the 3-bettor one seat behind. Change CANONICAL_* below to re-pick; the
full per-opponent archive is kept in crib_multi_opener/ so re-deriving the
canonical set never needs a re-scrape.

Outputs:
  crib/<5-part-slug>.csv          canonical files the Swift importer compiles
  crib_multi_opener/<slug>.csv    every opponent matchup (archive)

Run:
  python3 Tools/RangeImporter/scripts/scrape_all_ranges.py            # scrape + compile + validate
  python3 Tools/RangeImporter/scripts/scrape_all_ranges.py --canonical-only
  python3 Tools/RangeImporter/scripts/scrape_all_ranges.py --no-compile
Prerequisite: Chrome → View ▸ Developer ▸ "Allow JavaScript from Apple Events".
"""

import argparse
import json
import os
import subprocess
import sys
import time
import datetime
import hashlib
from pathlib import Path

# ---------------------------------------------------------------------------
# Paths & logging
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).parent.resolve()
IMPORTER_DIR = SCRIPT_DIR.parent.resolve()
RANGES_DIR = (IMPORTER_DIR.parent.parent / "Cutoff" / "Resources" / "Ranges").resolve()
CRIB_DIR = IMPORTER_DIR / "crib"
ARCHIVE_DIR = IMPORTER_DIR / "crib_multi_opener"
MANIFEST = SCRIPT_DIR / "scrape_manifest.json"
EXTRACT_JS = (SCRIPT_DIR / "poker_academy_extract.js").read_text(encoding="utf-8")
LOG_FILE = IMPORTER_DIR / "scrape_log.txt"

G, Y, R, B, C, X = "\033[92m", "\033[93m", "\033[91m", "\033[94m", "\033[96m", "\033[0m"


def log(msg=""):
    print(msg, flush=True)
    try:
        clean = msg
        for code in (G, Y, R, B, C, X):
            clean = clean.replace(code, "")
        with open(LOG_FILE, "a", encoding="utf-8") as fh:
            fh.write(f"[{datetime.datetime.now():%Y-%m-%d %H:%M:%S}] {clean}\n")
    except Exception:
        pass


# ---------------------------------------------------------------------------
# Chrome / AppleScript bridge
# ---------------------------------------------------------------------------
_AS_FILE = SCRIPT_DIR / ".chrome_eval.applescript"


def chrome_eval(js, timeout=30):
    """Execute JS in the active Chrome tab; return (ok, stdout, stderr)."""
    esc = (js.replace("\\", "\\\\").replace('"', '\\"')
             .replace("\n", "\\n").replace("\r", "\\r"))
    _AS_FILE.write_text(
        f'tell application "Google Chrome" to execute active tab '
        f'of front window javascript "{esc}"', encoding="utf-8")
    try:
        res = subprocess.run(["osascript", str(_AS_FILE)],
                             capture_output=True, text=True, timeout=timeout)
        return res.returncode == 0, res.stdout.strip(), res.stderr.strip()
    except subprocess.TimeoutExpired:
        return False, "", "osascript timed out"
    finally:
        try:
            _AS_FILE.unlink()
        except OSError:
            pass


def chrome_get_url():
    ok, out, _ = chrome_eval("window.location.href")
    return out if ok else ""


def chrome_navigate(url):
    safe = url.replace("'", "")
    subprocess.run(["osascript", "-e",
                    f'tell application "Google Chrome" to set URL of active tab '
                    f'of front window to "{safe}"'], capture_output=True)


def chrome_reload():
    subprocess.run(["osascript", "-e",
                    'tell application "Google Chrome" to reload active tab of front window'],
                   capture_output=True)


# ---------------------------------------------------------------------------
# Grid extraction & opponent selection
# ---------------------------------------------------------------------------
def extract_grids():
    """Return list of grids [{'n':int,'hands':{...}}, ...] or None on failure."""
    ok, out, err = chrome_eval(EXTRACT_JS)
    if not ok or not out:
        return None
    try:
        return json.loads(out).get("grids", [])
    except json.JSONDecodeError:
        return None


def choose_grid(grids, facing):
    """Pick the grid that holds HERO's strategy. poker.academy labels each grid
    (e.g. "40bb CO vs. 3bet from BTN Hero" vs "... Opponent"); the hero grid is
    tagged "Hero". RFI renders a single grid (no Hero/Opponent tag)."""
    if not grids:
        return None
    if len(grids) == 1:
        return grids[0]
    hero = [g for g in grids if "hero" in g.get("label", "").lower()]
    if hero:
        return hero[0]
    # Fallback if labels ever go missing: the hero grid says "vs." and the
    # opponent grids say "opponent".
    vs = [g for g in grids
          if "vs." in g.get("label", "").lower()
          and "opponent" not in g.get("label", "").lower()]
    if vs:
        return vs[0]
    return min(grids, key=lambda g: g["n"]) if facing == "vs3bet" else max(grids, key=lambda g: g["n"])


def _nonfold_count(hands):
    return sum(1 for v in hands.values()
               if any(a != "fold" and f > 0.001 for a, f in v.items()))


def _signature(hands):
    rounded = {h: {a: round(f, 2) for a, f in v.items()} for h, v in hands.items()}
    return hashlib.md5(json.dumps(rounded, sort_keys=True).encode()).hexdigest()


def poll_grid_loaded(facing, timeout=12.0, interval=0.35, post=0.3):
    """Poll until hero's grid is rendered, has ≥1 non-fold hand, and is stable
    across two reads. Returns the hands dict or None on timeout."""
    time.sleep(post)
    deadline = time.time() + timeout
    last_sig = None
    full = facing in ("unopened", "vsopen")
    while time.time() < deadline:
        grids = extract_grids()
        grid = choose_grid(grids, facing) if grids else None
        if grid:
            hands = grid["hands"]
            ok = (grid["n"] >= 160) if full else (grid["n"] >= 8)
            if ok and _nonfold_count(hands) >= 1:
                sig = _signature(hands)
                if sig == last_sig:
                    return hands
                last_sig = sig
        time.sleep(interval)
    return None


def wait_for_opponent_selector(timeout=12.0, interval=0.4):
    """After navigating to a vsOpen/vs3Bet page, poll until the opponent
    position buttons exist."""
    js = """
    (function(){
      var labels=Array.from(document.querySelectorAll('p,div,span,label'));
      for(var i=0;i<labels.length;i++){
        var own=Array.from(labels[i].childNodes).filter(function(n){return n.nodeType===3;})
                 .map(function(n){return n.textContent.trim();}).join(' ').toLowerCase();
        if(own.indexOf('opponent')>-1) return "yes";
      }
      return "no";
    })();
    """
    deadline = time.time() + timeout
    while time.time() < deadline:
        ok, out, _ = chrome_eval(js)
        if ok and out == "yes":
            return True
        time.sleep(interval)
    return False


def click_scenario(label):
    """Click a scenario tab (e.g. 'vs. 3bet') to drive the SPA's client-side
    router, which renders grids that a cold URL load leaves blank."""
    js = """
    (function(){
      var b=Array.from(document.querySelectorAll('div,span,button,li')).filter(function(e){
        return (e.textContent||'').trim()===%r && e.children.length<=1 && e.getBoundingClientRect().width>0;});
      if(!b.length) return "none";
      b.sort(function(x,y){return x.getBoundingClientRect().top-y.getBoundingClientRect().top;});
      b[0].click(); return "ok";
    })();
    """ % label
    ok, out, _ = chrome_eval(js)
    return ok and out == "ok"


def click_opponent(label):
    """Click the opponent-position button matching `label`. Returns (ok, info)."""
    js = """
    (function(){
      var target="%s";
      var labels=Array.from(document.querySelectorAll('p,div,span,label'));
      var hdr=null;
      for(var i=0;i<labels.length;i++){
        var own=Array.from(labels[i].childNodes).filter(function(n){return n.nodeType===3;})
                 .map(function(n){return n.textContent.trim();}).join(' ').toLowerCase();
        if(own.indexOf('opponent')>-1){hdr=labels[i];break;}
      }
      if(!hdr) return "ERR:no-opponent-header";
      var hTop=hdr.getBoundingClientRect().top;
      var POS=['EP','MP','LJ','HJ','CO','BTN','SB','BB'];
      var btns=Array.from(document.querySelectorAll('div')).filter(function(e){
        return POS.indexOf((e.textContent||'').trim())>-1
            && (e.className||'').toString().indexOf('sc-')>-1
            && e.getBoundingClientRect().top>hTop;
      });
      if(!btns.length) return "ERR:no-buttons";
      var minTop=Math.min.apply(null,btns.map(function(b){return b.getBoundingClientRect().top;}));
      btns=btns.filter(function(b){return b.getBoundingClientRect().top<=minTop+80;});
      var cand=btns.filter(function(b){return b.textContent.trim()===target;});
      if(!cand.length) return "ERR:no-target";
      cand[0].click();
      return "OK";
    })();
    """ % label
    ok, out, err = chrome_eval(js)
    return (ok and out == "OK"), (out or err)


# ---------------------------------------------------------------------------
# Poker model
# ---------------------------------------------------------------------------
POS_SITE = ["EP", "MP", "LJ", "HJ", "CO", "BTN", "SB", "BB"]
POS_APP = {"EP": "utg", "MP": "utg1", "LJ": "lj", "HJ": "hj",
           "CO": "co", "BTN": "btn", "SB": "sb", "BB": "bb"}
DEPTHS = [10, 15, 20, 25, 30, 35, 40, 50, 60, 70, 80, 100]

# Neutral colour tokens → CribAction vocabulary, per scenario.
REMAP = {
    "unopened": {"jam": "jam", "raise": "raise",   "call": "limp", "fold": "fold"},
    "vsopen":   {"jam": "jam", "raise": "threeBet", "call": "call", "fold": "fold"},
    "vs3bet":   {"jam": "jam", "raise": "threeBet", "call": "call", "fold": "fold"},
}
FACING_JSON = {"unopened": "RFI", "vsopen": "vs.%20RFI", "vs3bet": "vs.%203bet"}


def build_tasks(pack, speed, canonical_only):
    """Return ordered task list. Canonical matchups first (app-critical), then
    the full per-opponent archive. Each task is a dict."""
    canonical, archive = [], []

    def url(facing, depth, hero):
        return f"https://poker.academy/tournaments/s/{pack}/{depth}/{speed}/{FACING_JSON[facing]}/{hero}///"

    for depth in DEPTHS:
        # A. RFI / unopened — 7 positions (EP..SB), no opponent.
        for hero in POS_SITE[:7]:
            canonical.append({
                "facing": "unopened", "depth": depth, "hero": hero, "opp": None,
                "url": url("unopened", depth, hero),
                "slug": f"mtt_8max_{depth}bb_{POS_APP[hero]}_unopened",
                "canonical": True,
            })
        # B. vsOpen — hero (defender) faces an earlier opener.
        for h_idx in range(1, 8):
            hero = POS_SITE[h_idx]
            for o_idx in range(h_idx):
                opp = POS_SITE[o_idx]
                is_canon = (o_idx == h_idx - 1)  # closest raiser
                t = {
                    "facing": "vsopen", "depth": depth, "hero": hero, "opp": opp,
                    "url": url("vsopen", depth, hero),
                    "slug": f"mtt_8max_{depth}bb_{POS_APP[hero]}_vsopen" if is_canon else None,
                    "archive_slug": f"mtt_8max_{depth}bb_{POS_APP[hero]}_vsopen_vs_{POS_APP[opp]}",
                    "canonical": is_canon,
                }
                (canonical if is_canon else archive).append(t)
        # C. vs3Bet — hero (opener) faces a later 3-bettor.
        for h_idx in range(7):
            hero = POS_SITE[h_idx]
            for o_idx in range(h_idx + 1, 8):
                opp = POS_SITE[o_idx]
                is_canon = (o_idx == h_idx + 1)  # closest 3-bettor
                t = {
                    "facing": "vs3bet", "depth": depth, "hero": hero, "opp": opp,
                    "url": url("vs3bet", depth, hero),
                    "slug": f"mtt_8max_{depth}bb_{POS_APP[hero]}_vs3bet" if is_canon else None,
                    "archive_slug": f"mtt_8max_{depth}bb_{POS_APP[hero]}_vs3bet_vs_{POS_APP[opp]}",
                    "canonical": is_canon,
                }
                (canonical if is_canon else archive).append(t)

    if canonical_only:
        return canonical
    # Group archive by page so same-page opponents are scraped without re-nav.
    archive.sort(key=lambda t: (t["facing"], t["depth"], t["hero"], t["opp"]))
    return canonical + archive


# ---------------------------------------------------------------------------
# CSV emission (CribSheet-compatible: per-hand freqs sum to 1.0 ± 0.001)
# ---------------------------------------------------------------------------
def normalize(acc):
    """Round, drop sub-0.5% noise, renormalize to sum exactly 1.0."""
    items = {a: f for a, f in acc.items() if f >= 0.005}
    if not items:
        return {}
    s = sum(items.values())
    items = {a: round(f / s, 4) for a, f in items.items()}
    resid = round(1.0 - sum(items.values()), 4)
    if abs(resid) >= 0.0001:
        k = max(items, key=items.get)
        items[k] = round(items[k] + resid, 4)
    return items


def grid_to_csv(hands, facing, depth, hero, opp):
    remap = REMAP[facing]
    rows = []
    for hand, acc in hands.items():
        # collapse neutral tokens to crib actions, summing collisions
        crib = {}
        for tok, freq in acc.items():
            crib[remap[tok]] = crib.get(remap[tok], 0.0) + freq
        norm = normalize(crib)
        if not norm or (len(norm) == 1 and "fold" in norm):
            continue  # pure fold → omit (importer treats absence as fold)
        for action, freq in sorted(norm.items()):
            rows.append(f"{hand},{action},{freq}")
    header = [
        f"# poker.academy CE-Symmetric — {depth}bb {facing}"
        + (f" | hero {hero} vs {opp}" if opp else f" | {hero} first-in"),
        f"# Scraped {datetime.date.today()} via scrape_all_ranges.py",
        f"# TreeParams: poker.academy CE-Symmetric Regular @ {depth}bb (GTO ChipEV, 1bb ante)",
        "notation,action,freq",
    ]
    return "\n".join(header + rows) + "\n", len(rows)


# ---------------------------------------------------------------------------
# Manifest (atomic)
# ---------------------------------------------------------------------------
def load_manifest():
    if MANIFEST.exists():
        try:
            return set(json.loads(MANIFEST.read_text(encoding="utf-8")))
        except Exception:
            log(f"{Y}[Manifest]{X} corrupt manifest ignored; starting fresh.")
    return set()


def save_manifest(done):
    tmp = MANIFEST.with_suffix(".tmp")
    tmp.write_text(json.dumps(sorted(done), indent=2), encoding="utf-8")
    os.replace(tmp, MANIFEST)


def task_key(t):
    return t["archive_slug"] if t["opp"] else t["slug"]


# ---------------------------------------------------------------------------
# Compile / validate
# ---------------------------------------------------------------------------
def run_cmd(cmd, cwd=None):
    log(f"{B}$ {cmd}{X}")
    res = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True)
    if res.stdout:
        log(res.stdout.strip()[-2000:])
    if res.returncode != 0 and res.stderr:
        log(f"{R}{res.stderr.strip()[-2000:]}{X}")
    return res.returncode == 0


def compile_and_validate():
    log(f"\n{C}=== Copying all multi-opener charts to crib/ ==={X}")
    run_cmd("cp crib_multi_opener/*.csv crib/", cwd=IMPORTER_DIR)
    
    log(f"\n{C}=== Compiling crib → JSON + deriving 9-max ==={X}")
    run_cmd("swift run RangeImporter import --input crib/ --output ../../Cutoff/Resources/Ranges/", cwd=IMPORTER_DIR)
    run_cmd("swift run RangeImporter derive-9max --input ../../Cutoff/Resources/Ranges/ --output ../../Cutoff/Resources/Ranges/", cwd=IMPORTER_DIR)
    log(f"\n{C}=== Validating bundled ranges ==={X}")
    ok = run_cmd(f'python3 "{SCRIPT_DIR / "validate_ranges.py"}"')
    if ok:
        log(f"{G}[Validator] All ranges passed.{X}")
    else:
        log(f"{Y}[Validator] Reported issues — see output above (warnings do not block).{X}")
    return ok


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--canonical-only", action="store_true",
                    help="Scrape only the closest-raiser matchups (app-critical, ~252 spots).")
    ap.add_argument("--no-compile", action="store_true",
                    help="Skip the Swift compile + validation at the end.")
    ap.add_argument("--reset", action="store_true", help="Ignore manifest; rescrape everything.")
    ap.add_argument("--limit", type=int, default=0, help="Stop after N newly-scraped spots (testing).")
    args = ap.parse_args()

    CRIB_DIR.mkdir(exist_ok=True)
    ARCHIVE_DIR.mkdir(exist_ok=True)

    log(f"{G}=== poker.academy bulk scraper (v3) ==={X}")

    # --- Pre-flight ---------------------------------------------------------
    ok, out, err = chrome_eval("1+1")
    if not ok or out != "2":
        log(f"{R}[Abort]{X} Cannot run JS in Chrome.")
        log("Open Chrome and enable: View ▸ Developer ▸ 'Allow JavaScript from Apple Events'.")
        log(f"(osascript said: {err or out})")
        sys.exit(1)

    url = chrome_get_url()
    if "poker.academy/tournaments" not in url:
        log(f"{R}[Abort]{X} Active Chrome tab must be a poker.academy tournament page. Got: {url}")
        sys.exit(1)

    parts = [p for p in url.split("/") if p]
    try:
        s = parts.index("s")
        pack, speed = parts[s + 1], parts[s + 3]
    except (ValueError, IndexError):
        pack, speed = "CE-Symmetric", "Regular"
    log(f"{C}[Pack]{X} {pack} | Speed: {speed}")

    tasks = build_tasks(pack, speed, args.canonical_only)
    done = set() if args.reset else load_manifest()
    n_canon = sum(1 for t in tasks if t["canonical"])
    log(f"{G}[Plan]{X} {len(tasks)} spots ({n_canon} canonical + {len(tasks)-n_canon} archive). "
        f"{len(done)} already done.")

    start = time.time()
    cur_page = None
    scraped = failed = skipped = 0
    consec_fail = 0

    try:
        for i, t in enumerate(tasks):
            key = task_key(t)
            if key in done:
                continue

            facing, depth, hero, opp = t["facing"], t["depth"], t["hero"], t["opp"]
            page = (facing, depth, hero)
            tag = f"{depth}bb {hero} {facing}" + (f" vs {opp}" if opp else "")
            log(f"\n{G}[{i+1}/{len(tasks)}]{X} {C}{tag}{X}"
                + (f" {B}(canonical){X}" if t["canonical"] else ""))

            def acquire():
                """Navigate (if page changed) + select opponent + return grid."""
                nonlocal cur_page
                if page != cur_page:
                    chrome_navigate(t["url"])
                    if facing == "unopened":
                        if not poll_grid_loaded(facing, timeout=14):
                            return None
                    else:
                        if not wait_for_opponent_selector():
                            return None
                        # vs3Bet's SPA route needs a scenario "kick" after a
                        # cold URL load before the selector wires up the grid.
                        if facing == "vs3bet":
                            click_scenario("vs. 3bet")
                            time.sleep(1.0)
                    cur_page = page
                if opp:
                    clicked = False
                    for _ in range(4):
                        ok, info = click_opponent(opp)
                        if ok:
                            clicked = True
                            break
                        time.sleep(0.6)
                    if not clicked:
                        return None
                    return poll_grid_loaded(facing, timeout=12)
                return poll_grid_loaded(facing, timeout=12)

            hands = acquire()
            if hands is None:
                # self-heal: reload page once and retry from scratch
                log(f"{Y}[heal]{X} grid not ready — reloading tab and retrying")
                chrome_reload()
                cur_page = None
                time.sleep(4)
                hands = acquire()

            if hands is None:
                log(f"{R}[fail]{X} could not load grid for {tag}")
                failed += 1
                consec_fail += 1
                if consec_fail >= 8:
                    log(f"{Y}[backoff]{X} {consec_fail} consecutive failures — pausing 30s + reload.")
                    chrome_reload()
                    cur_page = None
                    time.sleep(30)
                    consec_fail = 0
                continue
            consec_fail = 0

            # Sanity: AA should not be pure-fold for open/defend spots.
            aa = hands.get("AA", {})
            aa_fold = aa.get("fold", 0) >= 0.99
            if facing in ("unopened", "vsopen") and aa_fold:
                log(f"{Y}[warn]{X} AA folds in {tag} — suspicious, skipping (will retry next run).")
                failed += 1
                continue

            # Write archive copy (always) + canonical copy (if applicable).
            if opp:
                csv, nrows = grid_to_csv(hands, facing, depth, hero, opp)
                (ARCHIVE_DIR / f"{t['archive_slug']}.csv").write_text(csv, encoding="utf-8")
            if t["slug"]:
                csv, nrows = grid_to_csv(hands, facing, depth, hero, opp)
                (CRIB_DIR / f"{t['slug']}.csv").write_text(csv, encoding="utf-8")
                log(f"{G}[saved]{X} {t['slug']}.csv ({nrows} action rows)")
            else:
                log(f"{G}[archived]{X} {t['archive_slug']}.csv")

            scraped += 1
            done.add(key)
            save_manifest(done)

            if args.limit and scraped >= args.limit:
                log(f"{Y}[limit]{X} reached --limit {args.limit}, stopping.")
                break

    except KeyboardInterrupt:
        log(f"\n{Y}[Interrupted]{X} progress saved to manifest.")

    elapsed = (time.time() - start) / 60
    log(f"\n{G}=== Scrape finished ==={X}")
    log(f"Elapsed: {elapsed:.1f} min | scraped: {G}{scraped}{X} | "
        f"failed: {R}{failed}{X} | already-done: {len(done)-scraped}")

    if not args.no_compile:
        compile_and_validate()

    log(f"{G}Done.{X} Canonical CSVs in crib/, full archive in crib_multi_opener/.")


if __name__ == "__main__":
    main()
