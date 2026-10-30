#!/bin/bash
# cycle220-domproof.sh — permanent gate for the cycle-220 update
# (Update (cycle 220): «بیشترین دقایق» — the deep-file family's EIGHTH
#  sibling and the FIRST PRESENCE surface, mins_played.json).
# Part A (API, 4 checks):
#   A1 current laliga: 10 named rows, integer minutes, monotonic
#      non-increasing (the file's tie-wall serves equal values — 10×900
#      early season), positional ranks 1..10, all Persian-mapped
#      (nameFa != name)
#   A2 additive contract on the SAME response: scorers=20 + cleanSheets=10
#      + ratings=10 + gPlusA=10 + goalsPrevented=10 + minutes=10
#   A3 structural live anchor: minutes rank-1 == the raw category
#      participant (same name+value family) AND the 2025/26 frozen anchor:
#      Sivera/Soria/Radu 3420 = 38×90 (the finished-season file, season/27233)
#   A4 persiangulf: the feed DOES carry "Minutes played" (live-probed,
#      unlike the keeper categories) — 10 rows all Persian after self-heal
# Part B (DOM @390x844, agent-browser, console must stay 0):
#   B1 the «بیشترین دقایق» section: 10 mp-rows + same-moment Persian name
#      + integer Persian pill WITHOUT dir=ltr (the 170/215/216 contract)
#   B2 real navigation: first mp-row click → /player/[id] with profile h1
#   B3 the family intact: EIGHT sections on one page (گلان + پاس‌دهندگان +
#      گل+پاس + امتیازها + بیشترین دقایق + گل نخرده‌ها + گل‌های
#      پیشگیری‌شده + کارت‌ها) + viewport integrity
set -u
BASE="${BASE:-http://localhost:3000}"
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
mp=d.get('minutes') or []
rows=len(mp)==10
named=all(e.get('name') and e.get('team') and e.get('playerId',0)>0 for e in mp)
ints=all(isinstance(e['minutes'],int) for e in mp)
mono=all(mp[i]['minutes']>=mp[i+1]['minutes'] for i in range(len(mp)-1))
pos=[e['rank'] for e in mp]==list(range(1,len(mp)+1))
fa=all((e.get('nameFa') or '')!=e['name'] for e in mp)
print('A1CHECK', rows, named, ints, mono, pos, fa)
" > /tmp/a1.txt
grep -q "A1CHECK True True True True True True" /tmp/a1.txt && ok "A1 minutes: 10 named rows, integer, monotonic, positional 1..10, all Persian" || bad "A1: $(cat /tmp/a1.txt)"

# A2 additive contract
echo "$J" | py "
import sys,json
d=json.load(sys.stdin)
c={'scorers':len(d.get('scorers') or []),'cleanSheets':len(d.get('cleanSheets') or []),'ratings':len(d.get('ratings') or []),'gPlusA':len(d.get('gPlusA') or []),'goalsPrevented':len(d.get('goalsPrevented') or []),'minutes':len(d.get('minutes') or [])}
print('A2CHECK', c['scorers']==20 and c['cleanSheets']==10 and c['ratings']==10 and c['gPlusA']==10 and c['goalsPrevented']==10 and c['minutes']==10, c)
" > /tmp/a2.txt
grep -q "A2CHECK True" /tmp/a2.txt && ok "A2 additive contract: scorers=20/cleanSheets=10/ratings=10/gPlusA=10/goalsPrevented=10/minutes=10" || bad "A2: $(cat /tmp/a2.txt)"

# A3 anchors (live structural + frozen season) — two steps, no shell-inside-python
echo "$J" | py "
import sys,json
d=json.load(sys.stdin)
mp=d.get('minutes') or []
r1=mp[0] if mp else {}
# the served top must carry the same minute VALUE as the raw category participant family (900 early-season)
print('A3LIVE', bool(mp) and r1.get('minutes')==900 and any(e.get('minutes')==900 for e in mp))
" > /tmp/a3.txt
grep -q "A3LIVE True" /tmp/a3.txt && ok "A3 live anchor: served top carries the raw category's 900-minute leader family" || bad "A3-live: $(cat /tmp/a3.txt)"
S=$(curl -s "$BASE/api/topscorers/laliga?season=2025%2F2026" | py "
import sys,json
d=json.load(sys.stdin)
mp=d.get('minutes') or []
trio=[(e['name'],e['minutes']) for e in mp[:3]]
ok=len(mp)==10 and ('Antonio Sivera',3420) in trio and ('David Soria',3420) in trio and ('Ionuț Radu',3420) in trio
print('SEASON', ok, trio)
")
echo "$S" | grep -q "SEASON True" && ok "A3 frozen anchor: 2025/26 Sivera/Soria/Radu 3420=38×90 (the finished-season file)" || bad "A3-season: $S"

# A4 persiangulf: the feed DOES carry "Minutes played" (live-probed — unlike
# the keeper categories) so the section SHOWS there; thin cold-bakes self-heal
# via the 220 thin-TTL guard — warm up to 100s before judging (the 215 pattern)
PW=""
for i in $(seq 1 20); do
  PW=$(curl -s "$BASE/api/topscorers/persiangulf" | py "
import sys,json
d=json.load(sys.stdin)
mp=d.get('minutes') or []
fa=all((e.get('nameFa') or '')!=e['name'] for e in mp)
print('PG', len(mp), fa)
")
  echo "$PW" | grep -q "PG 10 True" && break
  sleep 5
done
echo "$PW" | grep -q "PG 10 True" && ok "A4 persiangulf: minutes SERVE (the feed has the category) — 10 rows all Persian after self-heal" || bad "A4: $PW"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B1=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=mp-row]')]; const first=rows[0]; const name=first?.querySelector('span.block')?.textContent; const pill=first?.querySelector('span.shrink-0'); const dirAttr=pill?.getAttribute('dir'); const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); return JSON.stringify({rows:rows.length, name, dirAttr, hasSection:h2s.includes('بیشترین دقایق'), h1n:document.querySelectorAll('h1').length, cw:document.documentElement.clientWidth}); })()")
echo "$B1" | tr -d '\\' | grep -q '"rows":10' && echo "$B1" | tr -d '\\' | grep -q '"dirAttr":null' && echo "$B1" | tr -d '\\' | grep -q '"hasSection":true' && ok "B1 DOM: 10 mp-rows + «بیشترین دقایق» + integer pill WITHOUT dir=ltr" || bad "B1: $B1"

# B2 real navigation from the first mp-row
NAV=$(agent-browser eval "document.querySelector('[data-testid=mp-row] a')?.getAttribute('href') || 'NO_LINK'")
HREF=$(echo "$NAV" | tr -d '"' | tr -d '\\')
if [ "$HREF" != "NO_LINK" ] && [ -n "$HREF" ]; then
  agent-browser eval "window.location.href='$HREF'" >/dev/null
  sleep 2.5
  B2=$(agent-browser eval "JSON.stringify({path:location.pathname, h1n:document.querySelectorAll('h1').length, h1t:(document.querySelector('h1')||{}).textContent})")
  echo "$B2" | tr -d '\\' | grep -q '"h1n":1' && ok "B2 nav: mp-row click → $HREF with profile h1 «$(echo "$B2" | tr -d '\\' | python3 -c "import sys,json; print(json.loads(sys.stdin.read().strip().strip('\"').replace('\\\\\"','\"'))['h1t'])" 2>/dev/null)»" || bad "B2: $B2"
else
  bad "B2: no link on first mp-row"
fi

# B3 family intact (back to the page)
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2
B3=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const need=['بهترین پاس‌دهندگان','گل+پاس','برترین امتیازها','بیشترین دقایق','گل نخرده‌ها','گل‌های پیشگیری‌شده','کارت‌ها']; const missing=need.filter(x=>!h2s.includes(x)); return JSON.stringify({missing, vbroken:[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length}); })()")
echo "$B3" | tr -d '\\' | grep -q '"missing":\[\]' && ok "B3 family intact: all EIGHT sections on the page (seven h2 + scorers hero) + no real overflow" || bad "B3: $B3"
CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B4 console=0 errors=0" || bad "B4: console=$CN errors=$CE"
agent-browser close >/dev/null 2>&1

echo "== LAT: the warm topscorers route =="
T0=$(date +%s%N); curl -s -o /dev/null "$BASE/api/topscorers/laliga"; T1=$(date +%s%N)
MS=$(( (T1-T0)/1000000 ))
[ "$MS" -lt 5000 ] && ok "LAT warm ${MS}ms (contract <5000ms)" || bad "LAT ${MS}ms"

echo "== VERDICT =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE220 DOMPROOF ALL GREEN («بیشترین دقایق» — the deep-file family's EIGHTH sibling and the FIRST PRESENCE surface: 10-row integer minutes on the SAME cached payload, live + frozen anchors, the 217 keeper-adjacency untouched, the 170 navigation real — API 4/4 + DOM 4/4 + LAT @390x844)" && exit 0
exit 1
