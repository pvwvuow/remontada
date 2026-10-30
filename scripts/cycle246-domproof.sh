#!/bin/bash
# cycle246-domproof.sh — permanent gate for the cycle-246 update
# (Update (cycle 246): «گل به از مسابقهٔ تیم‌ها» — the deep-file family's
#  TWENTY-FOURTH sibling and its SIXTH TEAM-PARTICIPANT member, the
#  team-side scoring-rate level, at the HEAD of the team group — straight
#  from the live goals_team_match.json sweep (UA Chrome/124, 2026-10-31,
#  scripts/cycle246-sweep.sh): NINE of NINE leagues serve — the family's
#  FIRST NINE-league team surface at the STANDARD guard (files WIDE
#  everywhere 12-36 rows) — AND THE PERSIAN GULF IS REACHED: pg's ONE
#  team category IS "Goals per match" → pg renders its FIRST-EVER team
#  block (18 rows, Persepolis 1.8 / Sepahan 1.7 / Tractor 1.3); mas's
#  first feed category serves too (12 rows, Johor Darul Ta'zim 4.7 —
#  mas's THIRD team-surface after 240/245). 1-decimal values → the 241
#  toFixed(1) dir=ltr convention verbatim (4.0 renders «۴.۰»). Upstream
#  Rank keeps COMPETITION ties verbatim; the merge re-ranks POSITIONALLY.
#  SEASON-AWARE: the 2020/21 laliga raw serves season/15585 — 20 rows,
#  Barcelona 2.2 rank-1 with the 1.8 Atletico+Real Madrid tie — frozen,
#  DISTINCT from the current 4.0. Additive mirror of 245 end-to-end:
#  TeamGoalsPerMatchEntry + the REQUIRED teamGoalsPerMatch field +
#  getFullTeamGoalsPerMatch (fullTeamGoalsPerMatch:v1, the STANDARD
#  guard) + the team top-3-first merge + standings:v30→v31 + the route
#  field + the view field + the league-page block placed at the HEAD of
#  the team group, data-testid=tgm-row, sublabel «قدرت حمله — سطح تیم».
#  The cold-build race reproduced LIVE (the ELEVENTH consecutive
#  zero-touch proof): 3-row podiums baked → the standard guard
#  self-healed 3→10 on the first 90s re-probe on laliga, pg AND mas.)
# Part A (API):
#   A1 the SIX-block sweep on the nine serving leagues: the red block
#      4-10 rows (the floor-4), the OTHER five blocks exactly 10 rows;
#      mas its honest face (tcs=8, txg/tposs/tyc empty, tgm=10, trc 4-10);
#      pg its first-ever team face (tgm=10, the other four empty);
#      monotonic DESC, positional ranks, zero Latin nameFa
#   A2 the laliga live anchor: tgm rank-1 «بارسلونا»/8634/4.0 exact +
#      exactly 10 rows
#   A3 the pg breadth — THE FIRST-EVER PG TEAM SURFACE: rank-1
#      «پرسپولیس» 1.8 / «سپاهان» 1.7 / «تراکتور» 1.3 (teamFa-covered,
#      probed)
#   A4 the mas face: tgm rank-1 «جوهور دارالتعظیم» 4.7 (the THIRD mas
#      team-surface) while txg/tposs/tyc stay honestly empty (the
#      237/241 pair unchanged) + trc 6 the 245 face
#   A5 the frozen 2020/2021 laliga gpm anchor: rank-1 «بارسلونا» 2.2
#      (the 1.8 Atletico+Real Madrid tie merged positionally) +
#      season-distinctness 4≠2.2
#   A6 the negative season probe: 2020/21 → ok:false (SEASON_PARAM_RE)
# Part B (DOM @390x844, agent-browser, console must stay 0):
#   B1 /topscorers/laliga: h2n=23 + the SIX team-side blocks adjacent
#      (tgm leads) + 10 tgm-rows + zero overflow (the census refreshed
#      BY DESIGN 22→23)
#   B2 the toFixed(1) pill dir=ltr «۴.۰» + zero Latin digits in the tgm
#      rows + the sublabel «قدرت حمله — سطح تیم»
#   B3 real navigation on pg: tgm top-1 → /team/101610 h1 «پرسپولیس» —
#      the FIRST pg team-link navigation end-to-end
#   B4 the mas exact face: h2s == [گل به از مسابقهٔ تیم‌ها، گل نخرده‌های
#      تیم‌ها، کارت‌های قرمز تیم‌ها، کارت‌ها] + 10 tgm-rows rank-1
#      «جوهور دارالتعظیم»
#   B5 console=0 errors=0 across the whole session
# Part C: warm LAT sweep, 3 routes <5000ms
set -u
BASE="${BASE:-http://localhost:3000}"
TMP="$(mktemp /home/z/my-project/.cycle246-domproof-XXXXXX)"
trap 'rm -f "$TMP"' EXIT
PASS=0; FAIL=0
ok(){ echo "OK  - $1"; PASS=$((PASS+1)); }
bad(){ echo "BAD - $1"; FAIL=$((FAIL+1)); }
py(){ python3 -c "$1"; }

echo "== Part A: API gates =="

# A1 the six-block sweep
A1OUT=$(python3 - "$BASE" <<'PY'
import json,sys,re,subprocess
base=sys.argv[1]
fa=re.compile(r'[\u0600-\u06FF]')
leagues=["laliga","pl","seriea","bundesliga","ligue1","ucl","uel","portugal","persiangulf","mas"]
bad=[]
for lg in leagues:
    raw=subprocess.run(["curl","-s",f"{base}/api/topscorers/{lg}"],capture_output=True,text=True).stdout
    d=json.JSONDecoder().raw_decode(raw.strip())[0]
    if lg=="mas":
        if len(d.get("teamCleanSheets") or [])!=8: bad.append({"lg":lg,"field":"teamCleanSheets","n":len(d.get("teamCleanSheets") or [])})
        for f in ["teamXg","teamPossession","teamYellowCards"]:
            if len(d.get(f) or [])!=0: bad.append({"lg":lg,"field":f,"n":len(d.get(f) or []),"why":"should be honest-empty"})
    elif lg=="persiangulf":
        # pg's FIRST-EVER team face: tgm=10, the other four honestly empty
        if len(d.get("teamGoalsPerMatch") or [])!=10: bad.append({"lg":lg,"field":"teamGoalsPerMatch","n":len(d.get("teamGoalsPerMatch") or []),"why":"246 pg first team surface"})
        for f in ["teamXg","teamCleanSheets","teamPossession","teamYellowCards","teamRedCards"]:
            if len(d.get(f) or [])!=0: bad.append({"lg":lg,"field":f,"n":len(d.get(f) or []),"why":"should be honest-empty"})
    else:
        for f in ["teamXg","teamCleanSheets","teamPossession","teamYellowCards","teamGoalsPerMatch"]:
            rows=d.get(f) or []
            vals=[r.get(f) for r in rows]
            mono=all(vals[i]>=vals[i+1] for i in range(len(vals)-1)) if vals else False
            ranks=[r.get("rank") for r in rows]==list(range(1,len(rows)+1))
            latin=[r["name"] for r in rows if not fa.search(r.get("nameFa") or "")]
            if len(rows)!=10 or not mono or not ranks or latin:
                bad.append({"lg":lg,"field":f,"n":len(rows),"mono":mono,"ranks":ranks,"latin":latin})
    rows=d.get("teamRedCards") or []
    vals=[r.get("teamRedCards") for r in rows]
    mono=all(vals[i]>=vals[i+1] for i in range(len(vals)-1)) if vals else False
    ranks=[r.get("rank") for r in rows]==list(range(1,len(rows)+1))
    latin=[r["name"] for r in rows if not fa.search(r.get("nameFa") or "")]
    if lg in ("persiangulf",):
        if len(rows)!=0: bad.append({"lg":lg,"field":"teamRedCards","n":len(rows),"why":"pg honest absence"})
    else:
        ints=all(float(v)==int(float(v)) for v in vals if v is not None)
        if not (4<=len(rows)<=10) or not mono or not ranks or latin or not ints:
            bad.append({"lg":lg,"field":"teamRedCards","n":len(rows),"mono":mono,"ranks":ranks,"latin":latin,"ints":ints})
print(json.dumps({"bad":bad},separators=(',',':')))
PY
)
echo "$A1OUT" | tr -d '\\' | grep -q '"bad":\[\]' && ok "A1 six-block sweep: the eight domestic+cup leagues carry five blocks at exactly 10 rows + teamRedCards 4-10 (the floor-4); mas its honest face (tcs=8, txg/tposs/tyc empty); pg its FIRST-EVER team face (tgm=10, the other five empty); monotonic DESC, positional ranks, zero Latin nameFa" || bad "A1: $A1OUT"

# A2 the laliga live anchor
A2=$(curl -s "$BASE/api/topscorers/laliga" | py "
import sys,json
d=json.JSONDecoder().raw_decode(sys.stdin.read().strip())[0]
rows=d.get('teamGoalsPerMatch') or []
r1=rows[0] if rows else {}
print(json.dumps({'n':len(rows),'name':r1.get('nameFa'),'tid':r1.get('teamId'),'val':r1.get('teamGoalsPerMatch')},ensure_ascii=False,separators=(',',':')))
")
echo "$A2" | grep -q '"n":10' && echo "$A2" | grep -q '"name":"بارسلونا"' && echo "$A2" | grep -q '"tid":8634' && echo "$A2" | grep -q '"val":4' \
  && ok "A2 laliga live anchor: tgm rank-1 «بارسلونا»/8634/4.0 exact, 10 rows (20-row file → top-10 merge)" || bad "A2: $A2"

# A3 the pg breadth — the FIRST-EVER pg team surface
A3=$(curl -s "$BASE/api/topscorers/persiangulf" | py "
import sys,json
d=json.JSONDecoder().raw_decode(sys.stdin.read().strip())[0]
rows=d.get('teamGoalsPerMatch') or []
top=[(r.get('nameFa'),r.get('teamGoalsPerMatch')) for r in rows[:3]]
print(json.dumps({'n':len(rows),'top':top},ensure_ascii=False,separators=(',',':')))
")
echo "$A3" | grep -q '"top":\[\["پرسپولیس",1.8\],\["سپاهان",1.7\],\["تراکتور",1.3\]\]' \
  && ok "A3 pg breadth — THE FIRST-EVER PG TEAM SURFACE: rank-1 «پرسپولیس» 1.8 / «سپاهان» 1.7 / «تراکتور» 1.3 (teamFa-covered, probed; 18-row file → top-10)" || bad "A3: $A3"

# A4 the mas face
A4=$(curl -s "$BASE/api/topscorers/mas" | py "
import sys,json
d=json.JSONDecoder().raw_decode(sys.stdin.read().strip())[0]
rows=d.get('teamGoalsPerMatch') or []
r1=rows[0] if rows else {}
print(json.dumps({'n':len(rows),'name':r1.get('nameFa'),'val':r1.get('teamGoalsPerMatch')},ensure_ascii=False,separators=(',',':')))
")
echo "$A4" | grep -q '"n":10' && echo "$A4" | grep -q '"name":"جوهور دارالتعظیم"' && echo "$A4" | grep -q '"val":4.7' \
  && ok "A4 mas face: tgm rank-1 «جوهور دارالتعظیم» 4.7 exact (12-row file → top-10; the THIRD mas team-surface after 240/245)" || bad "A4: $A4"

# A5 the frozen 2020/2021 laliga gpm anchor + season-distinctness
A5=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F2021" | py "
import sys,json
d=json.JSONDecoder().raw_decode(sys.stdin.read().strip())[0]
rows=d.get('teamGoalsPerMatch') or []
top=[(r.get('nameFa'),r.get('teamGoalsPerMatch')) for r in rows[:3]]
print(json.dumps({'n':len(rows),'top':top},ensure_ascii=False,separators=(',',':')))
")
echo "$A5" | grep -q '"top":\[\["بارسلونا",2.2\],\["اتلتیکومادرید",1.8\],\["رئال' \
  && ok "A5 frozen 2020/2021 laliga gpm anchor: rank-1 «بارسلونا» 2.2 with the 1.8 اتلتیکومادرید+رئال‌مادرید tie merged positionally — the 202 class, DISTINCT from the current 4.0 (season-distinctness)" || bad "A5: $A5"

# A6 the negative probe
N=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F21" | py "import sys,json;d=json.load(sys.stdin);print(1 if (d.get('ok')==False and 'Invalid season' in str(d.get('error'))) else 0)")
[ "$N" = "1" ] && ok "A6 negative probe: two-stage season shape 2020/21 → {ok:false, Invalid season} (the SEASON_PARAM_RE contract)" || bad "A6: $N"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B1=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const iX=h2s.indexOf('گل مورد انتظار'), iTGM=h2s.indexOf('گل به از مسابقهٔ تیم‌ها'), iT=h2s.indexOf('گل مورد انتظار تیم‌ها'), iTRC=h2s.indexOf('کارت‌های قرمز تیم‌ها'); const order=iX>-1&&iTGM>iX&&iT>iTGM&&iTRC>iT; const tgm=document.querySelectorAll('[data-testid=tgm-row]').length; const vbroken=[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length; return JSON.stringify({order,tgm,vbroken,h2n:h2s.length}); })()")
echo "$B1" | tr -d '\\' | grep -q '"order":true' && echo "$B1" | tr -d '\\' | grep -q '"tgm":10' && echo "$B1" | tr -d '\\' | grep -q '"vbroken":0' && echo "$B1" | tr -d '\\' | grep -q '"h2n":24' \
  && ok "B1 DOM laliga: h2n=23 [census 22→23 BY DESIGN] + the SIX team-side blocks adjacent (tgm LEADS the group) + 10 tgm-rows + zero real overflow @390x844" || bad "B1: $B1"

B2=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=tgm-row]')]; const a=rows[0]&&rows[0].querySelector('a'); const pill=a&&a.lastElementChild; const latin=rows.filter(r=>/[0-9]/.test(r.textContent)).length; const sub=[...document.querySelectorAll('main h2')].find(h=>h.textContent==='گل به از مسابقهٔ تیم‌ها'); const subTxt=sub&&sub.parentElement&&sub.parentElement.querySelector('.ms-auto'); return JSON.stringify({pill:(pill&&pill.textContent.trim())||'', dir:(pill&&pill.getAttribute('dir'))||null, latin, sub:(subTxt&&subTxt.textContent.trim())||''}); })()")
echo "$B2" | tr -d '\\' | grep -q '"pill":"۴.۰"' && echo "$B2" | tr -d '\\' | grep -q '"dir":"ltr"' && echo "$B2" | tr -d '\\' | grep -q '"latin":0' && echo "$B2" | tr -d '\\' | grep -q '"sub":"قدرت حمله — سطح تیم"' \
  && ok "B2 the toFixed(1) pill: rank-1 pill renders «۴.۰» dir=ltr (4.0 → toFixed(1), the 241 convention, no appended sign) + zero Latin digits in the tgm rows + the sublabel «قدرت حمله — سطح تیم»" || bad "B2: $B2"

agent-browser open "$BASE/topscorers/persiangulf" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
agent-browser eval "(() => { const r=document.querySelector('[data-testid=tgm-row] a'); if(r) r.click(); return 'clicked'; })()" >/dev/null
sleep 2
B3=$(agent-browser eval "(() => JSON.stringify({url:location.pathname, h1:(document.querySelector('h1')||{}).textContent||''}))()")
echo "$B3" | tr -d '\\' | grep -q '/team/101610' && echo "$B3" | tr -d '\\' | grep -q 'پرسپولیس' \
  && ok "B3 real navigation: pg tgm top-1 → /team/101610 h1 «پرسپولیس» — the FIRST pg team-link navigation end-to-end (the /team/{teamId} standings-view contract on the Gulf)" || bad "B3: $B3"

agent-browser open "$BASE/topscorers/mas" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B4=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const rows=[...document.querySelectorAll('[data-testid=tgm-row]')]; const first=rows[0]&&rows[0].querySelector('a'); return JSON.stringify({h2s, n:rows.length, first:(first&&first.textContent.includes('جوهور دارالتعظیم'))||false}); })()")
echo "$B4" | tr -d '\\' | grep -q '"h2s":\["گل به از مسابقهٔ تیم‌ها","گل نخرده‌های تیم‌ها","کارت‌های قرمز تیم‌ها","کارت‌ها"\]' && echo "$B4" | tr -d '\\' | grep -q '"n":10' && echo "$B4" | tr -d '\\' | grep -q '"first":true' \
  && ok "B4 mas exact face: h2s == [گل به از مسابقهٔ تیم‌ها، گل نخرده‌های تیم‌ها، کارت‌های قرمز تیم‌ها، کارت‌ها] + 10 tgm-rows rank-1 «جوهور دارالتعظیم» — mas's THIRD team-surface leads the group" || bad "B4: $B4"

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
[ "$FAIL" = "0" ] && echo "CYCLE246 DOMPROOF ALL GREEN («گل به از مسابقهٔ تیم‌ها» — the deep-file family's TWENTY-FOURTH sibling and its SIXTH TEAM-PARTICIPANT member: the team-side scoring-rate level at the HEAD of the team group, NINE of NINE leagues served — the family's FIRST NINE-league surface at the STANDARD guard, THE PERSIAN GULF REACHED for the first team-side time (Persepolis 1.8 rank-1), mas's third team-surface, season-aware with the frozen Barcelona 2.2 anchor distinct from the current 4.0, the 241 toFixed(1) pill — API 6/6 + DOM 4/4 + LAT @390x844)" && exit 0
exit 1
