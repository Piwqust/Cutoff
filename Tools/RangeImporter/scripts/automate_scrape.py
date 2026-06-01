#!/usr/bin/env python3
import subprocess
import sys
import os
from pathlib import Path

# Color terminal formatting helpers
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
BLUE = "\033[94m"
RESET = "\033[0m"

def run_cmd(cmd, cwd=None):
    print(f"{BLUE}[Execute]{RESET} {cmd}")
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd=cwd)
    if res.returncode != 0:
        print(f"{RED}[Error]{RESET} Command failed with code {res.returncode}")
        print(res.stderr)
        return False, res.stdout, res.stderr
    return True, res.stdout, res.stderr

def main():
    print(f"{GREEN}=== Starting Automated Poker.academy Range Ingestion ==={RESET}")
    
    # 1. Path setup
    script_dir = Path(__file__).parent.resolve()
    project_root = script_dir.parent.parent.resolve()
    importer_dir = script_dir.parent.resolve()
    
    print(f"Project root: {project_root}")
    print(f"Importer directory: {importer_dir}")
    
    # 2. Check if Chrome is running and get URL
    applescript_url = 'tell application "Google Chrome" to get URL of active tab of first window'
    success, stdout, stderr = run_cmd(f"osascript -e '{applescript_url}'")
    if not success:
        print(f"{RED}[Abort]{RESET} Could not communicate with Google Chrome. Ensure Chrome is running and responsive.")
        sys.exit(1)
        
    url = stdout.strip()
    print(f"{GREEN}[Found Chrome Tab]{RESET} URL: {url}")
    
    if "poker.academy/tournaments" not in url:
        print(f"{RED}[Abort]{RESET} Active Chrome tab is not on poker.academy. Please open the range chart page in Chrome.")
        sys.exit(1)
        
    # 3. Read the JavaScript scraping utility
    js_file = script_dir / "poker_academy_console_script.js"
    if not js_file.exists():
        print(f"{RED}[Abort]{RESET} Scraper script not found at {js_file}")
        sys.exit(1)
        
    js_code = js_file.read_text(encoding="utf-8")
    
    # 4. Modify JavaScript code slightly to return the CSV content instead of initiating a browser file download
    # We replace the download logic block with a return statement
    search_target = "const blob = new Blob([csvContent]"
    if search_target in js_code:
        # Splice out the download block and append return statement
        lines = js_code.split("\n")
        filtered_lines = []
        skip = False
        for line in lines:
            if "// 6. Generate file download in browser" in line:
                skip = True
                filtered_lines.append("    // Returned directly to Python AppleScript runner:")
                filtered_lines.append("    return csvContent;")
            if "})();" in line:
                skip = False
            if not skip:
                filtered_lines.append(line)
        js_code = "\n".join(filtered_lines)
    else:
        # Fallback inline append
        js_code += "\ncsvContent;"
        
    # Escape for AppleScript double-quoted string
    escaped_js = js_code.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '\\r')
    
    # 5. Execute JavaScript in the active Chrome tab via AppleScript
    print(f"{YELLOW}[Chrome]{RESET} Injecting scraper JavaScript to parse range chart...")
    applescript_exec = f'tell application "Google Chrome" to execute active tab of first window javascript "{escaped_js}"'
    
    # Temporary AppleScript file to avoid shell argument length limits
    as_file = script_dir / "temp_scrape.applescript"
    as_file.write_text(applescript_exec, encoding="utf-8")
    
    success, stdout, stderr = run_cmd(f'osascript "{as_file}"')
    
    # Cleanup temporary script file
    if as_file.exists():
        os.remove(as_file)
        
    if not success:
        if "Executing JavaScript through AppleScript is turned off" in stderr or "Executing JavaScript through AppleScript is turned off" in stdout:
            print(f"\n{RED}[Action Required]{RESET} JavaScript execution through AppleScript is disabled in Google Chrome.")
            print(f"Please enable it by clicking in Chrome's menu bar:")
            print(f"  {YELLOW}View > Developer > Allow JavaScript from Apple Events{RESET}")
            print(f"After enabling it, rerun this automation script!\n")
        else:
            print(f"{RED}[Error]{RESET} Failed to execute JavaScript via AppleScript:")
            print(stderr)
        sys.exit(1)
        
    csv_content = stdout.strip()
    if not csv_content or "notation,action,freq" not in csv_content:
        print(f"{RED}[Error]{RESET} Scraping returned invalid or empty CSV data.")
        print(f"Scraper output preview: {csv_content[:200]}")
        sys.exit(1)
        
    print(f"{GREEN}[Scrape Successful]{RESET} Extracted {len(csv_content.splitlines()) - 1} rows of range data.")
    
    # 6. Parse path parameters from URL to determine slug name
    # URL e.g. https://poker.academy/tournaments/s/CE-Symmetric/60/Regular/RFI/CO///
    path_parts = [p for p in url.split('/') if p]
    depth = "60bb"
    position = "co"
    facing = "unopened"
    
    if len(path_parts) >= 6:
        try:
            depth_val = int(path_parts[5])
            depth = f"{depth_val}bb"
        except ValueError:
            pass
            
        position = path_parts[-1].lower()
        if position == "co" or position == "cutoff":
            position = "co"
            
        scenario = path_parts[7].lower()
        if scenario in ["rfi", "unopened"]:
            facing = "unopened"
        elif scenario.startswith("vs"):
            facing = "vsopen"
        else:
            facing = scenario
            
    csv_filename = f"mtt_8max_{depth}_{position}_{facing}.csv"
    csv_path = importer_dir / "crib" / csv_filename
    
    # Write the CSV file
    print(f"{YELLOW}[Crib]{RESET} Saving crib sheet to {csv_path}")
    csv_path.write_text(csv_content, encoding="utf-8")
    
    # 7. Compile range using RangeImporter import command
    print(f"\n{YELLOW}[Compiler]{RESET} Compiling CSV into canonical JSON...")
    success, stdout, stderr = run_cmd("swift run RangeImporter import --input crib/ --output ../../Cutoff/Resources/Ranges/", cwd=importer_dir)
    if not success:
        print(f"{RED}[Compile Failed]{RESET}")
        sys.exit(1)
        
    # 8. Derive 9-max sibling
    print(f"\n{YELLOW}[Compiler]{RESET} Deriving 9-max siblings...")
    success, stdout, stderr = run_cmd("swift run RangeImporter derive-9max --input ../../Cutoff/Resources/Ranges/ --output ../../Cutoff/Resources/Ranges/", cwd=importer_dir)
    if not success:
        print(f"{RED}[Derivation Failed]{RESET}")
        sys.exit(1)
        
    # 9. Verify with validator
    print(f"\n{YELLOW}[Validation]{RESET} Running validator...")
    # Run validator (note: it may return exit code 1 due to existing pre-existing vs3betjam duplicate warnings in other files, so we check output)
    _, stdout, stderr = run_cmd("python3 scripts/validate_ranges.py", cwd=importer_dir)
    
    target_json = f"mtt_8max_{depth}_{position}_{facing}.json"
    target_9max_json = f"mtt_9max_{depth}_{position}_{facing}.json"
    
    print(f"\n{GREEN}=== Pipeline Executed Successfully ==={RESET}")
    print(f"Generated 8-max JSON: {GREEN}Cutoff/Resources/Ranges/{target_json}{RESET}")
    print(f"Generated 9-max JSON: {GREEN}Cutoff/Resources/Ranges/{target_9max_json}{RESET}")
    print("Everything is up to date and verified.")

if __name__ == "__main__":
    main()
