import json
import os
import glob

OUT_DIR = "MTTPokerTrainer/Resources/Ranges"

pos_order = ["UTG", "UTG1", "LJ", "HJ", "CO", "BTN", "SB", "BB"]

fac_dist = {
    "unopened": {"unopened":0, "pushFold": 1, "vsOpen": 2},
    "vsOpen": {"vsOpen":0, "blindDefense": 1, "squeeze": 2, "vs3Bet": 3, "unopened": 4},
    "vs3Bet": {"vs3Bet":0, "squeeze": 1, "vsOpen": 2, "unopened": 4},
    "blindDefense": {"blindDefense":0, "vsOpen": 1, "vs3Bet": 3},
    "squeeze": {"squeeze":0, "vs3Bet": 1, "vsOpen": 2},
    "pushFold": {"pushFold":0, "unopened": 1, "vsOpen": 3}
}

def get_score(donor, target):
    d_pos, d_depth, d_fac = donor
    t_pos, t_depth, t_fac = target

    depth_diff = abs(d_depth - t_depth)
    pos_diff = abs(pos_order.index(d_pos) - pos_order.index(t_pos))
    fac_diff = fac_dist.get(t_fac, {}).get(d_fac, 100)

    # Priority: 1. Facing (must match as close as possible), 2. Position, 3. Depth
    return fac_diff * 1000 + pos_diff * 100 + depth_diff

# Load existing GTO files
existing = {}
for f in glob.glob(f"{OUT_DIR}/*.json"):
    with open(f, "r") as file:
        try:
            data = json.load(file)
            spot = data.get("spot", {})
            p = spot.get("position")
            d = spot.get("stackDepthBB")
            fa = spot.get("facingAction")
            if p and d and fa:
                existing[(p, d, fa)] = data
        except Exception:
            pass

print(f"Loaded {len(existing)} existing files.")

# Generate all theoretically valid combinations
valid_combos = []
depths = [10, 15, 20, 25, 30, 40, 50, 75, 100, 125]
for d in depths:
    for p in pos_order:
        for fa in ["unopened", "vsOpen", "vs3Bet", "blindDefense", "squeeze", "pushFold"]:
            # Exclude truly invalid poker scenarios
            if fa == "unopened" and p == "BB": continue
            if fa == "blindDefense" and p != "BB": continue
            if fa == "vsOpen" and p == "UTG": continue
            if fa == "squeeze" and p in ["UTG", "UTG1"]: continue

            valid_combos.append((p, d, fa))

count = 0
for target in valid_combos:
    if target in existing: continue

    # Find the mathematically closest existing chart to use as a donor
    best_donor_key = min(existing.keys(), key=lambda k: get_score(k, target))
    donor_data = existing[best_donor_key]
    
    t_pos, t_depth, t_fa = target

    new_id = f"gto_fill_mtt_9max_{t_depth}bb_{t_pos.lower()}_{t_fa.lower()}"
    new_data = {
        "id": new_id,
        "format": "NLHE_MTT_9MAX",
        "spot": {
            "position": t_pos,
            "stackDepthBB": t_depth,
            "facingAction": t_fa,
            "anteType": "bigBlindAnte"
        },
        "source": {
            "type": "gto",
            "description": "GTO approximation (cloned from closest spot to fill missing database entry)."
        },
        "hands": donor_data["hands"]
    }

    with open(f"{OUT_DIR}/{new_id}.json", "w") as f_out:
        json.dump(new_data, f_out, indent=2)
    
    count += 1

print(f"Filled {count} missing spots.")
