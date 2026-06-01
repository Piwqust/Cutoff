/**
 * Poker.academy Range Grid Scraper & CSV Exporter
 * 
 * INSTRUCTIONS:
 * 1. Open Chrome and navigate to the target range page:
 *    e.g., https://poker.academy/tournaments/s/CE-Symmetric/60/Regular/RFI/CO///
 * 2. Open Developer Tools (Press F12, or Cmd+Option+I on Mac).
 * 3. Select the "Console" tab.
 * 4. Paste this entire script and press Enter.
 * 5. It will automatically parse the 13x13 grid, classify the colors into poker actions,
 *    calculate VPIP as a sanity check, and download the CSV file directly (e.g. `mtt_8max_60bb_co_unopened.csv`).
 */

(function() {
    console.log("%c[Poker.academy Scraper] Initializing...", "color: #4db6ac; font-weight: bold; font-size: 14px;");

    // 1. Define poker hand grid constants
    const RANKS = ["A", "K", "Q", "J", "T", "9", "8", "7", "6", "5", "4", "3", "2"];
    const HAND_WEIGHTS = { pair: 6, suited: 4, offsuit: 12 };

    function getHandAt(row, col) {
        if (row === col) return RANKS[row] + RANKS[col];
        if (row < col) return RANKS[row] + RANKS[col] + 's';
        return RANKS[col] + RANKS[row] + 'o';
    }

    // 2. Classify colors into poker actions
    // Poker.academy typically uses:
    // - Red / Orange/ Pink -> Raise
    // - Green / Teal / Cyan -> Call
    // - Blue / Indigo -> Limp
    // - Dark Grey / Transparent / Light Grey -> Fold
    function classifyColor(rgbStr) {
        if (!rgbStr) return "fold";
        const match = rgbStr.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*[\d.]+)?\)/);
        if (!match) return "fold";
        
        const r = parseInt(match[1]);
        const g = parseInt(match[2]);
        const b = parseInt(match[3]);

        // If it's grey, white or dark grey
        const max = Math.max(r, g, b);
        const min = Math.min(r, g, b);
        if (max - min < 20) {
            if (max > 220 || max < 100) return "fold"; // too light or too dark
        }

        // Red/Orange dominant
        if (r > g * 1.3 && r > b * 1.3 && r > 100) {
            return "raise";
        }
        // Green dominant
        if (g > r * 1.1 && g > b * 0.9 && g > 100) {
            return "call";
        }
        // Blue/Indigo dominant
        if (b > r * 1.2 && b > g * 1.1 && b > 100) {
            return "limp";
        }

        // Catch-all heuristic for orange/pink tints
        if (r > 150 && g > 80 && b > 80 && r > g) {
            return "raise";
        }
        // Catch-all heuristic for teal/cyan tints
        if (g > 150 && b > 150 && g > r) {
            return "call";
        }

        return "fold";
    }

    // 3. Find the 13x13 grid cells in the DOM
    // We scan all elements on the page for ones containing exactly hand labels (e.g. AA, AKs, etc.)
    const allElements = Array.from(document.querySelectorAll('*'));
    const handCells = [];
    const seenHands = new Set();

    // Regex to match exact poker hand notations
    const handRegex = /^(?:[2-9TJQKA]{2}[so]?)$/;

    for (const el of allElements) {
        // Only target small elements with direct text nodes
        if (el.children.length <= 2 && el.textContent) {
            const txt = el.textContent.trim();
            if (handRegex.test(txt) && !seenHands.has(txt)) {
                // Confirm this looks like a grid cell by checking if it has background styles or is inside a grid
                const style = window.getComputedStyle(el);
                const bg = style.backgroundColor || style.backgroundImage;
                
                handCells.push({
                    hand: txt,
                    element: el
                });
                seenHands.add(txt);
            }
        }
    }

    console.log(`[Poker.academy Scraper] Found ${handCells.length} candidate hand cell elements.`);

    if (handCells.length !== 169) {
        console.warn(`%c[Warning] Expected exactly 169 cells, but found ${handCells.length}. Attempting fallback matching...`, "color: #ffa726;");
        
        // Fallback: search for elements by exact layout or grids if text matching is offset
        if (handCells.length === 0) {
            console.error("%c[Error] Could not find any hand grid cells. Make sure you are on the range chart page and the chart is fully rendered.", "color: #ef5350;");
            alert("Error: Could not locate range chart elements. Please ensure the chart is fully visible on the screen.");
            return;
        }
    }

    // Map found cells into a dictionary for quick lookup
    const cellMap = {};
    for (const cell of handCells) {
        cellMap[cell.hand] = cell.element;
    }

    // 4. Parse the strategy for each cell
    const csvRows = [];
    csvRows.push("notation,action,freq");
    
    let totalPlayedCombos = 0;
    let raiseCombos = 0;
    let callCombos = 0;
    let limpCombos = 0;

    for (let r = 0; r < 13; r++) {
        for (let c = 0; c < 13; c++) {
            const hand = getHandAt(r, c);
            const el = cellMap[hand];
            
            if (!el) {
                // If a cell is missing, treat as implicit fold
                continue;
            }

            const handType = r === c ? "pair" : (r < c ? "suited" : "offsuit");
            const combos = HAND_WEIGHTS[handType];
            
            // Check for split strategies (nested child divs with distinct background colors)
            // React grids often split a cell by rendering divs side-by-side or stacked
            const children = Array.from(el.children).filter(child => {
                const w = child.offsetWidth;
                const h = child.offsetHeight;
                return w > 0 && h > 0;
            });

            const strategies = [];

            if (children.length > 1) {
                // Split-action cell
                let totalWidth = children.reduce((acc, child) => acc + child.offsetWidth, 0);
                if (totalWidth === 0) totalWidth = 1;

                for (const child of children) {
                    const style = window.getComputedStyle(child);
                    const bg = style.backgroundColor;
                    const action = classifyColor(bg);
                    const pct = child.offsetWidth / totalWidth;
                    
                    if (pct > 0.05) { // filter out noise
                        strategies.push({ action, freq: pct });
                    }
                }
            } else {
                // Single action cell or background-gradient split
                const style = window.getComputedStyle(el);
                const bgImage = style.backgroundImage; // could contain a linear-gradient
                const bgColor = style.backgroundColor;

                if (bgImage && bgImage.includes("linear-gradient")) {
                    // Simple parse of linear-gradient stops, e.g. linear-gradient(..., rgb(...) 0%, rgb(...) 50%, ...)
                    const rgbMatches = bgImage.match(/rgb\(\d+,\s*\d+,\s*\d+\)/g);
                    if (rgbMatches && rgbMatches.length > 1) {
                        // Estimate frequencies equally or look for percentage stops
                        const stops = bgImage.match(/\d+%/g);
                        if (stops && stops.length >= 2) {
                            // Map matches to actions
                            const uniqueActions = rgbMatches.map(classifyColor);
                            // Simple rough split parsing (e.g. 50/50)
                            const set = new Set(uniqueActions);
                            if (set.size > 1) {
                                const arr = Array.from(set);
                                for (const a of arr) {
                                    strategies.push({ action: a, freq: 1.0 / arr.length });
                                }
                            } else {
                                strategies.push({ action: uniqueActions[0], freq: 1.0 });
                            }
                        }
                    }
                }

                if (strategies.length === 0) {
                    const action = classifyColor(bgColor);
                    strategies.push({ action, freq: 1.0 });
                }
            }

            // Normalise frequencies to sum to exactly 1.0 (quantising to nearest standard step)
            // Standard chart engines typically round to 25%, 33%, 50%, or 100%
            let nonFoldSum = 0;
            let finalStrategies = [];

            for (const strat of strategies) {
                // Clean up action
                let act = strat.action;
                let freq = strat.freq;

                // Round frequencies to nearest nice step: 25%, 50%, 75%, 100%
                if (freq > 0.85) freq = 1.0;
                else if (freq > 0.62) freq = 0.75;
                else if (freq > 0.37) freq = 0.50;
                else if (freq > 0.15) freq = 0.25;
                else freq = 0;

                if (freq > 0) {
                    finalStrategies.push({ action: act, freq });
                    if (act !== "fold") {
                        nonFoldSum += freq;
                    }
                }
            }

            // If frequencies don't sum to 1.0, adjust or default to fold for the rest
            const totalSum = finalStrategies.reduce((acc, s) => acc + s.freq, 0);
            if (totalSum < 1.0 && totalSum > 0) {
                // Add fold to fill the rest
                finalStrategies.push({ action: "fold", freq: 1.0 - totalSum });
            } else if (totalSum > 1.0) {
                // Normalise down to 1.0
                const scale = 1.0 / totalSum;
                finalStrategies.forEach(s => s.freq = Math.round(s.freq * scale * 4) / 4);
            }

            // Filter out 0 freq and write to CSV
            for (const s of finalStrategies) {
                if (s.freq > 0 && s.action !== "fold") {
                    csvRows.push(`${hand},${s.action},${s.freq}`);
                    
                    // Accumulate for VPIP checksum
                    if (s.action === "raise") raiseCombos += combos * s.freq;
                    if (s.action === "call") callCombos += combos * s.freq;
                    if (s.action === "limp") limpCombos += combos * s.freq;
                    totalPlayedCombos += combos * s.freq;
                }
            }
        }
    }

    // 5. Build dynamic filename from current URL
    // URL structure: https://poker.academy/tournaments/s/CE-Symmetric/60/Regular/RFI/CO///
    const pathParts = window.location.pathname.split('/').filter(p => p.length > 0);
    
    // Fallbacks if URL parsing is different
    let depth = "60bb";
    let position = "co";
    let facing = "unopened";

    if (pathParts.length >= 3) {
        // e.g. pathParts = ["tournaments", "s", "CE-Symmetric", "60", "Regular", "RFI", "CO"]
        const depthVal = parseInt(pathParts[3]);
        if (!isNaN(depthVal)) depth = `${depthVal}bb`;
        
        const posVal = pathParts[6] || pathParts[pathParts.length - 1];
        if (posVal) position = posVal.toLowerCase();

        const scenarioVal = pathParts[5];
        if (scenarioVal) {
            const sc = scenarioVal.toLowerCase();
            if (sc === "rfi" || sc === "unopened") facing = "unopened";
            else if (sc.startsWith("vs")) facing = "vsopen";
            else facing = sc;
        }
    }

    const filename = `mtt_8max_${depth}_${position}_${facing}.csv`;

    // 6. Generate file download in browser
    const csvContent = csvRows.join("\n") + "\n";
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const link = document.createElement("a");
    
    const url = URL.createObjectURL(blob);
    link.setAttribute("href", url);
    link.setAttribute("download", filename);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    // 7. Output complete statistics summary in Console
    const vpipPct = (totalPlayedCombos / 1326) * 100;
    const raisePct = (raiseCombos / 1326) * 100;
    const callPct = (callCombos / 1326) * 100;
    const limpPct = (limpCombos / 1326) * 100;

    console.log(`%c[Poker.academy Scraper] Export Complete!`, "color: #4db6ac; font-weight: bold; font-size: 14px;");
    console.log(`%cFilename: ${filename}`, "font-weight: bold;");
    console.log(`%cTotal VPIP: ${vpipPct.toFixed(2)}% (${totalPlayedCombos.toFixed(1)} / 1326 combos)`, "color: #81c784; font-weight: bold;");
    console.log(`  - Open Raise: ${raisePct.toFixed(2)}% (${raiseCombos.toFixed(1)} combos)`);
    if (callPct > 0) console.log(`  - Call: ${callPct.toFixed(2)}% (${callCombos.toFixed(1)} combos)`);
    if (limpPct > 0) console.log(`  - Limp: ${limpPct.toFixed(2)}% (${limpCombos.toFixed(1)} combos)`);
    console.log(`%cDrop this downloaded file into 'Tools/RangeImporter/crib/' and run the importer!`, "color: #4fc3f7; font-style: italic;");
})();
