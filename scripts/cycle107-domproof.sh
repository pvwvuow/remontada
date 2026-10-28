#!/bin/bash
# Cycle-107 update DOM proof at 390x844 — «تکمیل قوس نام صادق»: the honest
# Persian name map reaches the last raw-name surfaces:
#   • league page «آقای گل» hero + rows + season-board player rows
#   • /topscorers/[league] hero + rows
#   • player-profile avatar initials follow the displayed Persian name
#   • honest fallback: unmapped board/scorer names stay raw English (API-cross-checked)
set -u
B=agent-browser
FAIL=0

$B set viewport 390 844 >/dev/null 2>&1
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1

# cross-check: player board containing an UNMAPPED row (its headerFa chip +
# one mapped row name from the SAME board) from the live standings API
read -r UNM_BOARD BOARD_FA BOARD_MAPPED <<<$(curl -s "http://localhost:3000/api/standings?league=pl" | python3 -c "
import json, sys
d = json.load(sys.stdin)
for b in d.get('boards') or []:
    if b.get('kind') != 'player':
        continue
    unm = next((r['name'] for r in b.get('rows', []) if r.get('nameFa') == r.get('name')), '')
    mpp = next((r['nameFa'] for r in b.get('rows', []) if r.get('nameFa') and r['nameFa'] != r['name']), '')
    if unm and mpp:
        print(unm.replace(' ', '·'), b.get('headerFa', '').replace(' ', '·'), mpp.replace(' ', '·')); sys.exit()
print('· · ·')
")
UNM_BOARD=${UNM_BOARD//·/ }; BOARD_FA=${BOARD_FA//·/ }; BOARD_MAPPED=${BOARD_MAPPED//·/ }
echo "API board sample: board=[$BOARD_FA] mapped=[$BOARD_MAPPED] unmapped=[$UNM_BOARD]"
UNM_JSON=$(python3 -c "import json;print(json.dumps('''$UNM_BOARD'''))")
BFA_JSON=$(python3 -c "import json;print(json.dumps('''$BOARD_FA'''))")
BMP_JSON=$(python3 -c "import json;print(json.dumps('''$BOARD_MAPPED'''))")

# ---------- 1) league page (/league/pl): «آقای گل» tab ----------
$B open "http://localhost:3000/league/pl" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3
$B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>x.textContent&&x.textContent.trim()==="آقای گل");if(b)b.click();return b?1:0})()' >/dev/null 2>&1
sleep 3
OUT=$($B eval "JSON.stringify((()=>{const t=document.body.innerText||'';return {scorerFa:t.includes('ارلینگ هالند'),noRawHaaland:!t.includes('Erling Haaland'),h1n:document.querySelectorAll('h1').length,sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=='hidden').length}})())" 2>/dev/null)
echo "LEAGUE-SCORERS-TAB: $OUT"
echo "$OUT" | tr -d '"\\' | grep -q 'scorerFa:true' || FAIL=$((FAIL+1))
echo "$OUT" | tr -d '"\\' | grep -q 'noRawHaaland:true' || FAIL=$((FAIL+1))
echo "$OUT" | tr -d '"\\' | grep -q 'h1n:1' || FAIL=$((FAIL+1))
echo "$OUT" | tr -d '"\\' | grep -q 'sw:390,cw:390' || FAIL=$((FAIL+1))
echo "$OUT" | tr -d '"\\' | grep -q 'vbroken:0' || FAIL=$((FAIL+1))

# ---------- 1b) «آمار فصل» tab: season boards → «بازیکنان» → target board ----------
$B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>x.textContent&&x.textContent.trim()==="آمار فصل");if(b)b.click();return b?1:0})()' >/dev/null 2>&1
sleep 3
$B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>x.textContent&&x.textContent.trim()==="بازیکنان");if(b)b.click();return b?1:0})()' >/dev/null 2>&1
sleep 1.5
$B eval "(()=>{const b=[...document.querySelectorAll(\"button\")].find(x=>x.textContent&&x.textContent.trim()===$BFA_JSON);if(b)b.click();return b?1:0})()" >/dev/null 2>&1
sleep 2
OUT1B=$($B eval "JSON.stringify((()=>{const t=document.body.innerText||'';return {boardFa:t.includes($BMP_JSON),unmappedBoardRaw:t.includes($UNM_JSON),boardsHeader:t.includes('برترین‌های رسمی فصل')}})())" 2>/dev/null)
echo "LEAGUE-BOARDS-TAB: $OUT1B"
echo "$OUT1B" | tr -d '"\\' | grep -q 'boardFa:true' || FAIL=$((FAIL+1))
[ -n "$UNM_BOARD" ] && echo "$OUT1B" | tr -d '"\\' | grep -q 'unmappedBoardRaw:true' || FAIL=$((FAIL+1))

# ---------- 2) per-league scorers page (/topscorers/pl) ----------
$B open "http://localhost:3000/topscorers/pl" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3
OUT2=$($B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {heroFa:t.includes("ارلینگ هالند")||t.includes("الکساندر ایساک")||t.includes("ژائو پدرو"),noRawHero:!t.includes("Erling Haaland"),h1n:document.querySelectorAll("h1").length}})())' 2>/dev/null)
echo "TOPSCORERS-PL: $OUT2"
echo "$OUT2" | tr -d '"\\' | grep -q 'heroFa:true' || FAIL=$((FAIL+1))
echo "$OUT2" | tr -d '"\\' | grep -q 'noRawHero:true' || FAIL=$((FAIL+1))
echo "$OUT2" | tr -d '"\\' | grep -q 'h1n:1' || FAIL=$((FAIL+1))

# ---------- 3) player profile (737066): h1 + avatar + console ----------
$B open "http://localhost:3000/player/737066" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.querySelector('h1') && document.querySelector('h1').innerText.length > 2" >/dev/null 2>&1
sleep 2.5
OUT3=$($B eval 'JSON.stringify((()=>{const h=document.querySelector("h1");return {h1:(h||{}).innerText||"",h1n:document.querySelectorAll("h1").length,sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length}})())' 2>/dev/null)
echo "PROFILE: $OUT3"
echo "$OUT3" | tr -d '"\\' | grep -q 'ارلینگ هالند' || FAIL=$((FAIL+1))
echo "$OUT3" | tr -d '"\\' | grep -q 'h1n:1' || FAIL=$((FAIL+1))
echo "$OUT3" | tr -d '"\\' | grep -q 'sw:390,cw:390' || FAIL=$((FAIL+1))
echo "$OUT3" | tr -d '"\\' | grep -q 'vbroken:0' || FAIL=$((FAIL+1))

C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception:
  print('ERR')")
E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  print(len([e for e in es if e.get('url')]))
except Exception:
  print('ERR')")
echo "console=$C appErrors=$E"
[ "$C" = "0" ] && [ "$E" = "0" ] || FAIL=$((FAIL+1))
echo "==="
echo "DOMPROOF_FAIL=$FAIL"
