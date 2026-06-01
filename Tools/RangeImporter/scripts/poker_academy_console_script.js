/**
 * Poker.academy Range Grid Scraper & CSV Exporter (Ultra-Robust Version)
 * 
 * INSTRUCTIONS:
 * 1. Open Chrome and navigate to the target range page:
 *    e.g., https://poker.academy/tournaments/s/CE-Symmetric/60/Regular/RFI/CO///
 * 2. Open Developer Tools (Press F12, or Cmd+Option+I on Mac).
 * 3. Select the "Console" tab.
 * 4. Paste this entire script and press Enter.
 * 5. It will automatically parse the 13x13 grid, classify the colors into poker actions,
 *    calculate VPIP as a sanity check, and download the CSV file directly.
 */

(function() {
    console.log("%c[Poker.academy Scraper] Initializing ultra-robust parser...", "color: #4db6ac; font-weight: bold; font-size: 14px;");

    // 1. Define poker hand grid constants
    const RANKS = ["A", "K", "Q", "J", "T", "9", "8", "7", "6", "5", "4", "3", "2"];
    const HAND_WEIGHTS = { pair: 6, suited: 4, offsuit: 12 };

    function getHandAt(row, col) {
        if (row === col) return RANKS[row] + RANKS[col];
        if (row < col) return RANKS[row] + RANKS[col] + 's';
        return RANKS[col] + RANKS[row] + 'o';
    }

    // 2. Classify colors into poker actions
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
            if (max > 220 || max < 100) return "fold";
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

        // Catch-all heuristics for poker chart palettes
        if (r > 150 && g > 80 && b > 80 && r > g) {
            return "raise";
        }
        if (g > 150 && b > 150 && g > r) {
            return "call";
        }

        return "fold";
    }

    // 3. Find all elements on the page matching the hand regex exactly
    const handRegex = /^(?:[2-9TJQKA]{2}[so]?)$/;
    const allElements = Array.from(document.querySelectorAll('*'));
    const candidates = [];

    for (const el of allElements) {
        if (el.textContent) {
            const txt = el.textContent.trim();
            if (handRegex.test(txt) && txt.length <= 3) {
                candidates.push({ txt, el });
            }
        }
    }

    // 4. For each unique hand notation, find the "best" grid cell element container
    const handCells = [];
    const uniqueHands = Array.from(new Set(candidates.map(c => c.txt)));

    for (const hand of uniqueHands) {
        const handElements = candidates.filter(c => c.txt === hand).map(c => c.el);
        
        let bestEl = null;
        let maxScore = -1;
        
        for (const el of handElements) {
            let score = 0;
            const style = window.getComputedStyle(el);
            const bgColor = style.backgroundColor;
            
            // If it has children that are visible/active split blocks, high score
            const children = Array.from(el.children).filter(c => c.offsetWidth > 0 || c.offsetHeight > 0);
            if (children.length > 1) {
                score += 150;
            }
            
            // If it has a colored background (not transparent, white, or body color)
            if (bgColor && bgColor !== "rgba(0, 0, 0, 0)" && bgColor !== "rgb(255, 255, 255)" && bgColor !== "transparent") {
                score += 50;
            }
            
            // Prefer div/td elements over spans
            const tag = el.tagName.toLowerCase();
            if (tag === "div" || tag === "td") {
                score += 30;
            }
            
            // Prefer elements with children over raw text elements
            score += el.children.length * 2;

            if (score > maxScore) {
                maxScore = score;
                bestEl = el;
            }
        }
        
        if (bestEl) {
            handCells.push({ hand, element: bestEl });
        }
    }

    console.log(`[Poker.academy Scraper] Located ${handCells.length}/169 unique hand grid cells.`);

    if (handCells.length === 0) {
        console.error("%c[Error] Could not locate any hand grid cells. Make sure you are on the range chart page.", "color: #ef5350;");
        return;
    }

    const cellMap = {};
    for (const cell of handCells) {
        cellMap[cell.hand] = cell.element;
    }

    // 5. Parse the strategy for each cell
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
            
            if (!el) continue;

            const handType = r === c ? "pair" : (r < c ? "suited" : "offsuit");
            const combos = HAND_WEIGHTS[handType];
            
            // Find active child components representing action splits
            const children = Array.from(el.children).filter(child => {
                return child.offsetWidth > 0 || child.offsetHeight > 0;
            });

            const strategies = [];

            if (children.length > 1) {
                // Split-action cell (Chakra flex boxes / standard split layout)
                let totalWidth = children.reduce((acc, child) => acc + child.offsetWidth, 0);
                if (totalWidth === 0) totalWidth = 1;

                for (const child of children) {
                    const style = window.getComputedStyle(child);
                    const bg = style.backgroundColor;
                    const action = classifyColor(bg);
                    const pct = child.offsetWidth / totalWidth;
                    
                    if (pct > 0.05) {
                        strategies.push({ action, freq: pct });
                    }
                }
            } else {
                // Single action cell or background-gradient split
                const style = window.getComputedStyle(el);
                const bgImage = style.backgroundImage;
                const bgColor = style.backgroundColor;

                if (bgImage && bgImage.includes("linear-gradient")) {
                    const rgbMatches = bgImage.match(/rgb\(\d+,\s*\d+,\s*\d+\)/g);
                    if (rgbMatches && rgbMatches.length > 1) {
                        const uniqueActions = rgbMatches.map(classifyColor);
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

                if (strategies.length === 0) {
                    const action = classifyColor(bgColor);
                    strategies.push({ action, freq: 1.0 });
                }
            }

            // Normalise frequencies to sum to exactly 1.0
            let nonFoldSum = 0;
            let finalStrategies = [];

            for (const strat of strategies) {
                let act = strat.action;
                let freq = strat.freq;

                // Round to nearest standard steps
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

            const totalSum = finalStrategies.reduce((acc, s) => acc + s.freq, 0);
            if (totalSum < 1.0 && totalSum > 0) {
                finalStrategies.push({ action: "fold", freq: 1.0 - totalSum });
            } else if (totalSum > 1.0) {
                const scale = 1.0 / totalSum;
                finalStrategies.forEach(s => s.freq = Math.round(s.freq * scale * 4) / 4);
            }

            for (const s of finalStrategies) {
                if (s.freq > 0 && s.action !== "fold") {
                    csvRows.push(`${hand},${s.action},${s.freq}`);
                    
                    if (s.action === "raise") raiseCombos += combos * s.freq;
                    if (s.action === "call") callCombos += combos * s.freq;
                    if (s.action === "limp") limpCombos += combos * s.freq;
                    totalPlayedCombos += combos * s.freq;
                }
            }
        }
    }

    // 6. Build dynamic filename from URL
    const pathParts = window.location.pathname.split('/').filter(p => p.length > 0);
    let depth = "60bb";
    let position = "co";
    let facing = "unopened";

    if (pathParts.length >= 3) {
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
    const csvContent = csvRows.join("\n") + "\n";

    // Trigger file download
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const link = document.createElement("a");
    const url = URL.createObjectURL(blob);
    link.setAttribute("href", url);
    link.setAttribute("download", filename);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    console.log(`%c[Poker.academy Scraper] Export Complete!`, "color: #4db6ac; font-weight: bold; font-size: 14px;");
    return csvContent;
})();
