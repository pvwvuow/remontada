#!/bin/bash
# cycle-365 DOM proof at 390x844 — the season-leaderboard catalog expands
# (cycle-196 pattern, round 2): 12 team + 10 player podium categories join
# «برترین‌های رسمی فصل» in the آمار فصل tab.
#   1) /league/pl — آمار فصل: new team chips present («گل انتظاری خورده (xGA)»,
#      «موقعیت طلایی», «لمس در محدودهٔ حریف», «کارت قرمز»), click xGA → podium
#      rows render with values
#   2) /league/pl — player kind toggle → new player chips («گل انتظاری (xG)»,
#      «شوت در چارچوب در هر ۹۰ دقیقه», «پاس خط‌شکن در هر ۹۰ دقیقه») → xG podium
#   3) /league/laliga — same chips serve on a second rich league
#   4) /league/iraq — honest absence: thin feed → new chips absent, old tab
#      intact, no empty board shell
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

echo "=== P1: /league/pl — new team chips + xGA podium ==="
nav "http://localhost:3000/league/pl"
sleep 5
js "(() => { const tb=[...document.querySelectorAll('button')].find(b=>b.textContent.trim()==='آمار فصل'); if(!tb) return 'NO_TAB'; tb.click(); return 'tab_clicked'; })()"
sleep 2
js "(() => { const chips=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].map(b=>b.textContent.trim()); const want=['گل انتظاری خورده (xGA)','موقعیت طلایی','موقعیت طلایی از دست رفته','لمس در محدودهٔ حریف','پاس عرضی دقیق در هر بازی','گل خورده از ضربات ایستگاهی','پنالتی داده‌شده','مهار در هر بازی','خطا در هر بازی','کارت قرمز','برد توپ در ثلث پایانی']; const have=want.filter(w=>chips.includes(w)); return JSON.stringify({chipsTotal: chips.length, newPresent: have.length + '/' + want.length, missing: want.filter(w=>!chips.includes(w))}); })()"
js "(() => { const chip=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].find(b=>b.textContent.trim()==='گل انتظاری خورده (xGA)'); if(!chip) return 'NO_XGA_CHIP'; chip.click(); return 'xga_clicked'; })()"
sleep 1
js "(() => { const sec=document.querySelector('[data-testid=league-boards]'); const rows=[...sec.querySelectorAll('.flex.flex-col > a, .flex.flex-col > div')].filter(r=>r.querySelector('.tabular-persian[aria-label]')); const sub=sec.querySelector('p.text-\\[10px\\]'); return JSON.stringify({sub: sub?sub.textContent.slice(0,60):null, podium: rows.map(r=>r.textContent.trim().slice(0,40)).slice(0,3)}); })()"
errs

echo "=== P2: /league/pl — player kind + new player podiums ==="
js "(() => { const pk=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].find(b=>b.textContent.trim()==='بازیکنان'); if(!pk) return 'NO_KIND_TOGGLE'; pk.click(); return 'players_kind'; })()"
sleep 1
js "(() => { const chips=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].map(b=>b.textContent.trim()); const want=['گل انتظاری (xG)','شوت در چارچوب در هر ۹۰ دقیقه','xG + xA در هر ۹۰ دقیقه','بلاک در هر ۹۰ دقیقه','دفع توپ در هر ۹۰ دقیقه','اقدام دفاعی در هر ۹۰ دقیقه','پاس خط‌شکن در هر ۹۰ دقیقه','پنالتی گرفته‌شده','پاس بلند دقیق در هر ۹۰ دقیقه','بردهای توپ در هر ۹۰ دقیقه']; const have=want.filter(w=>chips.includes(w)); return JSON.stringify({newPlayerPresent: have.length + '/' + want.length, missing: want.filter(w=>!chips.includes(w))}); })()"
js "(() => { const chip=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].find(b=>b.textContent.trim()==='گل انتظاری (xG)'); if(!chip) return 'NO_XG_CHIP'; chip.click(); return 'xg_clicked'; })()"
sleep 1
$B eval "(() => { const sec=document.querySelector('[data-testid=league-boards]'); const rows=[...sec.querySelectorAll('a')].filter(a=>a.href.includes('/player/')); return JSON.stringify({podiumRows: rows.length, allLinked: rows.length>0 && rows.every(a=>a.href.includes('/player/')), sample: rows.slice(0,3).map(a=>a.textContent.trim().slice(0,35))}); })()"
errs

echo "=== P3: viewport + second rich league (laliga) ==="
$B eval "JSON.stringify({sw: screen.width, cw: document.documentElement.clientWidth})"
nav "http://localhost:3000/league/laliga"
sleep 5
js "(() => { const tb=[...document.querySelectorAll('button')].find(b=>b.textContent.trim()==='آمار فصل'); if(!tb) return 'NO_TAB'; tb.click(); return 'tab_clicked'; })()"
sleep 2
js "(() => { const chips=[...document.querySelectorAll('[data-testid=league-boards] button[role=tab]')].map(b=>b.textContent.trim()); return JSON.stringify({chipsTotal: chips.length, xga: chips.includes('گل انتظاری خورده (xGA)'), redCards: chips.includes('کارت قرمز'), touches: chips.includes('لمس در محدودهٔ حریف')}); })()"
errs

echo "=== P4: /league/iraq — honest absence on thin feed ==="
nav "http://localhost:3000/league/iraq"
sleep 5
js "(() => { const tb=[...document.querySelectorAll('button')].find(b=>b.textContent.trim()==='آمار فصل'); if(!tb) return 'NO_TAB'; tb.click(); return 'tab_clicked'; })()"
sleep 2
js "(() => { const sec=document.querySelector('[data-testid=league-boards]'); const chips=sec? [...sec.querySelectorAll('button[role=tab]')].map(b=>b.textContent.trim()) : []; const banned=['گل انتظاری خورده (xGA)','موقعیت طلایی','کارت قرمز','گل انتظاری (xG)','پاس خط‌شکن در هر ۹۰ دقیقه']; return JSON.stringify({boardExists: !!sec, chipsTotal: chips.length, bannedLeaked: banned.filter(b=>chips.includes(b))}); })()"
$B eval "JSON.stringify({sw: screen.width, cw: document.documentElement.clientWidth})"
errs

echo "=== DONE ==="
