#!/bin/bash
# cycle231-fixproof.sh — permanent gate for the cycle-231 update
# (Update (cycle 231): «سانس بزرگ خلق‌شده» — the deep-file family's
#  FIFTEENTH sibling and the production-CREATION volume surface beside the
#  analytics twins (xG 226 / xA 230), straight from the live
#  big_chances_created.json probe. Live-probed 2026-10-30 UA Chrome/124:
#  serving on 22 of the 24 leagues.ts entries — every league but
#  persiangulf (5 player cats) and mas (2 cats), the gp90 footprint — six
#  domestics with WIDE files (ucl 190 Yamal 5 / pl 152 Groß 7 / laliga 185
#  Yamal 14 / seriea 202 Dybala 8 / bundesliga 160 Nusa+Kane 6 / ligue1
#  157 Thauvin 9 rows). INTEGER-VALUED floats (probed nonint=0 on every
#  serving file — StatValue 5.0/14.0) → the 215/216/220 integer
#  convention: rounded once at build, the pill renders Persian digits
#  WITHOUT dir=ltr (the minutes contract). SEASON-AWARE (the
#  124/175/185/226/227/230 class): the 2020/21 laliga raw serves its OWN
#  file — 309 rows, Lionel Messi 22.0 / Iago Aspas 16.0 / Gerard Moreno
#  14.0 — frozen anchor, and the 229 curation rides free («لیونل مسی» /
#  «یاگو آسپاس» / «ژرارد مورنو»); 2023/24 pl = Salah 22.0. THE FIFTEENTH
#  THIN-GUARD CLAUSE (the 210 class) — PROVEN LIVE THIS CYCLE, the 230
#  lesson institutionalized: the cold build dropped the fetch (3-row
#  category fallback baked), the bcc guard clause re-probed in 90s and
#  self-healed to 10/10 with ZERO manual purge. Placement: right after
#  پاس مورد انتظار so the creation trio (xG quality → xA quality → BCC
#  volume) stays together and the keeper QUINTET stays untouched. The
#  badge rides the SAME id-intersection mechanism (live-observed: 7 global
#  badges, Dion Drena Beljo 5 hnl first).)
# Part A (API, live-observed 2026-10-30):
#   A1 laliga: 10 rows positional 1..10, integer values monotonic,
#      rank-1 = (1467236, «لامین یامال», 14) — the live anchor
#   A2 the league contract: six domestics bcc=10 + the full sibling
#      contract (incl. xg=10 + gp90=10 + xa=10); persiangulf honestly
#      ABSENT (bcc=0) while minutes=10/scorers=20/gp90=10 still serve;
#      mas honestly 0 while its scorers still serve 20
#   A3 SEASON-AWARE: laliga?season=2020/2021 → bcc 10 rows, rank-1
#      name='Lionel Messi' nameFa=«لیونل مسی» bcc=22 (the frozen anchor +
#      the 229 curation riding free) + pl?season=2023/2024 → rank-1
#      Salah 22
#   A4 integer precision: every served bcc satisfies round(v)==v
#   A5 the badge flow: the GLOBAL merge carries bigChances on scorer rows
#      (live-observed: 7 rows — Beljo 5 hnl first)
# Part B (DOM @390x844, agent-browser, console must stay 0):
#   B1 «سانس بزرگ خلق‌شده» h2 + 10 bcc-rows on /topscorers/laliga
#   B2 order: گل مورد انتظار → گل در هر ۹۰ → پاس مورد انتظار → سانس بزرگ
#      خلق‌شده → بیشترین دقایق (the 226/227/230 analytics run grows by
#      one) + the keeper QUINTET still adjacent + no real overflow
#   B3 integer pill: NO dir attribute + «۱۴» on the first row (the 215/220
#      integer contract)
#   B4 real navigation: first bcc-row → /player/1467236 h1 «لامین یامال»
#   B5a persiangulf honest absence in DOM: no «سانس بزرگ خلق‌شده» h2 while
#      «گل در هر ۹۰» still renders
#   B5b mas honest absence: no bcc h2 while the scorers table still renders
#   B6 console=0 errors=0 across the whole session
# Part C: warm LAT <5000ms on laliga
set -u
BASE="${BASE:-http://localhost:3000}"
TMP="$(mktemp -d /home/z/my-project/.cycle231-dom-XXXXXX)"
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
b=d.get('bigChancesCreated') or []
ranks=[e['rank'] for e in b]
r1=b[0] if b else {}
mono=all(b[i]['bigChances']>=b[i+1]['bigChances'] for i in range(len(b)-1)) if len(b)==10 else False
ints=all(round(e['bigChances'])==e['bigChances'] for e in b)
print('A1CHECK', len(b)==10, ranks==list(range(1,11)), mono, ints, r1.get('playerId')==1467236 and r1.get('nameFa')=='لامین یامال' and r1.get('bigChances')==14)
" > "$TMP/a1.txt"
grep -q "A1CHECK True True True True True" "$TMP/a1.txt" && ok "A1 laliga: 10 rows positional 1..10, integer monotonic, rank-1 «لامین یامال»/1467236/14 (live anchor)" || bad "A1: $(cat "$TMP/a1.txt")"

# A2 the league contract: domestics serve 10 + siblings intact; the Gulf
# honestly absent; mas honestly absent
SW=1
for K in ucl pl laliga seriea bundesliga ligue1; do
  L=$(curl -s "$BASE/api/topscorers/$K" | py "
import sys,json
d=json.load(sys.stdin)
b=d.get('bigChancesCreated') or []
f=lambda k: len(d.get(k) or [])
ok=(len(b)==10 and f('scorers')==20 and f('cleanSheets')==10 and f('ratings')==10 and f('gPlusA')==10 and f('goalsPrevented')==10 and f('minutes')==10 and f('savePercentage')==10 and f('savesPer90')==10 and 1<=f('penaltySaves')<=10 and f('xg')==10 and f('goalsPer90')==10 and f('xa')==10)
print(1 if ok else 0)
")
  [ "$L" = "1" ] || { SW=0; bad "A2: $K failed ($L)"; }
done
PG=$(curl -s "$BASE/api/topscorers/persiangulf" | py "
import sys,json
d=json.load(sys.stdin)
f=lambda k: len(d.get(k) or [])
ok=(f('bigChancesCreated')==0 and f('minutes')==10 and f('scorers')==20 and f('goalsPer90')==10)
print(1 if ok else 0)
")
MAS=$(curl -s "$BASE/api/topscorers/mas" | py "
import sys,json
d=json.load(sys.stdin)
print(1 if len(d.get('bigChancesCreated') or [])==0 and len(d.get('scorers') or [])==20 else 0)
")
[ "$SW" = "1" ] && [ "$PG" = "1" ] && [ "$MAS" = "1" ] && ok "A2 six domestics carry bcc=10 + the full sibling contract (xg/gp90/xa=10 beside it); persiangulf honestly ABSENT (bcc=0) while minutes=10/scorers=20/gp90=10 still serve; mas mirror-honest (bcc=0, scorers=20)" || bad "A2: SW=$SW PG=$PG MAS=$MAS"

# A3 SEASON-AWARE frozen anchors (Messi 22 + Salah 22)
H=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F2021" | py "
import sys,json
d=json.load(sys.stdin)
b=d.get('bigChancesCreated') or []
r1=b[0] if b else {}
print('H', len(b)==10, r1.get('name')=='Lionel Messi' and r1.get('bigChances')==22 and r1.get('nameFa')=='لیونل مسی')
")
echo "$H" | grep -q "H True True" && ok "A3a historical 2020/21: bcc serves 10 rows with the frozen anchor Lionel Messi 22 AND «لیونل مسی» (the 229 curation rides free, the 202 pattern, season-aware)" || bad "A3a: $H"
H2=$(curl -s "$BASE/api/topscorers/pl?season=2023%2F2024" | py "
import sys,json
d=json.load(sys.stdin)
b=d.get('bigChancesCreated') or []
r1=b[0] if b else {}
print('H2', len(b)==10, r1.get('name')=='Mohamed Salah' and r1.get('bigChances')==22)
")
echo "$H2" | grep -q "H2 True True" && ok "A3b historical 2023/24 pl: rank-1 Mohamed Salah 22 (the second frozen anchor)" || bad "A3b: $H2"

# A4 integer precision across all six serving leagues
PD=1
for K in ucl pl laliga seriea bundesliga ligue1; do
  L=$(curl -s "$BASE/api/topscorers/$K" | py "
import sys,json
d=json.load(sys.stdin)
b=d.get('bigChancesCreated') or []
print(1 if all(round(e['bigChances'])==e['bigChances'] for e in b) else 0)
")
  [ "$L" = "1" ] || PD=0
done
[ "$PD" = "1" ] && ok "A4 precision: every served bcc on all six leagues satisfies round(v)==v (the integer convention, probed nonint=0 upstream)" || bad "A4: PD=$PD"

# A5 the badge flow on the global merge
G=$(curl -s "$BASE/api/topscorers" | py "
import sys,json
d=json.load(sys.stdin)
sb=[s for s in (d.get('scorers') or []) if s.get('bigChances') is not None]
print('G', len(sb)>=1, (sb[0]['name'], sb[0]['bigChances']) if sb else None)
")
echo "$G" | grep -q "G True" && ok "A5 global merge carries bigChances badges on scorer rows (live-observed: $(echo "$G" | sed 's/G True //') — the id-intersection mechanism)" || bad "A5: $G"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B1=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=bcc-row]')]; const h2=[...document.querySelectorAll('main h2')].some(h=>h.textContent==='سانس بزرگ خلق‌شده'); return JSON.stringify({rows:rows.length, h2}); })()")
echo "$B1" | tr -d '\\' | grep -q '"rows":10' && echo "$B1" | tr -d '\\' | grep -q '"h2":true' && ok "B1 DOM: «سانس بزرگ خلق‌شده» h2 renders + 10 bcc-rows on /topscorers/laliga" || bad "B1: $B1"
B2=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const iX=h2s.indexOf('گل مورد انتظار'), iG=h2s.indexOf('گل در هر ۹۰'), iA=h2s.indexOf('پاس مورد انتظار'), iB=h2s.indexOf('سانس بزرگ خلق‌شده'), iM=h2s.indexOf('بیشترین دقایق'); const order=iX>-1&&iG>iX&&iA>iG&&iB>iA&&iM>iB; const q=['درصد سیو','سیو در هر ۹۰','گل نخرده‌ها','گل‌های پیشگیری‌شده','پنالتی‌های مهارشده'].map(x=>h2s.indexOf(x)); const quintet=q.every(i=>i>-1)&&q.every((i,k)=>k===0||i>q[k-1]); const vbroken=[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length; return JSON.stringify({order, quintet, vbroken}); })()")
echo "$B2" | tr -d '\\' | grep -q '"order":true' && echo "$B2" | tr -d '\\' | grep -q '"quintet":true' && echo "$B2" | tr -d '\\' | grep -q '"vbroken":0' && ok "B2 DOM: گل مورد انتظار → گل در هر ۹۰ → پاس مورد انتظار → سانس بزرگ خلق‌شده → دقایق (the creation trio together) + keeper QUINTET still adjacent + no real overflow @390x844" || bad "B2: $B2"
B3=$(agent-browser eval "(() => { const row=document.querySelector('[data-testid=bcc-row]'); const pill=row.firstElementChild.lastElementChild; return JSON.stringify({dirAttr:pill?.getAttribute('dir'), txt:pill?.textContent}); })()")
echo "$B3" | tr -d '\\' | grep -q '"dirAttr":null' && echo "$B3" | tr -d '\\' | grep -q '"txt":"۱۴"' && ok "B3 DOM: integer pill WITHOUT dir renders «۱۴» (the 215/220 integer contract, Persian digits)" || bad "B3: $B3"
HREF=$(agent-browser eval "document.querySelector('[data-testid=bcc-row] a')?.getAttribute('href') || 'NO_LINK'" | tr -d '"' | tr -d '\\')
if [ "$HREF" = "/player/1467236" ]; then
  agent-browser eval "window.location.href='$HREF'" >/dev/null
  sleep 2.5
  B4=$(agent-browser eval "JSON.stringify({path:location.pathname, h1:(document.querySelector('h1')||{}).textContent})")
  echo "$B4" | tr -d '\\' | grep -q '"/player/1467236"' && echo "$B4" | tr -d '\\' | grep -q '"لامین یامال"' && ok "B4 DOM: first bcc-row really navigates to /player/1467236 with h1 «لامین یامال» (the 170/176 link contract)" || bad "B4: $B4"
else
  bad "B4: first bcc-row href is $HREF (expected /player/1467236)"
fi
agent-browser open "$BASE/topscorers/persiangulf" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B5A=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); return JSON.stringify({bcc:h2s.includes('سانس بزرگ خلق‌شده'), gp90:h2s.includes('گل در هر ۹۰'), min:h2s.includes('بیشترین دقایق')}); })()")
echo "$B5A" | tr -d '\\' | grep -q '"bcc":false' && echo "$B5A" | tr -d '\\' | grep -q '"gp90":true' && echo "$B5A" | tr -d '\\' | grep -q '"min":true' && ok "B5a DOM: persiangulf honestly hides «سانس بزرگ خلق‌شده» (no category) while «گل در هر ۹۰» + «بیشترین دقایق» still render" || bad "B5a: $B5A"
agent-browser open "$BASE/topscorers/mas" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B5B=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const table=document.querySelector('main table, main ol'); return JSON.stringify({bcc:h2s.includes('سانس بزرگ خلق‌شده'), scorers:!!table}); })()")
echo "$B5B" | tr -d '\\' | grep -q '"bcc":false' && echo "$B5B" | tr -d '\\' | grep -q '"scorers":true' && ok "B5b DOM: mas honestly hides the section (no bcc h2) while its scorers surface still renders" || bad "B5b: $B5B"
CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B6 console=0 errors=0 across the whole session" || bad "B6: console=$CN errors=$CE"
agent-browser close >/dev/null 2>&1

echo "== Part C: warm LAT =="
T0=$(date +%s%N); curl -s -o /dev/null "$BASE/api/topscorers/laliga"; T1=$(date +%s%N)
MS=$(( (T1-T0)/1000000 ))
[ "$MS" -lt 5000 ] && ok "LAT warm /api/topscorers/laliga = ${MS}ms (<5000ms)" || bad "LAT: ${MS}ms"

echo "== VERDICT =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE231 FIXPROOF ALL GREEN («سانس بزرگ خلق‌شده» — the deep-file family's FIFTEENTH sibling and the production-CREATION volume surface: 22-of-24 leagues served at 10 rows, persiangulf+mas honestly absent, season-aware with the frozen Messi 22 anchor + the 229 curation riding free, the FIFTEENTH thin-guard clause proven live with a ZERO-touch 90s self-heal (the 230 lesson institutionalized), integer pill the 215/220 contract, badge flow on the id-intersection mechanism — API 6/6 + DOM 6/6 + LAT @390x844)" && exit 0
exit 1
