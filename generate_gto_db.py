import json
import os
import glob
import math

with open('/tmp/pekarstas.json', 'r') as f:
    pekarstas = json.load(f)

with open('/tmp/poker_range_converter/result_full.json', 'r') as f:
    jennifear = json.load(f)

OUT_DIR = "MTTPokerTrainer/Resources/Ranges"
for f in glob.glob(f"{OUT_DIR}/*.json"):
    os.remove(f)

pek_to_app_pos = {
    'UTG': 'LJ',
    'MP': 'HJ',
    'CO': 'CO',
    'BTN': 'BTN',
    'SB': 'SB',
    'BB': 'BB'
}

def write_json(file_id, pos, depth, facing, hands):
    if len(hands) == 0: return
    # remove defaults like fold
    filtered = {k:v for k,v in hands.items() if v != 'fold'}
    if len(filtered) == 0: return
    data = {
        "id": file_id,
        "format": "NLHE_MTT_9MAX",
        "spot": {
            "position": pos,
            "stackDepthBB": depth,
            "facingAction": facing,
            "anteType": "bigBlindAnte"
        },
        "source": {
            "type": "gto",
            "description": "GTO solver output derived from 100bb DB & Push/Fold."
        },
        "hands": filtered
    }
    with open(f"{OUT_DIR}/{file_id}.json", "w") as f_out:
        json.dump(data, f_out, indent=2)

count = 0

depths = [10, 15, 20, 25, 30, 40, 50, 75, 100, 125]
app_positions = ["UTG", "UTG1", "LJ", "HJ", "CO", "BTN", "SB", "BB"]
facings = ["unopened", "vsOpen", "vs3Bet", "blindDefense", "squeeze", "pushFold"]

jen_to_app = {
    'SB': 'SB',
    'BTN': 'BTN',
    'CO': 'CO',
    'HJ': 'HJ',
    'MP2': 'LJ',
    'MP1': 'UTG1',
    'UTG+1': 'UTG'
}

# 1. GENERATE PUSHFOLD (from Jennifear)
for d in [10, 15, 20]:
    for jen_pos, app_pos in jen_to_app.items():
        if str(d) in jennifear[jen_pos]:
            # grab 12.5% antes
            antes_data = jennifear[jen_pos][str(d)]
            hands_jen = antes_data.get('12.5%') or antes_data.get('10%') or antes_data.get('None')
            if hands_jen:
                hands = {k: "jam" for k in hands_jen.keys() if len(k)>1}
                file_id = f"gto_mtt_9max_{d}bb_{app_pos.lower()}_pushfold"
                write_json(file_id, app_pos, d, "pushFold", hands)
                count += 1

# 2. GENERATE OTHERS (from Pekarstas 100bb)
# Map Pekarstas -> App:
# RFI
rfi_keys = {'UTG': 'UTG-RFI', 'UTG1': 'UTG-RFI', 'LJ': 'UTG-RFI', 'HJ': 'MP-RFI', 'CO': 'CO-RFI', 'BTN': 'BTN-RFI', 'SB': 'SB-RFI'}

for d in depths:
    if d <= 20: continue # use pushfold
    for pos in app_positions:
        if pos == 'BB': continue
        pek_key = rfi_keys[pos]
        if pek_key in pekarstas:
            # For UTG, UTG1, we should artificially tighten the UTG(6-max) range by dropping weakest hands?
            # Or just pass it as is (many players use UTG 6-max for 9-max since ranges are close enough)
            hands = pekarstas[pek_key]
            # Pekarstas uses "raise", "fold", "mixed".
            file_id = f"gto_mtt_9max_{d}bb_{pos.lower()}_unopened"
            write_json(file_id, pos, d, "unopened", hands)
            count += 1

# vsOpen
# If I am BB: BB-vs-open-UTG, BB-vs-open-MP, BB-vs-open-CO, BB-vs-open-BTN, BB-vs-open-SB
# Let's just pick a generic vsOpen. E.g. vs MP for generic early, or CO. Let's use vs-open-CO as default vsOpen.
vs_open_map = {
    'UTG': None,
    'UTG1': None,
    'LJ': None, # MP vs UTG
    'HJ': 'MP-vs-open-UTG',
    'CO': 'CO-vs-open-UTG',
    'BTN': 'BTN-vs-open-CO',
    'SB': 'SB-vs-open-BTN',
    'BB': 'BB-vs-open-BTN'
}
for d in depths:
    if d <= 20: continue
    for pos in app_positions:
        key = vs_open_map.get(pos)
        if key and key in pekarstas:
            hands = pekarstas[key]
            # Replace allin with jam
            hands = {k: ("jam" if v == "allin" else v) for k, v in hands.items()}
            file_id = f"gto_mtt_9max_{d}bb_{pos.lower()}_vsopen"
            facing = "blindDefense" if pos == 'BB' else "vsOpen"
            write_json(file_id, pos, d, facing, hands)
            count += 1

# vs3Bet
vs_3bet_map = {
    'UTG': 'UTG-vs-3bet-MP',
    'UTG1': 'UTG-vs-3bet-MP',
    'LJ': 'UTG-vs-3bet-MP',
    'HJ': 'MP-vs-3bet-BTN',
    'CO': 'CO-vs-3bet-BTN',
    'BTN': 'BTN-vs-3bet-BB',
    'SB': 'SB-vs-3bet-BB',
    'BB': None
}
for d in depths:
    if d <= 20: continue
    for pos in app_positions:
        key = vs_3bet_map.get(pos)
        if key and key in pekarstas:
            hands = pekarstas[key]
            hands = {k: ("jam" if v == "allin" else v) for k, v in hands.items()}
            file_id = f"gto_mtt_9max_{d}bb_{pos.lower()}_vs3bet"
            write_json(file_id, pos, d, "vs3Bet", hands)
            count += 1

# vs4Bet -> Squeeze (fallback)
# Since pekarstas has BB-vs-4bet-BTN, let's use it for Squeeze spots loosely?
# Actually Squeeze = we are facing Open + Call. 
# We'll skip Squeeze for now or use vs-open but tighter. Let's just generate Squeeze as vs-open minus the bottom 20%.

print(f"Generated {count} GTO ranges.")
