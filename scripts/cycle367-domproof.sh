#!/bin/bash
# cycle-367 DOM proof at 390x844 — the boards pipeline learns fmt=meter
# (m→km, the deepStatValueFa convention) and the LAST boards join:
# «مسافت پوشیده در هر بازی» (team 31/31) + «جمع مسافت پوشیده» /
# «مسافت در هر ۹۰ دقیقه» (player 45/46, Top scorer stays a documented
# duplicate). Probe 2026-11-02: meter boards live on pl/ucl (2/4 rich feeds).
#   1) /league/pl — team view: 31 categories + 2 kind toggles = 33 role=tab
#      buttons, distance chip present → podium Fulham ۱۱۹٫۴ کیلومتر
#   2) /league/pl — player view: 46+2=48 buttons, both distance chips present
#      → total-distance podium Pascal Groß ۱۰۷٫۴ کیلومتر, rows /player/-linked
#   3) /league/ucl — second meter feed serves the same chips
#   4) /league/iraq — honest absence: thin feed, zero banned chips
# Every page: scrollW=cw=390, console+page errors empty.
set -u
B=agent-browser

errs() {
  E=$($B errors --json 2>/dev/null | python3 -c 'import json,sys
try: print(len([e for e in json.load(sys.stdin)["data"]["errors"] if e.get("url")]))
except Exception: print("ERR")')
  C=$($B console 2>/dev/null | grep -ci error || true)
  echo "   appErr=$E consoleErr=$C"
}

nav() {
  $B errors --clear >/dev/null 2>&1
  $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B set viewport 390 844 >/dev/null 2>&1
}

js() { $B eval "$1" 2>&1; }

echo "=== P1: /league/pl — distance chip (team, meters→km) ==="
nav "http://localhost:3000/league/pl"
sleep 6
js "(() => { const tb=[...document.querySelectorAll('button')].find(b=>b.textContent.trim()==='آمار فصل'); if(!tb) return 'NO_TAB'; tb.click(); return 'tab_clicked'; })()"
sleep 2
js "(() => { const chips=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].map(b=>b.textContent.trim()); return JSON.stringify({teamButtons: chips.length, hasDistance: chips.includes('مسافت پوشیده در هر بازی')}); })()"
js "(() => { const chip=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].find(b=>b.textContent.trim()==='مسافت پوشیده در هر بازی'); if(!chip) return 'NO_DIST_CHIP'; chip.click(); return 'dist_clicked'; })()"
sleep 1
js "(() => { const sec=document.querySelector('[data-testid=league-boards]'); const rows=[...sec.querySelectorAll('a')].filter(a=>a.href.includes('/team/')); const sub=sec.querySelector('p.text-\\\\[10px\\\\]'); return JSON.stringify({sub: sub?sub.textContent.slice(0,55):null, podium: rows.slice(0,3).map(r=>r.textContent.trim().slice(0,42))}); })()"
js "JSON.stringify({scrollW: document.documentElement.scrollWidth, cw: document.documentElement.clientWidth})"
errs

echo "=== P2: /league/pl — player distance chips ==="
js "(() => { const pk=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].find(b=>b.textContent.trim()==='بازیکنان'); if(!pk) return 'NO_KIND_TOGGLE'; pk.click(); return 'players_kind'; })()"
sleep 1
js "(() => { const chips=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].map(b=>b.textContent.trim()); return JSON.stringify({playerButtons: chips.length, totalDist: chips.includes('جمع مسافت پوشیده'), dist90: chips.includes('مسافت در هر ۹۰ دقیقه')}); })()"
js "(() => { const chip=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].find(b=>b.textContent.trim()==='جمع مسافت پوشیده'); if(!chip) return 'NO_TOTAL_CHIP'; chip.click(); return 'total_clicked'; })()"
sleep 1
$B eval "(() => { const sec=document.querySelector('[data-testid=league-boards]'); const rows=[...sec.querySelectorAll('a')].filter(a=>a.href.includes('/player/')); return JSON.stringify({podiumRows: rows.length, allLinked: rows.length>0 && rows.every(a=>a.href.includes('/player/')), sample: rows.slice(0,3).map(a=>a.textContent.trim().slice(0,40))}); })()"
errs

echo "=== P3: /league/ucl — second meter feed ==="
nav "http://localhost:3000/league/ucl"
sleep 6
js "(() => { const tb=[...document.querySelectorAll('button')].find(b=>b.textContent.trim()==='آمار فصل'); if(!tb) return 'NO_TAB'; tb.click(); return 'tab_clicked'; })()"
sleep 2
js "(() => { const chips=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].map(b=>b.textContent.trim()); return JSON.stringify({teamButtons: chips.length, hasDistance: chips.includes('مسافت پوشیده در هر بازی')}); })()"
js "(() => { const chip=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].find(b=>b.textContent.trim()==='مسافت پوشیده در هر بازی'); if(!chip) return 'NO_DIST_CHIP'; chip.click(); return 'dist_clicked'; })()"
sleep 1
js "(() => { const sec=document.querySelector('[data-testid=league-boards]'); const rows=[...sec.querySelectorAll('a')].filter(a=>a.href.includes('/team/')); return JSON.stringify({podium: rows.slice(0,3).map(r=>r.textContent.trim().slice(0,42))}); })()"
$B eval "JSON.stringify({scrollW: document.documentElement.scrollWidth, cw: document.documentElement.clientWidth})"
errs

echo "=== P4: /league/iraq — honest absence ==="
nav "http://localhost:3000/league/iraq"
sleep 5
js "(() => { const tb=[...document.querySelectorAll('button')].find(b=>b.textContent.trim()==='آمار فصل'); if(!tb) return 'NO_TAB'; tb.click(); return 'tab_clicked'; })()"
sleep 2
js "(() => { const sec=document.querySelector('[data-testid=league-boards]'); const chips=sec? [...sec.querySelectorAll('button[role=tab]')].map(b=>b.textContent.trim()) : []; const banned=['مسافت پوشیده در هر بازی','جمع مسافت پوشیده','مسافت در هر ۹۰ دقیقه']; return JSON.stringify({boardExists: !!sec, chipsTotal: chips.length, bannedLeaked: banned.filter(b=>chips.includes(b))}); })()"
$B eval "JSON.stringify({scrollW: document.documentElement.scrollWidth, cw: document.documentElement.clientWidth})"
errs

echo "=== DONE ==="
