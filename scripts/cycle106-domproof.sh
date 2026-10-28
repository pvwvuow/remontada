#!/bin/bash
# Cycle-106 update DOM proof at 390x844 — the honest Persian name map extends
# to the match page surfaces (cycle-104/105 registered candidate):
#   • scoreboard: POTM strip + scorer strips render Persian when mapped
#   • «ترکیب» tab: pitch chip labels + bench + coach row
#   • «بازیکن‌ها» tab: per-player rating rows
#   • honest fallback: unmapped names stay raw English (cross-checked with API)
#   • /player/737066: profile h1 renders «ارلینگ هالند» (playerData v5 nameFa)
set -u
B=agent-browser
FAIL=0

$B set viewport 390 844 >/dev/null 2>&1
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1

# unmapped samples cross-checked from the live API (honest-fallback proof)
read -r UNM_SCORER UNM_CHIP <<<$(curl -s "http://localhost:3000/api/match/5749720" | python3 -c "
import json, sys
d = json.load(sys.stdin)
un = next((s['player'].replace(' ', '·') for s in d.get('scorers') or [] if s.get('nameFa') == s.get('player')), '')
lu = d.get('lineups') or {}
chip = ''
for side in ('home', 'away'):
    t = lu.get(side) or {}
    for row in (t.get('rows') or []):
        for p in (row.get('players') or []):
            if p.get('nameFa') == p.get('name'):
                chip = p['name'].replace(' ', '·'); break
        if chip: break
    if chip: break
print(un, chip)
")
# '·' marks the space so the shell never splits a two-word name; restore before use
UNM_SCORER=${UNM_SCORER//·/ }
UNM_CHIP=${UNM_CHIP//·/ }
echo "API unmapped samples: scorer=[$UNM_SCORER] chip=[$UNM_CHIP]"
UN_SCORER_JSON=$(python3 -c "import json;print(json.dumps('''$UNM_SCORER'''))")
UN_CHIP_JSON=$(python3 -c "import json;print(json.dumps('''$UNM_CHIP'''))")

# ---------- 1) match scoreboard (default events tab) ----------
$B open "http://localhost:3000/match/5749720" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3.5
OUT=$($B eval "JSON.stringify((()=>{const t=document.body.innerText||'';return {potmFa:t.includes('ساموئل مبانگولا'),noRawPotm:!t.includes('Samuel Mbangula'),scorerFa:t.includes('توماسو پوبگا')||t.includes('ساموئل مبانگولا'),unmappedScorerRaw:t.includes($UN_SCORER_JSON),h1n:document.querySelectorAll('h1').length,sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=='hidden').length}})())" 2>/dev/null)
echo "SCOREBOARD: $OUT"
echo "$OUT" | tr -d '"\\' | grep -q 'potmFa:true,noRawPotm:true' || FAIL=$((FAIL+1))
echo "$OUT" | tr -d '"\\' | grep -q 'unmappedScorerRaw:true' || FAIL=$((FAIL+1))
echo "$OUT" | tr -d '"\\' | grep -q 'h1n:1' || FAIL=$((FAIL+1))
echo "$OUT" | tr -d '"\\' | grep -q 'sw:390,cw:390' || FAIL=$((FAIL+1))
echo "$OUT" | tr -d '"\\' | grep -q 'vbroken:0' || FAIL=$((FAIL+1))

# ---------- 2) «ترکیب» tab: pitch chips + bench + coach ----------
$B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>x.textContent&&x.textContent.trim()==="ترکیب");if(b)b.click();return b?1:0})()' >/dev/null 2>&1
sleep 2.5
OUT2=$($B eval "JSON.stringify((()=>{const t=document.body.innerText||'';return {lineupCoachRow:t.includes('سرمربی'),coachFa:t.includes('روبن آموریم')||t.includes('رافائله پالادینو'),chipFa:t.includes('ساموئل مبانگولا')||t.includes('آردون یاشاری')||t.includes('پرویس استوپینان'),unmappedChipRaw:t.includes($UN_CHIP_JSON),benchHeader:t.includes('بازیکنان ذخیره')}})())" 2>/dev/null)
echo "LINEUPS: $OUT2"
echo "$OUT2" | tr -d '"\\' | grep -q 'lineupCoachRow:true' || FAIL=$((FAIL+1))
echo "$OUT2" | tr -d '"\\' | grep -q 'coachFa:true' || FAIL=$((FAIL+1))
echo "$OUT2" | tr -d '"\\' | grep -q 'chipFa:true' || FAIL=$((FAIL+1))
echo "$OUT2" | tr -d '"\\' | grep -q 'unmappedChipRaw:true' || FAIL=$((FAIL+1))

# ---------- 3) «بازیکن‌ها» tab: rating rows ----------
$B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>x.textContent&&x.textContent.trim()==="بازیکن‌ها");if(b)b.click();return b?1:0})()' >/dev/null 2>&1
sleep 2.5
OUT3=$($B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {playersFa:t.includes("ساموئل مبانگولا")||t.includes("توماسو پوبگا")||t.includes("پرویس استوپینان")}})())' 2>/dev/null)
echo "PLAYERS-TAB: $OUT3"
echo "$OUT3" | tr -d '"\\' | grep -q 'playersFa:true' || FAIL=$((FAIL+1))

# ---------- 4) player profile h1 (737066) ----------
$B open "http://localhost:3000/player/737066" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.querySelector('h1') && document.querySelector('h1').innerText.length > 2" >/dev/null 2>&1
sleep 2.5
OUT4=$($B eval 'JSON.stringify((()=>{const h=document.querySelector("h1");return {h1:(h||{}).innerText||"",h1n:document.querySelectorAll("h1").length,sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length}})())' 2>/dev/null)
echo "PROFILE: $OUT4"
echo "$OUT4" | tr -d '"\\' | grep -q 'ارلینگ هالند' || FAIL=$((FAIL+1))
echo "$OUT4" | tr -d '"\\' | grep -q 'h1n:1' || FAIL=$((FAIL+1))
echo "$OUT4" | tr -d '"\\' | grep -q 'sw:390,cw:390' || FAIL=$((FAIL+1))
echo "$OUT4" | tr -d '"\\' | grep -q 'vbroken:0' || FAIL=$((FAIL+1))

# ---------- console / app errors ----------
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
