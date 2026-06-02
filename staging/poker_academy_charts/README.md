# poker.academy preflop range harvester

Captures preflop ranges from your authenticated **poker.academy** subscription
using your own logged-in browser. Range data is read from the rendered
Strategy-Grid tiles (legend color → action; each tile's stacked segment heights
→ per-action frequency). Nothing leaves your machine except the requests your
browser already makes; no credentials are transmitted anywhere.

## Contents
- `full_harvest.js` — paste-once browser-console script. Sweeps the **entire**
  library your subscription exposes: every game-type × stack × scenario ×
  category × hero × villain, all grids. Resumable.
- `receiver.py` — tiny local server that writes each captured range to `files/`.
- `files/` — output. One JSON per spot, plus `_spotlist.json` and `_progress.json`.

## How to run the full harvest
1. **Terminal:**
   ```sh
   cd "staging/poker_academy_charts"
   python3 receiver.py
   ```
   (Leave it running. It listens on `127.0.0.1:8799` and writes to `files/`.)
2. Log in to poker.academy and open any Strategy-Grid page
   (`https://poker.academy/tournaments/s/...`).
3. Open the browser **DevTools console** on that tab, paste all of
   `full_harvest.js`, press Enter.
4. **Keep that tab focused.** Watch `files/` fill up; live counter is in
   `files/_progress.json` and the console.

### Live controls (type in the console)
- `__PA.status()` — print current phase / counts.
- `__PA.stop()` — pause after the current spot.
- `__PA.resume()` — continue (also resumes after a refresh; finished spots are
  skipped via `localStorage`).

### Narrowing scope (optional)
Edit the `CONFIG` block at the top of `full_harvest.js` before pasting:
```js
ONLY_GAMETYPES: ['ChipEV'],     // e.g. just ChipEV
ONLY_STACKS:    ['100','50'],   // e.g. just 100bb & 50bb
ONLY_SCENARIOS: ['Regular'],    // e.g. just Regular
```
Empty arrays = capture everything. Raise `DWELL_MS` if you see `EMPTY` captures
on a slow connection.

## Scale (what "everything" means)
The catalog is **context-scoped** — each game-type/stack/scenario combination
exposes its own set of spots (the 100bb/Regular/ChipEV context alone has 170).
A full sweep is on the order of a few thousand grids and can take a while; it is
fully resumable, so a dropped connection or closed tab just means re-paste.

## JSON shape (one file per spot)
```json
{
  "fn": "CE-Symmetric_100bb_Regular_RFI_CO_m1081131",
  "url": "https://poker.academy/tournaments/s/CE-Symmetric/100/Regular/RFI/CO///",
  "meta": { "gameType":"CE-Symmetric","stack":"100","scenario":"Regular",
            "category":"RFI","hero":"CO","villain":null,"raiseSize":"2.5","multiway":null },
  "legend": [ {"action":"Raise 2.5x","rgb":[224,97,6]}, {"action":"Fold","rgb":[173,173,173]} ],
  "nGrids": 1,
  "grids": [
    { "caption":"#1081131 CE-Symmetric 100BB CO RFI (Regular) Mixed strategy",
      "hands": { "AA":{"Raise 2.5x":100.0}, "ATs":{"Raise 2.5x":100.0}, "72o":{"Fold":100.0} } }
  ]
}
```
169 hands per grid (13×13); frequencies are percentages summing to ~100. The
filename ends in `_m<id>` (the matrix id) so distinct sizings / multiway configs
never overwrite each other.

## Already captured (this run)
`CE-Symmetric / 100bb / Regular` — 157 files / 170 catalog spots
(13 were same-name sizing variants under the older naming; the new `_m<id>`
scheme in `full_harvest.js` keeps them all separate on the next run).
Validation of the captured set: 0 empty, 0 malformed, 26,533 hands checked,
every grid exactly 169 hands, every hand's frequencies sum to 100 within ±2%.

## Accuracy & caveats
- Frequencies come from rendered pixel heights, so **mixed** cells carry a small
  rounding tolerance (~0.1–0.5%). **Pure** cells (100/0) are exact.
- The site footer notes its tool isn't for in-game use per their ToS; this
  export is for your own offline study.
