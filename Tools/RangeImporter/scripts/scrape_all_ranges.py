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

def main():
    print(f"{GREEN}=== Starting Bulk Tournament Range Scraper ==={RESET}")
    print("This script will automatically navigate Chrome through all stack depths and scenarios")
    print("for your tournament structure, scrape the ranges, and compile them.\n")

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
    # Format e.g.: https://poker.academy/tournaments/s/CE-Symmetric/60/Regular/RFI/CO///
    path_parts = [p for p in current_url.split('/') if p]
    if len(path_parts) < 5:
        print(f"{RED}[Abort]{RESET} URL structure is not recognized. Please open a valid range chart page.")
        sys.exit(1)

    # Walk path parts to extract structure
    # tournaments -> s -> [Pack] -> [Depth] -> [Speed]
    try:
        s_idx = path_parts.index("s")
        pack_name = path_parts[s_idx + 1]
        speed_name = path_parts[s_idx + 3]
    except (ValueError, IndexError):
        pack_name = "CE-Symmetric"
        speed_name = "Regular"

    print(f"{CYAN}[Tourney Pack]{RESET} Pack: {pack_name} | Speed: {speed_name}")

    # 3. Generate all combinations of spots to scrape
    depths = [10, 15, 20, 25, 30, 40, 50, 60, 75, 100, 125]
    positions = ["UTG", "UTG1", "LJ", "HJ", "CO", "BTN", "SB", "BB"]
    
    spots_to_scrape = []

    # A. RFI spots (all positions except BB)
    for depth in depths:
        for pos in positions[:-1]: # exclude BB
            spots_to_scrape.append({
                "type": "RFI",
                "depth": depth,
                "url": f"https://poker.academy/tournaments/s/{pack_name}/{depth}/{speed_name}/RFI/{pos}///",
                "slug": f"mtt_8max_{depth}bb_{pos.lower()}_unopened",
                "desc": f"{depth}bb RFI from {pos}"
            })

    # B. vsOpen (Facing RFI) spots
    # Valid (Opener, Hero) pairs
    vs_open_pairs = [
        ("UTG", ["UTG1", "LJ", "HJ", "CO", "BTN", "SB", "BB"]),
        ("UTG1", ["LJ", "HJ", "CO", "BTN", "SB", "BB"]),
        ("LJ", ["HJ", "CO", "BTN", "SB", "BB"]),
        ("HJ", ["CO", "BTN", "SB", "BB"]),
        ("CO", ["BTN", "SB", "BB"]),
        ("BTN", ["SB", "BB"]),
        ("SB", ["BB"])
    ]

    for depth in depths:
        for opener, heroes in vs_open_pairs:
            for hero in heroes:
                # Format: vsOpen/[Opener]/[Hero]
                spots_to_scrape.append({
                    "type": "vsOpen",
                    "depth": depth,
                    "url": f"https://poker.academy/tournaments/s/{pack_name}/{depth}/{speed_name}/vsOpen/{opener}/{hero}///",
                    "slug": f"mtt_8max_{depth}bb_{hero.lower()}_vsopen", # in app: mtt_8max_Xbb_[hero]_vsopen.json
                    "desc": f"{depth}bb {hero} vs {opener} open"
                })

    # C. vs3Bet (Facing 3-Bet) spots
    # Standard 3-bet pairs (Opener, 3Beter)
    vs_3bet_pairs = [
        ("UTG", ["LJ", "HJ", "CO", "BTN", "SB", "BB"]),
        ("UTG1", ["LJ", "HJ", "CO", "BTN", "SB", "BB"]),
        ("LJ", ["HJ", "CO", "BTN", "SB", "BB"]),
        ("HJ", ["CO", "BTN", "SB", "BB"]),
        ("CO", ["BTN", "SB", "BB"]),
        ("BTN", ["SB", "BB"]),
        ("SB", ["BB"])
    ]

    for depth in depths:
        for opener, three_beters in vs_3bet_pairs:
            for tb in three_beters:
                # Format: vs3Bet/[Opener]/[3Beter]
                spots_to_scrape.append({
                    "type": "vs3Bet",
                    "depth": depth,
                    "url": f"https://poker.academy/tournaments/s/{pack_name}/{depth}/{speed_name}/vs3Bet/{opener}/{tb}///",
                    "slug": f"mtt_8max_{depth}bb_{opener.lower()}_vs3bet",
                    "desc": f"{depth}bb {opener} vs {tb} 3-bet"
                })

    print(f"{GREEN}[Planner]{RESET} Generated {len(spots_to_scrape)} total potential range spots to scrape.")

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

    # Double-quote escape for AppleScript double-quoted string literals
    escaped_js = js_code.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '\\r')

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
            
            # Navigate Chrome to the target URL
            nav_script = f'tell application "Google Chrome" to set URL of active tab of first window to "{spot["url"]}"'
            success, _, _ = run_cmd(f"osascript -e '{nav_script}'")
            if not success:
                print(f"{RED}[Error]{RESET} Failed to navigate Chrome. Is the tab closed?")
                break
                
            # Wait 2.2 seconds for the React app to fetch data and render the grid
            time.sleep(2.2)

            # Inject and execute scraper JS with a retry loop to survive rendering/network lag
            max_retries = 3
            csv_content = ""
            
            for attempt in range(1, max_retries + 1):
                if attempt > 1:
                    time.sleep(1.2)
                    
                applescript_exec = f'tell application "Google Chrome" to execute active tab of first window javascript "{escaped_js}"'
                as_file = script_dir / "temp_bulk_scrape.applescript"
                as_file.write_text(applescript_exec, encoding="utf-8")
                
                success, stdout, stderr = run_cmd(f'osascript "{as_file}"')
                if as_file.exists():
                    os.remove(as_file)
                    
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
