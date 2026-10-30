#!/bin/bash
# cycle242-domproof.sh — permanent gate for the cycle-242 update
# (Update (cycle 242): «کارت‌های زرد تیم‌ها» — the deep-file family's
#  TWENTY-SECOND sibling and its FOURTH TEAM-PARTICIPANT member: the
#  team-side yellow-card surface. Live-probed 2026-10-30 UA Chrome/124
#  (scripts/cycle242-probe.sh): stats/{id}/season/{sid}/
#  total_yel_card_team.json serves WIDE files on all six domestic
#  globalMerge leagues — laliga 20 Getafe 33.0 / pl 20 AFC Bournemouth
#  22.0 / seriea 20 Fiorentina 20.0 / bundesliga 18 Borussia
#  Mönchengladbach 21.0 / ligue1 18 Nice 19.0 / ucl 36 Club Brugge 9.0
#  rows; portugal 18 Académico Viseu 27.0 with the top-3 25,25 tie probed
#  for breadth; persiangulf AND mas honestly absent (the 237/241 absence
#  pair exactly — pg's feed carries ONE team category, Goals per match;
#  mas's feed carries FOUR — Goals per match / Goals conceded per match /
#  Clean sheets / Red cards — and yellow is not one, probed).
#  INTEGER-VALUED floats (probed int on every serving file) → the
#  215/220/231/235/236 integer convention: the pill renders String(value)
#  dir=ltr (33.0 renders «۳۳»). Upstream Rank keeps COMPETITION ties
#  verbatim (laliga rank 5,6 on 25.0 / 15,16,16 on 17.0) — the merge
#  re-ranks POSITIONALLY. SEASON-AWARE: the 2020/21 laliga raw serves its
#  OWN file — season/15585, 20 rows, Getafe 114.0 / Celta Vigo 104.0 /
#  Atletico Madrid 100.0 — frozen, the 202 anchor pattern, DISTINCT from
#  the current 33.0 (Getafe tops BOTH eras, probed). Rows link
#  /team/{teamId}; the block rides the league page only, placed right
#  after مالکیت توپ تیم‌ها so the FOUR team-side blocks read together;
#  data-testid=tyc-row. The standard thin guard applies — NO
#  league-aware floor (the honest-empty pair degrades to [] upstream,
#  the 237/241 pattern). THE COLD-BUILD RACE REPRODUCED LIVE THIS CYCLE:
#  the first SSG cold build baked the 3-row category podium (the 210
#  incident class) and the thin guard self-healed 3→10 zero-touch on the
#  first 90s re-probe — the EIGHTH consecutive zero-touch proof.
# Part A (API, live-observed 2026-10-30):
#   A1 the six-domestic contract: teamYellowCards=10 rows positional
#      1..10, INTEGER-valued, monotonic DESC; laliga live anchor rank-1 =
#      («ختافه», 8305, 33)
#   A2 portugal breadth: 10 rows, rank-1 Académico Viseu 27
#   A3 the 237/241 absence pair: persiangulf [] AND mas []
#   A4 SEASON-AWARE frozen anchor: laliga?season=2020/2021 → 10 rows,
#      rank-1 Getafe 114 (the 202 pattern)
#   A5 season-distinctness: current 33 ≠ historical 114 (the 94 lesson)
#   A6 the negative season probe (the two-stage shape contract)
# Part B (DOM @390x844, agent-browser, console must stay 0):
#   B1 «کارت‌های زرد تیم‌ها» h2 + 10 tyc-rows on /topscorers/laliga + the
#      order: گل مورد انتظار تیم‌ها < گل نخرده‌های تیم‌ها < مالکیت توپ
#      تیم‌ها < کارت‌های زرد تیم‌ها (the FOUR team-side blocks adjacent)
#      + the keeper QUINTET untouched + zero real overflow
#   B2 the integer pill: dir=ltr + «۳۳» on the first row + zero Latin
#      digits + zero row-level inner overflow
#   B3 real navigation: first tyc-row → /team/8305 with the teamFa h1
#      «ختافه»
#   B4 persiangulf DOM honest absence: no کارت‌های زرد تیم‌ها h2 while
#      the page still renders its other blocks
#   B5 mas DOM honest absence: no کارت‌های زرد تیم‌ها h2 while its cards
#      block still renders (the 176 mas contract)
#   B6 console=0 errors=0 across the whole session
# Part C: warm LAT <5000ms on laliga
set -u
BASE="${BASE:-http://localhost:3000}"
TMP="$(mktemp -d /home/z/my-project/.cycle242-dom-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok(){ echo "OK  - $1"; PASS=$((PASS+1)); }
bad(){ echo "BAD - $1"; FAIL=$((FAIL+1)); }
py(){ python3 -c "$1"; }
enc(){ python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$1"; }

echo "== Part A: API gates =="

# A1 the six-domestic contract + the laliga live anchor
A1=1
for K in pl seriea bundesliga ligue1 ucl; do
  L=$(curl -s "$BASE/api/topscorers/$K" | py "
import sys,json
d=json.load(sys.stdin)
ps=d.get('teamYellowCards') or []
ranks=[e['rank'] for e in ps]
mono=all(ps[i]['teamYellowCards']>=ps[i+1]['teamYellowCards'] for i in range(len(ps)-1)) if len(ps)==10 else False
ints=all(abs(e['teamYellowCards']-round(e['teamYellowCards']))<1e-9 for e in ps)
print(1 if (len(ps)==10 and ranks==list(range(1,11)) and mono and ints) else 0)
")
  [ "$L" = "1" ] || { A1=0; bad "A1: $K failed ($L)"; }
done
curl -s "$BASE/api/topscorers/laliga" > "$TMP/laliga.json"
py "
import json
d=json.load(open('$TMP/laliga.json'))
ps=d.get('teamYellowCards') or []
r1=ps[0] if ps else {}
ranks=[e['rank'] for e in ps]
mono=all(ps[i]['teamYellowCards']>=ps[i+1]['teamYellowCards'] for i in range(len(ps)-1)) if len(ps)==10 else False
ints=all(abs(e['teamYellowCards']-round(e['teamYellowCards']))<1e-9 for e in ps)
print('A1CHECK', len(ps)==10, ranks==list(range(1,11)), mono, ints, r1.get('teamId')==8305 and r1.get('nameFa')=='ختافه' and r1.get('teamYellowCards')==33)
" > "$TMP/a1.txt"
grep -q "A1CHECK True True True True True" "$TMP/a1.txt" && [ "$A1" = "1" ] && ok "A1 six domestics: teamYellowCards=10 rows positional 1..10, INTEGER monotonic + the laliga live anchor «ختافه»/8305/33" || bad "A1: $(cat "$TMP/a1.txt") A1=$A1"

# A2 portugal breadth
PGP=$(curl -s "$BASE/api/topscorers/portugal" | py "
import sys,json
d=json.load(sys.stdin)
ps=d.get('teamYellowCards') or []
r1=ps[0] if ps else {}
print(1 if (len(ps)==10 and r1.get('name')=='Académico Viseu' and r1.get('teamYellowCards')==27) else 0)
")
[ "$PGP" = "1" ] && ok "A2 portugal breadth: 10 rows, rank-1 Académico Viseu 27 — the team family's breadth re-verified on the new sibling" || bad "A2: $PGP"

# A3 the 237/241 absence pair: persiangulf [] AND mas []
PG=$(curl -s "$BASE/api/topscorers/persiangulf" | py "
import sys,json
d=json.load(sys.stdin)
print(1 if len(d.get('teamYellowCards') or [])==0 else 0)
")
MAS=$(curl -s "$BASE/api/topscorers/mas" | py "
import sys,json
d=json.load(sys.stdin)
print(1 if len(d.get('teamYellowCards') or [])==0 else 0)
")
[ "$PG" = "1" ] && [ "$MAS" = "1" ] && ok "A3 the 237/241 absence pair: persiangulf [] AND mas [] (pg's feed carries ONE team category, Goals per match; mas's carries FOUR — Goals per match / Goals conceded per match / Clean sheets / Red cards — and yellow is not one, probed) — both degrade honestly upstream of the guard, no league-aware floor needed" || bad "A3: PG=$PG MAS=$MAS"

# A4 SEASON-AWARE frozen anchor (Getafe 114)
H=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F2021" | py "
import sys,json
d=json.load(sys.stdin)
ps=d.get('teamYellowCards') or []
r1=ps[0] if ps else {}
print('H', len(ps)==10, r1.get('name')=='Getafe' and r1.get('teamYellowCards')==114, len(d.get('penaltySaves') or [])==0)
")
echo "$H" | grep -q "H True True True" && ok "A4 historical 2020/21: teamYellowCards serves 10 rows with the frozen anchor Getafe 114 (Celta Vigo 104 behind — the 202 pattern, season-aware) while penaltySaves stays honestly 0" || bad "A4: $H"

# A5 season-distinctness (the 94 lesson)
D=$(curl -s "$BASE/api/topscorers/laliga" | py "
import sys,json
v=(json.load(sys.stdin).get('teamYellowCards') or [{}])[0].get('teamYellowCards',0)
print(1 if v==33 else 0)
")
[ "$D" = "1" ] && ok "A5 season-distinctness: current rank-1 33 ≠ historical 114 (the two seasons provably serve DIFFERENT files — and Getafe tops BOTH eras, probed)" || bad "A5: $D"

# A6 the negative season probe
NG=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F21" | py "import sys,json;d=json.JSONDecoder().raw_decode(sys.stdin.read())[0];print(1 if (d.get('ok')==False and 'Invalid season' in str(d.get('error'))) else 0)")
[ "$NG" = "1" ] && ok "A6 negative probe: season 2020/21 → {ok:false, Invalid season} (the two-stage shape contract)" || bad "A6: $NG"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B1=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const iT=h2s.indexOf('گل مورد انتظار تیم‌ها'), iCS=h2s.indexOf('گل نخرده‌های تیم‌ها'), iPOS=h2s.indexOf('مالکیت توپ تیم‌ها'), iYC=h2s.indexOf('کارت‌های زرد تیم‌ها'); const order=iT>-1&&iCS>iT&&iPOS>iCS&&iYC>iPOS; const q=['درصد سیو','سیو در هر ۹۰','گل نخرده‌ها','گل‌های پیشگیری‌شده','پنالتی‌های مهارشده'].map(x=>h2s.indexOf(x)); const quintet=q.every(i=>i>-1)&&q.every((i,k)=>k===0||i>q[k-1]); const rows=[...document.querySelectorAll('[data-testid=tyc-row]')]; const vbroken=[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length; return JSON.stringify({order,quintet,n:rows.length,vbroken}); })()")
echo "$B1" | tr -d '\\' | grep -q '"order":true' && echo "$B1" | tr -d '\\' | grep -q '"quintet":true' && echo "$B1" | tr -d '\\' | grep -q '"n":10' && echo "$B1" | tr -d '\\' | grep -q '"vbroken":0' && ok "B1 DOM: «کارت‌های زرد تیم‌ها» h2 renders + 10 tyc-rows on /topscorers/laliga + the order گل مورد انتظار تیم‌ها < گل نخرده‌های تیم‌ها < مالکیت توپ تیم‌ها < کارت‌های زرد تیم‌ها (the FOUR team-side blocks adjacent) + the keeper QUINTET untouched + zero real overflow @390x844" || bad "B1: $B1"
B2=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=tyc-row]')]; const a=rows[0]&&rows[0].querySelector('a'); const pill=a&&a.lastElementChild; const innerOvf=rows.filter(r=>r.scrollWidth>r.clientWidth+1).length; const latinPill=rows.filter(r=>/[0-9]/.test((r.querySelector('[dir=ltr]')||{}).textContent||'')).length; return JSON.stringify({pill:(pill&&pill.textContent.trim())||'', dir:(pill&&pill.getAttribute('dir'))||null, innerOvf, latinPill}); })()")
echo "$B2" | tr -d '\\' | grep -q '"dir":"ltr"' && echo "$B2" | tr -d '\\' | grep -q '"pill":"۳۳"' && echo "$B2" | tr -d '\\' | grep -q '"innerOvf":0' && echo "$B2" | tr -d '\\' | grep -q '"latinPill":0' && ok "B2 DOM: the integer pill dir=ltr renders «۳۳» on the first row (String(value), the 215/220/231/235/236 integer convention) + zero Latin digits + zero row-level inner overflow" || bad "B2: $B2"
HREF=$(agent-browser eval "document.querySelector('[data-testid=tyc-row] a')?.getAttribute('href') || 'NO_LINK'" | tr -d '"' | tr -d '\\')
if [ "$HREF" = "/team/8305" ]; then
  agent-browser eval "window.location.href='$HREF'" >/dev/null
  sleep 2.5
  B3=$(agent-browser eval "JSON.stringify({path:location.pathname, h1:(document.querySelector('h1')||{}).textContent})")
  echo "$B3" | tr -d '\\' | grep -q '"/team/8305"' && echo "$B3" | tr -d '\\' | grep -q '"ختافه"' && ok "B3 DOM: the first tyc-row really navigates to /team/8305 with the teamFa h1 «ختافه» (the standings-view link contract)" || bad "B3: $B3"
else
  bad "B3: first tyc-row href is $HREF (expected /team/8305)"
fi
agent-browser open "$BASE/topscorers/persiangulf" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B4=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); return JSON.stringify({yc:h2s.includes('کارت‌های زرد تیم‌ها'), any:h2s.length>0}); })()")
echo "$B4" | tr -d '\\' | grep -q '"yc":false' && echo "$B4" | tr -d '\\' | grep -q '"any":true' && ok "B4 DOM: persiangulf honestly hides the section (no کارت‌های زرد تیم‌ها h2) while its other blocks still render" || bad "B4: $B4"
agent-browser open "$BASE/topscorers/mas" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B5=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); return JSON.stringify({yc:h2s.includes('کارت‌های زرد تیم‌ها'), cards:h2s.includes('کارت‌ها')}); })()")
echo "$B5" | tr -d '\\' | grep -q '"yc":false' && echo "$B5" | tr -d '\\' | grep -q '"cards":true' && ok "B5 DOM: mas honestly hides the team yellow-cards section while its cards block still renders (the 176 mas contract) — the 237/241 absence pair in DOM" || bad "B5: $B5"
CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B6 console=0 errors=0 across the whole session" || bad "B6: console=$CN errors=$CE"
agent-browser close >/dev/null 2>&1

echo "== Part C: warm LAT =="
T0=$(date +%s%N); curl -s -o /dev/null "$BASE/api/topscorers/laliga"; T1=$(date +%s%N)
MS=$(( (T1-T0)/1000000 ))
[ "$MS" -lt 5000 ] && ok "LAT warm /api/topscorers/laliga = ${MS}ms (<5000ms)" || bad "LAT: ${MS}ms"

echo "== VERDICT =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE242 DOMPROOF ALL GREEN («کارت‌های زرد تیم‌ها» — the deep-file family's TWENTY-SECOND sibling and its FOURTH TEAM-PARTICIPANT member: the team-side yellow-card surface, WIDE on all six domestics at top-10, portugal breadth, the 237/241 absence pair pg+mas honestly empty, season-aware with the frozen Getafe 114 anchor distinct from the current 33, the String() integer pill — API 6/6 + DOM 6/6 + LAT @390x844)" && exit 0
exit 1
