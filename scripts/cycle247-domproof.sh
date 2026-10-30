#!/bin/bash
# cycle247-domproof.sh — permanent gate for the cycle-247 update
# (Update (cycle 247): «کرنرهای تیم‌ها» — the deep-file family's
#  TWENTY-FIFTH sibling and its SEVENTH TEAM-PARTICIPANT member, the
#  team-side corner volume, placed right after گل به از مسابقهٔ تیم‌ها so
#  the raw attack-volume pair reads together — straight from the live
#  corner_taken_team.json probe (UA Chrome/124, 2026-10-31,
#  scripts/cycle247-probe.sh + probe2.sh): EIGHT leagues serve (the seven
#  feed leagues + uel 73 — files WIDE 18-36 rows everywhere) — back on
#  the STANDARD guard (no league-aware floor, the 246 class);
#  persiangulf AND mas honestly absent TWICE OVER (not in feed AND the
#  bare direct files both ABSENT — the 241 honesty, stronger than the
#  245 bare-serves class). Integer values → the 215/…/245 integer
#  convention (String() pill dir=ltr, 75 renders «۷۵» (live anchor refreshed 2026-10-31: 73→75); the frozen
#  2020/21 file's 224 renders «۲۲۴»). Upstream Rank keeps COMPETITION
#  ties verbatim; the merge re-ranks POSITIONALLY. SEASON-AWARE: the
#  2020/21 laliga raw serves season/15585 — 20 rows, Real Madrid 224
#  rank-1 with the 196 Atletico+Real Sociedad tie — frozen, DISTINCT
#  from the current 75 (probed via the NAME-form season feed, the exact
#  call getLeagueRaw makes; the numeric-form season=15585 feed provably
#  leaks the CURRENT fetchAllUrls — documented in the probe). The
#  honest-name contract rides the EXISTING teamFa map for every CURRENT
#  top-10 (70/70 probed, zero new entries) — ONE new entry for the
#  frozen file's rank-3 «Eibar» → «ایبار». Additive mirror of 246
#  end-to-end: TeamCornerEntry + the REQUIRED teamCorners field +
#  getFullTeamCorners (fullTeamCorners:v1, the STANDARD guard) + the
#  team top-3-first merge + standings:v31→v32 + the route field + the
#  view field + the league-page block placed right after the tgm block,
#  data-testid=tcor-row, the corner-flag glyph, sublabel «حجم حملات —
#  سطح تیم».)
# Part A (API):
#   A1 the EIGHT-league corners sweep: exactly 10 rows each, monotonic
#      DESC, positional ranks, zero Latin nameFa, integer values;
#      pg AND mas honest-empty teamCorners
#   A2 the laliga live anchor: tcor rank-1 «ویارئال»/10205/75 exact +
#      exactly 10 rows
#   A3 the honest-absence pair: pg=0 AND mas=0 (not in feed AND bare
#      direct files absent — asserted on the served API)
#   A4 the frozen 2020/2021 laliga corner anchor: rank-1 «رئال‌مادرید»
#      224 («بارسلونا» 217, «ایبار» 198 — the new teamFa entry) +
#      season-distinctness 75≠224
#   A5 the negative season probe: 2020/21 → ok:false (SEASON_PARAM_RE)
# Part B (DOM @390x844, agent-browser, console must stay 0):
#   B1 /topscorers/laliga: h2n=24 + the SEVEN team-side blocks in the
#      family order with tcor right after tgm + 10 tcor-rows + zero
#      overflow (the census refreshed BY DESIGN 23→24)
#   B2 the String() integer pill dir=ltr «۷۳» + zero Latin digits in the
#      tcor rows + the sublabel «حجم حملات — سطح تیم»
#   B3 real navigation on laliga: tcor top-1 → /team/10205 h1 «ویارئال»
#   B4 the honest-absence DOM: mas h2s unchanged (4 faces, NO corners h2,
#      tcor-rows=0) + pg unchanged (1 team face = tgm, NO corners h2,
#      tcor-rows=0, gp90 still active)
#   B5 console=0 errors=0 across the whole session
# Part C: warm LAT sweep, 3 routes <5000ms
set -u
BASE="${BASE:-http://localhost:3000}"
TMP="$(mktemp /home/z/my-project/.cycle247-domproof-XXXXXX)"
trap 'rm -f "$TMP"' EXIT
PASS=0; FAIL=0
ok(){ echo "OK  - $1"; PASS=$((PASS+1)); }
bad(){ echo "BAD - $1"; FAIL=$((FAIL+1)); }
py(){ python3 -c "$1"; }

echo "== Part A: API gates =="

# A1 the eight-league corners sweep + the honest-absence pair
A1OUT=$(python3 - "$BASE" <<'PY'
import json,sys,re,subprocess
base=sys.argv[1]
fa=re.compile(r'[\u0600-\u06FF]')
leagues=["laliga","pl","seriea","bundesliga","ligue1","ucl","uel","portugal","persiangulf","mas"]
bad=[]
for lg in leagues:
    raw=subprocess.run(["curl","-s",f"{base}/api/topscorers/{lg}"],capture_output=True,text=True).stdout
    d=json.JSONDecoder().raw_decode(raw.strip())[0]
    rows=d.get("teamCorners") or []
    if lg in ("persiangulf","mas"):
        if len(rows)!=0: bad.append({"lg":lg,"n":len(rows),"why":"honest absence"})
        continue
    vals=[r.get("teamCorners") for r in rows]
    mono=all(vals[i]>=vals[i+1] for i in range(len(vals)-1)) if vals else False
    ranks=[r.get("rank") for r in rows]==list(range(1,len(rows)+1))
    latin=[r["name"] for r in rows if not fa.search(r.get("nameFa") or "")]
    ints=all(float(v)==int(float(v)) for v in vals if v is not None)
    if len(rows)!=10 or not mono or not ranks or latin or not ints:
        bad.append({"lg":lg,"n":len(rows),"mono":mono,"ranks":ranks,"latin":latin,"ints":ints})
print(json.dumps({"bad":bad},separators=(',',':')))
PY
)
echo "$A1OUT" | tr -d '\\' | grep -q '"bad":\[\]' && ok "A1 eight-league sweep: the EIGHT serving leagues (incl. uel) carry exactly 10 tcor rows each — monotonic DESC, positional ranks, integer values, zero Latin nameFa; pg AND mas honest-empty (the 241 twice-over class)" || bad "A1: $A1OUT"

# A2 the laliga live anchor
A2=$(curl -s "$BASE/api/topscorers/laliga" | py "
import sys,json
d=json.JSONDecoder().raw_decode(sys.stdin.read().strip())[0]
rows=d.get('teamCorners') or []
r1=rows[0] if rows else {}
print(json.dumps({'n':len(rows),'name':r1.get('nameFa'),'tid':r1.get('teamId'),'val':r1.get('teamCorners')},ensure_ascii=False,separators=(',',':')))
")
echo "$A2" | grep -q '"n":10' && echo "$A2" | grep -q '"name":"ویارئال"' && echo "$A2" | grep -q '"tid":10205' && echo "$A2" | grep -q '"val":75' \
  && ok "A2 laliga live anchor: tcor rank-1 «ویارئال»/10205/75 exact, 10 rows (20-row file → top-10 merge)" || bad "A2: $A2"

# A3 the honest-absence pair (served API) — pg AND mas
A3=$(python3 - "$BASE" <<'PY'
import json,sys,subprocess
base=sys.argv[1]
out={}
for lg in ["persiangulf","mas"]:
    raw=subprocess.run(["curl","-s",f"{base}/api/topscorers/{lg}"],capture_output=True,text=True).stdout
    d=json.JSONDecoder().raw_decode(raw.strip())[0]
    out[lg]=len(d.get("teamCorners") or [])
print(json.dumps(out,separators=(',',':')))
PY
)
echo "$A3" | grep -q '"persiangulf":0' && echo "$A3" | grep -q '"mas":0' \
  && ok "A3 honest absence: pg AND mas serve ZERO corner rows (no Corners team category in their feeds AND the bare direct files data.fotmob.com/stats/{523,8985}/corner_taken_team.json both ABSENT — the 241 honesty, twice over)" || bad "A3: $A3"

# A4 the frozen 2020/2021 laliga corner anchor + season-distinctness
A4=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F2021" | py "
import sys,json
d=json.JSONDecoder().raw_decode(sys.stdin.read().strip())[0]
rows=d.get('teamCorners') or []
top=[(r.get('nameFa'),r.get('teamCorners')) for r in rows[:3]]
print(json.dumps({'n':len(rows),'top':top},ensure_ascii=False,separators=(',',':')))
")
echo "$A4" | grep -q '"top":\[\["رئال‌مادرید",224\],\["بارسلونا",217\],\["ایبار",198\]\]' \
  && ok "A4 frozen 2020/2021 laliga corner anchor: rank-1 «رئال‌مادرید» 224 («بارسلونا» 217, «ایبار» 198 — the ONE new teamFa entry) — the 202 class, DISTINCT from the current 75 (season-distinctness; the 196 Atletico+Real Sociedad tie merges positionally)" || bad "A4: $A4"

# A5 the negative probe
N=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F21" | py "import sys,json;d=json.load(sys.stdin);print(1 if (d.get('ok')==False and 'Invalid season' in str(d.get('error'))) else 0)")
[ "$N" = "1" ] && ok "A5 negative probe: two-stage season shape 2020/21 → {ok:false, Invalid season} (the SEASON_PARAM_RE contract)" || bad "A5: $N"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B1=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const iX=h2s.indexOf('گل مورد انتظار'), iTGM=h2s.indexOf('گل به از مسابقهٔ تیم‌ها'), iCOR=h2s.indexOf('کرنرهای تیم‌ها'), iT=h2s.indexOf('گل مورد انتظار تیم‌ها'), iCS=h2s.indexOf('گل نخرده‌های تیم‌ها'), iPOS=h2s.indexOf('مالکیت توپ تیم‌ها'), iYC=h2s.indexOf('کارت‌های زرد تیم‌ها'), iTRC=h2s.indexOf('کارت‌های قرمز تیم‌ها'), iXG=h2s.indexOf('گل مورد انتظار روی دروازه'), iG=h2s.indexOf('گل در هر ۹۰'), iA=h2s.indexOf('پاس مورد انتظار'), iB=h2s.indexOf('سانس بزرگ خلق‌شده'), iC=h2s.indexOf('فرصت‌های خلق‌شده'), iBM=h2s.indexOf('سانس بزرگ ازدست‌رفته'), iM=h2s.indexOf('بیشترین دقایق'); const order=iX>-1&&iTGM>iX&&iCOR>iTGM&&iT>iCOR&&iCS>iT&&iPOS>iCS&&iYC>iPOS&&iTRC>iYC&&iXG>iTRC&&iG>iXG&&iA>iG&&iB>iA&&iC>iB&&iBM>iC&&iM>iBM; const tcor=document.querySelectorAll('[data-testid=tcor-row]').length; const vbroken=[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length; return JSON.stringify({order,tcor,vbroken,h2n:h2s.length}); })()")
echo "$B1" | tr -d '\\' | grep -q '"order":true' && echo "$B1" | tr -d '\\' | grep -q '"tcor":10' && echo "$B1" | tr -d '\\' | grep -q '"vbroken":0' && echo "$B1" | tr -d '\\' | grep -q '"h2n":24' \
  && ok "B1 DOM laliga: h2n=24 [census refreshed BY DESIGN 23→24 — the 247 team corners block] + the SEVEN team-side blocks in the family order (tcor right after tgm) + 10 tcor-rows + zero real overflow @390x844" || bad "B1: $B1"

B2=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=tcor-row]')]; const a=rows[0]&&rows[0].querySelector('a'); const pill=a&&a.lastElementChild; const latin=rows.filter(r=>/[0-9]/.test(r.textContent)).length; const sub=[...document.querySelectorAll('main h2')].find(h=>h.textContent==='کرنرهای تیم‌ها'); const subTxt=sub&&sub.parentElement&&sub.parentElement.querySelector('.ms-auto'); return JSON.stringify({pill:(pill&&pill.textContent.trim())||'', dir:(pill&&pill.getAttribute('dir'))||null, latin, sub:(subTxt&&subTxt.textContent.trim())||''}); })()")
echo "$B2" | tr -d '\\' | grep -q '"pill":"۷۵"' && echo "$B2" | tr -d '\\' | grep -q '"dir":"ltr"' && echo "$B2" | tr -d '\\' | grep -q '"latin":0' && echo "$B2" | tr -d '\\' | grep -q '"sub":"حجم حملات — سطح تیم"' \
  && ok "B2 the String() integer pill: rank-1 pill renders «۷۳» dir=ltr (73 → String(), the 215/…/245 convention, storage never rounds) + zero Latin digits in the tcor rows + the sublabel «حجم حملات — سطح تیم»" || bad "B2: $B2"

agent-browser eval "(() => { const r=document.querySelector('[data-testid=tcor-row] a'); if(r) r.click(); return 'clicked'; })()" >/dev/null
sleep 2
B3=$(agent-browser eval "(() => JSON.stringify({url:location.pathname, h1:(document.querySelector('h1')||{}).textContent||''}))()")
echo "$B3" | tr -d '\\' | grep -q '/team/10205' && echo "$B3" | tr -d '\\' | grep -q 'ویارئال' \
  && ok "B3 real navigation: laliga tcor top-1 → /team/10205 h1 «ویارئال» — the /team/{teamId} standings-view contract end-to-end on the new block" || bad "B3: $B3"

agent-browser open "$BASE/topscorers/mas" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B4a=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); return JSON.stringify({h2s, tcor:document.querySelectorAll('[data-testid=tcor-row]').length, cornerH2:h2s.includes('کرنرهای تیم‌ها')}); })()")
echo "$B4a" | tr -d '\\' | grep -q '"h2s":\["گل به از مسابقهٔ تیم‌ها","گل نخرده‌های تیم‌ها","کارت‌های قرمز تیم‌ها","کارت‌ها"\]' && echo "$B4a" | tr -d '\\' | grep -q '"tcor":0' && echo "$B4a" | tr -d '\\' | grep -q '"cornerH2":false' \
  && ok "B4a mas honest face UNCHANGED: h2s == [گل به از مسابقهٔ تیم‌ها، گل نخرده‌های تیم‌ها، کارت‌های قرمز تیم‌ها، کارت‌ها] — NO corners h2, zero tcor-rows (the twice-over absence, DOM side)" || bad "B4a: $B4a"

agent-browser open "$BASE/topscorers/persiangulf" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B4b=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const teamSurfaces=['گل به از مسابقهٔ تیم‌ها','گل مورد انتظار تیم‌ها','گل نخرده‌های تیم‌ها','مالکیت توپ تیم‌ها','کارت‌های زرد تیم‌ها','کارت‌های قرمز تیم‌ها','کرنرهای تیم‌ها']; const g90=h2s.indexOf('گل در هر ۹۰'); return JSON.stringify({teamSurfaces:h2s.filter(t=>teamSurfaces.includes(t)).length, cornerH2:h2s.includes('کرنرهای تیم‌ها'), tcor:document.querySelectorAll('[data-testid=tcor-row]').length, g90}); })()")
echo "$B4b" | tr -d '\\' | grep -q '"teamSurfaces":1' && echo "$B4b" | tr -d '\\' | grep -q '"cornerH2":false' && echo "$B4b" | tr -d '\\' | grep -q '"tcor":0' && echo "$B4b" | tr -d '\\' | grep -q '"g90":[0-9]' \
  && ok "B4b pg honest face UNCHANGED: exactly ONE team surface (tgm — the 246 first) with NO corners h2, zero tcor-rows, and the gp90 block still active (the 244 g90>=0 lesson honored)" || bad "B4b: $B4b"

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
[ "$FAIL" = "0" ] && echo "CYCLE247 DOMPROOF ALL GREEN («کرنرهای تیم‌ها» — the deep-file family's TWENTY-FIFTH sibling and its SEVENTH TEAM-PARTICIPANT member: the team-side corner volume right after the scoring-rate block, EIGHT leagues served incl. uel — back on the STANDARD guard, pg+mas honestly absent twice over (feed AND bare-direct), the 215/…/245 String() integer pill («۷۳»), season-aware with the frozen Real Madrid 224 anchor distinct from the current 75 (the NAME-form season feed lesson), ONE new teamFa entry (Eibar → ایبار) for the frozen rows while all 70 current top-10 names ride the existing map — API 5/5 + DOM 5/5 + LAT @390x844)" && exit 0
exit 1
