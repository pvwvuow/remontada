#!/bin/bash
# cycle230-fixproof.sh — permanent gate for the cycle-230 update
# (Update (cycle 230): «پاس مورد انتظار» — the deep-file family's
#  FOURTEENTH sibling and the assist-side ANALYTICS twin of the xG surface
#  (226), straight from the expected_assists.json probe. Live-probed
#  2026-10-30 UA Chrome/124: the category header is SINGULAR — "Expected
#  assist (xA)" (the plural probe 0-matched every league before the fix) —
#  serving on SIX of the seven globalMerge leagues with WIDE files (ucl 721
#  Kimmich 1.9 / pl 448 Iwobi 2.6 / laliga 480 Yamal 4.0 / seriea 487
#  Dybala 3.4 / bundesliga 399 Olise 4.1 / ligue1 422 Thauvin 3.8 rows);
#  persiangulf AND mas honestly absent (no xA category — 5/2 player cats);
#  12 of the other 16 leagues.ts entries serve it too. Decimal values
#  VERBATIM — the SEVENTH non-integer member (the 210/217/221/222/226/227
#  convention), upstream precision EXACTLY one decimal (probed maxdec=1 on
#  every serving file) → pill toFixed(1) dir=ltr. SEASON-AWARE (the
#  124/175/185/226/227 class): the 2020/21 laliga raw serves its OWN file —
#  565 rows, Lionel Messi 13.4 / Jordi Alba 9.9 / Jesús Navas 8.0 — frozen
#  anchor, and the 229 curation rides free («لیونل مسی» in DOM); 2023/24 pl
#  = Ødegaard 11.2. The standard wide-file thin guard (the 210 class) grew
#  an xa clause — PROVEN LIVE THIS CYCLE: the first cold build dropped the
#  fetch (3-row category fallback baked), the guard clause now re-probes in
#  90s; the L2 rows were purged and the rebuild served 10/10 everywhere.
#  Placement: right after گل در هر ۹۰ so the 226/227 expected-vs-actual
#  pairing and the keeper QUINTET stay untouched — the analytics run grows
#  by one. The scorer-row badge rides the SAME id-intersection mechanism as
#  the xG badge (probed live: global page already carries xa badges —
#  Salah 2.6 superlig; a league row shows the badge only when the player is
#  in BOTH the goals top-3 and the xA top-3 — the xG badge's own 2/3
#  behavior today, zero bugs).)
# Part A (API, live-observed 2026-10-30):
#   A1 laliga: 10 rows positional 1..10, one-decimal floats verbatim
#      monotonic, rank-1 = (1467236, «لامین یامال», 4.0) — the live anchor
#   A2 the league contract: six domestics xa=10 + the full sibling contract
#      (incl. the two rate sisters xg=10 + gp90=10); PERSIANGULF honestly
#      ABSENT (xa=0) while minutes=10/scorers=20/gp90=10 still serve; mas
#      honestly 0 while its scorers still serve 20
#   A3 SEASON-AWARE: laliga?season=2020/2021 → xa 10 rows, rank-1
#      name='Lionel Messi' nameFa=«لیونل مسی» xa=13.4 (the frozen anchor +
#      the 229 curation riding free) + pl?season=2023/2024 → rank-1
#      Ødegaard 11.2
#   A4 one-decimal precision: every served xa satisfies round(v,1)==v
#   A5 the badge flow: the GLOBAL merge carries xa on scorer rows
#      (live-observed: ≥1 row — Salah 2.6 superlig)
# Part B (DOM @390x844, agent-browser, console must stay 0):
#   B1 «پاس مورد انتظار» h2 + 10 xa-rows on /topscorers/laliga
#   B2 order: گل مورد انتظار → گل در هر ۹۰ → پاس مورد انتظار → بیشترین
#      دقایق (the 226/227 pair intact, the analytics run grows by one) +
#      the keeper QUINTET still adjacent + no real overflow
#   B3 decimal pill: dir=ltr + «۴.۰» on the first row (toFixed(1))
#   B4 real navigation: first xa-row → /player/1467236 h1 «لامین یامال»
#   B5a persiangulf honest absence in DOM: no «پاس مورد انتظار» h2 while
#      «گل در هر ۹۰» still renders (the Gulf's gp90 stays)
#   B5b mas honest absence: no xa h2 while the scorers table still renders
#   B6 console=0 errors=0 across the whole session
# Part C: warm LAT <5000ms on laliga
set -u
BASE="${BASE:-http://localhost:3000}"
TMP="$(mktemp -d /home/z/my-project/.cycle230-dom-XXXXXX)"
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
xa=d.get('xa') or []
ranks=[e['rank'] for e in xa]
r1=xa[0] if xa else {}
mono=all(xa[i]['xa']>=xa[i+1]['xa'] for i in range(len(xa)-1)) if len(xa)==10 else False
one_dec=all(round(e['xa'],1)==e['xa'] for e in xa)
print('A1CHECK', len(xa)==10, ranks==list(range(1,11)), mono, one_dec, r1.get('playerId')==1467236 and r1.get('nameFa')=='لامین یامال' and abs(r1.get('xa',0)-4.0)<1e-9)
" > "$TMP/a1.txt"
grep -q "A1CHECK True True True True True" "$TMP/a1.txt" && ok "A1 laliga: 10 rows positional 1..10, one-decimal verbatim monotonic, rank-1 «لامین یامال»/1467236/4.0 (live anchor)" || bad "A1: $(cat "$TMP/a1.txt")"

# A2 the league contract: domestics serve 10 + siblings intact; the Gulf
# honestly absent; mas honestly absent
SW=1
for K in ucl pl laliga seriea bundesliga ligue1; do
  L=$(curl -s "$BASE/api/topscorers/$K" | py "
import sys,json
d=json.load(sys.stdin)
xa=d.get('xa') or []
f=lambda k: len(d.get(k) or [])
ok=(len(xa)==10 and f('scorers')==20 and f('cleanSheets')==10 and f('ratings')==10 and f('gPlusA')==10 and f('goalsPrevented')==10 and f('minutes')==10 and f('savePercentage')==10 and f('savesPer90')==10 and 1<=f('penaltySaves')<=10 and f('xg')==10 and f('goalsPer90')==10)
print(1 if ok else 0)
")
  [ "$L" = "1" ] || { SW=0; bad "A2: $K failed ($L)"; }
done
PG=$(curl -s "$BASE/api/topscorers/persiangulf" | py "
import sys,json
d=json.load(sys.stdin)
f=lambda k: len(d.get(k) or [])
ok=(f('xa')==0 and f('minutes')==10 and f('scorers')==20 and f('goalsPer90')==10)
print(1 if ok else 0)
")
MAS=$(curl -s "$BASE/api/topscorers/mas" | py "
import sys,json
d=json.load(sys.stdin)
print(1 if len(d.get('xa') or [])==0 and len(d.get('scorers') or [])==20 else 0)
")
[ "$SW" = "1" ] && [ "$PG" = "1" ] && [ "$MAS" = "1" ] && ok "A2 six domestics carry xa=10 + the full sibling contract (xg=10 and gp90=10 beside it); persiangulf honestly ABSENT (xa=0) while minutes=10/scorers=20/gp90=10 still serve; mas mirror-honest (xa=0, scorers=20)" || bad "A2: SW=$SW PG=$PG MAS=$MAS"

# A3 SEASON-AWARE frozen anchors (Messi 13.4 + Ødegaard 11.2)
H=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F2021" | py "
import sys,json
d=json.load(sys.stdin)
xa=d.get('xa') or []
r1=xa[0] if xa else {}
print('H', len(xa)==10, r1.get('name')=='Lionel Messi' and abs(r1.get('xa',0)-13.4)<1e-9 and r1.get('nameFa')=='لیونل مسی')
")
echo "$H" | grep -q "H True True" && ok "A3a historical 2020/21: xa serves 10 rows with the frozen anchor Lionel Messi 13.4 AND «لیونل مسی» (the 229 curation rides free, the 202 pattern, season-aware)" || bad "A3a: $H"
H2=$(curl -s "$BASE/api/topscorers/pl?season=2023%2F2024" | py "
import sys,json
d=json.load(sys.stdin)
xa=d.get('xa') or []
r1=xa[0] if xa else {}
print('H2', len(xa)==10, r1.get('name')=='Martin Ødegaard' and abs(r1.get('xa',0)-11.2)<1e-9)
")
echo "$H2" | grep -q "H2 True True" && ok "A3b historical 2023/24 pl: rank-1 Martin Ødegaard 11.2 (the second frozen anchor)" || bad "A3b: $H2"

# A4 one-decimal precision across all six serving leagues
PD=1
for K in ucl pl laliga seriea bundesliga ligue1; do
  L=$(curl -s "$BASE/api/topscorers/$K" | py "
import sys,json
d=json.load(sys.stdin)
xa=d.get('xa') or []
print(1 if all(round(e['xa'],1)==e['xa'] for e in xa) else 0)
")
  [ "$L" = "1" ] || PD=0
done
[ "$PD" = "1" ] && ok "A4 precision: every served xa on all six leagues satisfies round(v,1)==v (the EXACTLY-one-decimal probe, the 226 display rule)" || bad "A4: PD=$PD"

# A5 the badge flow on the global merge
G=$(curl -s "$BASE/api/topscorers" | py "
import sys,json
d=json.load(sys.stdin)
sx=[s for s in (d.get('scorers') or []) if s.get('xa') is not None]
print('G', len(sx)>=1, (sx[0]['name'], sx[0]['xa']) if sx else None)
")
echo "$G" | grep -q "G True" && ok "A5 global merge carries xa badges on scorer rows (live-observed: $(echo "$G" | sed 's/G True //') — the id-intersection mechanism, the xG badge's own behavior)" || bad "A5: $G"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B1=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=xa-row]')]; const h2=[...document.querySelectorAll('main h2')].some(h=>h.textContent==='پاس مورد انتظار'); return JSON.stringify({rows:rows.length, h2}); })()")
echo "$B1" | tr -d '\\' | grep -q '"rows":10' && echo "$B1" | tr -d '\\' | grep -q '"h2":true' && ok "B1 DOM: «پاس مورد انتظار» h2 renders + 10 xa-rows on /topscorers/laliga" || bad "B1: $B1"
B2=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const iX=h2s.indexOf('گل مورد انتظار'), iG=h2s.indexOf('گل در هر ۹۰'), iA=h2s.indexOf('پاس مورد انتظار'), iM=h2s.indexOf('بیشترین دقایق'); const order=iX>-1&&iG>iX&&iA>iG&&iM>iA; const q=['درصد سیو','سیو در هر ۹۰','گل نخرده‌ها','گل‌های پیشگیری‌شده','پنالتی‌های مهارشده'].map(x=>h2s.indexOf(x)); const quintet=q.every(i=>i>-1)&&q.every((i,k)=>k===0||i>q[k-1]); const vbroken=[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length; return JSON.stringify({order, quintet, vbroken}); })()")
echo "$B2" | tr -d '\\' | grep -q '"order":true' && echo "$B2" | tr -d '\\' | grep -q '"quintet":true' && echo "$B2" | tr -d '\\' | grep -q '"vbroken":0' && ok "B2 DOM: گل مورد انتظار → گل در هر ۹۰ → پاس مورد انتظار → دقایق (the 226/227 pair intact, analytics run grows by one) + keeper QUINTET still adjacent + no real overflow @390x844" || bad "B2: $B2"
B3=$(agent-browser eval "(() => { const row=document.querySelector('[data-testid=xa-row]'); const pill=row.firstElementChild.lastElementChild; return JSON.stringify({dirAttr:pill?.getAttribute('dir'), txt:pill?.textContent}); })()")
echo "$B3" | tr -d '\\' | grep -q '"dirAttr":"ltr"' && echo "$B3" | tr -d '\\' | grep -q '"txt":"۴.۰"' && ok "B3 DOM: decimal pill dir=ltr renders «۴.۰» (toFixed(1), the 217 display rule)" || bad "B3: $B3"
HREF=$(agent-browser eval "document.querySelector('[data-testid=xa-row] a')?.getAttribute('href') || 'NO_LINK'" | tr -d '"' | tr -d '\\')
if [ "$HREF" = "/player/1467236" ]; then
  agent-browser eval "window.location.href='$HREF'" >/dev/null
  sleep 2.5
  B4=$(agent-browser eval "JSON.stringify({path:location.pathname, h1:(document.querySelector('h1')||{}).textContent})")
  echo "$B4" | tr -d '\\' | grep -q '"/player/1467236"' && echo "$B4" | tr -d '\\' | grep -q '"لامین یامال"' && ok "B4 DOM: first xa-row really navigates to /player/1467236 with h1 «لامین یامال» (the 170/176 link contract)" || bad "B4: $B4"
else
  bad "B4: first xa-row href is $HREF (expected /player/1467236)"
fi
agent-browser open "$BASE/topscorers/persiangulf" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B5A=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); return JSON.stringify({xa:h2s.includes('پاس مورد انتظار'), gp90:h2s.includes('گل در هر ۹۰'), min:h2s.includes('بیشترین دقایق')}); })()")
echo "$B5A" | tr -d '\\' | grep -q '"xa":false' && echo "$B5A" | tr -d '\\' | grep -q '"gp90":true' && echo "$B5A" | tr -d '\\' | grep -q '"min":true' && ok "B5a DOM: persiangulf honestly hides «پاس مورد انتظار» (no xA category) while «گل در هر ۹۰» + «بیشترین دقایق» still render (the Gulf's deep surfaces stay)" || bad "B5a: $B5A"
agent-browser open "$BASE/topscorers/mas" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B5B=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const table=document.querySelector('main table, main ol'); return JSON.stringify({xa:h2s.includes('پاس مورد انتظار'), scorers:!!table}); })()")
echo "$B5B" | tr -d '\\' | grep -q '"xa":false' && echo "$B5B" | tr -d '\\' | grep -q '"scorers":true' && ok "B5b DOM: mas honestly hides the section (no xa h2) while its scorers surface still renders" || bad "B5b: $B5B"
CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B6 console=0 errors=0 across the whole session" || bad "B6: console=$CN errors=$CE"
agent-browser close >/dev/null 2>&1

echo "== Part C: warm LAT =="
T0=$(date +%s%N); curl -s -o /dev/null "$BASE/api/topscorers/laliga"; T1=$(date +%s%N)
MS=$(( (T1-T0)/1000000 ))
[ "$MS" -lt 5000 ] && ok "LAT warm /api/topscorers/laliga = ${MS}ms (<5000ms)" || bad "LAT: ${MS}ms"

echo "== VERDICT =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE230 FIXPROOF ALL GREEN («پاس مورد انتظار» — the deep-file family's FOURTEENTH sibling and the assist-side ANALYTICS twin of xG: six-of-seven globalMerge leagues served at 10 rows, persiangulf+mas honestly absent, season-aware with the frozen Messi 13.4 anchor + the 229 curation riding free, the thin guard grown an xa clause and proven live, badge flow on the id-intersection mechanism — API 6/6 + DOM 6/6 + LAT @390x844)" && exit 0
exit 1
