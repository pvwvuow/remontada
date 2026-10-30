#!/bin/bash
# cycle226-domproof.sh — permanent gate for the cycle-226 update
# (Update (cycle 226): «گل مورد انتظار» — the deep-file family's TWELFTH
#  sibling and its first pure-ANALYTICS surface, straight from the
#  expected_goals.json probe (the old remainders list turned out stale —
#  bracket 56 / transfers 57 / season selector 180 were already shipped; the
#  unserved-categories sweep found xG). Live-probed 2026-10-30 UA Chrome/124:
#  serves on SIX of the seven leagues with WIDE files (laliga 389 / ucl 479
#  rows — Mbappé 12.2 / Raphinha 9.2 / Yamal 7.0), persiangulf honestly
#  absent (no xG category). Decimal values VERBATIM — the FIFTH non-integer
#  member (the 210/217/221/222 convention), upstream precision EXACTLY one
#  decimal (probed: all 389 rows) → pill toFixed(1) dir=ltr. SEASON-AWARE
#  (the 124/175/185 class): the 2020/21 raw serves its OWN file — 471 rows,
#  Lionel Messi 23.9 / Gerard Moreno 19.0 / Benzema 18.8 — frozen anchor.
#  Standard wide-file thin guard (the 210 class) — PROVEN LIVE ON THIS
#  CYCLE: the cold build dropped the fetch (3 rows), the 90s guard
#  re-probed and self-healed to 10. The 224 search-fold chain grows to
#  NINE blocks («بودیمیر»/251269 searchable, zero fetch).)
# Part A (API, live-observed 2026-10-30):
#   A1 laliga: 10 rows positional 1..10, one-decimal floats monotonic,
#      rank-1 = (701154, «کیلیان امباپه», 12.2) — the live anchor
#   A2 the 7-league contract: six serving leagues xg=10 + sibling contract
#      intact (scorers=20 + the 10-row blocks + penalty natural sizes);
#      persiangulf honestly 0 while minutes still serve 10
#   A3 SEASON-AWARE: laliga?season=2020/2021 → xg 10 rows, rank-1
#      name='Lionel Messi' xg=23.9 (the frozen anchor) while penaltySaves
#      stays honestly 0 (the 132 class sibling)
#   A4 the fold chain: «بودیمیر» (251269) ≥1 + «امباپه» control = 2
# Part B (DOM @390x844, agent-browser, console must stay 0):
#   B1 «گل مورد انتظار» h2 + 10 xg-rows on /topscorers/laliga
#   B2 order: گل مورد انتظار between برترین امتیازها and بیشترین دقایق +
#      the keeper QUINTET still adjacent + no real overflow
#   B3 decimal pill: dir=ltr + «۱۲.۲» on the first row (toFixed(1))
#   B4 real navigation: first xg-row → /player/701154 h1 «کیلیان امباپه»
#   B5 persiangulf: no گل مورد انتظار h2 while بیشترین دقایق serves 10
#   B6 console=0 errors=0 across the whole session
# Part C: warm LAT <5000ms on laliga
set -u
BASE="${BASE:-http://localhost:3000}"
TMP="$(mktemp -d /home/z/my-project/.cycle226-dom-XXXXXX)"
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
xg=d.get('xg') or []
ranks=[e['rank'] for e in xg]
r1=xg[0] if xg else {}
mono=all(xg[i]['xg']>=xg[i+1]['xg'] for i in range(len(xg)-1)) if len(xg)==10 else False
one_dec=all(round(e['xg'],1)==e['xg'] for e in xg)
print('A1CHECK', len(xg)==10, ranks==list(range(1,11)), mono, one_dec, r1.get('playerId')==701154 and r1.get('nameFa')=='کیلیان امباپه' and abs(r1.get('xg',0)-12.2)<1e-9)
" > "$TMP/a1.txt"
grep -q "A1CHECK True True True True True" "$TMP/a1.txt" && ok "A1 laliga: 10 rows positional 1..10, one-decimal verbatim monotonic, rank-1 «کیلیان امباپه»/701154/12.2 (live anchor)" || bad "A1: $(cat "$TMP/a1.txt")"

# A2 the 7-league contract + siblings intact
SW=1
for K in ucl pl laliga seriea bundesliga ligue1; do
  L=$(curl -s "$BASE/api/topscorers/$K" | py "
import sys,json
d=json.load(sys.stdin)
xg=d.get('xg') or []
f=lambda k: len(d.get(k) or [])
ok=(len(xg)==10 and f('scorers')==20 and f('cleanSheets')==10 and f('ratings')==10 and f('gPlusA')==10 and f('goalsPrevented')==10 and f('minutes')==10 and f('savePercentage')==10 and f('savesPer90')==10 and 1<=f('penaltySaves')<=10)
print(1 if ok else 0)
")
  [ "$L" = "1" ] || { SW=0; bad "A2: $K failed ($L)"; }
done
PG=$(curl -s "$BASE/api/topscorers/persiangulf" | py "
import sys,json
d=json.load(sys.stdin)
print(1 if len(d.get('xg') or [])==0 and len(d.get('minutes') or [])==10 and len(d.get('scorers') or [])==20 else 0)
")
[ "$SW" = "1" ] && [ "$PG" = "1" ] && ok "A2 six serving leagues carry xg=10 + the full sibling contract; persiangulf mirror-honest (xg=0, minutes=10, scorers=20)" || bad "A2: SW=$SW PG=$PG"

# A3 SEASON-AWARE frozen anchor (Messi 23.9)
H=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F2021" | py "
import sys,json
d=json.load(sys.stdin)
xg=d.get('xg') or []
r1=xg[0] if xg else {}
print('H', len(xg)==10, r1.get('name')=='Lionel Messi' and abs(r1.get('xg',0)-23.9)<1e-9, len(d.get('penaltySaves') or [])==0)
")
echo "$H" | grep -q "H True True True" && ok "A3 historical 2020/21: xg serves 10 rows with the frozen anchor Lionel Messi 23.9 (the 202 pattern, season-aware) while penaltySaves stays honestly 0 (the 132 sibling)" || bad "A3: $H"

# A4 the fold chain extension
B=$(curl -s "$BASE/api/search?q=$(enc "بودیمیر")" | py "
import sys,json
ps=json.load(sys.stdin).get('players') or []
h=[p for p in ps if p['playerId']==251269]
print('AB', bool(h) and h[0]['fa']=='آنته بودیمیر')
")
echo "$B" | grep -q "AB True" && ok "A4a fold extension: «بودیمیر» (Ante Budimir 251269, the xG-4th king) searchable — the xG block joined the 224 chain (nine blocks)" || bad "A4a: $B"
M=$(curl -s "$BASE/api/search?q=$(enc "امباپه")" | py "import sys,json;print(len(json.load(sys.stdin).get('players') or []))")
[ "$M" -ge 2 ] && ok "A4b control intact: «امباپه» = $M (Ethan + Kylian)" || bad "A4b: $M"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B1=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=xg-row]')]; const h2=[...document.querySelectorAll('main h2')].some(h=>h.textContent==='گل مورد انتظار'); return JSON.stringify({rows:rows.length, h2}); })()")
echo "$B1" | tr -d '\\' | grep -q '"rows":10' && echo "$B1" | tr -d '\\' | grep -q '"h2":true' && ok "B1 DOM: «گل مورد انتظار» h2 renders + 10 xg-rows on /topscorers/laliga" || bad "B1: $B1"
B2=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const iR=h2s.indexOf('برترین امتیازها'), iX=h2s.indexOf('گل مورد انتظار'), iM=h2s.indexOf('بیشترین دقایق'); const order=iR>-1&&iX>iR&&iM>iX; const q=['درصد سیو','سیو در هر ۹۰','گل نخرده‌ها','گل‌های پیشگیری‌شده','پنالتی‌های مهارشده'].map(x=>h2s.indexOf(x)); const quintet=q.every(i=>i>-1)&&q.every((i,k)=>k===0||i>q[k-1]); const vbroken=[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length; return JSON.stringify({order, quintet, vbroken}); })()")
echo "$B2" | tr -d '\\' | grep -q '"order":true' && echo "$B2" | tr -d '\\' | grep -q '"quintet":true' && echo "$B2" | tr -d '\\' | grep -q '"vbroken":0' && ok "B2 DOM: xG between امتیازها and دقایق + keeper QUINTET still adjacent + no real overflow @390x844" || bad "B2: $B2"
B3=$(agent-browser eval "(() => { const row=document.querySelector('[data-testid=xg-row]'); const pill=row.firstElementChild.lastElementChild; return JSON.stringify({dirAttr:pill?.getAttribute('dir'), txt:pill?.textContent}); })()")
echo "$B3" | tr -d '\\' | grep -q '"dirAttr":"ltr"' && echo "$B3" | tr -d '\\' | grep -q '"txt":"۱۲.۲"' && ok "B3 DOM: decimal pill dir=ltr renders «۱۲.۲» (toFixed(1), the 217 display rule)" || bad "B3: $B3"
HREF=$(agent-browser eval "document.querySelector('[data-testid=xg-row] a')?.getAttribute('href') || 'NO_LINK'" | tr -d '"' | tr -d '\\')
if [ "$HREF" = "/player/701154" ]; then
  agent-browser eval "window.location.href='$HREF'" >/dev/null
  sleep 2.5
  B4=$(agent-browser eval "JSON.stringify({path:location.pathname, h1:(document.querySelector('h1')||{}).textContent})")
  echo "$B4" | tr -d '\\' | grep -q '"/player/701154"' && echo "$B4" | tr -d '\\' | grep -q '"کیلیان امباپه"' && ok "B4 DOM: first xg-row really navigates to /player/701154 with h1 «کیلیان امباپه» (the 170/176 link contract)" || bad "B4: $B4"
else
  bad "B4: first xg-row href is $HREF (expected /player/701154)"
fi
agent-browser open "$BASE/topscorers/persiangulf" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B5=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); return JSON.stringify({xg:h2s.includes('گل مورد انتظار'), minutes:h2s.includes('بیشترین دقایق'), mpRows:document.querySelectorAll('[data-testid=mp-row]').length}); })()")
echo "$B5" | tr -d '\\' | grep -q '"xg":false' && echo "$B5" | tr -d '\\' | grep -q '"minutes":true' && echo "$B5" | tr -d '\\' | grep -q '"mpRows":10' && ok "B5 DOM: persiangulf hides the xG section (per-category honest absence) while بیشترین دقایق serves 10 mp-rows" || bad "B5: $B5"
CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B6 console=0 errors=0 across the whole session" || bad "B6: console=$CN errors=$CE"
agent-browser close >/dev/null 2>&1

echo "== Part C: warm LAT =="
T0=$(date +%s%N); curl -s -o /dev/null "$BASE/api/topscorers/laliga"; T1=$(date +%s%N)
MS=$(( (T1-T0)/1000000 ))
[ "$MS" -lt 5000 ] && ok "LAT warm /api/topscorers/laliga = ${MS}ms (<5000ms)" || bad "LAT: ${MS}ms"

echo "== VERDICT =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE226 DOMPROOF ALL GREEN («گل مورد انتظار» — the deep-file family's TWELFTH sibling and the first ANALYTICS surface: wide files served at 10 rows, season-aware with the frozen Messi 23.9 anchor, the dropped-fetch self-heal proven live, fold chain nine blocks — API 4/4 + DOM 6/6 + LAT @390x844)" && exit 0
exit 1
