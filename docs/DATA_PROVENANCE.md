# Data Provenance

This app ships **only demo training data**. No data here is solver-verified, and no data in this repository was derived from a paid solver, paid course, or proprietary chart.

## Categories of poker data

| Category | Source | UI label |
|---|---|---|
| Demo | Hand-authored approximate ranges shipped in `MTTPokerTrainer/Resources/Ranges/*.json` | "Demo training range — not solver-verified" |
| User-defined | Created locally by the user (future feature; not in MVP) | "Your range — not solver-verified" |
| Imported | Loaded by the user from a JSON file (future feature; not in MVP) | "Imported range — provenance set by you" |

The app **never** labels a range as "solver-verified", "GTO", or "optimal".

## Demo range JSON schema

```json
{
  "id": "mtt_9max_100bb_utg_open_demo_v1",
  "format": "NLHE_MTT_9MAX",
  "spot": {
    "position": "UTG",
    "stackDepthBB": 100,
    "facingAction": "unopened",
    "anteType": "unknown"
  },
  "source": {
    "type": "demo",
    "description": "Approximate demo training range. Not solver-verified."
  },
  "hands": {
    "AA": "raise",
    "KK": "raise",
    "QQ": "raise",
    "AKs": "raise",
    "AQs": "raise",
    "A2o": "fold"
  }
}
```

### Required keys
- `id` — stable, lowercase, snake-case, ending in `_demo_v{N}` for demo data.
- `format` — currently always `"NLHE_MTT_9MAX"`.
- `spot.position` — one of `UTG`, `UTG+1`, `LJ`, `HJ`, `CO`, `BTN`, `SB`, `BB`.
- `spot.stackDepthBB` — integer.
- `spot.facingAction` — one of `unopened`, `vsOpen`, `vs3Bet`, `blindDefense`, `squeeze`, `pushFold`.
- `spot.anteType` — `none`, `classic`, `bigBlindAnte`, `unknown`.
- `source.type` — `demo`, `userDefined`, or `imported`.
- `source.description` — required free-text caveat.
- `hands` — map of hand string (`AA`, `AKs`, `AKo`, `72o`, ...) to a `RangeAction` (`fold`, `call`, `raise`, `threeBet`, `jam`, `mixed`).

### Sparse files are fine
A demo range does not need to cover all 169 combos. The UI treats any hand not listed in `hands` as the **implicit fold** for that spot, and labels the implicit cells accordingly in the Range Grid.

## What demo data IS NOT
- Not a solver output.
- Not vetted by a coach.
- Not balanced for any specific stack-depth distribution.
- Not a substitute for paid study material.

## Future: importing user ranges (post-MVP design intent)
- The import flow will accept a JSON file matching the schema above.
- If `source.type` is missing or empty, the importer will set it to `"userDefined"` automatically.
- Imported files will be labeled in the UI according to their declared `source.type` — the app must not re-label imported data.
- The app **must** strip any field claiming "solver-verified" / "GTO-verified" / "optimal" before accepting the file. Such claims are not validated and could mislead users.

## Legal warning to future contributors
Do **not** add, paste, or commit:
- GTO Wizard charts or any GTO Wizard data
- DTO charts or DTO solver output
- Run It Once paid material
- Upswing paid charts or Upswing course content
- Any closed/paywalled solver dataset
- Any range data from another app's source code, JSON, or screenshot

If a future contributor authors new demo ranges, they must be **original work**. Approximation by hand is fine; copying any third-party chart — even from a free preview — is not.
