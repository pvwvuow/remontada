#!/bin/bash
# cycle240-domproof.sh — permanent gate for the cycle-240 update
# (Update (cycle 240): «گل نخرده‌های تیم‌ها» — the deep-file family's
#  TWENTIETH sibling and its SECOND TEAM-PARTICIPANT member: the team-side
#  LEVEL of the keeper clean-sheets surface (215), the team-twin
#  relationship 237 established for xG. Live-probed 2026-10-30 UA
#  Chrome/124 (scripts/cycle240-probe.sh): stats/{id}/season/{sid}/
#  clean_sheet_team.json serves WIDE files on all six domestic globalMerge
#  leagues — laliga 18 Athletic Club 6.0 / pl 18 Arsenal 5.0 / seriea 18
#  Roma 5.0 / bundesliga 16 Borussia Dortmund 5.0 / ligue1 14 Lorient 5.0
#  / ucl 17 Arsenal 2.0 rows; portugal 17 with the THREE-WAY tie
#  Arouca/Porto/Santa Clara 5,5,5 probed for breadth; persiangulf honestly
#  absent (its feed carries ONE team category, goals_team_match) while MAS
#  SERVES a naturally-thin 8-row file (Johor Darul Ta'zim 6.0 — the FIRST
#  below-the-floor serve in the family, the 225 health-rule class on the
#  mas panel; the standings TTL guard carries the league-scoped mas
#  exemption). INTEGER-VALUED floats (StatFormat number) → the
#  215/220/231/235/236 integer convention: the pill renders String(value)
#  dir=ltr (6.0 renders «۶»). Upstream ties kept verbatim (laliga rank
#  2,2 Atlético+Celta) — the merge re-ranks POSITIONALLY. SEASON-AWARE:
#  the 2020/21 laliga raw serves its OWN file — 20 rows, Atletico Madrid
#  18.0 / Real Madrid 17.0 / Sevilla 17.0 — frozen, the 202 anchor
#  pattern. The honest-name contract rides the EXISTING teamFa map (zero
#  new PLAYER_NAME_FA entries). Rows link /team/{teamId}; the block rides
#  the league page only, placed right after گل مورد انتظار تیم‌ها so the
#  two team-side blocks read together; data-testid=tcs-row.
# Part A (API, live-observed 2026-10-30):
#   A1 the six-domestic contract: teamCleanSheets=10 rows positional 1..10,
#      integer-valued, monotonic DESC; laliga live anchor rank-1 =
#      («اتلتیک‌بیلبائو», 8315, 6.0)
#   A2 portugal breadth: 10 rows + the three-way 5,5,5 tie re-ranked
#      positionally 1,2,3
#   A3 the honest pair: persiangulf [] (absent) + mas SERVES thin 8 rows
#      (Johor Darul Ta'zim 6.0) — the first below-the-floor serve
#   A4 SEASON-AWARE frozen anchor: laliga?season=2020/2021 → 10 rows,
#      rank-1 Atletico Madrid 18.0 (the 202 pattern) while penaltySaves
#      stays honestly 0
#   A5 season-distinctness: current 6 ≠ historical 18 (the 94 lesson)
#   A6 the negative season probe (the two-stage shape contract)
# Part B (DOM @390x844, agent-browser, console must stay 0):
#   B1 «گل نخرده‌های تیم‌ها» h2 + 10 tcs-rows on /topscorers/laliga + the
#      order: گل مورد انتظار < گل مورد انتظار تیم‌ها < گل نخرده‌های تیم‌ها
#      (the two team-side blocks adjacent) + the keeper QUINTET untouched
#      + zero real overflow
#   B2 the integer pill: dir=ltr + «۶» on the first row + zero Latin
#      digits + zero row-level inner overflow
#   B3 real navigation: first tcs-row → /team/8315 with the teamFa h1
#   B4 mas DOM: /topscorers/mas renders its honest thin 8 tcs-rows
#   B5 persiangulf DOM honest absence: no گل نخرده‌های تیم‌ها h2 while the
#      page still renders its other blocks
#   B6 console=0 errors=0 across the whole session
# Part C: warm LAT <5000ms on laliga
set -u
BASE="${BASE:-http://localhost:3000}"
TMP="$(mktemp -d /home/z/my-project/.cycle240-dom-XXXXXX)"
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
cs=d.get('teamCleanSheets') or []
ranks=[e['rank'] for e in cs]
mono=all(cs[i]['teamCleanSheets']>=cs[i+1]['teamCleanSheets'] for i in range(len(cs)-1)) if len(cs)==10 else False
ints=all(float(e['teamCleanSheets']).is_integer() for e in cs)
print(1 if (len(cs)==10 and ranks==list(range(1,11)) and mono and ints) else 0)
")
  [ "$L" = "1" ] || { A1=0; bad "A1: $K failed ($L)"; }
done
curl -s "$BASE/api/topscorers/laliga" > "$TMP/laliga.json"
py "
import json
d=json.load(open('$TMP/laliga.json'))
cs=d.get('teamCleanSheets') or []
r1=cs[0] if cs else {}
ranks=[e['rank'] for e in cs]
mono=all(cs[i]['teamCleanSheets']>=cs[i+1]['teamCleanSheets'] for i in range(len(cs)-1)) if len(cs)==10 else False
ints=all(float(e['teamCleanSheets']).is_integer() for e in cs)
tie2=cs[1]['teamCleanSheets']==cs[2]['teamCleanSheets'] if len(cs)>=3 else False
print('A1CHECK', len(cs)==10, ranks==list(range(1,11)), mono, ints, tie2, r1.get('teamId')==8315 and r1.get('nameFa')=='اتلتیک‌بیلبائو' and abs(r1.get('teamCleanSheets',0)-6.0)<1e-9)
" > "$TMP/a1.txt"
grep -q "A1CHECK True True True True True True" "$TMP/a1.txt" && [ "$A1" = "1" ] && ok "A1 six domestics: teamCleanSheets=10 rows positional 1..10, integer-valued monotonic + the laliga live anchor «اتلتیک‌بیلبائو»/8315/6.0 with the upstream 2,2 tie kept (positional merge)" || bad "A1: $(cat "$TMP/a1.txt") A1=$A1"

# A2 portugal breadth: the three-way 5,5,5 tie re-ranked positionally
PGP=$(curl -s "$BASE/api/topscorers/portugal" | py "
import sys,json
d=json.load(sys.stdin)
cs=d.get('teamCleanSheets') or []
top3vals=[e['teamCleanSheets'] for e in cs[:3]]
ranks=[e['rank'] for e in cs[:3]]
print(1 if (len(cs)==10 and top3vals==[5.0,5.0,5.0] and ranks==[1,2,3]) else 0)
")
[ "$PGP" = "1" ] && ok "A2 portugal breadth: 10 rows, the upstream THREE-WAY 5,5,5 tie (Arouca/Porto/Santa Clara) re-ranked positionally 1,2,3 — the 237 tie class re-observed on the new sibling" || bad "A2: $PGP"

# A3 the honest pair: persiangulf absent + mas serves thin 8
PG=$(curl -s "$BASE/api/topscorers/persiangulf" | py "
import sys,json
d=json.load(sys.stdin)
print(1 if len(d.get('teamCleanSheets') or [])==0 else 0)
")
MAS=$(curl -s "$BASE/api/topscorers/mas" | py "
import sys,json
d=json.load(sys.stdin)
cs=d.get('teamCleanSheets') or []
r1=cs[0] if cs else {}
print(1 if (len(cs)==8 and r1.get('nameFa')=='جوهور دارالتعظیم' and abs(r1.get('teamCleanSheets',0)-6.0)<1e-9) else 0)
")
[ "$PG" = "1" ] && [ "$MAS" = "1" ] && ok "A3 the honest pair: persiangulf [] (its feed carries ONE team category, goals_team_match — probed) + MAS SERVES its naturally-thin 8-row file («جوهور دارالتعظیم» 6.0 — the FIRST below-the-floor serve in the family, the 225 health-rule class; the standings guard's mas exemption)" || bad "A3: PG=$PG MAS=$MAS"

# A4 SEASON-AWARE frozen anchor (Atletico Madrid 18.0)
H=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F2021" | py "
import sys,json
d=json.load(sys.stdin)
cs=d.get('teamCleanSheets') or []
r1=cs[0] if cs else {}
print('H', len(cs)==10, r1.get('name')=='Atletico Madrid' and r1.get('nameFa')=='اتلتیکومادرید' and abs(r1.get('teamCleanSheets',0)-18.0)<1e-9, len(d.get('penaltySaves') or [])==0)
")
echo "$H" | grep -q "H True True True" && ok "A4 historical 2020/21: teamCleanSheets serves 10 rows with the frozen anchor Atletico Madrid 18.0 (Real Madrid 17.0 behind — the 202 pattern, season-aware) while penaltySaves stays honestly 0" || bad "A4: $H"

# A5 season-distinctness (the 94 lesson)
D=$(curl -s "$BASE/api/topscorers/laliga" | py "
import sys,json
v=(json.load(sys.stdin).get('teamCleanSheets') or [{}])[0].get('teamCleanSheets',0)
print(1 if abs(v-6.0)<1e-9 else 0)
")
[ "$D" = "1" ] && ok "A5 season-distinctness: current rank-1 6.0 ≠ historical 18.0 (the two seasons provably serve DIFFERENT files)" || bad "A5: $D"

# A6 the negative season probe
NG=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F21" | py "import sys,json;d=json.JSONDecoder().raw_decode(sys.stdin.read())[0];print(1 if (d.get('ok')==False and 'Invalid season' in str(d.get('error'))) else 0)")
[ "$NG" = "1" ] && ok "A6 negative probe: season 2020/21 → {ok:false, Invalid season} (the two-stage shape contract)" || bad "A6: $NG"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B1=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const iX=h2s.indexOf('گل مورد انتظار'), iT=h2s.indexOf('گل مورد انتظار تیم‌ها'), iCS=h2s.indexOf('گل نخرده‌های تیم‌ها'); const order=iX>-1&&iT>iX&&iCS>iT; const q=['درصد سیو','سیو در هر ۹۰','گل نخرده‌ها','گل‌های پیشگیری‌شده','پنالتی‌های مهارشده'].map(x=>h2s.indexOf(x)); const quintet=q.every(i=>i>-1)&&q.every((i,k)=>k===0||i>q[k-1]); const rows=[...document.querySelectorAll('[data-testid=tcs-row]')]; const vbroken=[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length; return JSON.stringify({order,quintet,n:rows.length,vbroken}); })()")
echo "$B1" | tr -d '\\' | grep -q '"order":true' && echo "$B1" | tr -d '\\' | grep -q '"quintet":true' && echo "$B1" | tr -d '\\' | grep -q '"n":10' && echo "$B1" | tr -d '\\' | grep -q '"vbroken":0' && ok "B1 DOM: «گل نخرده‌های تیم‌ها» h2 renders + 10 tcs-rows on /topscorers/laliga + the order گل مورد انتظار < گل مورد انتظار تیم‌ها < گل نخرده‌های تیم‌ها (the TWO team-side blocks adjacent) + the keeper QUINTET untouched + zero real overflow @390x844" || bad "B1: $B1"
B2=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=tcs-row]')]; const a=rows[0]&&rows[0].querySelector('a'); const pill=a&&a.lastElementChild; const innerOvf=rows.filter(r=>r.scrollWidth>r.clientWidth+1).length; const latinPill=rows.filter(r=>/[0-9]/.test((r.querySelector('[dir=ltr]')||{}).textContent||'')).length; return JSON.stringify({pill:(pill&&pill.textContent.trim())||'', dir:(pill&&pill.getAttribute('dir'))||null, innerOvf, latinPill}); })()")
echo "$B2" | tr -d '\\' | grep -q '"dir":"ltr"' && echo "$B2" | tr -d '\\' | grep -q '"pill":"۶"' && echo "$B2" | tr -d '\\' | grep -q '"innerOvf":0' && echo "$B2" | tr -d '\\' | grep -q '"latinPill":0' && ok "B2 DOM: the integer pill dir=ltr renders «۶» on the first row (String(6.0) → «۶», the 215/220/231/235/236 convention) + zero Latin digits + zero row-level inner overflow" || bad "B2: $B2"
HREF=$(agent-browser eval "document.querySelector('[data-testid=tcs-row] a')?.getAttribute('href') || 'NO_LINK'" | tr -d '"' | tr -d '\\')
if [ "$HREF" = "/team/8315" ]; then
  agent-browser eval "window.location.href='$HREF'" >/dev/null
  sleep 2.5
  B3=$(agent-browser eval "JSON.stringify({path:location.pathname, h1:(document.querySelector('h1')||{}).textContent})")
  echo "$B3" | tr -d '\\' | grep -q '"/team/8315"' && echo "$B3" | tr -d '\\' | grep -q '"اتلتیک' && ok "B3 DOM: the first tcs-row really navigates to /team/8315 with the teamFa h1 «اتلتیک‌بیلبائو» (the standings-view link contract)" || bad "B3: $B3"
else
  bad "B3: first tcs-row href is $HREF (expected /team/8315)"
fi
agent-browser open "$BASE/topscorers/mas" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B4=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=tcs-row]')]; const h2=[...document.querySelectorAll('main h2')].some(h=>h.textContent==='گل نخرده‌های تیم‌ها'); const first=rows[0]?.textContent||''; return JSON.stringify({n:rows.length, h2, johor:first.includes('جوهور')}); })()")
echo "$B4" | tr -d '\\' | grep -q '"n":8' && echo "$B4" | tr -d '\\' | grep -q '"h2":true' && echo "$B4" | tr -d '\\' | grep -q '"johor":true' && ok "B4 DOM: mas renders its honest THIN serve — 8 tcs-rows with «جوهور دارالتعظیم» first (the first below-the-floor DOM serve in the family)" || bad "B4: $B4"
agent-browser open "$BASE/topscorers/persiangulf" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B5=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); return JSON.stringify({tcs:h2s.includes('گل نخرده‌های تیم‌ها'), scorers:h2s.includes('گلزن‌ها')||h2s.length>0}); })()")
echo "$B5" | tr -d '\\' | grep -q '"tcs":false' && echo "$B5" | tr -d '\\' | grep -q '"scorers":true' && ok "B5 DOM: persiangulf honestly hides the section (no گل نخرده‌های تیم‌ها h2) while its other blocks still render (the honest-absence contract)" || bad "B5: $B5"
CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B6 console=0 errors=0 across the whole session" || bad "B6: console=$CN errors=$CE"
agent-browser close >/dev/null 2>&1

echo "== Part C: warm LAT =="
T0=$(date +%s%N); curl -s -o /dev/null "$BASE/api/topscorers/laliga"; T1=$(date +%s%N)
MS=$(( (T1-T0)/1000000 ))
[ "$MS" -lt 5000 ] && ok "LAT warm /api/topscorers/laliga = ${MS}ms (<5000ms)" || bad "LAT: ${MS}ms"

echo "== VERDICT =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE240 DOMPROOF ALL GREEN («گل نخرده‌های تیم‌ها» — the deep-file family's TWENTIETH sibling and its SECOND TEAM-PARTICIPANT member: the team-side LEVEL of the keeper clean sheets 215, WIDE on all six domestics at top-10, the portugal three-way 5,5,5 tie re-ranked positionally, persiangulf honestly absent + mas honestly THIN at 8 rows (the 225 health-rule class with the league-scoped guard exemption), season-aware with the frozen Atletico 18.0 anchor, the integer String() pill the 215/220/231/235/236 convention — API 6/6 + DOM 6/6 + LAT @390x844)" && exit 0
exit 1
