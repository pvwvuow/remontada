#!/bin/bash
# cycle-366 DOM proof at 390x844 — the season-leaderboard catalog round 3:
# 4 team (defensive-volume family) + 21 player (output/per-90/GK/sprint
# families) podium categories join «برترین‌های رسمی فصل» in the آمار فصل tab.
#   1) /league/pl — team chips: the 4 new chips present (total 30), click
#      «تکل در هر بازی» → podium renders (Crystal Palace leads)
#   2) /league/pl — player kind: 11 spot-checked new chips (total 43), click
#      «پاس گل» → podium rows all /player/-linked
#   3) /league/laliga — new chips serve on a second rich league
#   4) /league/iraq — honest absence: thin feed → no board section, no leak
# Every page: sw=cw=390, console+page errors empty.
set -u
B=agent-browser

errs() {
  E=$($B errors --json 2>/dev/null | python3 -c 'import json,sys
try: print(len([e for e in json.load(sys.stdin)["data"]["errors"] if e.get("url")]))
except Exception: print("ERR")')
  C=$($B console 2>/dev/null | grep -ci error || true)
  echo "   appErr=$E consoleErr=$C"
}

nav() { # nav <url>
  $B errors --clear >/dev/null 2>&1
  $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B set viewport 390 844 >/dev/null 2>&1
}

js() { # js <expr> — eval with error propagation
  $B eval "$1" 2>&1
}

echo "=== P1: /league/pl — 4 new team chips + tackles podium ==="
nav "http://localhost:3000/league/pl"
sleep 5
js "(() => { const tb=[...document.querySelectorAll('button')].find(b=>b.textContent.trim()==='آمار فصل'); if(!tb) return 'NO_TAB'; tb.click(); return 'tab_clicked'; })()"
sleep 2
js "(() => { const chips=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].map(b=>b.textContent.trim()); const want=['تکل در هر بازی','قطع توپ در هر بازی','دفع توپ در هر بازی','پاس بلند دقیق در هر بازی']; const have=want.filter(w=>chips.includes(w)); return JSON.stringify({teamChipsTotal: chips.length, newPresent: have.length + '/4', missing: want.filter(w=>!chips.includes(w))}); })()"
js "(() => { const chip=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].find(b=>b.textContent.trim()==='تکل در هر بازی'); if(!chip) return 'NO_TACKLE_CHIP'; chip.click(); return 'tackle_clicked'; })()"
sleep 1
js "(() => { const sec=document.querySelector('[data-testid=league-boards]'); const rows=[...sec.querySelectorAll('a')].filter(a=>a.href.includes('/team/')); const sub=sec.querySelector('p.text-\\\\[10px\\\\]'); return JSON.stringify({sub: sub?sub.textContent.slice(0,55):null, podium: rows.slice(0,3).map(r=>r.textContent.trim().slice(0,38))}); })()"
errs

echo "=== P2: /league/pl — 11 new player chips + assists podium ==="
js "(() => { const pk=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].find(b=>b.textContent.trim()==='بازیکنان'); if(!pk) return 'NO_KIND_TOGGLE'; pk.click(); return 'players_kind'; })()"
sleep 1
js "(() => { const chips=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].map(b=>b.textContent.trim()); const want=['پاس گل','گل + پاس گل','دقایق بازی','گل در هر ۹۰ دقیقه','گل انتظاری در هر ۹۰ دقیقه','گل انتظاری روی چارچوب (xGOT)','شوت در هر ۹۰ دقیقه','پاس منجر انتظاری در هر ۹۰ دقیقه','کارت قرمز','مهار پنالتی','اسپرینت در هر ۹۰ دقیقه']; const have=want.filter(w=>chips.includes(w)); return JSON.stringify({playerChipsTotal: chips.length, newPresent: have.length + '/11', missing: want.filter(w=>!chips.includes(w))}); })()"
js "(() => { const chip=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].find(b=>b.textContent.trim()==='پاس گل'); if(!chip) return 'NO_ASSIST_CHIP'; chip.click(); return 'assist_clicked'; })()"
sleep 1
$B eval "(() => { const sec=document.querySelector('[data-testid=league-boards]'); const rows=[...sec.querySelectorAll('a')].filter(a=>a.href.includes('/player/')); return JSON.stringify({podiumRows: rows.length, allLinked: rows.length>0 && rows.every(a=>a.href.includes('/player/')), sample: rows.slice(0,3).map(a=>a.textContent.trim().slice(0,35))}); })()"
errs

echo "=== P3: viewport + second rich league (laliga) ==="
$B eval "JSON.stringify({sw: screen.width, cw: document.documentElement.clientWidth})"
nav "http://localhost:3000/league/laliga"
sleep 5
js "(() => { const tb=[...document.querySelectorAll('button')].find(b=>b.textContent.trim()==='آمار فصل'); if(!tb) return 'NO_TAB'; tb.click(); return 'tab_clicked'; })()"
sleep 2
js "(() => { const chips=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].map(b=>b.textContent.trim()); return JSON.stringify({chipsTotal: chips.length, tackles: chips.includes('تکل در هر بازی'), assists: chips.includes('پاس گل'), xgot: chips.includes('گل انتظاری روی چارچوب (xGOT)'), penaltySaves: chips.includes('مهار پنالتی')}); })()"
errs

echo "=== P4: /league/iraq — honest absence on thin feed ==="
nav "http://localhost:3000/league/iraq"
sleep 5
js "(() => { const tb=[...document.querySelectorAll('button')].find(b=>b.textContent.trim()==='آمار فصل'); if(!tb) return 'NO_TAB'; tb.click(); return 'tab_clicked'; })()"
sleep 2
js "(() => { const sec=document.querySelector('[data-testid=league-boards]'); const chips=sec? [...sec.querySelectorAll('button[role=tab]')].map(b=>b.textContent.trim()) : []; const banned=['تکل در هر بازی','پاس گل','مهار پنالتی','گل انتظاری روی چارچوب (xGOT)','اسپرینت در هر ۹۰ دقیقه']; return JSON.stringify({boardExists: !!sec, chipsTotal: chips.length, bannedLeaked: banned.filter(b=>chips.includes(b))}); })()"
$B eval "JSON.stringify({sw: screen.width, cw: document.documentElement.clientWidth})"
errs

echo "=== DONE ==="
