#!/usr/bin/env python3
import subprocess
import sys
import os
import time
import json
from pathlib import Path

# Color terminal formatting helpers
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
BLUE = "\033[94m"
CYAN = "\033[96m"
RESET = "\033[0m"

def run_cmd(cmd, cwd=None, capture=True):
    if not capture:
        print(f"{BLUE}[Execute]{RESET} {cmd}")
        res = subprocess.run(cmd, shell=True, cwd=cwd)
        return res.returncode == 0, "", ""
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd=cwd)
    if res.returncode != 0:
        return False, res.stdout, res.stderr
    return True, res.stdout, res.stderr

def execute_js_in_chrome(js_code, script_dir):
    escaped_js = js_code.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '\\r')
    applescript_exec = f'tell application "Google Chrome" to execute active tab of first window javascript "{escaped_js}"'
    
    as_file = script_dir / "temp_run_js.applescript"
    as_file.write_text(applescript_exec, encoding="utf-8")
    
    success, stdout, stderr = run_cmd(f'osascript "{as_file}"')
    
    if as_file.exists():
        os.remove(as_file)
        
    return success, stdout, stderr

def derive_vs3betjam_csv(csv_content):
    lines = csv_content.strip().split("\n")
    if not lines or len(lines) < 2:
        return ""
    
    header = lines[0]
    out_lines = [header]
    
    premiums = {"AA", "KK", "QQ", "JJ", "TT", "99", "88", "AKs", "AKo", "AQs", "AQo", "AJs", "AJo", "ATs"}
    
    # Group by hand to normalize frequencies
    hand_strats = {}
    for line in lines[1:]:
        parts = line.split(",")
        if len(parts) < 3:
            continue
        hand, action, freq = parts[0], parts[1], float(parts[2])
        if hand not in hand_strats:
            hand_strats[hand] = {}
        hand_strats[hand][action] = freq
        
    for hand in sorted(hand_strats.keys()):
        strat = hand_strats[hand]
        # Facing a jam, we can only call or fold
        call_freq = 0.0
        
        # 1. Existing call or jam/shove always goes to call
        call_freq += strat.get("call", 0.0)
        call_freq += strat.get("jam", 0.0)
        call_freq += strat.get("shove", 0.0)
        
        # 2. Raise goes to call if premium, otherwise folds (bluffs)
        raise_freq = sum(f for act, f in strat.items() if act in ("raise", "raise25x", "raise3x", "minRaise"))
        if hand in premiums:
            call_freq += raise_freq
            
        call_freq = min(1.0, max(0.0, call_freq))
        
        # Round to standard 25% steps
        if call_freq > 0.85: call_freq = 1.0
        elif call_freq > 0.62: call_freq = 0.75
        elif call_freq > 0.37: call_freq = 0.50
        elif call_freq > 0.15: call_freq = 0.25
        else: call_freq = 0.0
        
        if call_freq > 0:
            out_lines.append(f"{hand},call,{call_freq}")
            if call_freq < 1.0:
                out_lines.append(f"{hand},fold,{round(1.0 - call_freq, 2)}")
        else:
            out_lines.append(f"{hand},fold,1.0")
            
    return "\n".join(out_lines) + "\n"

def main():
    print(f"{GREEN}=== Starting Bulk Tournament Range Scraper ==={RESET}")
    print("This script will automatically navigate Chrome through all stack depths and scenarios")
    print("for your tournament structure, click appropriate filters, scrape the ranges, and compile them.\n")

    # 1. Path setup
    script_dir = Path(__file__).parent.resolve()
    importer_dir = script_dir.parent.resolve()
    manifest_file = importer_dir / "scripts" / "scrape_manifest.json"
    js_file = script_dir / "poker_academy_console_script.js"

    if not js_file.exists():
        print(f"{RED}[Abort]{RESET} Scraper script not found at {js_file}")
        sys.exit(1)

    # 2. Check if Chrome is running and get the current active URL to extract pack and speed
    applescript_url = 'tell application "Google Chrome" to get URL of active tab of first window'
    success, stdout, stderr = run_cmd(f"osascript -e '{applescript_url}'")
    if not success:
        print(f"{RED}[Abort]{RESET} Could not communicate with Google Chrome. Please open Chrome to poker.academy.")
        sys.exit(1)

    current_url = stdout.strip()
    print(f"{GREEN}[Found Chrome Tab]{RESET} Active URL: {current_url}")

    if "poker.academy/tournaments" not in current_url:
        print(f"{RED}[Abort]{RESET} Your active Chrome window must be open on a poker.academy tournament chart page.")
        sys.exit(1)

    # Extract Pack Name and Speed from current URL
    path_parts = [p for p in current_url.split('/') if p]
    if len(path_parts) < 5:
        print(f"{RED}[Abort]{RESET} URL structure is not recognized. Please open a valid range chart page.")
        sys.exit(1)

    try:
        s_idx = path_parts.index("s")
        pack_name = path_parts[s_idx + 1]
        speed_name = path_parts[s_idx + 3]
    except (ValueError, IndexError):
        pack_name = "CE-Symmetric"
        speed_name = "Regular"

    print(f"{CYAN}[Tourney Pack]{RESET} Pack: {pack_name} | Speed: {speed_name}")

    # 3. Generate all combinations of spots to scrape matching the exact website structure
    depths = [10, 15, 20, 25, 30, 40, 50, 60, 70, 100]
    
    def get_app_depth(d):
        return 75 if d == 70 else d
        
    def get_app_pos(p):
        if p == "EP": return "utg"
        if p == "MP": return "utg1"
        return p.lower()
    
    spots_to_scrape = []

    # A. RFI spots (all positions except BB)
    rfi_positions = ["EP", "MP", "LJ", "HJ", "CO", "BTN", "SB"]
    for depth in depths:
        app_depth = get_app_depth(depth)
        for pos in rfi_positions:
            app_pos = get_app_pos(pos)
            spots_to_scrape.append({
                "type": "RFI",
                "depth": depth,
                "url": f"https://poker.academy/tournaments/s/{pack_name}/{depth}/{speed_name}/RFI/{pos}///",
                "slug": f"mtt_8max_{app_depth}bb_{app_pos}_unopened",
                "desc": f"{depth}bb RFI from {pos}",
                "opp_pos": None
            })

    # B. Targeted representative vsOpen (Facing RFI) spots
    vs_open_matchups = [
        ("MP", "EP"),
        ("LJ", "MP"),
        ("HJ", "LJ"),
        ("CO", "HJ"),
        ("BTN", "CO"),
        ("SB", "BTN"),
        ("BB", "BTN")
    ]
    for depth in depths:
        app_depth = get_app_depth(depth)
        for defender, opener in vs_open_matchups:
            app_defender = get_app_pos(defender)
            spots_to_scrape.append({
                "type": "vsOpen",
                "depth": depth,
                "url": f"https://poker.academy/tournaments/s/{pack_name}/{depth}/{speed_name}/vs.%20RFI/{defender}///",
                "slug": f"mtt_8max_{app_depth}bb_{app_defender}_vsopen",
                "desc": f"{depth}bb Hero {defender} vs Opponent {opener} open",
                "opp_pos": opener
            })

    # C. Targeted representative vs3Bet (Facing 3-Bet) spots
    vs_3bet_matchups = [
        ("EP", "BTN"),
        ("MP", "BTN"),
        ("LJ", "BTN"),
        ("HJ", "BTN"),
        ("CO", "BTN"),
        ("BTN", "BB"),
        ("SB", "BB")
    ]
    for depth in depths:
        app_depth = get_app_depth(depth)
        for opener, three_bettor in vs_3bet_matchups:
            app_opener = get_app_pos(opener)
            spots_to_scrape.append({
                "type": "vs3Bet",
                "depth": depth,
                "url": f"https://poker.academy/tournaments/s/{pack_name}/{depth}/{speed_name}/vs.%203bet/{opener}///",
                "slug": f"mtt_8max_{app_depth}bb_{app_opener}_vs3bet",
                "desc": f"{depth}bb Hero {opener} vs Opponent {three_bettor} 3-bet",
                "opp_pos": three_bettor
            })

    print(f"{GREEN}[Planner]{RESET} Generated {len(spots_to_scrape)} targeted GTO range spots to scrape.")

    # 4. Load manifest to support Resume functionality
    completed_slugs = set()
    if manifest_file.exists():
        try:
            completed_slugs = set(json.loads(manifest_file.read_text(encoding="utf-8")))
            print(f"{YELLOW}[Manifest]{RESET} Found manifest. Resuming scrape; {len(completed_slugs)} spots already completed.")
        except Exception:
            pass

    # Read JS code
    js_code = js_file.read_text(encoding="utf-8")
    
    # Modify JS code to return the CSV content directly to AppleScript
    search_target = "const blob = new Blob([csvContent]"
    if search_target in js_code:
        lines = js_code.split("\n")
        filtered_lines = []
        skip = False
        for line in lines:
            if "// 6. Generate file download in browser" in line:
                skip = True
                filtered_lines.append("    return csvContent;")
            if "})();" in line:
                skip = False
            if not skip:
                filtered_lines.append(line)
        js_code = "\n".join(filtered_lines)
    else:
        js_code += "\ncsvContent;"

    # 5. Main loop
    total_spots = len(spots_to_scrape)
    skipped_count = 0
    scraped_count = 0
    
    start_time = time.time()

    try:
        for idx, spot in enumerate(spots_to_scrape):
            slug = spot["slug"]
            if slug in completed_slugs:
                continue

            print(f"\n{GREEN}[Spot {idx+1}/{total_spots}]{RESET} Processing {CYAN}{spot['desc']}{RESET}...")
            
            # Navigate Chrome to the target URL (sets Category + Hero Position)
            nav_script = f'tell application "Google Chrome" to set URL of active tab of first window to "{spot["url"]}"'
            success, _, _ = run_cmd(f"osascript -e '{nav_script}'")
            if not success:
                print(f"{RED}[Error]{RESET} Failed to navigate Chrome. Is the tab closed?")
                break
                
            # Wait 2.0 seconds for the React app to load the page layout
            time.sleep(2.0)

            # If there is an opponent position to select (vsOpen / vs3Bet), click it programmatically!
            if spot["opp_pos"]:
                print(f"{YELLOW}[Chrome]{RESET} Clicking Opponent Position '{spot['opp_pos']}'...")
                click_opp_js = f"""
                (function() {{
                    const headers = Array.from(document.querySelectorAll('div.headerSection, .headerSection'));
                    const oppHeader = headers.find(el => {{
                        const text = el.textContent.trim().toLowerCase();
                        return text.includes("opponent") && text.includes("position");
                    }});
                    
                    if (!oppHeader) return "Opponent header not found";
                    
                    const buttonsContainer = oppHeader.nextElementSibling;
                    if (!buttonsContainer) return "Buttons container not found";
                    
                    const buttons = Array.from(buttonsContainer.querySelectorAll('.sc-gbvfcU, div, button'));
                    const btn = buttons.find(b => b.textContent.trim() === '{spot["opp_pos"]}');
                    
                    if (!btn) return "Opponent button '{spot["opp_pos"]}' not found";
                    
                    btn.click();
                    return "Clicked Opponent " + '{spot["opp_pos"]}';
                }})();
                """
                click_success, click_stdout, click_stderr = execute_js_in_chrome(click_opp_js, script_dir)
                if click_success and "Clicked Opponent" in click_stdout:
                    # Wait 1.2 seconds for React to fetch and render the newly selected grid
                    time.sleep(1.2)
                else:
                    print(f"{YELLOW}[Warning]{RESET} Failed to select Opponent Position '{spot['opp_pos']}' (result: {click_stdout.strip()}). HTML structure might be different.")

            # Inject and execute scraper JS with a retry loop to survive rendering/network lag
            max_retries = 3
            csv_content = ""
            
            for attempt in range(1, max_retries + 1):
                if attempt > 1:
                    time.sleep(1.2)
                    
                success, stdout, stderr = execute_js_in_chrome(js_code, script_dir)
                
                if not success:
                    if "Executing JavaScript through AppleScript is turned off" in stderr or "Executing JavaScript through AppleScript is turned off" in stdout:
                        print(f"\n{RED}[Action Required]{RESET} JavaScript execution through AppleScript is disabled in Google Chrome.")
                        print(f"Please enable it by clicking in Chrome's menu bar:")
                        print(f"  {YELLOW}View > Developer > Allow JavaScript from Apple Events{RESET}\n")
                        sys.exit(1)
                    continue
                    
                csv_content = stdout.strip()
                if csv_content and "notation,action,freq" in csv_content:
                    break

            if not csv_content or "notation,action,freq" not in csv_content:
                # Page is not a valid chart or completely empty, skip it
                print(f"{YELLOW}[Skip]{RESET} No valid range grid found at URL after {max_retries} attempts.")
                skipped_count += 1
                completed_slugs.add(slug)
                continue

            # Save the CSV crib sheet
            csv_path = importer_dir / "crib" / f"{slug}.csv"
            csv_path.write_text(csv_content, encoding="utf-8")
            print(f"{GREEN}[Saved]{RESET} Crib sheet written to {csv_path.name}")
            
            # Automatically derive and save the vs3betjam sibling if applicable!
            if spot["type"] == "vs3Bet":
                jam_slug = slug.replace("_vs3bet", "_vs3betjam")
                jam_csv_path = importer_dir / "crib" / f"{jam_slug}.csv"
                jam_csv_content = derive_vs3betjam_csv(csv_content)
                if jam_csv_content:
                    jam_csv_path.write_text(jam_csv_content, encoding="utf-8")
                    print(f"{GREEN}[Derived]{RESET} Sibling crib sheet written to {jam_csv_path.name}")
            
            scraped_count += 1
            completed_slugs.add(slug)
            
            # Save progress to manifest
            manifest_file.write_text(json.dumps(list(completed_slugs), indent=2), encoding="utf-8")

            # Periodically compile to show live progress (every 5 scraped charts)
            if scraped_count % 5 == 0:
                print(f"{YELLOW}[Compiler]{RESET} Running batch compilation to sync app resources...")
                run_cmd("swift run RangeImporter import --input crib/ --output ../../Cutoff/Resources/Ranges/", cwd=importer_dir)
                run_cmd("swift run RangeImporter derive-9max --input ../../Cutoff/Resources/Ranges/ --output ../../Cutoff/Resources/Ranges/", cwd=importer_dir)

    except KeyboardInterrupt:
        print(f"\n{YELLOW}[Interrupted]{RESET} Bulk scraping paused by user. Progress saved.")

    # Final Compilation
    print(f"\n{YELLOW}[Compiler]{RESET} Running final compilation and 9-max derivation...")
    run_cmd("swift run RangeImporter import --input crib/ --output ../../Cutoff/Resources/Ranges/", cwd=importer_dir)
    run_cmd("swift run RangeImporter derive-9max --input ../../Cutoff/Resources/Ranges/ --output ../../Cutoff/Resources/Ranges/", cwd=importer_dir)

    elapsed = time.time() - start_time
    print(f"\n{GREEN}=== Bulk Scraping Finished ==={RESET}")
    print(f"Time elapsed: {elapsed/60:.1f} minutes")
    print(f"Successfully scraped: {GREEN}{scraped_count} ranges{RESET}")
    print(f"Skipped / empty slots: {YELLOW}{skipped_count} spots{RESET}")
    print(f"All progress has been fully integrated into the Cutoff SwiftUI project!")

if __name__ == "__main__":
    main()
