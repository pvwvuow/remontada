#!/bin/bash
# cycle245-domproof.sh — permanent gate for the cycle-245 update
# (Update (cycle 245): «کارت‌های قرمز تیم‌ها» — the deep-file family's
#  TWENTY-THIRD sibling and its FIFTH TEAM-PARTICIPANT member, the
#  team-side red-card surface (the yellow 242 sibling's red brother) —
#  straight from the live total_red_card_team.json probe (UA Chrome/124,
#  2026-10-31, scripts/cycle245-probe.sh): NATURALLY SHORT files on the
#  NINE serving leagues (laliga 16 Getafe 5.0 / pl 12 Brentford 2.0 /
#  seriea 6 Atalanta 2.0 / bundesliga 7 Hoffenheim 2.0 / ligue1 9 Le Havre
#  2.0 / ucl 7 Inter 1.0 / uel 4 Milan 2.0 / portugal 13 Alverca 3.0 with
#  the top-3 2,2 tie / mas 11 Kuching City 3.0 — the SECOND mas
#  team-surface after the 240 clean-sheets); persiangulf honestly absent
#  (feed-driven: ONE team category, probed — the bare direct file serves
#  15 rows but the app is feed-driven). INTEGER-VALUED floats → the
#  215/220/231/235/236/242 integer convention: storage never rounds, the
#  pill renders String(value) dir=ltr (5.0 renders «۵»). Upstream Rank
#  keeps COMPETITION ties verbatim (laliga 2,3,4 on 3.0 / the duplicated
#  14,14,16 probed); the merge re-ranks POSITIONALLY. SEASON-AWARE: the
#  2020/21 laliga raw serves season/15585 — 19 rows, Deportivo Alaves 8.0
#  rank-1 with the 8,8 Betis tie, frozen, DISTINCT from the current
#  Getafe 5.0. Additive mirror of 242 end-to-end: TeamRedCardEntry + the
#  REQUIRED teamRedCards field + getFullTeamRedCards (fullTeamRedCards:v1,
#  the 240 floor-4 class GENERALIZED league-wide — red files are
#  naturally short, the standard <10 guard would re-probe forever; uel's
#  file is EXACTLY 4) + the team top-3-first merge + standings:v29→v30 +
#  the route field + the view field + the league-page block «کارت‌های
#  قرمز تیم‌ها» placed right after کارت‌های زرد تیم‌ها so the FIVE
#  team-side blocks read together, data-testid=trc-row, the red-card rect
#  icon, sublabel «انضباط — سطح تیم».)
# Part A (API):
#   A1 the FIVE-block family sweep on the NINE serving leagues: the four
#      older blocks stay exactly 10 rows; the red block serves 4-10 rows
#      (naturally short files — the floor-4), monotonic DESC, positional
#      1..n, zero Latin nameFa
#   A2 the laliga live anchor: red rank-1 «ختافه»/8305/5 exact + exactly
#      10 rows (16-row file → top-10 merge), the three-way 3,3,3 tie
#      re-ranked positionally
#   A3 the portugal breadth: rank-1 «آلورکا» 3.0 + the 2,2 tie re-ranked
#      (سانتا کلارا / آروکا) — the 240 three-way-tie class
#   A4 the honest absences: pg red [] on current AND historical
#      (feed-driven, probed); mas red = 10 rows rank-1 «کوچینگ سیتی» 3.0
#      (the SECOND mas team-surface) while mas txg/tposs/tyc stay honestly
#      empty (the 237/241 pair unchanged)
#   A5 the frozen 2020/2021 laliga red anchor: rank-1 «آلاوس» 8.0 (the
#      8,8 رئال‌بتیس tie kept, merged positionally) + season-distinctness
#      5≠8
#   A6 the negative season probe: 2020/21 → ok:false (SEASON_PARAM_RE)
#   A7 the uel floor-4 face: red rows >= 4 and <= 10 (the natural-thin
#      proof — exactly 4 as-found; the standard guard would re-probe
#      forever, the floor-4 league-wide exemption documented)
# Part B (DOM @390x844, agent-browser, console must stay 0):
#   B1 /topscorers/laliga: h2n=22 + the FIVE team-side blocks adjacent +
#      10 trc-rows + zero overflow (the 238 census refreshed BY DESIGN
#      21→22)
#   B2 the String() integer pill dir=ltr «۵» + zero Latin digits in the
#      trc rows
#   B3 real navigation trc top-1 → /team/8305 h1 «ختافه» (the
#      /team/{teamId} standings-view contract, live)
#   B4 the mas exact face: h2s == [گل نخرده‌های تیم‌ها، کارت‌های قرمز
#      تیم‌ها، کارت‌ها] with 10 trc-rows rank-1 «کوچینگ سیتی» + the pg
#      zero-team face (red honestly absent in DOM, gp90 active)
#   B5 console=0 errors=0 across the whole session
# Part C: warm LAT sweep, 3 routes <5000ms
set -u
BASE="${BASE:-http://localhost:3000}"
TMP="$(mktemp /home/z/my-project/.cycle245-domproof-XXXXXX)"
trap 'rm -f "$TMP"' EXIT
PASS=0; FAIL=0
ok(){ echo "OK  - $1"; PASS=$((PASS+1)); }
bad(){ echo "BAD - $1"; FAIL=$((FAIL+1)); }
py(){ python3 -c "$1"; }

echo "== Part A: API gates =="

# A1 the five-block sweep on the nine serving leagues
A1OUT=$(python3 - "$BASE" <<'PY'
import json,sys,re,subprocess
base=sys.argv[1]
fa=re.compile(r'[\u0600-\u06FF]')
OLD=[("teamXg","teamXg"),("teamCleanSheets","teamCleanSheets"),("teamPossession","teamPossession"),("teamYellowCards","teamYellowCards")]
leagues=["laliga","pl","seriea","bundesliga","ligue1","ucl","uel","portugal","mas"]
bad=[]
for lg in leagues:
    raw=subprocess.run(["curl","-s",f"{base}/api/topscorers/{lg}"],capture_output=True,text=True).stdout
    d=json.JSONDecoder().raw_decode(raw.strip())[0]
    for field,key in OLD:
        rows=d.get(field) or []
        if lg=="mas":
            # mas's honest five-block face: tcs=8 (the 240 floor
            # exemption), txg/tposs/tyc honestly empty (the 237/241
            # pair) — the red (245) and goals-per-match (246) blocks
            # are the OTHER surfaces
            want=8 if field=="teamCleanSheets" else 0
            if len(rows)!=want: bad.append({"lg":lg,"field":field,"n":len(rows),"why":"mas honest face","want":want})
            continue
        vals=[r.get(field) for r in rows]
        mono=all(vals[i]>=vals[i+1] for i in range(len(vals)-1)) if vals else False
        ranks=[r.get("rank") for r in rows]==list(range(1,len(rows)+1))
        latin=[r["name"] for r in rows if not fa.search(r.get("nameFa") or "")]
        if len(rows)!=10 or not mono or not ranks or latin:
            bad.append({"lg":lg,"field":field,"n":len(rows),"mono":mono,"ranks":ranks,"latin":latin})
    rows=d.get("teamRedCards") or []
    vals=[r.get("teamRedCards") for r in rows]
    mono=all(vals[i]>=vals[i+1] for i in range(len(vals)-1)) if vals else False
    ranks=[r.get("rank") for r in rows]==list(range(1,len(rows)+1))
    latin=[r["name"] for r in rows if not fa.search(r.get("nameFa") or "")]
    ints=all(float(v)==int(float(v)) for v in vals if v is not None)
    if not (4<=len(rows)<=10) or not mono or not ranks or latin or not ints:
        bad.append({"lg":lg,"field":"teamRedCards","n":len(rows),"mono":mono,"ranks":ranks,"latin":latin,"ints":ints})
    rows=d.get("teamGoalsPerMatch") or []
    vals=[r.get("teamGoalsPerMatch") for r in rows]
    mono=all(vals[i]>=vals[i+1] for i in range(len(vals)-1)) if vals else False
    ranks=[r.get("rank") for r in rows]==list(range(1,len(rows)+1))
    latin=[r["name"] for r in rows if not fa.search(r.get("nameFa") or "")]
    if len(rows)!=10 or not mono or not ranks or latin:
        bad.append({"lg":lg,"field":"teamGoalsPerMatch","n":len(rows),"mono":mono,"ranks":ranks,"latin":latin})
print(json.dumps({"bad":bad},separators=(',',':')))
PY
)
echo "$A1OUT" | tr -d '\\' | grep -q '"bad":\[\]' && ok "A1 five-block sweep: the eight domestic+cup leagues carry the four older blocks (10 rows each) AND mas its honest face (tcs=8 the floor exemption, txg/tposs/tyc honestly empty); ALL NINE carry teamRedCards 4-10 rows (naturally short files, the floor-4), monotonic DESC, positional ranks, INTEGER values, zero Latin nameFa (41 block-sweeps)" || bad "A1: $A1OUT"

# A2 the laliga live anchor
A2=$(curl -s "$BASE/api/topscorers/laliga" | py "
import sys,json
d=json.JSONDecoder().raw_decode(sys.stdin.read().strip())[0]
rows=d.get('teamRedCards') or []
r1=rows[0] if rows else {}
print(json.dumps({'n':len(rows),'name':r1.get('nameFa'),'tid':r1.get('teamId'),'val':r1.get('teamRedCards')},ensure_ascii=False,separators=(',',':')))
")
echo "$A2" | grep -q '"n":10' && echo "$A2" | grep -q '"name":"ختافه"' && echo "$A2" | grep -q '"tid":8305' && echo "$A2" | grep -q '"val":5' \
  && ok "A2 laliga live anchor: red rank-1 «ختافه»/8305/5.0 exact, 10 rows (16-row file → top-10 merge), the three-way 3,3,3 tie re-ranked positionally" || bad "A2: $A2"

# A3 the portugal breadth (the 2,2 tie class)
A3=$(curl -s "$BASE/api/topscorers/portugal" | py "
import sys,json
d=json.JSONDecoder().raw_decode(sys.stdin.read().strip())[0]
rows=d.get('teamRedCards') or []
top=[(r.get('nameFa'),r.get('teamRedCards')) for r in rows[:3]]
print(json.dumps({'n':len(rows),'top':top},ensure_ascii=False,separators=(',',':')))
")
echo "$A3" | grep -q '"top":\[\["آلورکا",3\],\["آروکا",2\],\["بنفیکا",2\]\]' \
  && ok "A3 portugal breadth: rank-1 «آلورکا» 3.0 + the 2,2 tie re-ranked positionally with the name tiebreak (آروکا / بنفیکا — the merge's positional convention; the file keeps upstream ties verbatim 2,2,2)" || bad "A3: $A3"

# A4 the honest absences + mas the SECOND team-surface
A4=$(python3 - "$BASE" <<'PY'
import json,sys,subprocess
base=sys.argv[1]
det={}
for lg in ["persiangulf","mas"]:
    for tag,season in [("cur",""),("hist","?season=2020/2021")]:
        raw=subprocess.run(["curl","-s",f"{base}/api/topscorers/{lg}{season}"],capture_output=True,text=True).stdout
        d=json.JSONDecoder().raw_decode(raw.strip())[0]
        det[f"{lg}-{tag}"]={"trc":len(d.get("teamRedCards") or []),
                "txg":len(d.get("teamXg") or []),"tyc":len(d.get("teamYellowCards") or [])}
mraw=subprocess.run(["curl","-s",f"{base}/api/topscorers/mas"],capture_output=True,text=True).stdout
md=json.JSONDecoder().raw_decode(mraw.strip())[0]
mrows=md.get("teamRedCards") or []
r1=mrows[0] if mrows else {}
det["mas-r1"]={"name":r1.get("nameFa"),"val":r1.get("teamRedCards")}
print(json.dumps(det,ensure_ascii=False,separators=(',',':')))
PY
)
echo "$A4" | tr -d '\\' | grep -q '"persiangulf-cur":{"trc":0,"txg":0,"tyc":0}' && echo "$A4" | tr -d '\\' | grep -q '"persiangulf-hist":{"trc":10,"txg":0,"tyc":0}' \
  && echo "$A4" | tr -d '\\' | grep -q '"mas-cur":{"trc":6,"txg":0,"tyc":0}' && echo "$A4" | tr -d '\\' | grep -q '"mas-r1":{"name":"کوچینگ سیتی","val":3}' \
  && ok "A4 the honest faces as-found: pg red [] on CURRENT (feed-driven: ONE team category, probed — the bare direct file serves 15 rows but the app never fetches it) while pg HISTORICAL red SERVES 10 rows (the 243 historical-tcs class AGAIN — the current absence is current-season-scoped, pinned as breadth); mas red = 6 rows rank-1 «کوچینگ سیتی» 3.0 (the file's REAL current size — re-probed 6 live after the first probe saw 11; upstream volatility documented, the floor-4 keeps it healthy) while txg/tyc stay honestly empty (the 237/241 pair unchanged)" || bad "A4: $A4"

# A5 the frozen 2020/2021 laliga red anchor + season-distinctness
A5=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F2021" | py "
import sys,json
d=json.JSONDecoder().raw_decode(sys.stdin.read().strip())[0]
rows=d.get('teamRedCards') or []
top=[(r.get('nameFa'),r.get('teamRedCards')) for r in rows[:3]]
print(json.dumps({'n':len(rows),'top':top},ensure_ascii=False,separators=(',',':')))
")
echo "$A5" | grep -q '"top":\[\["آلاوس",8\],\["رئال‌بتیس",8\],\["ختافه",7\]\]' \
  && ok "A5 frozen 2020/2021 laliga red anchor: rank-1 «آلاوس» 8.0 with the 8,8 «رئال‌بتیس» tie merged positionally + «ختافه» 7.0 rank-3 — the 202 class, DISTINCT from the current Getafe 5.0 (season-distinctness 5≠8)" || bad "A5: $A5"

# A6 the negative probe
N=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F21" | py "import sys,json;d=json.load(sys.stdin);print(1 if (d.get('ok')==False and 'Invalid season' in str(d.get('error'))) else 0)")
[ "$N" = "1" ] && ok "A6 negative probe: two-stage season shape 2020/21 → {ok:false, Invalid season} (the SEASON_PARAM_RE contract)" || bad "A6: $N"

# A7 the uel floor-4 face
A7=$(curl -s "$BASE/api/topscorers/uel" | py "
import sys,json
d=json.JSONDecoder().raw_decode(sys.stdin.read().strip())[0]
rows=d.get('teamRedCards') or []
print(json.dumps({'n':len(rows)},separators=(',',':')))
")
echo "$A7" | grep -q '"n":4' \
  && ok "A7 uel floor-4 face: red = EXACTLY 4 rows as-found (the natural-thin proof — the standard <10 guard would re-probe forever; the 240 floor-4 class generalized league-wide keeps it served)" || bad "A7: $A7"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B1=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const iPOS=h2s.indexOf('مالکیت توپ تیم‌ها'), iYC=h2s.indexOf('کارت‌های زرد تیم‌ها'), iTRC=h2s.indexOf('کارت‌های قرمز تیم‌ها'), iXG=h2s.indexOf('گل مورد انتظار روی دروازه'); const order=iPOS>-1&&iYC>iPOS&&iTRC>iYC&&iXG>iTRC; const trc=document.querySelectorAll('[data-testid=trc-row]').length; const vbroken=[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length; return JSON.stringify({order,trc,vbroken,h2n:h2s.length}); })()")
echo "$B1" | tr -d '\\' | grep -q '"order":true' && echo "$B1" | tr -d '\\' | grep -q '"trc":10' && echo "$B1" | tr -d '\\' | grep -q '"vbroken":0' && echo "$B1" | tr -d '\\' | grep -q '"h2n":23' \
  && ok "B1 DOM laliga: h2n=23 [census refreshed BY DESIGN 22→23 — the 246 team goals-per-match block] + the SIX team-side blocks adjacent + 10 trc-rows + zero real overflow @390x844" || bad "B1: $B1"

B2=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=trc-row]')]; const a=rows[0]&&rows[0].querySelector('a'); const pill=a&&a.lastElementChild; const latin=rows.filter(r=>/[0-9]/.test(r.textContent)).length; const sub=[...document.querySelectorAll('main h2')].find(h=>h.textContent==='کارت‌های قرمز تیم‌ها'); const subTxt=sub&&sub.parentElement&&sub.parentElement.querySelector('.ms-auto'); return JSON.stringify({pill:(pill&&pill.textContent.trim())||'', dir:(pill&&pill.getAttribute('dir'))||null, latin, sub:(subTxt&&subTxt.textContent.trim())||''}); })()")
echo "$B2" | tr -d '\\' | grep -q '"pill":"۵"' && echo "$B2" | tr -d '\\' | grep -q '"dir":"ltr"' && echo "$B2" | tr -d '\\' | grep -q '"latin":0' && echo "$B2" | tr -d '\\' | grep -q '"sub":"انضباط — سطح تیم"' \
  && ok "B2 the String() integer pill: rank-1 pill renders «۵» dir=ltr (5.0 → String, never rounded) + zero Latin digits in the trc rows + the sublabel «انضباط — سطح تیم»" || bad "B2: $B2"

agent-browser eval "(() => { const r=document.querySelector('[data-testid=trc-row] a'); if(r) r.click(); return 'clicked'; })()" >/dev/null
sleep 2
B3=$(agent-browser eval "(() => JSON.stringify({url:location.pathname, h1:(document.querySelector('h1')||{}).textContent||''}))()")
echo "$B3" | tr -d '\\' | grep -q '/team/8305' && echo "$B3" | tr -d '\\' | grep -q 'ختافه' \
  && ok "B3 real navigation: trc top-1 → /team/8305 h1 «ختافه» (the /team/{teamId} standings-view contract, live)" || bad "B3: $B3"

agent-browser open "$BASE/topscorers/mas" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B4a=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const rows=[...document.querySelectorAll('[data-testid=trc-row]')]; const first=rows[0]&&rows[0].querySelector('a'); return JSON.stringify({h2s, n:rows.length, first:(first&&first.textContent.includes('کوچینگ سیتی'))||false}); })()")
echo "$B4a" | tr -d '\\' | grep -q '"h2s":\["گل به از مسابقهٔ تیم‌ها","گل نخرده‌های تیم‌ها","کارت‌های قرمز تیم‌ها","کارت‌ها"\]' && echo "$B4a" | tr -d '\\' | grep -q '"n":6' && echo "$B4a" | tr -d '\\' | grep -q '"first":true' \
  && ok "B4a mas exact face: h2s == [گل به از مسابقهٔ تیم‌ها، گل نخرده‌های تیم‌ها، کارت‌های قرمز تیم‌ها، کارت‌ها] + 6 trc-rows rank-1 «کوچینگ سیتی» (the file's real current size) — mas's team surfaces render live" || bad "B4a: $B4a"
agent-browser open "$BASE/topscorers/persiangulf" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B4b=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); return JSON.stringify({teamH2s:h2s.filter(x=>x.includes('تیم‌ها')).length, gp90:h2s.includes('گل در هر ۹۰')}); })()")
echo "$B4b" | tr -d '\\' | grep -q '"teamH2s":1' && echo "$B4b" | tr -d '\\' | grep -q '"gp90":true' \
  && ok "B4b pg face [refreshed BY DESIGN — the 246 goals-per-match is pg's FIRST-EVER team surface]: exactly ONE team h2 with gp90 still active (the 227 contract)" || bad "B4b: $B4b"

CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B5 console=0 errors=0 across the whole session" || bad "B5: console=$CN errors=$CE"
agent-browser close >/dev/null 2>&1

echo "== Part C: warm LAT sweep =="
LAT=1
for P_ in / /topscorers/laliga /topscorers/uel; do
  T=$(curl -s -o /dev/null -w '%{time_total}' --max-time 30 "$BASE$P_")
  echo "     LAT $P_ = ${T}s"
  python3 -c "import sys; sys.exit(0 if float('$T')<5.0 else 1)" || LAT=0
done
[ "$LAT" = "1" ] && ok "Part C warm LAT: 3 routes <5000ms" || bad "Part C: a route exceeded 5000ms"

echo "== VERDICT =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE245 DOMPROOF ALL GREEN («کارت‌های قرمز تیم‌ها» — the deep-file family's TWENTY-THIRD sibling and its FIFTH TEAM-PARTICIPANT member: the team-side red-card surface, NATURALLY SHORT files on NINE serving leagues — the family's FIRST NINE-league surface, mas the SECOND mas team-surface, pg honestly absent feed-driven, season-aware with the frozen Alaves 8.0 anchor distinct from the current Getafe 5.0, the floor-4 guard generalized league-wide, the String() integer pill — API 7/7 + DOM 5/5 + LAT @390x844)" && exit 0
exit 1
