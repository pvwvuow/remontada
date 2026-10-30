#!/bin/bash
# cycle225-domproof.sh — permanent gate for the cycle-225 update
# (Update (cycle 225): «پنالتی‌های مهارشده» — the deep-file family's ELEVENTH
#  sibling and its FIFTH keeper surface, straight from the penalty_save.json
#  re-probe the 222/224 cards ordered (the category serves on SIX of the
#  seven leagues — ucl 2 / pl 2 / laliga 5 / seriea 5 / bundesliga 4 /
#  ligue1 3 rows; persiangulf honestly absent; files NATURALLY thin —
#  THE GUARD DECISION: no length-based thin guard anywhere (a <10 guard
#  would re-probe forever, the 176 red-cards lesson); the DROPPED-FETCH
#  class is guarded precisely via the penaltySavesDropped marker the build
#  sets when the category exists but the file fetch failed — the payload
#  re-probes in 90s. CURRENT-SEASON ONLY (the 132 class, probed: the
#  2020/21, 2023/24 and 2025/26 raws lack the category). The 224 search-fold
#  chain extends by one block — penalty-saves kings searchable too.)
# Part A (API, live-observed 2026-10-30):
#   A1 laliga: 5 rows (the FULL file, not the 3-row fallback — rows 4-5
#      Agirrezabala/Ryan prove the deep fetch merged), positional 1..5,
#      integer values, rank-1 = (999171, «آلوارو والس»)
#   A2 the 7-league natural-size contract (six serving leagues 1..10 rows
#      integer values; persiangulf honestly 0) + the additive sibling
#      contract intact (scorers=20/cs=10/rat=10/gpa=10/gp=10/min=10/
#      svpct=10/sp90=10)
#   A3 CURRENT-SEASON-ONLY: laliga?season=2020/2021 → penaltySaves=[] while
#      goalsPrevented still serves 10 (the sibling works historically)
#   A4 the 224 fold chain extends: «دامن» (Finn Dahmen 926445, the
#      bundesliga penalty-saves king) ≥1 + «والس» (999171) still ≥1
# Part B (DOM @390x844, agent-browser, console must stay 0):
#   B1 «پنالتی‌های مهارشده» h2 + 5 ps-rows on /topscorers/laliga
#   B2 the keeper QUINTET adjacent (درصد سیو → سیو در هر ۹۰ → گل نخرده‌ها →
#      گل‌های پیشگیری‌شده → پنالتی‌های مهارشده) + no real overflow
#   B3 integer pill convention: the ps-row value pill has NO dir attribute
#      (the 215/216 integer convention) and renders Persian digits
#   B4 real navigation: first ps-row → /player/999171 h1 «آلوارو والس»
#   B5 persiangulf: no پنالتی h2 while بیشترین دقایق serves 10 mp-rows
#   B6 console=0 errors=0 across the whole session
# Part C: warm LAT <5000ms on laliga
set -u
BASE="${BASE:-http://localhost:3000}"
TMP="$(mktemp -d /home/z/my-project/.cycle225-dom-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok(){ echo "OK  - $1"; PASS=$((PASS+1)); }
bad(){ echo "BAD - $1"; FAIL=$((FAIL+1)); }
py(){ python3 -c "$1"; }
enc(){ python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$1"; }

echo "== Part A: API gates =="

# A1 the FULL file merged (5 rows, not the 3-row fallback) + anchor
curl -s "$BASE/api/topscorers/laliga" > "$TMP/laliga.json"
py "
import json
d=json.load(open('$TMP/laliga.json'))
ps=d.get('penaltySaves') or []
ranks=[e['rank'] for e in ps]
vals=[e['penaltySaves'] for e in ps]
r1=ps[0] if ps else {}
ids={e.get('playerId') for e in ps}
print('A1CHECK', len(ps)==5, ranks==[1,2,3,4,5], all(isinstance(v,int) and v>=1 for v in vals), r1.get('playerId')==999171 and r1.get('nameFa')=='آلوارو والس', 1280020 in ids and 185644 in ids)
" > "$TMP/a1.txt"
grep -q "A1CHECK True True True True True" "$TMP/a1.txt" && ok "A1 laliga: 5 rows (FULL file — Agirrezabala/Ryan prove the deep merge), positional 1..5, integer values, rank-1 «آلوارو والس»/999171" || bad "A1: $(cat "$TMP/a1.txt")"

# A2 the 7-league natural-size contract + additive siblings intact
SW=1
for K in ucl pl laliga seriea bundesliga ligue1; do
  L=$(curl -s "$BASE/api/topscorers/$K" | py "
import sys,json
d=json.load(sys.stdin)
ps=d.get('penaltySaves') or []
ok_len=1<=len(ps)<=10
ok_int=all(isinstance(e['penaltySaves'],int) and e['penaltySaves']>=1 for e in ps)
ok_pos=[e['rank'] for e in ps]==list(range(1,len(ps)+1))
f=lambda k: len(d.get(k) or [])
ok_sib=(f('scorers')==20 and f('cleanSheets')==10 and f('ratings')==10 and f('gPlusA')==10 and f('goalsPrevented')==10 and f('minutes')==10 and f('savePercentage')==10 and f('savesPer90')==10)
print(1 if (ok_len and ok_int and ok_pos and ok_sib) else 0)
")
  [ "$L" = "1" ] || { SW=0; bad "A2: $K failed ($L)"; }
done
PG=$(curl -s "$BASE/api/topscorers/persiangulf" | py "
import sys,json
d=json.load(sys.stdin)
print(1 if len(d.get('penaltySaves') or [])==0 and len(d.get('scorers') or [])==20 else 0)
")
[ "$SW" = "1" ] && [ "$PG" = "1" ] && ok "A2 six serving leagues carry natural-size penalty lists (1..10 rows, integer, positional) + full sibling contract; persiangulf mirror-honest (0 penalty rows, scorers=20)" || bad "A2: SW=$SW PG=$PG"

# A3 CURRENT-SEASON-ONLY (the 132 class) — historical hides, sibling survives
H=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F2021" | py "
import sys,json
d=json.load(sys.stdin)
print('H', len(d.get('penaltySaves') or [])==0, len(d.get('goalsPrevented') or [])==10, d.get('selectedSeason'))
")
echo "$H" | grep -q "H True True 2020/2021" && ok "A3 historical 2020/21: penaltySaves honestly [] while goalsPrevented serves 10 — CURRENT-SEASON-ONLY (the 132 class), sibling intact" || bad "A3: $H"

# A4 the 224 fold chain extends to the new block
D=$(curl -s "$BASE/api/search?q=$(enc "دامن")" | py "
import sys,json
ps=json.load(sys.stdin).get('players') or []
h=[p for p in ps if p['playerId']==926445]
print('FD', bool(h) and h[0]['fa']=='فین دامن')
")
echo "$D" | grep -q "FD True" && ok "A4a fold extension: «دامن» (Finn Dahmen 926445, bundesliga penalty-saves king) searchable — the 225 block joined the 224 chain" || bad "A4a: $D"
V=$(curl -s "$BASE/api/search?q=$(enc "والس")" | py "
import sys,json
ps=json.load(sys.stdin).get('players') or []
print('VV', any(p['playerId']==999171 for p in ps))
")
echo "$V" | grep -q "VV True" && ok "A4b control intact: «والس» (999171) still searchable" || bad "A4b: $V"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B1=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=ps-row]')]; const h2=[...document.querySelectorAll('main h2')].some(h=>h.textContent==='پنالتی‌های مهارشده'); return JSON.stringify({rows:rows.length, h2}); })()")
echo "$B1" | tr -d '\\' | grep -q '"rows":5' && echo "$B1" | tr -d '\\' | grep -q '"h2":true' && ok "B1 DOM: «پنالتی‌های مهارشده» h2 renders + 5 ps-rows on /topscorers/laliga" || bad "B1: $B1"
B2=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const q=['درصد سیو','سیو در هر ۹۰','گل نخرده‌ها','گل‌های پیشگیری‌شده','پنالتی‌های مهارشده'].map(x=>h2s.indexOf(x)); const adj=q.every(i=>i>-1)&&q.every((i,k)=>k===0||i>q[k-1]); const vbroken=[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length; return JSON.stringify({quintet:adj, idx:q, vbroken}); })()")
echo "$B2" | tr -d '\\' | grep -q '"quintet":true' && echo "$B2" | tr -d '\\' | grep -q '"vbroken":0' && ok "B2 DOM: the keeper QUINTET adjacent (درصد سیو → سیو در هر ۹۰ → گل نخرده‌ها → گل‌های پیشگیری‌شده → پنالتی‌های مهارشده) + no real overflow @390x844" || bad "B2: $B2"
B3=$(agent-browser eval "(() => { const row=document.querySelector('[data-testid=ps-row]'); const pill=row.firstElementChild.lastElementChild; const txt=pill?.textContent; return JSON.stringify({dirAttr:pill?.getAttribute('dir'), txt}); })()")
echo "$B3" | tr -d '\\' | grep -q '"dirAttr":null' && echo "$B3" | tr -d '\\' | grep -q '"txt":"۱"' && ok "B3 DOM: integer pill convention — NO dir attribute (the 215/216 integer convention) + Persian digit «۱»" || bad "B3: $B3"
HREF=$(agent-browser eval "document.querySelector('[data-testid=ps-row] a')?.getAttribute('href') || 'NO_LINK'" | tr -d '"' | tr -d '\\')
if [ "$HREF" = "/player/999171" ]; then
  agent-browser eval "window.location.href='$HREF'" >/dev/null
  sleep 2.5
  B4=$(agent-browser eval "JSON.stringify({path:location.pathname, h1:(document.querySelector('h1')||{}).textContent})")
  echo "$B4" | tr -d '\\' | grep -q '"/player/999171"' && echo "$B4" | tr -d '\\' | grep -q '"آلوارو والس"' && ok "B4 DOM: first ps-row really navigates to /player/999171 with h1 «آلوارو والس» (the 170/176 link contract)" || bad "B4: $B4"
else
  bad "B4: first ps-row href is $HREF (expected /player/999171)"
fi
agent-browser open "$BASE/topscorers/persiangulf" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B5=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); return JSON.stringify({ps:h2s.includes('پنالتی‌های مهارشده'), minutes:h2s.includes('بیشترین دقایق'), mpRows:document.querySelectorAll('[data-testid=mp-row]').length}); })()")
echo "$B5" | tr -d '\\' | grep -q '"ps":false' && echo "$B5" | tr -d '\\' | grep -q '"minutes":true' && echo "$B5" | tr -d '\\' | grep -q '"mpRows":10' && ok "B5 DOM: persiangulf hides the penalty section (per-category honest absence) while بیشترین دقایق serves 10 mp-rows" || bad "B5: $B5"
CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B6 console=0 errors=0 across the whole session" || bad "B6: console=$CN errors=$CE"
agent-browser close >/dev/null 2>&1

echo "== Part C: warm LAT =="
T0=$(date +%s%N); curl -s -o /dev/null "$BASE/api/topscorers/laliga"; T1=$(date +%s%N)
MS=$(( (T1-T0)/1000000 ))
[ "$MS" -lt 5000 ] && ok "LAT warm /api/topscorers/laliga = ${MS}ms (<5000ms)" || bad "LAT: ${MS}ms"

echo "== VERDICT =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE225 DOMPROOF ALL GREEN («پنالتی‌های مهارشده» — the deep-file family's ELEVENTH sibling and the FIFTH keeper surface: naturally-thin files served at their true sizes, the dropped-fetch class guarded via the marker, current-season-only honesty, the 224 fold chain extended, quintet adjacent — API 4/4 + DOM 6/6 + LAT @390x844)" && exit 0
exit 1
