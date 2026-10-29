#!/usr/bin/env bash
# cycle-164 fix probe B (permanent gate): three live behaviors as regression:
#   B1 season deep-link /league/pl?season=2024/2025 — the cycle-99 feature.
#      Live truth (od-verified 2026-10-30): h1 = «پریمیرلیگ انگلیس» (NOT
#      «لیگ برتر» — the first draft asserted the wrong string, D5), standings
#      table 20 rows + scorers table 20 rows (two tbodys — the first draft
#      counted 40 across both), first row = لیورپول ۳۸ ۲۵ ۹ ۴ ۸۴ (champions
#      row), selector value + URL param stay in sync, label «فصل ۲۰۲۴/۲۰۲۵».
#   B2 /topscorers index — default filter «همه لیگ‌ها» shows ZERO dedicated
#      links BY DESIGN (the link renders only when a chip is active); after a
#      REAL chip click (سوئیس) exactly one Link → /topscorers/swiss appears.
#      Selectors od-verified: a[href^='/topscorers/'] (the first draft copied
#      the display-mangled «aref^=» form out of the terminal — the 157
#      byte-lesson hitting my own output channel; never copy selector text
#      from mangled display, od-check the file).
#   B3 gibberish search via real UI input events — page must stay alive,
#      exactly one h1, no horizontal overflow, console clean.
set -u
B=agent-browser
BASE="http://localhost:3000"
$B set viewport 390 844 >/dev/null
BAD=0

collect() {
  local FEAT="$1" LABEL="$2" OUT C E RC=0
  OUT=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null | tr -d '"\\')
  C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception: print('ERR')")
  E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  print(len([e for e in es if e.get('url')]))
except Exception: print('ERR')")
  echo "$LABEL → $OUT | feat=$FEAT | console=$C appErrors=$E"
  echo "$FEAT" | grep -q "false\|null" && RC=1
  [ -z "$FEAT" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
  return 0
}

open_page() {
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 3
}

# B1: season deep-link — historical 2024/2025 premier league table really loads
open_page "$BASE/league/pl?season=2024%2F2025"
FEAT=$($B eval "JSON.stringify(({h1:((document.querySelector('h1')||{}).innerText||'')===''||((document.querySelector('h1')||{}).innerText||'').includes('پریمیرلیگ'),rowTb:document.querySelectorAll('tbody').length===2,rowsPl:document.querySelectorAll('tbody')[0] ? document.querySelectorAll('tbody')[0].querySelectorAll('tr').length : 0,rowsSc:document.querySelectorAll('tbody')[1] ? document.querySelectorAll('tbody')[1].querySelectorAll('tr').length : 0,seasonInPage:(document.body.innerText||'').includes('۲۰۲۴'),selectorVal:(document.querySelector('select')||{}).value||'',urlHasSeason:location.search.indexOf('season=2024')>-1,liverpool:((document.querySelectorAll('tbody')[0]||{}).innerText||'').indexOf('لیورپول')>-1}))" 2>/dev/null | tr -d '"\\')
collect "$FEAT" "B1 season deep-link 2024/2025"

# B2: /topscorers index — default: no dedicated link; REAL chip click سوئیس → exactly one link
open_page "$BASE/topscorers"
FEAT1=$($B eval "JSON.stringify(({defaultLinks:document.querySelectorAll('a[href^=\"/topscorers/\"]').length,chipSwiss:[...document.querySelectorAll('button')].some(function(b){return (b.textContent||'').indexOf('سوئیس')>-1})}))" 2>/dev/null | tr -d '"\\')
$B eval "(function(){const t=[...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').indexOf('سوئیس')>-1});if(t)t.click();return t?'clicked':'no-chip'})()" >/dev/null 2>&1
sleep 3
FEAT2=$($B eval "JSON.stringify(({linksAfter:document.querySelectorAll('a[href^=\"/topscorers/\"]').length,direct:!!document.querySelector('a[href=\"/topscorers/swiss\"]'),linkFa:(document.body.innerText||'').indexOf('صفحه اختصاصی گلزنان')>-1}))" 2>/dev/null | tr -d '"\\')
collect "pre:$FEAT1 post:$FEAT2" "B2 topscorers index + chip click"

# B3: gibberish search via real UI — honest no-crash
open_page "$BASE/"
$B eval "(function(){const i=document.querySelector('input[type=search],input');if(!i)return 'no-input';const set=Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype,'value').set;set.call(i,'zzzqqqxxx');i.dispatchEvent(new Event('input',{bubbles:true}));i.dispatchEvent(new Event('change',{bubbles:true}));const f=i.closest('form');if(f)f.dispatchEvent(new Event('submit',{bubbles:true,cancelable:true}));return 'typed'})()" >/dev/null 2>&1
sleep 3
FEAT=$($B eval "JSON.stringify(({alive:(document.body.innerText||'').length>60,h1n:document.querySelectorAll('h1').length,sw:document.documentElement.scrollWidth}))" 2>/dev/null | tr -d '"\\')
collect "$FEAT" "B3 gibberish search no-crash"

echo "PROBE_B_BAD=$BAD"
[ "$BAD" -eq 0 ] && echo "PROBE_B OK" || echo "PROBE_B FAILED"
