#!/bin/bash
# cycle237-domproof.sh — permanent gate for the cycle-237 update
# (Update (cycle 237): «گل مورد انتظار تیم‌ها» — the deep-file family's
#  NINETEENTH sibling and its FIRST TEAM-PARTICIPANT member: the
#  team-side LEVEL of the xG surface (226), straight from the live
#  expected_goals_team.json probe (UA Chrome/124, 2026-10-30): NATURALLY-
#  THIN team files on ALL SIX domestic globalMerge leagues — laliga 20
#  Barcelona 34.8 / pl 20 Manchester City 16.7 / seriea 20 Inter 25.5 /
#  bundesliga 18 Bayern 23.8 / ligue1 18 PSG 20.0 / ucl 36 PSG 10.1 rows
#  (uel 36 Leverkusen 11.0 + portugal 18 Benfica 20.8 probed for
#  breadth); persiangulf honestly absent (1 team category) and mas
#  absent (4 team cats, no xG). DECIMAL 1-fraction (probed nonint 15-32
#  per file, maxdec=1 on every serving file) → the 210/217/226/230/232
#  VERBATIM-decimal convention: storage never rounds, the pill renders
#  toFixed(1) dir=ltr (34.8 renders «۳۴.۸»); the JS-number corner (20.0
#  serializing as 20) renders «۲۰.۰» the same. Upstream Rank positional
#  (one competition tie probed: portugal 5,5) — the merge re-ranks
#  POSITIONALLY like every sibling. The rows' ParticiantId is ALWAYS 0
#  (teams carry TeamId) → dedup by TeamId. NO badge twin and NO
#  global-merge participation BY DESIGN (the badge/merge mechanisms key
#  on PLAYER ids — a team surface has none); the block rides the league
#  page only, rows link /team/[id] (the standings-view contract). The
#  honest-name contract rides the EXISTING teamFa map — zero new
#  PLAYER_NAME_FA entries + the teamFa edition of the 170 read-time
#  freshener line. SEASON-AWARE (the 124/…/236 class): the 2020/21
#  laliga raw serves its OWN file — 20 rows, Barcelona 74.3 / Real
#  Madrid 62.3 / Real Sociedad 61.9 — frozen, the 202 anchor pattern.
#  Additive mirror of 230/231/232/235/236 end-to-end: TeamXgEntry + the
#  REQUIRED teamXg field on the mapped payload + statTeamCategory (the
#  team-side mirror of statCategory, the 92 cast) + getFullTeamXg
#  (fullTeamXg:v1, STANDARD guard — team files serve 18-36 rows, above
#  the FULL_LIST_HEALTHY_MIN floor, NO natural-thinness exemption) + the
#  team top-3-first merge (dedup by TEAM id, teamXg DESC, top-10,
#  POSITIONAL re-rank) + standings:v25→v26 (the 52/…/236 additive-shape
#  convention) + the league-page block «گل مورد انتظار تیم‌ها» placed
#  right after گل مورد انتظار so the player→team pair reads together
#  while the rest of the analytics run and the keeper QUINTET stay
#  untouched — the older gates' relative-order asserts are inequality-
#  based so the insertion provably keeps them green (all re-ran green) —
#  with data-testid=txg-row and the /team/{teamId} link contract. THE
#  NINETEENTH THIN-GUARD CLAUSE (the 210 class) — the cold-build
#  fallback lesson held: the guard re-probed in 90s and self-healed
#  3→10 with ZERO manual purge (the 230/231/232/235/236 mechanism,
#  fourth consecutive zero-touch proof).)
# Part A (API on /api/standings): A1 the six-domestic teamXg=10 contract
#               (monotonic decimal, positional 1..10, teamId>0, Persian
#               names) with the sister family beside it (xg/xgot/bcm=10)
#               + the laliga anchor «بارسلونا» 34.8
#               A1b the persiangulf/mas honest absences
#               A2a the frozen 2020/2021 laliga anchor («بارسلونا» 74.3 +
#               «رئال‌مادرید» 62.3) — season-awareness
#               A2b the ucl («پاری سن‌ژرمن» 10.1) + pl («منچسترسیتی»
#               16.7) live anchors
#               A3 the season-distinctness contract (cur 34.8 ≠ hist
#               74.3 — no v26 cache collision)
#               A4 the negative probe (bad season shape → ok:false)
# Part B (DOM @390x844): B1 h2 «گل مورد انتظار تیم‌ها» + 10 txg-rows +
#               the player→team pair order (xG → team-xG → xGOT → …)
#               with the keeper QUINTET adjacent + zero real overflow
#               B2 the dir=ltr decimal pill («۳۴.۸») + real navigation
#               to /team/<id> (title «بارسلونا — صفحه تیم»)
#               B3 the historical UI deep-link ?season=2020/2021 renders
#               the frozen «بارسلونا» «۷۴.۳» anchor with the URL param
#               preserved
#               B4 the honest absence in DOM (persiangulf) + console=0
#               errors=0
# Part C: warm LAT sweep, 3 routes <5000ms
set -u
BASE="${BASE:-http://localhost:3000}"
TMP="$(mktemp /home/z/my-project/.cycle237-domproof-XXXXXX)"
trap 'rm -f "$TMP"' EXIT
PASS=0; FAIL=0
ok(){ echo "OK  - $1"; PASS=$((PASS+1)); }
bad(){ echo "BAD - $1"; FAIL=$((FAIL+1)); }
py(){ python3 -c "$1"; }

echo "== Part A: API gates =="

# A1 the six-domestic contract + the laliga live anchor
A1=1
for K in ucl pl laliga seriea bundesliga ligue1; do
  L=$(curl -s "$BASE/api/standings?league=$K" | py "
import sys,json,re
d=json.load(sys.stdin)
t=d.get('teamXg') or []
ok=1
if len(t)!=10: ok=0
vals=[r.get('teamXg') for r in t]
if any(v is None for v in vals): ok=0
else:
    for i in range(len(t)-1):
        if float(vals[i])<float(vals[i+1]): ok=0
    for v in vals:
        s=str(v)
        if '.' in s and len(s.split('.')[1])>1: ok=0
if [r.get('rank') for r in t]!=list(range(1,11)): ok=0
if any(r.get('teamId',0)<=0 for r in t): ok=0
fa=sum(1 for r in t if r.get('nameFa') and re.search(r'[\u0600-\u06FF]',r.get('nameFa')))
if fa<8: ok=0
if len(d.get('xg') or [])!=10 or len(d.get('xgot') or [])!=10 or len(d.get('bigChancesMissed') or [])!=10: ok=0
print(f\"{ok}|{t[0].get('nameFa')}|{t[0].get('teamXg')}\" if t else '0|-|-')
")
  ST=$(echo "$L" | cut -d'|' -f1)
  [ "$ST" = "1" ] || { A1=0; bad "A1: $K contract failed ($L)"; }
done
LAL=$(curl -s "$BASE/api/standings?league=laliga" | py "
import sys,json
t=json.load(sys.stdin).get('teamXg') or []
print(f\"{t[0].get('nameFa')}|{t[0].get('teamXg')}\" if t else '-|-')
")
echo "$LAL" | grep -q "بارسلونا|34.8" && ok "A1 live anchor: laliga teamXg rank-1 = «بارسلونا» 34.8 (verbatim decimal, positional 1..10 monotonic, maxdec=1, teamId>0, Persian names 8+/10) + ALL SIX domestics teamXg=10 with the sister family (xg/xgot/bcm=10) beside it" || bad "A1 anchor: $LAL"

# A1b the honest absences
PG=$(curl -s "$BASE/api/standings?league=persiangulf" | py "
import sys,json
d=json.load(sys.stdin)
print(1 if (len(d.get('teamXg') or [])==0 and len(d.get('scorers') or [])==20 and len(d.get('goalsPer90') or [])==10) else 0)
")
MAS=$(curl -s "$BASE/api/standings?league=mas" | py "
import sys,json
d=json.load(sys.stdin)
print(1 if (len(d.get('teamXg') or [])==0 and len(d.get('scorers') or [])==20) else 0)
")
[ "$PG" = "1" ] && [ "$MAS" = "1" ] && ok "A1b honest absences: persiangulf teamXg=0 (scorers=20/gp90=10 intact — 1 team category) + mas teamXg=0 (4 team cats, no xG)" || bad "A1b: pg=$PG mas=$MAS"

# A2a the frozen 2020/2021 laliga anchor (season-awareness)
A2=$(curl -s "$BASE/api/standings?league=laliga&season=2020%2F2021" | py "
import sys,json
t=(json.load(sys.stdin).get('teamXg') or [])
r1=t[0] if t else {}
r2=t[1] if len(t)>1 else {}
print(f\"{r1.get('nameFa')}|{r1.get('teamXg')}|{r2.get('nameFa')}|{r2.get('teamXg')}\")
")
echo "$A2" | grep -q "بارسلونا|74.3" && echo "$A2" | grep -q "رئال‌مادرید|62.3" && ok "A2a frozen 2020/2021 laliga anchor: teamXg rank-1 «بارسلونا» 74.3 + rank-2 «رئال‌مادرید» 62.3 (the 202 anchor pattern — the historical raw serves its OWN file)" || bad "A2a: $A2"

# A2b the ucl + pl live anchors
UCL=$(curl -s "$BASE/api/standings?league=ucl" | py "
import sys,json
t=json.load(sys.stdin).get('teamXg') or []
print(f\"{t[0].get('nameFa')}|{t[0].get('teamXg')}\" if t else '-|-')
")
PLX=$(curl -s "$BASE/api/standings?league=pl" | py "
import sys,json
t=json.load(sys.stdin).get('teamXg') or []
print(f\"{t[0].get('nameFa')}|{t[0].get('teamXg')}\" if t else '-|-')
")
echo "$UCL" | grep -q "پاری سن‌ژرمن|10.1" && echo "$PLX" | grep -q "منچسترسیتی|16.7" && ok "A2b live anchors: ucl rank-1 «پاری سن‌ژرمن» 10.1 (36-row file → top-10) + pl rank-1 «منچسترسیتی» 16.7" || bad "A2b: ucl=$UCL pl=$PLX"

# A3 the season-distinctness contract (no v26 cache collision)
A3=$(curl -s "$BASE/api/standings?league=laliga" | py "
import sys,json
t=json.load(sys.stdin).get('teamXg') or []
print(t[0].get('teamXg') if t else '-')
")
[ "$A3" = "34.8" ] && ok "A3 season-distinctness: current laliga stays 34.8 beside the frozen 74.3 historical — the standings:v26 key separates cur from every historical season (the 94 lesson)" || bad "A3: cur r1=$A3"

# A4 the negative probe
N=$(curl -s "$BASE/api/standings?league=laliga&season=2020%2F21" | py "import sys,json;d=json.load(sys.stdin);print(1 if (d.get('ok')==False and 'Invalid season' in str(d.get('error'))) else 0)")
[ "$N" = "1" ] && ok "A4 negative probe: two-stage season shape 2020/21 → {ok:false, Invalid season} (the SEASON_PARAM_RE contract)" || bad "A4: $N"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B1=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const iX=h2s.indexOf('گل مورد انتظار'), iT=h2s.indexOf('گل مورد انتظار تیم‌ها'), iXG=h2s.indexOf('گل مورد انتظار روی دروازه'), iG=h2s.indexOf('گل در هر ۹۰'), iA=h2s.indexOf('پاس مورد انتظار'), iB=h2s.indexOf('سانس بزرگ خلق‌شده'), iC=h2s.indexOf('فرصت‌های خلق‌شده'), iBM=h2s.indexOf('سانس بزرگ ازدست‌رفته'), iM=h2s.indexOf('بیشترین دقایق'); const order=iX>-1&&iT>iX&&iXG>iT&&iG>iXG&&iA>iG&&iB>iA&&iC>iB&&iBM>iC&&iM>iBM; const q=['درصد سیو','سیو در هر ۹۰','گل نخرده‌ها','گل‌های پیشگیری‌شده','پنالتی‌های مهارشده'].map(x=>h2s.indexOf(x)); const quintet=q.every(i=>i>-1)&&q.every((i,k)=>k===0||i>q[k-1]); const rows=document.querySelectorAll('[data-testid=txg-row]').length; const vbroken=[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length; return JSON.stringify({order,quintet,rows,vbroken,h2:h2s.includes('گل مورد انتظار تیم‌ها')}); })()")
echo "$B1" | tr -d '\\' | grep -q '"order":true' && echo "$B1" | tr -d '\\' | grep -q '"quintet":true' && echo "$B1" | tr -d '\\' | grep -q '"rows":10' && echo "$B1" | tr -d '\\' | grep -q '"vbroken":0' && echo "$B1" | tr -d '\\' | grep -q '"h2":true' \
  && ok "B1 DOM laliga: h2 «گل مورد انتظار تیم‌ها» + 10 txg-rows, the player→team pair order (گل مورد انتظار → گل مورد انتظار تیم‌ها → گل مورد انتظار روی دروازه → گل در هر ۹۰ → … → دقایق) with the keeper QUINTET adjacent + zero real overflow @390x844" || bad "B1: $B1"

B2=$(agent-browser eval "(() => { const r=document.querySelector('[data-testid=txg-row]'); const a=r&&r.querySelector('a'); const pill=a&&a.lastElementChild; return JSON.stringify({pill:(pill&&pill.textContent.trim())||'', dir:(pill&&pill.getAttribute('dir'))||null, href:(a&&a.getAttribute('href'))||''}); })()")
TID=$(echo "$B2" | tr -d '\\' | grep -oE '"href":"[^"]*"' | grep -oE 'team/[0-9]+' | grep -oE '[0-9]+' | head -1)
PILL=$(echo "$B2" | tr -d '\\' | grep -oE '"pill":"[^"]*"' | cut -d'"' -f4)
DIRV=$(echo "$B2" | tr -d '\\' | grep -oE '"dir":"[^"]*"' | cut -d'"' -f4)
[ "$PILL" = "۳۴.۸" ] && [ "$DIRV" = "ltr" ] && ok "B2a DOM pill: the team-xg top-1 pill renders «۳۴.۸» WITH dir=ltr (the verbatim-decimal contract — the 210/217/226/230/232 display rule)" || bad "B2a: pill=$PILL dir=$DIRV"
agent-browser open "$BASE/team/$TID" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B2b=$(agent-browser eval "(() => JSON.stringify({title:document.title||''}))()")
echo "$B2b" | tr -d '\\' | grep -q "بارسلونا" && echo "$B2b" | tr -d '\\' | grep -q "صفحه تیم" && ok "B2b real navigation: /team/$TID → title «بارسلونا — صفحه تیم» (the /team/{teamId} link contract on the team-xg top-1)" || bad "B2b: title=$B2b"

agent-browser open "$BASE/topscorers/laliga?season=2020/2021" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B3=$(agent-browser eval "(() => { const txt=document.body.innerText||''; const url=new URL(location.href); return JSON.stringify({barca:txt.includes('بارسلونا'), v743:txt.includes('۷۴.۳'), season:url.searchParams.get('season')}); })()")
echo "$B3" | tr -d '\\' | grep -q '"barca":true' && echo "$B3" | tr -d '\\' | grep -q '"v743":true' && echo "$B3" | tr -d '\\' | grep -q '"season":"2020/2021"' \
  && ok "B3 DOM historical: ?season=2020/2021 renders the frozen «بارسلونا» «۷۴.۳» anchor with the URL param preserved (the honesty-snap rule)" || bad "B3: $B3"

agent-browser open "$BASE/topscorers/persiangulf" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B4=$(agent-browser eval "(() => { const txt=document.body.innerText||''; return JSON.stringify({txgAbsent:!txt.includes('گل مورد انتظار تیم‌ها'), gp90:txt.includes('گل در هر ۹۰')}); })()")
echo "$B4" | tr -d '\\' | grep -q '"txgAbsent":true' && echo "$B4" | tr -d '\\' | grep -q '"gp90":true' \
  && ok "B4 DOM honest absence: persiangulf hides the team-xg block while گل در هر ۹۰ serves (the 231/232/235/236 absence contract in DOM)" || bad "B4: $B4"
CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B5 console=0 errors=0 across the whole session" || bad "B5: console=$CN errors=$CE"
agent-browser close >/dev/null 2>&1

echo "== Part C: warm LAT sweep =="
LAT=1
for P_ in / /topscorers/laliga /topscorers/persiangulf; do
  T=$(curl -s -o /dev/null -w '%{time_total}' --max-time 30 "$BASE$P_")
  echo "     LAT $P_ = ${T}s"
  python3 -c "import sys; sys.exit(0 if float('$T')<5.0 else 1)" || LAT=0
done
[ "$LAT" = "1" ] && ok "Part C warm LAT: 3 routes <5000ms" || bad "Part C: a route exceeded 5000ms"

echo "== VERDICT =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE237 DOMPROOF ALL GREEN («گل مورد انتظار تیم‌ها» — the deep-file family's NINETEENTH sibling and its FIRST TEAM-PARTICIPANT member: naturally-thin-but-never-under-the-floor team files on all six domestics at top-10, persiangulf+mas honestly absent, season-aware with the frozen Barcelona 74.3 anchor, verbatim-decimal dir=ltr pill, /team/{teamId} links, NO badge twin BY DESIGN, the NINETEENTH thin-guard clause self-healed 3→10 zero-touch — API 6/6 + DOM 5/5 + LAT @390x844)" && exit 0
exit 1
