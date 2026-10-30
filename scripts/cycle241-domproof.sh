#!/bin/bash
# cycle241-domproof.sh — permanent gate for the cycle-241 update
# (Update (cycle 241): «مالکیت توپ تیم‌ها» — the deep-file family's
#  TWENTY-FIRST sibling and its THIRD TEAM-PARTICIPANT member: the
#  team-side possession surface. Live-probed 2026-10-30 UA Chrome/124:
#  stats/{id}/season/{sid}/possession_percentage_team.json serves WIDE
#  files on all six domestic globalMerge leagues — laliga 20 Barcelona
#  69.4 / pl 20 Manchester City 64.2 / seriea 20 Inter 63.0 / bundesliga
#  18 Bayern München 66.9 / ligue1 18 Paris Saint-Germain 68.0 / ucl 36
#  Barcelona 65.2 rows; portugal 18 Benfica 63.1 probed for breadth;
#  persiangulf AND mas honestly absent (the 237 absence pair exactly —
#  mas's feed carries FOUR team categories and possession is not one,
#  probed). PERCENT 1-fraction (StatFormat percent) → the 221 percent
#  convention VERBATIM: the pill renders toFixed(1) dir=ltr (69.4 renders
#  «۶۹.۴») with NO appended percent sign. SEASON-AWARE: the 2020/21
#  laliga raw serves its OWN file — 20 rows, Barcelona 65.8 / Sevilla
#  61.2 / Real Madrid 59.6 — frozen, the 202 anchor pattern. The
#  honest-name contract rides the EXISTING teamFa map. Rows link
#  /team/{teamId}; the block rides the league page only, placed right
#  after گل نخرده‌های تیم‌ها so the THREE team-side blocks read together;
#  data-testid=tposs-row. The standard thin guard applies — NO
#  league-aware floor (the honest-empty pair degrades to [] upstream,
#  the 237 pattern; unlike the 240 clean-sheet sibling mas does not
#  serve this category at all).
# Part A (API, live-observed 2026-10-30):
#   A1 the six-domestic contract: teamPossession=10 rows positional 1..10,
#      percent 1-decimal, monotonic DESC; laliga live anchor rank-1 =
#      («بارسلونا», 8634, 69.4)
#   A2 portugal breadth: 10 rows, rank-1 Benfica 63.1
#   A3 the 237 absence pair: persiangulf [] AND mas [] (possession is not
#      among mas's FOUR team categories — probed)
#   A4 SEASON-AWARE frozen anchor: laliga?season=2020/2021 → 10 rows,
#      rank-1 Barcelona 65.8 (the 202 pattern)
#   A5 season-distinctness: current 69.4 ≠ historical 65.8 (the 94 lesson)
#   A6 the negative season probe (the two-stage shape contract)
# Part B (DOM @390x844, agent-browser, console must stay 0):
#   B1 «مالکیت توپ تیم‌ها» h2 + 10 tposs-rows on /topscorers/laliga + the
#      order: گل مورد انتظار تیم‌ها < گل نخرده‌های تیم‌ها < مالکیت توپ
#      تیم‌ها (the THREE team-side blocks adjacent) + the keeper QUINTET
#      untouched + zero real overflow
#   B2 the percent pill: dir=ltr + «۶۹.۴» on the first row + zero Latin
#      digits + zero row-level inner overflow
#   B3 real navigation: first tposs-row → /team/8634 with the teamFa h1
#   B4 persiangulf DOM honest absence: no مالکیت توپ تیم‌ها h2 while the
#      page still renders its other blocks
#   B5 mas DOM honest absence: no مالکیت توپ تیم‌ها h2 while its cards
#      block still renders (the 176 mas contract)
#   B6 console=0 errors=0 across the whole session
# Part C: warm LAT <5000ms on laliga
set -u
BASE="${BASE:-http://localhost:3000}"
TMP="$(mktemp -d /home/z/my-project/.cycle241-dom-XXXXXX)"
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
ps=d.get('teamPossession') or []
ranks=[e['rank'] for e in ps]
mono=all(ps[i]['teamPossession']>=ps[i+1]['teamPossession'] for i in range(len(ps)-1)) if len(ps)==10 else False
dec1=all(abs(e['teamPossession']*10-round(e['teamPossession']*10))<1e-9 for e in ps)
print(1 if (len(ps)==10 and ranks==list(range(1,11)) and mono and dec1) else 0)
")
  [ "$L" = "1" ] || { A1=0; bad "A1: $K failed ($L)"; }
done
curl -s "$BASE/api/topscorers/laliga" > "$TMP/laliga.json"
py "
import json
d=json.load(open('$TMP/laliga.json'))
ps=d.get('teamPossession') or []
r1=ps[0] if ps else {}
ranks=[e['rank'] for e in ps]
mono=all(ps[i]['teamPossession']>=ps[i+1]['teamPossession'] for i in range(len(ps)-1)) if len(ps)==10 else False
dec1=all(abs(e['teamPossession']*10-round(e['teamPossession']*10))<1e-9 for e in ps)
print('A1CHECK', len(ps)==10, ranks==list(range(1,11)), mono, dec1, r1.get('teamId')==8634 and r1.get('nameFa')=='بارسلونا' and abs(r1.get('teamPossession',0)-69.4)<1e-9)
" > "$TMP/a1.txt"
grep -q "A1CHECK True True True True True" "$TMP/a1.txt" && [ "$A1" = "1" ] && ok "A1 six domestics: teamPossession=10 rows positional 1..10, percent 1-decimal monotonic + the laliga live anchor «بارسلونا»/8634/69.4" || bad "A1: $(cat "$TMP/a1.txt") A1=$A1"

# A2 portugal breadth
PGP=$(curl -s "$BASE/api/topscorers/portugal" | py "
import sys,json
d=json.load(sys.stdin)
ps=d.get('teamPossession') or []
r1=ps[0] if ps else {}
print(1 if (len(ps)==10 and r1.get('name')=='Benfica' and abs(r1.get('teamPossession',0)-63.1)<1e-9) else 0)
")
[ "$PGP" = "1" ] && ok "A2 portugal breadth: 10 rows, rank-1 Benfica 63.1 — the team family's breadth re-verified on the new sibling" || bad "A2: $PGP"

# A3 the 237 absence pair: persiangulf [] AND mas []
PG=$(curl -s "$BASE/api/topscorers/persiangulf" | py "
import sys,json
d=json.load(sys.stdin)
print(1 if len(d.get('teamPossession') or [])==0 else 0)
")
MAS=$(curl -s "$BASE/api/topscorers/mas" | py "
import sys,json
d=json.load(sys.stdin)
print(1 if len(d.get('teamPossession') or [])==0 else 0)
")
[ "$PG" = "1" ] && [ "$MAS" = "1" ] && ok "A3 the 237 absence pair: persiangulf [] AND mas [] (possession is not among mas's FOUR team categories — probed; unlike the 240 clean-sheet sibling mas does not serve this category) — both degrade honestly upstream of the guard, no league-aware floor needed" || bad "A3: PG=$PG MAS=$MAS"

# A4 SEASON-AWARE frozen anchor (Barcelona 65.8)
H=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F2021" | py "
import sys,json
d=json.load(sys.stdin)
ps=d.get('teamPossession') or []
r1=ps[0] if ps else {}
print('H', len(ps)==10, r1.get('name')=='Barcelona' and abs(r1.get('teamPossession',0)-65.8)<1e-9, len(d.get('penaltySaves') or [])==0)
")
echo "$H" | grep -q "H True True True" && ok "A4 historical 2020/21: teamPossession serves 10 rows with the frozen anchor Barcelona 65.8 (Sevilla 61.2 behind — the 202 pattern, season-aware) while penaltySaves stays honestly 0" || bad "A4: $H"

# A5 season-distinctness (the 94 lesson)
D=$(curl -s "$BASE/api/topscorers/laliga" | py "
import sys,json
v=(json.load(sys.stdin).get('teamPossession') or [{}])[0].get('teamPossession',0)
print(1 if abs(v-69.4)<1e-9 else 0)
")
[ "$D" = "1" ] && ok "A5 season-distinctness: current rank-1 69.4 ≠ historical 65.8 (the two seasons provably serve DIFFERENT files)" || bad "A5: $D"

# A6 the negative season probe
NG=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F21" | py "import sys,json;d=json.JSONDecoder().raw_decode(sys.stdin.read())[0];print(1 if (d.get('ok')==False and 'Invalid season' in str(d.get('error'))) else 0)")
[ "$NG" = "1" ] && ok "A6 negative probe: season 2020/21 → {ok:false, Invalid season} (the two-stage shape contract)" || bad "A6: $NG"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B1=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const iT=h2s.indexOf('گل مورد انتظار تیم‌ها'), iCS=h2s.indexOf('گل نخرده‌های تیم‌ها'), iPOS=h2s.indexOf('مالکیت توپ تیم‌ها'); const order=iT>-1&&iCS>iT&&iPOS>iCS; const q=['درصد سیو','سیو در هر ۹۰','گل نخرده‌ها','گل‌های پیشگیری‌شده','پنالتی‌های مهارشده'].map(x=>h2s.indexOf(x)); const quintet=q.every(i=>i>-1)&&q.every((i,k)=>k===0||i>q[k-1]); const rows=[...document.querySelectorAll('[data-testid=tposs-row]')]; const vbroken=[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length; return JSON.stringify({order,quintet,n:rows.length,vbroken}); })()")
echo "$B1" | tr -d '\\' | grep -q '"order":true' && echo "$B1" | tr -d '\\' | grep -q '"quintet":true' && echo "$B1" | tr -d '\\' | grep -q '"n":10' && echo "$B1" | tr -d '\\' | grep -q '"vbroken":0' && ok "B1 DOM: «مالکیت توپ تیم‌ها» h2 renders + 10 tposs-rows on /topscorers/laliga + the order گل مورد انتظار تیم‌ها < گل نخرده‌های تیم‌ها < مالکیت توپ تیم‌ها (the THREE team-side blocks adjacent) + the keeper QUINTET untouched + zero real overflow @390x844" || bad "B1: $B1"
B2=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=tposs-row]')]; const a=rows[0]&&rows[0].querySelector('a'); const pill=a&&a.lastElementChild; const innerOvf=rows.filter(r=>r.scrollWidth>r.clientWidth+1).length; const latinPill=rows.filter(r=>/[0-9]/.test((r.querySelector('[dir=ltr]')||{}).textContent||'')).length; return JSON.stringify({pill:(pill&&pill.textContent.trim())||'', dir:(pill&&pill.getAttribute('dir'))||null, innerOvf, latinPill}); })()")
echo "$B2" | tr -d '\\' | grep -q '"dir":"ltr"' && echo "$B2" | tr -d '\\' | grep -q '"pill":"۶۹.۴"' && echo "$B2" | tr -d '\\' | grep -q '"innerOvf":0' && echo "$B2" | tr -d '\\' | grep -q '"latinPill":0' && ok "B2 DOM: the percent pill dir=ltr renders «۶۹.۴» on the first row (toFixed(1) with NO appended sign, the 221 percent convention) + zero Latin digits + zero row-level inner overflow" || bad "B2: $B2"
HREF=$(agent-browser eval "document.querySelector('[data-testid=tposs-row] a')?.getAttribute('href') || 'NO_LINK'" | tr -d '"' | tr -d '\\')
if [ "$HREF" = "/team/8634" ]; then
  agent-browser eval "window.location.href='$HREF'" >/dev/null
  sleep 2.5
  B3=$(agent-browser eval "JSON.stringify({path:location.pathname, h1:(document.querySelector('h1')||{}).textContent})")
  echo "$B3" | tr -d '\\' | grep -q '"/team/8634"' && echo "$B3" | tr -d '\\' | grep -q '"بارسلونا"' && ok "B3 DOM: the first tposs-row really navigates to /team/8634 with the teamFa h1 «بارسلونا» (the standings-view link contract)" || bad "B3: $B3"
else
  bad "B3: first tposs-row href is $HREF (expected /team/8634)"
fi
agent-browser open "$BASE/topscorers/persiangulf" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B4=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); return JSON.stringify({pos:h2s.includes('مالکیت توپ تیم‌ها'), any:h2s.length>0}); })()")
echo "$B4" | tr -d '\\' | grep -q '"pos":false' && echo "$B4" | tr -d '\\' | grep -q '"any":true' && ok "B4 DOM: persiangulf honestly hides the section (no مالکیت توپ تیم‌ها h2) while its other blocks still render" || bad "B4: $B4"
agent-browser open "$BASE/topscorers/mas" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 2.5
B5=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); return JSON.stringify({pos:h2s.includes('مالکیت توپ تیم‌ها'), cards:h2s.includes('کارت‌ها')}); })()")
echo "$B5" | tr -d '\\' | grep -q '"pos":false' && echo "$B5" | tr -d '\\' | grep -q '"cards":true' && ok "B5 DOM: mas honestly hides the possession section while its cards block still renders (the 176 mas contract) — the 237 absence pair in DOM" || bad "B5: $B5"
CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B6 console=0 errors=0 across the whole session" || bad "B6: console=$CN errors=$CE"
agent-browser close >/dev/null 2>&1

echo "== Part C: warm LAT =="
T0=$(date +%s%N); curl -s -o /dev/null "$BASE/api/topscorers/laliga"; T1=$(date +%s%N)
MS=$(( (T1-T0)/1000000 ))
[ "$MS" -lt 5000 ] && ok "LAT warm /api/topscorers/laliga = ${MS}ms (<5000ms)" || bad "LAT: ${MS}ms"

echo "== VERDICT =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE241 DOMPROOF ALL GREEN («مالکیت توپ تیم‌ها» — the deep-file family's TWENTY-FIRST sibling and its THIRD TEAM-PARTICIPANT member: the team-side possession surface, WIDE on all six domestics at top-10, portugal breadth, the 237 absence pair pg+mas honestly empty, season-aware with the frozen Barcelona 65.8 anchor, the 221 percent toFixed(1) pill with no appended sign — API 6/6 + DOM 6/6 + LAT @390x844)" && exit 0
exit 1
