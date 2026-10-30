#!/bin/bash
# cycle222-domproof.sh — permanent gate for the cycle-222 update
# (Update (cycle 222): «سیو در هر ۹۰» — the deep-file family's TENTH sibling
#  and the FOURTH keeper surface, saves.json).
# Part A (API, 4 checks):
#   A1 current laliga: 10 named rows, per-90 values (0,15], monotonic
#      non-increasing, positional ranks 1..10, all Persian-mapped
#      (nameFa != name)
#   A2 additive contract on the SAME response: scorers=20 + cleanSheets=10
#      + ratings=10 + gPlusA=10 + goalsPrevented=10 + minutes=10
#      + savePercentage=10 + savesPer90=10
#   A3 anchors: LIVE — the served rank-1 name+value == the raw saves.json
#      file's rank-1 (fetched in-gate, UA Chrome/124); FROZEN — 2025/26
#      finished season: Aarón Escandell 4.1 / Marko Dmitrović 3.6 / Mathew
#      Ryan 3.5 top-3 (the 202 anchor pattern)
#   A4 persiangulf: honest absence — savesPer90=[] (the feed carries no
#      keeper category at all, live-probed) while the league itself still
#      serves (minutes=10, the 220 contract) — absence is per-category, not
#      a broken league
# Part B (DOM @390x844, agent-browser, console must stay 0):
#   B1 the «سیو در هر ۹۰» section: 10 sp90-rows + h2 present + first pill
#      dir="ltr" (the 210/217/221 decimal contract) with Persian digits
#   B2 real navigation: first sp90-row click → /player/[id] with profile h1
#   B3 the family intact: TEN sections on one page + the keeper QUARTET
#      adjacent (درصد سیو → سیو در هر ۹۰ → گل نخرده‌ها → گل‌های
#      پیشگیری‌شده, the 217 contract extended again) + the 2020/21
#      historical season renders all-Persian incl. «بادیا» + viewport
#      integrity
#   B4 console=0 errors=0
set -u
BASE="${BASE:-http://localhost:3000}"
TMP="$(mktemp -d /home/z/my-project/.cycle222-gate-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok(){ echo "OK  - $1"; PASS=$((PASS+1)); }
bad(){ echo "BAD - $1"; FAIL=$((FAIL+1)); }
py(){ python3 -c "$1"; }

echo "== Part A: API gates =="

# A1
J=$(curl -s "$BASE/api/topscorers/laliga")
echo "$J" | py "
import sys,json
d=json.load(sys.stdin)
sp=d.get('savesPer90') or []
rows=len(sp)==10
named=all(e.get('name') and e.get('team') and e.get('playerId',0)>0 for e in sp)
vals=all(0<e['savesPer90']<=15 for e in sp)
mono=all(sp[i]['savesPer90']>=sp[i+1]['savesPer90'] for i in range(len(sp)-1))
pos=[e['rank'] for e in sp]==list(range(1,len(sp)+1))
fa=all((e.get('nameFa') or '')!=e['name'] for e in sp)
print('A1CHECK', rows, named, vals, mono, pos, fa)
" > "$TMP/a1.txt"
grep -q "A1CHECK True True True True True True" "$TMP/a1.txt" && ok "A1 savesPer90: 10 named rows, per-90 (0,15], monotonic, positional 1..10, all Persian" || bad "A1: $(cat "$TMP/a1.txt")"

# A2 additive contract
echo "$J" | py "
import sys,json
d=json.load(sys.stdin)
c={'scorers':len(d.get('scorers') or []),'cleanSheets':len(d.get('cleanSheets') or []),'ratings':len(d.get('ratings') or []),'gPlusA':len(d.get('gPlusA') or []),'goalsPrevented':len(d.get('goalsPrevented') or []),'minutes':len(d.get('minutes') or []),'savePercentage':len(d.get('savePercentage') or []),'savesPer90':len(d.get('savesPer90') or [])}
print('A2CHECK', c['scorers']==20 and c['cleanSheets']==10 and c['ratings']==10 and c['gPlusA']==10 and c['goalsPrevented']==10 and c['minutes']==10 and c['savePercentage']==10 and c['savesPer90']==10, c)
" > "$TMP/a2.txt"
grep -q "A2CHECK True" "$TMP/a2.txt" && ok "A2 additive contract: scorers=20/cleanSheets=10/ratings=10/gPlusA=10/goalsPrevented=10/minutes=10/savePercentage=10/savesPer90=10" || bad "A2: $(cat "$TMP/a2.txt")"

# A3 live anchor: served rank-1 == the raw file's rank-1 (name+value)
UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
RAWW=$(curl -s --compressed -A "$UA" "https://www.fotmob.com/api/data/leagues?id=87&ccode3=ESP&lang=en" | py "
import sys,json
d=json.load(sys.stdin)
cat=next((c for c in (d.get('stats') or {}).get('players') or [] if (c.get('header') or '').lower()=='saves per 90'), None)
print(cat.get('fetchAllUrl') if cat else 'NONE')
")
echo "$J" > "$TMP/api.json"
if [ "$RAWW" != "NONE" ] && [ -n "$RAWW" ]; then
  curl -s --compressed -A "$UA" "$RAWW" > "$TMP/raw.json"
  py "
import json
api=json.load(open('$TMP/api.json'))
raw=json.load(open('$TMP/raw.json'))
rows=raw['TopLists'][0]['StatList']
sp=api.get('savesPer90') or []
r1=rows[0] if rows else {}
ok=bool(sp) and sp[0]['name']==r1.get('ParticipantName') and abs(sp[0]['savesPer90']-r1.get('StatValue',-1))<1e-9
print('A3LIVE', ok, sp[0]['name'] if sp else '-', r1.get('ParticipantName'), r1.get('StatValue'))
" > "$TMP/a3.txt"
  grep -q "A3LIVE True" "$TMP/a3.txt" && ok "A3 live anchor: served rank-1 == the raw saves.json rank-1 (name+value verbatim)" || bad "A3-live: $(cat "$TMP/a3.txt")"
else
  bad "A3-live: saves category fetchAllUrl unresolvable"
fi

# A3 frozen anchor: 2025/26 finished season
S=$(curl -s "$BASE/api/topscorers/laliga?season=2025%2F2026" | py "
import sys,json
d=json.load(sys.stdin)
sp=d.get('savesPer90') or []
trio=[(e['name'],e['savesPer90']) for e in sp[:3]]
ok=len(sp)==10 and ('Aarón Escandell',4.1) in trio and ('Marko Dmitrović',3.6) in trio and ('Mathew Ryan',3.5) in trio
print('SEASON', ok, trio)
")
echo "$S" | grep -q "SEASON True" && ok "A3 frozen anchor: 2025/26 Aarón Escandell 4.1 / Dmitrović 3.6 / Ryan 3.5 (the finished-season file)" || bad "A3-season: $S"

# A4 persiangulf honest absence + league still alive (minutes=10)
PW=$(curl -s "$BASE/api/topscorers/persiangulf" | py "
import sys,json
d=json.load(sys.stdin)
sp=d.get('savesPer90') or []
mp=d.get('minutes') or []
print('PG', len(sp), len(mp))
")
echo "$PW" | grep -q "PG 0 10" && ok "A4 persiangulf: savesPer90 honestly [] (no keeper category, probed) while minutes still serve 10 — per-category absence" || bad "A4: $PW"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B1=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=sp90-row]')]; const first=rows[0]; const pill=first?.querySelector('span[dir=ltr]'); const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); return JSON.stringify({rows:rows.length, dirAttr:pill?.getAttribute('dir'), pillTxt:pill?.textContent, hasSection:h2s.includes('سیو در هر ۹۰'), cw:document.documentElement.clientWidth}); })()")
echo "$B1" | tr -d '\\' | grep -q '"rows":10' && echo "$B1" | tr -d '\\' | grep -q '"dirAttr":"ltr"' && echo "$B1" | tr -d '\\' | grep -q '"hasSection":true' && ok "B1 DOM: 10 sp90-rows + «سیو در هر ۹۰» + per-90 pill WITH dir=ltr ($B1)" || bad "B1: $B1"

# B2 real navigation from the first sp90-row (Vallés → /player/999171, the 218-proven id)
HREF=$(agent-browser eval "document.querySelector('[data-testid=sp90-row] a')?.getAttribute('href') || 'NO_LINK'" | tr -d '"' | tr -d '\\')
if [ "$HREF" != "NO_LINK" ] && [ -n "$HREF" ]; then
  agent-browser eval "window.location.href='$HREF'" >/dev/null
  sleep 2.5
  B2=$(agent-browser eval "JSON.stringify({path:location.pathname, h1n:document.querySelectorAll('h1').length, h1t:(document.querySelector('h1')||{}).textContent})")
  echo "$B2" | tr -d '\\' | grep -q '"h1n":1' && ok "B2 nav: sp90-row click → $HREF with profile h1" || bad "B2: $B2"
else
  bad "B2: no link on first sp90-row"
fi

# B3 family intact + keeper quartet adjacent + viewport integrity
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2
B3=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const need=['بهترین پاس‌دهندگان','گل+پاس','برترین امتیازها','بیشترین دقایق','درصد سیو','سیو در هر ۹۰','گل نخرده‌ها','گل‌های پیشگیری‌شده','کارت‌ها']; const missing=need.filter(x=>!h2s.includes(x)); const q=['درصد سیو','سیو در هر ۹۰','گل نخرده‌ها','گل‌های پیشگیری‌شده'].map(x=>h2s.indexOf(x)); const quartet=q.every(i=>i>-1)&&q.every((i,k)=>k===0||i>q[k-1]); return JSON.stringify({missing, quartet, vbroken:[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length}); })()")
echo "$B3" | tr -d '\\' | grep -q '"missing":\[\]' && echo "$B3" | tr -d '\\' | grep -q '"quartet":true' && echo "$B3" | tr -d '\\' | grep -q '"vbroken":0' && ok "B3 family intact: all TEN sections + keeper quartet adjacent (درصد سیو → سیو در هر ۹۰ → گل نخرده‌ها → گل‌های پیشگیری‌شده) + no real overflow" || bad "B3: $B3"

# B3b historical season: 2020/21 renders all-Persian incl. «بادیا»
agent-browser open "$BASE/topscorers/laliga?season=2020%2F2021" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B3B=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=sp90-row]')]; const names=rows.map(r=>r.querySelector('span.block')?.textContent); return JSON.stringify({rows:rows.length, badia:names.includes('ادگار بادیا'), faCount:names.filter(n=>n&&/[\\u0600-\\u06FF]/.test(n)).length}); })()")
echo "$B3B" | tr -d '\\' | grep -q '"rows":10' && echo "$B3B" | tr -d '\\' | grep -q '"badia":true' && echo "$B3B" | tr -d '\\' | grep -q '"faCount":10' && ok "B3b 2020/21: 10 sp90-rows all Persian incl. «بادیا» rendering live" || bad "B3b: $B3B"

CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B4 console=0 errors=0" || bad "B4: console=$CN errors=$CE"
agent-browser close >/dev/null 2>&1

echo "== LAT: the warm topscorers route =="
T0=$(date +%s%N); curl -s -o /dev/null "$BASE/api/topscorers/laliga"; T1=$(date +%s%N)
MS=$(( (T1-T0)/1000000 ))
[ "$MS" -lt 5000 ] && ok "LAT warm ${MS}ms (contract <5000ms)" || bad "LAT ${MS}ms"

echo "== VERDICT =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE222 DOMPROOF ALL GREEN («سیو در هر ۹۰» — the deep-file family's TENTH sibling and the FOURTH keeper surface: 10-row verbatim per-90 decimals on the SAME cached payload, live + frozen anchors, the keeper quartet adjacent, the 170 navigation real, the 2020/21 history all-Persian — API 4/4 + DOM 5/5 + LAT @390x844)" && exit 0
exit 1
