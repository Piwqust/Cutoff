/**
 * poker.academy range-grid extractor (v3 — multi-grid aware).
 *
 * DOM model (CE-Symmetric pack, reverse-engineered 2026-06):
 *   `.pokermatrix` wraps one 13x13 grid of `.tile` cells. A `.tile` =
 *   `.tileInside` (hand text) + `.tileki` (action segments). Each segment is a
 *   div whose WIDTH encodes that action's frequency and whose
 *   `background-image: linear-gradient(... rgb(R,G,B) ...)` encodes the action:
 *       rgb(132,18,7)  red   -> All-in (jam)
 *       rgb(224,97,6)  orange-> Raise  (open / 3-bet / 4-bet by context)
 *       rgb(11,133,120)teal  -> Limp / Call
 *       rgb(128,128,128)grey -> Fold
 *   (Confirmed: 100bb RFI shows only orange+grey; no jam/limp.)
 *
 *   RFI renders ONE grid; vsOpen renders TWO (hero's defense + opponent's open
 *   range); vs3Bet renders THREE (hero's response + two opponent context grids).
 *   Each grid carries a human label like "40bb CO vs. 3bet from BTN  Hero" or
 *   "40bb BTN vs. RFI from CO  Opponent" — so this script returns every grid
 *   WITH its label, and the orchestrator selects the one tagged "Hero".
 *
 * Returns JSON: {"grids":[{"n":169,"label":"...","hands":{"AA":{"raise":1.0}}}, ...]}
 * Actions are NEUTRAL tokens (jam/raise/call/fold); Python remaps per scenario.
 * Frequencies are raw width fractions (Python rounds/normalises).
 */
(function () {
    var ANCHORS = [
        { act: "jam",   rgb: [132, 18, 7] },
        { act: "raise", rgb: [224, 97, 6] },
        { act: "call",  rgb: [11, 133, 120] },
        { act: "fold",  rgb: [128, 128, 128] }
    ];

    function nearestAction(r, g, b) {
        var best = "fold", bestD = Infinity;
        for (var i = 0; i < ANCHORS.length; i++) {
            var c = ANCHORS[i].rgb;
            var d = (r - c[0]) * (r - c[0]) + (g - c[1]) * (g - c[1]) + (b - c[2]) * (b - c[2]);
            if (d < bestD) { bestD = d; best = ANCHORS[i].act; }
        }
        return bestD <= 120 * 120 ? best : "fold";
    }

    var HAND_RE = /^(?:[2-9TJQKA]{2}[so]?)$/;

    function parseGrid(container) {
        var hands = {};
        var tiles = container.querySelectorAll(".tile");
        for (var i = 0; i < tiles.length; i++) {
            var tile = tiles[i];
            var inside = tile.querySelector(".tileInside");
            var ki = tile.querySelector(".tileki");
            if (!inside || !ki) continue;
            var hand = inside.textContent.trim();
            if (!HAND_RE.test(hand)) continue;
            if (!(tile.offsetWidth > 0 && tile.offsetHeight > 0)) continue;

            var segs = ki.children;
            var total = 0, parts = [];
            for (var s = 0; s < segs.length; s++) {
                var cs = getComputedStyle(segs[s]);
                var w = parseFloat(cs.width) || 0;
                if (w <= 0) continue;
                var src = cs.backgroundImage + " " + cs.backgroundColor;
                var mm = src.match(/rgba?\(\s*(\d+)[\s,]+(\d+)[\s,]+(\d+)/);
                parts.push({ act: mm ? nearestAction(+mm[1], +mm[2], +mm[3]) : "fold", w: w });
                total += w;
            }
            if (total <= 0) continue;
            var acc = {};
            for (var p = 0; p < parts.length; p++) {
                acc[parts[p].act] = (acc[parts[p].act] || 0) + parts[p].w / total;
            }
            hands[hand] = acc;
        }
        return hands;
    }

    // The chart title ("<d>bb <POS> vs. ... Hero/Opponent") lives in an
    // ancestor of each grid; climb up and grab the first matching leaf.
    function gridLabel(m) {
        var node = m;
        for (var up = 0; up < 5 && node; up++) {
            node = node.parentElement;
            if (!node) break;
            var cands = Array.from(node.querySelectorAll("*")).filter(function (e) {
                var t = (e.textContent || "").trim();
                return e.children.length <= 1 && /\b\d+bb\b/.test(t) && t.length < 60;
            });
            if (cands.length) return cands[0].textContent.trim().replace(/\s+/g, " ");
        }
        return "";
    }

    // Outer `.pokermatrix` only — `.matrix` is nested inside and would
    // double-count the same tiles.
    var containers = Array.from(document.querySelectorAll(".pokermatrix"));
    var grids = [];
    for (var c = 0; c < containers.length; c++) {
        var hands = parseGrid(containers[c]);
        var n = Object.keys(hands).length;
        if (n > 0) grids.push({ n: n, label: gridLabel(containers[c]), hands: hands });
    }

    return JSON.stringify({ grids: grids });
})();
