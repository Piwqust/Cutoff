#!/usr/bin/env python3
import json
import os
from pathlib import Path

# Color terminal formatting helpers
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
BLUE = "\033[94m"
RESET = "\033[0m"

def main():
    print(f"{GREEN}=== Auditing Ranges in Cutoff Project ==={RESET}")
    
    script_dir = Path(__file__).parent.resolve()
    project_root = script_dir.parent.parent.parent.resolve()
    ranges_dir = project_root / "Cutoff" / "Resources" / "Ranges"
    
    if not ranges_dir.exists():
        print(f"{RED}[Error]{RESET} Ranges directory does not exist at {ranges_dir}")
        return
        
    files = list(ranges_dir.glob("*.json"))
    print(f"Total range JSON files found: {BLUE}{len(files)}{RESET}\n")
    
    # Audit counters
    correct_count = 0
    corrupt_count = 0
    duplicate_count = 0
    
    breakdown = {}
    
    for f in sorted(files):
        try:
            content = json.loads(f.read_text(encoding="utf-8"))
        except Exception as e:
            print(f"{RED}[CORRUPT JSON]{RESET} {f.name}: failed to parse JSON - {e}")
            corrupt_count += 1
            continue
            
        # Parse fields
        fid = content.get("id", "")
        fmt = content.get("format", "")
        spot = content.get("spot", {})
        pos = spot.get("position", "")
        depth = spot.get("stackDepthBB", 0)
        facing = spot.get("facingAction", "")
        
        hands = content.get("hands", {})
        
        # Classification
        source = content.get("source", {})
        source_type = source.get("type", "")
        pub = source.get("publisher", {})
        pub_name = pub.get("name", "Unknown")
        
        # Verify basic structural rules
        is_corrupt = False
        reasons = []
        
        # Check 1: Empty or thin hands block
        if not hands or len(hands) < 2:
            reasons.append("Empty/thin hands block (<2 combos)")
            is_corrupt = True
            
        # Check 2: AA check for unopened/RFI
        if facing == "unopened" and "AA" in hands:
            # AA should be raise/raise25x with 100% or close to 100%
            aa_strat = hands["AA"]
            if isinstance(aa_strat, dict):
                raise_freq = aa_strat.get("raise25x", 0) + aa_strat.get("raise", 0) + aa_strat.get("shove", 0)
                if raise_freq < 0.8:
                    reasons.append(f"AA is folded/called with high freq ({1.0 - raise_freq}) in RFI")
                    is_corrupt = True
            elif isinstance(aa_strat, str):
                if aa_strat == "fold":
                    reasons.append("AA is pure fold in RFI")
                    is_corrupt = True
                    
        # Check 3: Check VPIP polarity (are trash hands played more than premiums?)
        if "72o" in hands and "AA" in hands:
            trash_strat = hands["72o"]
            aa_strat = hands["AA"]
            # Simple check: 72o shouldn't be raise/call in GTO if AA is fold
            if isinstance(trash_strat, dict) and (trash_strat.get("raise25x", 0) > 0.5 or trash_strat.get("call", 0) > 0.5):
                reasons.append("72o playing at high frequency (polarity inversion)")
                is_corrupt = True
                
        # Register in breakdown
        key = (fmt, depth, facing)
        if key not in breakdown:
            breakdown[key] = []
        breakdown[key].append({
            "file": f.name,
            "position": pos,
            "pub": pub_name,
            "type": source_type,
            "is_corrupt": is_corrupt,
            "reasons": reasons
        })
        
        if is_corrupt:
            corrupt_count += 1
            print(f"{RED}[CORRUPT CONTENT]{RESET} {f.name}: {', '.join(reasons)}")
        else:
            correct_count += 1

    print(f"\n{GREEN}=== Audit Summary ==={RESET}")
    print(f"Total range files audited : {BLUE}{len(files)}{RESET}")
    print(f"Perfect / clean ranges    : {GREEN}{correct_count}{RESET}")
    print(f"Corrupt / warning ranges  : {RED}{corrupt_count}{RESET}")
    
    print("\n--- STACK DEPTH & SCENARIO BREAKDOWN ---")
    for key in sorted(breakdown.keys()):
        fmt, depth, facing = key
        spot_files = breakdown[key]
        clean_spots = sum(1 for s in spot_files if not s["is_corrupt"])
        corr_spots = sum(1 for s in spot_files if s["is_corrupt"])
        
        print(f"  * {fmt} | {depth}bb | {facing}: {BLUE}{len(spot_files)} files{RESET} ({GREEN}{clean_spots} OK{RESET}, {RED}{corr_spots} Corrupt{RESET})")

if __name__ == "__main__":
    main()
