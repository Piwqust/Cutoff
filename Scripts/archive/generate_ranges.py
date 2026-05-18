import json
import os
import glob

RANKS = ['A', 'K', 'Q', 'J', 'T', '9', '8', '7', '6', '5', '4', '3', '2']
RANK_VALS = {r: 14-i for i, r in enumerate(RANKS)}

HANDS = []
for i in range(13):
    for j in range(13):
        if i == j:
            HANDS.append(RANKS[i] + RANKS[j])
        elif i < j:
            HANDS.append(RANKS[i] + RANKS[j] + 's')
        else:
            HANDS.append(RANKS[j] + RANKS[i] + 'o')

def hand_strength(hand):
    if len(hand) == 2:
        return RANK_VALS[hand[0]] * 3 + 30
    elif hand[2] == 's':
        return RANK_VALS[hand[0]] * 2 + RANK_VALS[hand[1]] + 15
    else:
        return RANK_VALS[hand[0]] * 2 + RANK_VALS[hand[1]]

def generate_hands(pos, depth, facing):
    pos_idx = ["UTG", "UTG1", "LJ", "HJ", "CO", "BTN", "SB", "BB"].index(pos)
    base_thresh = 54 - (pos_idx * 3)
    
    if facing == "unopened":
        if pos == "BB": return None
        threshold = base_thresh
            
    elif facing == "vsOpen":
        if pos == "UTG": return None
        threshold = base_thresh + 6
        
    elif facing == "vs3Bet":
        if pos == "UTG": return None
        threshold = base_thresh + 12
        
    elif facing == "blindDefense":
        if pos != "BB": return None
        threshold = base_thresh - 15
        
    elif facing == "squeeze":
        if pos in ["UTG", "UTG1"]: return None
        threshold = base_thresh + 16
        
    elif facing == "pushFold":
        threshold = base_thresh - 5
        
    else:
        return None

    res = {}
    for h in HANDS:
        s = hand_strength(h)
        if s >= threshold:
            if facing == "unopened":
                if depth <= 15: res[h] = "jam"
                else: res[h] = "raise"
            elif facing == "vsOpen":
                if s >= threshold + 10: res[h] = "threeBet"
                else: res[h] = "call"
            elif facing == "vs3Bet":
                if s >= threshold + 8: res[h] = "jam" if depth <= 30 else "raise"
                else: res[h] = "call"
            elif facing == "blindDefense":
                if s >= threshold + 18: res[h] = "threeBet"
                else: res[h] = "call"
            elif facing == "squeeze":
                if s >= threshold + 5: res[h] = "jam"
                else: res[h] = "call"
            elif facing == "pushFold":
                res[h] = "jam"
    
    return res if len(res) > 0 else {"AA": "raise"}

def main():
    out_dir = "MTTPokerTrainer/Resources/Ranges"
    
    # Clean up any previously generated 'demo' ones
    for f in glob.glob(f"{out_dir}/*_demo.json"):
        os.remove(f)
        
    existing_spots = set()
    for f in glob.glob(f"{out_dir}/*.json"):
        with open(f, "r") as file:
            try:
                data = json.load(file)
                spot = data.get("spot", {})
                pos = spot.get("position")
                depth = spot.get("stackDepthBB")
                facing = spot.get("facingAction")
                if pos and depth and facing:
                    existing_spots.add(f"{pos}_{depth}_{facing}")
            except Exception:
                pass

    depths = [10, 15, 20, 25, 30, 40, 50, 75, 100, 125]
    positions = ["UTG", "UTG1", "LJ", "HJ", "CO", "BTN", "SB", "BB"]
    facings = ["unopened", "vsOpen", "vs3Bet", "blindDefense", "squeeze", "pushFold"]
    
    count = 0
    for d in depths:
        for p in positions:
            for f in facings:
                if f == "unopened" and p == "BB": continue
                if f == "blindDefense" and p != "BB": continue
                if f in ["vsOpen", "vs3Bet"] and p == "UTG": continue
                if f == "squeeze" and p in ["UTG", "UTG1"]: continue
                if f == "pushFold" and d > 30: continue
                
                spot_key = f"{p}_{d}_{f}"
                if spot_key in existing_spots:
                    continue
                
                file_id = f"z_mtt_9max_{d}bb_{p.lower()}_{f.lower()}_demo"
                file_name = f"{out_dir}/{file_id}.json"
                
                hands = generate_hands(p, d, f)
                if hands is None: continue
                
                data = {
                    "id": file_id,
                    "format": "NLHE_MTT_9MAX",
                    "spot": {
                        "position": p,
                        "stackDepthBB": d,
                        "facingAction": f,
                        "anteType": "bigBlindAnte"
                    },
                    "source": {
                        "type": "demo",
                        "description": "Approximate demo training range. Generated heuristically to fill missing combinations. Not solver-verified."
                    },
                    "hands": hands
                }
                
                with open(file_name, "w") as f_out:
                    json.dump(data, f_out, indent=2)
                count += 1
                
    print(f"Generated {count} missing demo ranges safely.")

if __name__ == '__main__':
    main()
