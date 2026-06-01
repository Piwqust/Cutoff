/* =============================================================================
 * poker.academy preflop-range harvester  (v7 — chip-click catalog capture)
 * -----------------------------------------------------------------------------
 * Captures every range your subscription exposes for the loaded GAME TYPE:
 * every STACK × SCENARIO × CATEGORY × HERO × VILLAIN spot, all 13x13 grids.
 *
 * THE KEY MECHANIC (learned the hard way):
 *   - The catalog index is fetched by the app from
 *       wp.poker.academy/wp/wp-json/pfs/v3/matrices/<id>/simulation
 *     and is SCOPED to the selected stack. It is (re)fetched when you CLICK a
 *     stack chip — not on SPA URL nav, and the app.poker.academy/matrices/group
 *     endpoint rejects replayed tokens (401). So we hook fetch+XHR, click each
 *     stack chip, and capture whatever the app pulls.
 *   - Within a stack, individual spots render fine via SPA history navigation,
 *     so we visit each matrix's URL and scrape the grid.
 *
 * OUTPUT: one JSON per matrix -> ./files/<name>.json via receiver.py.
 *   Filename embeds _m<id> so nothing collides. Resumable (localStorage).
 *
 * USAGE
 *   1) Terminal:  python3 receiver.py
 *   2) Log in to poker.academy; open a Strategy-Grid page; pick the GAME TYPE
 *      you want in the top-right dropdown (real click).
 *   3) DevTools console -> paste this whole file -> Enter.
 *   4) Leave the tab focused. Watch files/ grow; status in files/_progress.json
 *      and window.__PA.
 *
 *   For OTHER game types: pick the type in the dropdown, then re-paste. Done
 *   spots are de-duped in localStorage, so everything accumulates in files/.
 *
 * CONSOLE CONTROLS:  __PA.status()  __PA.stop()  __PA.resume()
 *
 * TUNING (CONFIG below): ONLY_STACKS / ONLY_SCENARIOS whitelist; DWELL_MS.
 * ========================================================================== */
(function () {
  'use strict';
  if (window.__PA && window.__PA.running) { console.log('[PA] already running'); return; }

  var CONFIG = {
    RECEIVER: 'http://127.0.0.1:8799',
    DWELL_MS: 3000,
    RETRY_EMPTY_MS: 2600,
    CHIP_SETTLE_MS: 1500,     // after clicking a chip, before reading catalog
    CATALOG_WAIT_MS: 12000,   // max wait for the catalog fetch to land
    ONLY_STACKS: [],
    ONLY_SCENARIOS: []
  };

  var HAND = /^[AKQJT2-9]{2}[so]?$/;
  function sleep(ms){ return new Promise(function (r){ setTimeout(r, ms); }); }

  // ---- progress / dedupe ----------------------------------------------------
  var LSKEY = 'PA_HARVEST_DONE';
  function loadDone(){ try { return JSON.parse(localStorage.getItem(LSKEY)) || {}; } catch(e){ return {}; } }
  function saveDone(d){ try { localStorage.setItem(LSKEY, JSON.stringify(d)); } catch(e){} }
  var DONE = loadDone();
  function post(fn, o){ return fetch(CONFIG.RECEIVER + '/save', { method:'POST', headers:{ 'X-Filename': fn }, body: JSON.stringify(o) }); }
  function beacon(extra){ post('_progress', Object.assign({ ts:new Date().toISOString() }, window.__PA.progress, extra||{})).catch(function(){}); }

  // ---- catalog capture (fetch + XHR) ----------------------------------------
  // Captures the per-stack catalog array the app pulls from the wp simulation
  // endpoint. window.__PA_CAT is replaced each time a new one lands.
  var CATRE = /wp-json\/pfs\/v3\/matrices\/\d+\/simulation/;
  if (!window.__PA_CATHOOK) {
    var of = window.fetch;
    window.__PA_CAT = null;
    window.fetch = function (input) {
      var u = (typeof input === 'string') ? input : (input && input.url);
      var p = of.apply(this, arguments);
      if (u && CATRE.test(u)) p.then(function (r){ return r.clone().json(); }).then(function (j){ var d=j&&j.data&&j.data.data; if(Array.isArray(d)) window.__PA_CAT=d; }).catch(function(){});
      return p;
    };
    var oOpen = XMLHttpRequest.prototype.open, oSend = XMLHttpRequest.prototype.send;
    XMLHttpRequest.prototype.open = function (m, u){ this.__u = u; return oOpen.apply(this, arguments); };
    XMLHttpRequest.prototype.send = function (b){ var s=this; this.addEventListener('load', function (){ if (CATRE.test(s.__u||'')) { try { var j=JSON.parse(s.responseText); var d=j&&j.data&&j.data.data; if(Array.isArray(d)) window.__PA_CAT=d; } catch(e){} } }); return oSend.apply(this, arguments); };
    window.__PA_CATHOOK = true;
  }

  // ---- grid scraping --------------------------------------------------------
  function rgbBg(e){ var m=getComputedStyle(e).backgroundColor.match(/\d+/g); return m?m.slice(0,3).map(Number):null; }
  function topRgb(e){ var m=getComputedStyle(e).backgroundImage.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/); return m?[+m[1],+m[2],+m[3]]:rgbBg(e); }
  function readLegend(){
    var rows=[].slice.call(document.querySelectorAll('*')).filter(function(e){var t=e.textContent.trim();return /^(Allin|All-in|Raise|Call|Fold|Limp)\b/.test(t)&&t.length<45&&e.childElementCount>=1&&e.childElementCount<=3;});
    var map=[],seen={};
    rows.forEach(function(r){var m=r.textContent.trim().match(/^(Allin|All-in|Raise(?:\s*[\d.]+x)?|Call|Fold|Limp)/);if(!m)return;var a=m[0].trim();if(seen[a])return;var trip=null;[].concat([].slice.call(r.children),[r.firstElementChild,r.previousElementSibling]).forEach(function(x){if(x&&!trip){var c=rgbBg(x);if(c&&!(c[0]>250&&c[1]>250&&c[2]>250)&&!(c[0]===0&&c[1]===0&&c[2]===0))trip=c;}});if(trip){map.push({action:a,rgb:trip});seen[a]=1;}});
    return map;
  }
  function nearest(rgb,L){ if(!rgb)return'?'; var b=null,bd=1e9; for(var i=0;i<L.length;i++){var e=L[i];var d=Math.pow(e.rgb[0]-rgb[0],2)+Math.pow(e.rgb[1]-rgb[1],2)+Math.pow(e.rgb[2]-rgb[2],2);if(d<bd){bd=d;b=e;}} return b?b.action:'?'; }
  function cellFreqs(t,L){ var k=t.querySelector('.tileki'); if(!k)return{}; var sg=[].slice.call(k.children); var hs=sg.map(function(s){return s.getBoundingClientRect().height;}); var T=hs.reduce(function(a,b){return a+b;},0)||1; var o={}; sg.forEach(function(s,i){var a=nearest(topRgb(s),L);o[a]=(o[a]||0)+hs[i]/T*100;}); for(var q in o)o[q]=Math.round(o[q]*10)/10; return o; }
  function scrape(){
    var L=readLegend();
    var tiles=[].slice.call(document.querySelectorAll('div.tile')).filter(function(t){var i=t.querySelector('.tileInside');return i&&HAND.test(i.textContent.trim());});
    var grids=[]; for(var i=0;i+169<=tiles.length;i+=169) grids.push(tiles.slice(i,i+169));
    var caps=document.body.innerText.match(/#\d+ [^\n]*?strategy/gi)||[];
    var out=grids.map(function(g,gi){var h={};g.forEach(function(t){h[t.querySelector('.tileInside').textContent.trim()]=cellFreqs(t,L);});return {caption:caps[gi]||null,hands:h};});
    return {legend:L,nGrids:out.length,grids:out};
  }

  // ---- chip controls --------------------------------------------------------
  function chipEls(label){
    var leaf=[].slice.call(document.querySelectorAll('p,div,span')).find(function(e){return e.childElementCount===0&&e.textContent.trim()===label;});
    if(!leaf)return [];
    var cont=leaf.parentElement.nextElementSibling; if(!cont)return [];
    return [].slice.call(cont.children).filter(function(c){var t=c.textContent.trim();return c.tagName!=='STYLE'&&t.length>0&&t.length<26&&t.indexOf('{')<0&&t.indexOf('\n')<0&&t!=='Hide';});
  }
  function listChips(label){ return chipEls(label).map(function(c){ return c.textContent.trim(); }); }
  function clickChip(label, text){ var el=chipEls(label).find(function(c){return c.textContent.trim()===text;}); if(!el)return false; el.click(); return true; }
  function currentGT(){ var v=document.querySelector('.guiDropdowns [class*="-singleValue"], .guiDropdowns [class*="-single-value"]'); return v?v.textContent.trim():'ChipEV'; }

  function rowToSpot(x){
    var gt=x.simulation_type;
    return {
      path:'/tournaments/s/'+gt+'/'+x.stacksize+'/'+x.scenario+'/'+encodeURIComponent(x.category)+'/'+x.position_hero+'/'+(x.position_opp||'')+'//',
      fn:[gt,x.stacksize+'bb',x.scenario,x.category.replace(/[^A-Za-z0-9]+/g,'-').replace(/^-|-$/g,''),x.position_hero+(x.position_opp?('_vs_'+x.position_opp):''),'m'+x.id_matrix].join('_').replace(/\s+/g,'-'),
      meta:{ gameType:gt, stack:x.stacksize, scenario:x.scenario, category:x.category, hero:x.position_hero, villain:x.position_opp||null, raiseSize:x.raiseSize, multiway:x.multiway }
    };
  }

  async function harvestSpot(s){
    if (DONE[s.fn]) return 'skip';
    history.pushState({}, '', s.path); window.dispatchEvent(new PopStateEvent('popstate',{state:{}}));
    await sleep(CONFIG.DWELL_MS);
    var d = scrape(); if (d.nGrids===0) { await sleep(CONFIG.RETRY_EMPTY_MS); d = scrape(); }
    if (d.nGrids===0) return 'EMPTY';
    await post(s.fn, { fn:s.fn, url:location.href, extractedAt:new Date().toISOString(), meta:s.meta, legend:d.legend, nGrids:d.nGrids, grids:d.grids });
    DONE[s.fn]=true; saveDone(DONE);
    return 'ok';
  }

  var STOP=false;
  window.__PA = {
    running:true,
    progress:{ phase:'init', gt:'', stack:'', stackSpots:0, spotsDone:0, totalSaved:0, last:'' },
    stop:function(){ STOP=true; this.running=false; return 'stopping'; },
    resume:function(){ if(this.running) return 'running'; STOP=false; this.running=true; run(); return 'resumed'; },
    status:function(){ console.log('[PA]', JSON.stringify(this.progress)); return this.progress; }
  };

  async function waitCatalogFor(stack){
    var t0=Date.now();
    while (Date.now()-t0 < CONFIG.CATALOG_WAIT_MS) {
      var c=window.__PA_CAT;
      if (c && c.length && String(c[0].stacksize)===String(stack)) return c;
      await sleep(500);
    }
    return (window.__PA_CAT && window.__PA_CAT.length && String(window.__PA_CAT[0].stacksize)===String(stack)) ? window.__PA_CAT : null;
  }

  async function run(){
    var P=window.__PA.progress; P.gt=currentGT();
    var stacks=listChips('Hero Stack Size in BB');
    if (CONFIG.ONLY_STACKS.length) stacks=stacks.filter(function(s){return CONFIG.ONLY_STACKS.indexOf(s)>=0;});
    console.log('[PA] gt', P.gt, '| stacks', stacks.join(','));

    for (var si=0; si<stacks.length; si++){
      if (STOP){ window.__PA.running=false; return; }
      var st=stacks[si]; P.stack=st; P.phase='catalog';
      window.__PA_CAT=null;
      if (!clickChip('Hero Stack Size in BB', st)) { console.log('[PA] cannot click stack', st); continue; }
      await sleep(CONFIG.CHIP_SETTLE_MS);
      var cat=await waitCatalogFor(st);
      if (!cat) { P.last='no catalog for '+st; beacon(); console.log('[PA] no catalog for stack', st, '- skipping'); continue; }

      // scenario filter (catalog carries scenario; this game type is Regular-only here but keep general)
      var scenarios = CONFIG.ONLY_SCENARIOS.length ? CONFIG.ONLY_SCENARIOS : [].concat.apply([],[[...new Set(cat.map(function(x){return x.scenario;}))]]);
      var seen={}, spots=[];
      cat.forEach(function(x){ if(scenarios.indexOf(x.scenario)<0)return; if(!seen[x.id_matrix]){ seen[x.id_matrix]=1; spots.push(rowToSpot(x)); } });

      P.phase='harvest'; P.stackSpots=spots.length; P.spotsDone=0;
      console.log('[PA] stack', st, '-> spots', spots.length);
      for (var i=0;i<spots.length;i++){
        if (STOP){ window.__PA.running=false; return; }
        var res; try { res=await harvestSpot(spots[i]); } catch(e){ res='err'; }
        P.spotsDone=i+1; P.last=spots[i].fn+' ['+res+']';
        if (res==='ok') P.totalSaved++;
        if (i%4===0 || res!=='skip') beacon();
      }
      beacon();
    }
    P.phase='done'; beacon({done:true}); window.__PA.running=false;
    console.log('[PA] ALL DONE. saved this run', P.totalSaved);
  }

  console.log('[PA] v7 harvester starting.');
  run();
})();
