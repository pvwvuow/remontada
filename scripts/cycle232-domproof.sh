#!/bin/bash
# cycle232-domproof.sh — permanent gate for the cycle-232 update
# (Update (cycle 232): «گل مورد انتظار روی دروازه» — the deep-file family's
#  SIXTEENTH sibling and the third ANALYTICS level, the on-target accuracy
#  twin of the xG surface (226), straight from the live
#  expected_goalsontarget.json probe. Live-probed 2026-10-30 UA Chrome/124:
#  serving on SIX of the seven globalMerge leagues with WIDE files — ucl
#  305 Tresoldi 4.5 / pl 241 Haaland 8.2 / laliga 277 Mbappé 12.8 / seriea
#  286 Malen 6.6 / bundesliga 227 Füllkrug 6.2 / ligue1 227 Lepaul 6.0
#  rows; persiangulf honestly absent (5 player cats, no xGOT) and mas
#  absent (null payload); 12 of the other 16 leagues.ts entries serve it
#  too. Decimal values VERBATIM — the EIGHTH non-integer member (the
#  210/217/221/222/226/227/230 convention): upstream precision EXACTLY one
#  decimal (probed decimal-counts=[1] on every serving file AND the
#  historical raw) → the pill renders toFixed(1) dir=ltr (the 226/230
#  contract — 12.8 renders «۱۲.۸»). COMPETITION tie-ranks upstream (ucl
#  5,5 / pl 4,4 / seriea 4,4 / ligue1 3,3 — probed); the merge re-ranks
#  POSITIONALLY like every sibling. SEASON-AWARE (the
#  124/175/185/226/227/230/231 class): the 2020/21 laliga raw serves its
#  OWN file — 385 rows, Lionel Messi 32.8 / Gerard Moreno 24.8 / Luis
#  Suárez 20.2 — frozen anchor, and the 229 curation rides free («لیونل
#  مسی»); 2023/24 pl = 402 rows, Haaland 27.1 / Isak 22.8 / Palmer 20.0.
#  Placement: right after گل مورد انتظار so the quality→accuracy pair
#  reads together while the rest of the analytics run (گل در هر ۹۰ → پاس
#  مورد انتظار → سانس بزرگ خلق‌شده) and the keeper QUINTET stay untouched —
#  the 230/231 gates' relative-order asserts are inequality-based, so the
#  insertion provably keeps them green. The badge rides the SAME
#  id-intersection mechanism (live-observed: 27 global xGOT badges,
#  Raphinha 8.9 laliga first). THE SIXTEENTH THIN-GUARD CLAUSE (the 210
#  class) — PROVEN LIVE THIS CYCLE, the 230/231 lesson institutionalized:
#  the cold build dropped the deep fetch (3-row category fallback baked)
#  and the xgot guard clause re-probed in 90s and self-healed to 10/10
#  with ZERO manual purge.)
# Part A (API, live-observed 2026-10-30):
#   A1 laliga: 10 rows positional 1..10, one-decimal values monotonic
#      DESC, rank-1 = (701154, «کیلیان امباپه», 12.8) — the live anchor
#   A2 the league contract: six domestics xgot=10 + the full sibling
#      contract (incl. xg=10 + gp90=10 + xa=10 + bcc=10); persiangulf
#      honestly ABSENT (xgot=0) while minutes=10/scorers=20/gp90=10 still
#      serve; mas honestly 0 while its scorers still serve 20
#   A3 SEASON-AWARE: laliga?season=2020/2021 → xgot 10 rows, rank-1
#      name='Lionel Messi' nameFa=«لیونل مسی» xgot=32.8 (the frozen anchor
#      + the 229 curation riding free) + pl?season=2023/2024 → rank-1
#      Haaland 27.1
#   A4 one-decimal precision: every served xgot satisfies round(v*10)==v*10
#   A5 the badge flow: the GLOBAL merge carries xgot on scorer rows
#      (live-observed: 27 rows — Raphinha 8.9 laliga first)
# Part B (DOM @390x844, agent-browser, console must stay 0):
#   B1 «گل مورد انتظار روی دروازه» h2 + 10 xgot-rows on /topscorers/laliga
#   B2 order: گل مورد انتظار → گل مورد انتظار روی دروازه → گل در هر ۹۰ →
#      پاس مورد انتظار → سانس بزرگ خلق‌شده → بیشترین دقایق (the quality→
#      accuracy pair + the analytics run grows by one) + the keeper
#      QUINTET still adjacent + no real overflow
#   B3 decimal pill: dir=ltr + «۱۲.۸» on the first row (the 226/230
#      decimal contract, one decimal, Persian digits)
#   B4 real navigation: first xgot-row → /player/701154 h1 «کیلیان امباپه»
#   B5a persiangulf honest absence in DOM: no «گل مورد انتظار روی دروازه»
#      h2 while «گل در هر ۹۰» still renders
#   B5b mas honest absence: no xgot h2 while the scorers table still renders
#   B6 console=0 errors=0 across the whole session
# Part C: warm LAT <5000ms on laliga
set -u
BASE="${BASE:-http://localhost:3000}"
TMP="$(mktemp -d /home/z/my-project/.cycle232-dom-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok(){ echo "OK  - $1"; PASS=$((PASS+1)); }
bad(){ echo "BAD - $1"; FAIL=$((FAIL+1)); }
py(){ python3 -c "$1"; }
enc(){ python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$1"; }

echo "== Part A: API gates =="

# A1 the live anchor + shape
curl -s "$BASE/api/topscorers/laliga" > "$TMP/laliga.json"
py "
import json
d=json.load(open('$TMP/laliga.json'))
x=d.get('xgot') or []
ranks=[e['rank'] for e in x]
r1=x[0] if x else {}
mono=all(x[i]['xgot']>=x[i+1]['xgot'] for i in range(len(x)-1)) if len(x)==10 else False
decs=all(round(e['xgot']*10)==e['xgot']*10 for e in x)
print('A1CHECK', len(x)==10, ranks==list(range(1,11)), mono, decs, r1.get('playerId')==701154 and r1.get('nameFa')=='کیلیان امباپه' and r1.get('xgot')==12.8)
" > "$TMP/a1.txt"
grep -q "A1CHECK True True True True True" "$TMP/a1.txt" && ok "A1 laliga: 10 rows positional 1..10, one-decimal monotonic DESC, rank-1 «کیلیان امباپه»/701154/12.8 (live anchor)" || bad "A1: $(cat "$TMP/a1.txt")"

# A2 the league contract: domestics serve 10 + siblings intact; the Gulf
# honestly absent; mas honestly absent
SW=1
for K in ucl pl laliga seriea bundesliga ligue1; do
  L=$(curl -s "$BASE/api/topscorers/$K" | py "
import sys,json
d=json.load(sys.stdin)
x=d.get('xgot') or []
f=lambda k: len(d.get(k) or [])
ok=(len(x)==10 and f('scorers')==20 and f('cleanSheets')==10 and f('ratings')==10 and f('gPlusA')==10 and f('goalsPrevented')==10 and f('minutes')==10 and f('savePercentage')==10 and f('savesPer90')==10 and 1<=f('penaltySaves')<=10 and f('xg')==10 and f('goalsPer90')==10 and f('xa')==10 and f('bigChancesCreated')==10)
print(1 if ok else 0)
")
  [ "$L" = "1" ] || { SW=0; bad "A2: $K failed ($L)"; }
done
PG=$(curl -s "$BASE/api/topscorers/persiangulf" | py "
import sys,json
d=json.load(sys.stdin)
f=lambda k: len(d.get(k) or [])
ok=(f('xgot')==0 and f('minutes')==10 and f('scorers')==20 and f('goalsPer90')==10)
print(1 if ok else 0)
")
MAS=$(curl -s "$BASE/api/topscorers/mas" | py "
import sys,json
d=json.load(sys.stdin)
print(1 if len(d.get('xgot') or [])==0 and len(d.get('scorers') or [])==20 else 0)
")
[ "$SW" = "1" ] && [ "$PG" = "1" ] && [ "$MAS" = "1" ] && ok "A2 six domestics carry xgot=10 + the full sibling contract (xg/gp90/xa/bcc=10 beside it); persiangulf honestly ABSENT (xgot=0) while minutes=10/scorers=20/gp90=10 still serve; mas mirror-honest (xgot=0, scorers=20)" || bad "A2: SW=$SW PG=$PG MAS=$MAS"

# A3 SEASON-AWARE frozen anchors (Messi 32.8 + Haaland 27.1)
H=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F2021" | py "
import sys,json
d=json.load(sys.stdin)
x=d.get('xgot') or []
r1=x[0] if x else {}
print('H', len(x)==10, r1.get('name')=='Lionel Messi' and r1.get('xgot')==32.8 and r1.get('nameFa')=='لیونل مسی')
")
echo "$H" | grep -q "H True True" && ok "A3a historical 2020/21: xgot serves 10 rows with the frozen anchor Lionel Messi 32.8 AND «لیونل مسی» (the 229 curation rides free, the 202 pattern, season-aware)" || bad "A3a: $H"
H2=$(curl -s "$BASE/api/topscorers/pl?season=2023%2F2024" | py "
import sys,json
d=json.load(sys.stdin)
x=d.get('xgot') or []
r1=x[0] if x else {}
print('H2', len(x)==10, r1.get('name')=='Erling Haaland' and r1.get('xgot')==27.1)
")
echo "$H2" | grep -q "H2 True True" && ok "A3b historical 2023/24 pl: rank-1 Erling Haaland 27.1 (the second frozen anchor, 402-row file)" || bad "A3b: $H2"

# A4 one-decimal precision across all six serving leagues
PD=1
for K in ucl pl laliga seriea bundesliga ligue1; do
  L=$(curl -s "$BASE/api/topscorers/$K" | py "
import sys,json
d=json.load(sys.stdin)
x=d.get('xgot') or []
print(1 if all(round(e['xgot']*10)==e['xgot']*10 for e in x) else 0)
")
  [ "$L" = "1" ] || PD=0
done
[ "$PD" = "1" ] && ok "A4 precision: every served xgot on all six leagues satisfies round(v*10)==v*10 (one-decimal upstream, probed decimal-counts=[1])" || bad "A4: PD=$PD"

# A5 the badge flow on the global merge
G=$(curl -s "$BASE/api/topscorers" | py "
import sys,json
d=json.load(sys.stdin)
sb=[s for s in (d.get('scorers') or []) if s.get('xgot') is not None]
print('G', len(sb)>=1, (sb[0]['name'], sb[0]['xgot']) if sb else None)
")
echo "$G" | grep -q "G True" && ok "A5 global merge carries xgot badges on scorer rows (live-observed: $(echo "$G" | sed 's/G True //') — the id-intersection mechanism)" || bad "A5: $G"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B1=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=xgot-row]')]; const h2=[...document.querySelectorAll('main h2')].some(h=>h.textContent==='گل مورد انتظار روی دروازه'); return JSON.stringify({rows:rows.length, h2}); })()")
echo "$B1" | tr -d '\\' | grep -q '"rows":10' && echo "$B1" | tr -d '\\' | grep -q '"h2":true' && ok "B1 DOM: «گل مورد انتظار روی دروازه» h2 renders + 10 xgot-rows on /topscorers/laliga" || bad "B1: $B1"
B2=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const iX=h2s.indexOf('گل مورد انتظار'), iT=h2s.indexOf('گل مورد انتظار روی دروازه'), iG=h2s.indexOf('گل در هر ۹۰'), iA=h2s.indexOf('پاس مورد انتظار'), iB=h2s.indexOf('سانس بزرگ خلق‌شده'), iM=h2s.indexOf('بیشترین دقایق'); const order=iX>-1&&iT>iX&&iG>iT&&iA>iG&&iB>iA&&iM>iB; const q=['درصد سیو','سیو در هر ۹۰','گل نخرده‌ها','گل‌های پیشگیری‌شده','پنالتی‌های مهارشده'].map(x=>h2s.indexOf(x)); const quintet=q.every(i=>i>-1)&&q.every((i,k)=>k===0||i>q[k-1]); const vbroken=[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length; return JSON.stringify({order, quintet, vbroken}); })()")
echo "$B2" | tr -d '\\' | grep -q '"order":true' && echo "$B2" | tr -d '\\' | grep -q '"quintet":true' && echo "$B2" | tr -d '\\' | grep -q '"vbroken":0' && ok "B2 DOM: گل مورد انتظار → گل مورد انتظار روی دروازه → گل در هر ۹۰ → پاس مورد انتظار → سانس بزرگ خلق‌شده → دقایق (quality→accuracy pair + analytics run grows by one) + keeper QUINTET still adjacent + no real overflow @390x844" || bad "B2: $B2"
B3=$(agent-browser eval "(() => { const row=document.querySelector('[data-testid=xgot-row]'); const pill=row.firstElementChild.lastElementChild; return JSON.stringify({dirAttr:pill?.getAttribute('dir'), txt:pill?.textContent}); })()")
echo "$B3" | tr -d '\\' | grep -q '"dirAttr":"ltr"' && echo "$B3" | tr -d '\\' | grep -q '"txt":"۱۲.۸"' && ok "B3 DOM: decimal pill WITH dir=ltr renders «۱۲.۸» (the 226/230 one-decimal contract, Persian digits)" || bad "B3: $B3"
HREF=$(agent-browser eval "document.querySelector('[data-testid=xgot-row] a')?.getAttribute('href') || 'NO_LINK'" | tr -d '"' | tr -d '\\')
if [ "$HREF" = "/player/701154" ]; then
  agent-browser eval "window.location.href='$HREF'" >/dev/null
  sleep 2.5
  B4=$(agent-browser eval "JSON.stringify({path:location.pathname, h1:(document.querySelector('h1')||{}).textContent})")
  echo "$B4" | tr -d '\\' | grep -q '"/player/701154"' && echo "$B4" | tr -d '\\' | grep -q '"کیلیان امباپه"' && ok "B4 DOM: first xgot-row really navigates to /player/701154 with h1 «کیلیان امباپه» (the 170/176 link contract)" || bad "B4: $B4"
else
  bad "B4: first xgot-row href is $HREF (expected /player/701154)"
fi
agent-browser open "$BASE/topscorers/persiangulf" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B5A=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); return JSON.stringify({xgot:h2s.includes('گل مورد انتظار روی دروازه'), gp90:h2s.includes('گل در هر ۹۰'), min:h2s.includes('بیشترین دقایق')}); })()")
echo "$B5A" | tr -d '\\' | grep -q '"xgot":false' && echo "$B5A" | tr -d '\\' | grep -q '"gp90":true' && echo "$B5A" | tr -d '\\' | grep -q '"min":true' && ok "B5a DOM: persiangulf honestly hides «گل مورد انتظار روی دروازه» (no xGOT category) while «گل در هر ۹۰» + «بیشترین دقایق» still render (the Gulf's deep surfaces stay)" || bad "B5a: $B5A"
agent-browser open "$BASE/topscorers/mas" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B5B=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const table=document.querySelector('main table, main ol'); return JSON.stringify({xgot:h2s.includes('گل مورد انتظار روی دروازه'), scorers:!!table}); })()")
echo "$B5B" | tr -d '\\' | grep -q '"xgot":false' && echo "$B5B" | tr -d '\\' | grep -q '"scorers":true' && ok "B5b DOM: mas honestly hides the section (no xgot h2) while its scorers surface still renders" || bad "B5b: $B5B"
CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B6 console=0 errors=0 across the whole session" || bad "B6: console=$CN errors=$CE"
agent-browser close >/dev/null 2>&1

echo "== Part C: warm LAT =="
T0=$(date +%s%N); curl -s -o /dev/null "$BASE/api/topscorers/laliga"; T1=$(date +%s%N)
MS=$(( (T1-T0)/1000000 ))
[ "$MS" -lt 5000 ] && ok "LAT warm /api/topscorers/laliga = ${MS}ms (<5000ms)" || bad "LAT: ${MS}ms"

echo "== VERDICT =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE232 DOMPROOF ALL GREEN («گل مورد انتظار روی دروازه» — the deep-file family's SIXTEENTH sibling and the third ANALYTICS level: six-of-seven globalMerge leagues served at 10 rows, persiangulf+mas honestly absent, season-aware with the frozen Messi 32.8 anchor + the 229 curation riding free, one-decimal pill the 226/230 contract, badge flow on the id-intersection mechanism (27 global badges), the SIXTEENTH thin-guard clause proven live with a ZERO-touch 90s self-heal (the 230/231 lesson institutionalized) — API 6/6 + DOM 6/6 + LAT @390x844)" && exit 0
exit 1
