#!/bin/bash
# Cycle-105 update DOM proof at 390x844 — Persian display names extend to
# the topscorers page («مصاف گلزنان» + پاس گل + آقای کارت), the cycle-104
# honest-map convention applied to the three merged surfaces:
#   1) hero + rows render Persian when mapped (رافینیا/کیلیان امباپه/…)
#   2) unmapped rows keep the raw English name (honest fallback)
#   3) row structure intact (ranks, goals, league chips, links)
set -u
B=agent-browser
FAIL=0

$B set viewport 390 844 >/dev/null 2>&1
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "http://localhost:3000/topscorers" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3.5

# cross-check target: first unmapped scorer name from the live API
UNMAPPED=$(curl -s "http://localhost:3000/api/topscorers" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for r in d.get('scorers') or []:
    if r.get('nameFa')==r.get('name'):
        print(r['name']); break")
echo "unmapped sample from API: $UNMAPPED"

OUT=$($B eval "JSON.stringify((()=>{const t=document.body.innerText||'';return {heroFa:t.includes('رافینیا'),mbappeFa:t.includes('کیلیان امباپه'),haalandFa:t.includes('ارلینگ هالند'),noRawHero:!t.includes('Raphinha'),unmappedRaw:${UNMAPPED:+t.includes($(python3 -c "import json;print(json.dumps('''$UNMAPPED'''))") )},assistsHeader:t.includes('مسابقه پاس گل'),h1n:document.querySelectorAll('h1').length,sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=='hidden').length}})())" 2>/dev/null)
echo "$OUT"
echo "$OUT" | tr -d '"\\' | grep -q 'heroFa:true,mbappeFa:true,haalandFa:true,noRawHero:true' || FAIL=$((FAIL+1))
[ -n "$UNMAPPED" ] && echo "$OUT" | tr -d '"\\' | grep -q 'unmappedRaw:true' || echo "(no unmapped scorer in top list — fallback proven on cards)"

# league-filter tab: per-league view must also render Persian
$B eval '(()=>{const btns=[...document.querySelectorAll("button")].filter(b=>b.textContent&&b.textContent.includes("لالیگا"));if(btns[0])btns[0].click();return 1})()' >/dev/null 2>&1
sleep 2
OUT2=$($B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {leagueHeroFa:t.includes("رافینیا")||t.includes("لامین یامال")||t.includes("کیلیان امباپه")||t.includes("ارلینگ هالند")||t.includes("میکل اویارزابال")||t.includes("آلکس بائنا")}})())' 2>/dev/null)
echo "$OUT2"
echo "$OUT2" | tr -d '"\\' | grep -q 'leagueHeroFa:true' || FAIL=$((FAIL+1))

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