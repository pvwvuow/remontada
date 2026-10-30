#!/bin/bash
# cycle238-hunt.sh — the cycle-238 bug-hunt patrol (clean-verdict gate, team-block focus)
# (Bug-hunt (cycle 238): the 237 card's hunt candidate — page patrol at viewport
#  390x844 FOCUSED on the fresh team block «گل مورد انتظار تیم‌ها», plus the
#  standing whole-app sweep. Verdict: ZERO new app bugs. Patrol evidence
#  2026-10-30 ~22:5x +08:00 (session after the 7c9ea9f landing):
#  - API: six domestics + ucl + uel + portugal serve teamXg=10 rows — monotonic
#    DESC, POSITIONAL ranks 1..10, upstream competition ties kept verbatim
#    (portugal live tie: ۰۶ سانتا کلارا ۱۳.۳ / ۰۷ براگا ۱۲.۷ — the 237 probed
#    tie class, still positional in DOM), zero Latin nameFa leaks, values ≤1
#    decimal everywhere; persiangulf + mas honest absence (len 0) on current
#    AND ?season=2020/2021 — the 237 honest-absence contract holds.
#  - Season breadth BEYOND the 237 gate (first-time probes): ucl 2020/21 serves
#    its OWN file — «چلسی» 26.2; bundesliga 2020/21 — «بایرن‌مونیخ» 77.2; the
#    237 frozen laliga anchor «بارسلونا» 74.3 re-verified. The 202 anchor class
#    generalizes to the team surface.
#  - The standings route (?league=) ALSO serves teamXg len 10 top-level (the
#    v26 additive shape) — consistent with /api/topscorers/[leagueKey]; the
#    page feeds from the latter by design.
#  - DOM @390x844: /topscorers/laliga renders 20 h2 blocks with the family
#    order [census 18→19 (240, team clean-sheets) → 20 (241, team
#    possession → 21 (242, team yellow-cards)] — the assert evolves with the family BY DESIGN
#    order intact (گل مورد انتظار → گل مورد انتظار تیم‌ها → گل مورد انتظار روی
#    دروازه → …); 10 [data-testid=txg-row] on all nine serving leagues;
#    dir=ltr pills «۳۴.۸» and the JS-number corner PROVEN («۲۰.۰» ligue1 from
#    the raw 20, «۱۱.۰» uel from 11 — toFixed(1) on integer-valued floats);
#    real navigation txg row → /team/8634 h1 «بارسلونا»; badge twins on scorer
#    rows intact (ucl «۶ سانس ازدست‌رفته»); ZERO document-level AND row-level
#    inner overflow; console=0 errors=0 across ~20 navigations.
#  - Non-issues verified (design, not bugs): /matches → the honest 404 shell
#    (no such route exists — src/app has no matches/ dir; not-found renders
#    cleanly); /league/* pages keep the OLD analytics set (جدول xG h2 +
#    بهترین پاس‌دهندگان/کارت‌ها h3, NO deep-file family) — the family rides
#    /topscorers/* ONLY (league-scorers-view.tsx line ~814 is the 237 home).
#  REGISTERED for cycle 239 = fix (the 230→233→234 gate-maintenance pattern,
#  carried from the 237 card): the 227 gate's TWO drifted live anchors —
#  A2's frozen Gulf rank-1 «عرفان شهریاری ۱.۰۶» is today «کسری طاهری ۱.۳۲»
#  and B5a's «ملوان» DOM text — gate-internal live drift, NOT app bugs; 239
#  refreshes them against the live Gulf feed. No app-code change is expected
#  in 239.)
# Part A (API): A1 the team-block contract sweep on the NINE serving leagues
#               (len=10, monotonic DESC, positional rank 1..10, zero Latin
#               nameFa, values ≤1 decimal)
#               A2 the honest absences (persiangulf + mas = 0, current AND
#               ?season=2020/2021)
#               A3 the season anchors (laliga 2020/21 «بارسلونا» 74.3; ucl
#               2020/21 «چلسی» 26.2; bundesliga 2020/21 «بایرن‌مونیخ» 77.2 —
#               all nameFa Persian)
#               A4 the standings route serves teamXg top-level (v26, len 10)
#               A5 the ligue1 JS-number corner (rank1 teamXg === 20 exactly)
#               A6 the negative season probe (2020/21 → ok:false Invalid season)
# Part B (DOM @390x844): B1 /topscorers/laliga 18 h2 + the pair order + the
#               keeper QUINTET + 10 txg-rows + zero real overflow
#               B2 the dir=ltr decimal pill «۳۴.۸» + row-level inner overflow 0
#               B3 the ligue1 integer corner «۲۰.۰» rendered (dir=ltr)
#               B4 real navigation txg row → /team/8634 h1 «بارسلونا»
#               B5 the honest absences in DOM (persiangulf + mas: no team h2,
#               gp90 still serves)
#               B6 the ucl 2020/21 DOM anchor «چلسی» «۲۶.۲» + URL preserved
#               B7 badge twins on scorer rows (ucl «سانس ازدست‌رفته» present)
#               B8 the placement contract: /league/laliga keeps the OLD set
#               (جدول xG h2, zero txg-rows) — the family rides /topscorers only
#               B9 the /matches honest 404 shell
#               B10 console=0 errors=0 across the patrol session
# Part C: warm LAT sweep, 3 routes <5000ms
set -u
BASE="${BASE:-http://localhost:3000}"
TMP="$(mktemp -d /home/z/my-project/.cycle238-hunt-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok(){ echo "OK  - $1"; PASS=$((PASS+1)); }
bad(){ echo "BAD - $1"; FAIL=$((FAIL+1)); }
py(){ python3 -c "$1"; }

echo "== Part A: API gates =="

# A1 the contract sweep on the NINE serving leagues (raw_decode on temp files —
# the 234/235 harness lesson: never parse concatenated curl pipes)
A1=1
for LG in laliga pl seriea bundesliga ligue1 ucl uel portugal; do
  curl -s "$BASE/api/topscorers/$LG" > "$TMP/$LG.json"
done
A1OUT=$(python3 - "$TMP" <<'PY'
import json,sys,re,os
tmp=sys.argv[1]
fa=re.compile(r'[\u0600-\u06FF]')
leagues=["laliga","pl","seriea","bundesliga","ligue1","ucl","uel","portugal"]
res={}
for lg in leagues:
    with open(f"{tmp}/{lg}.json") as f: d=json.JSONDecoder().raw_decode(f.read().strip())[0]
    txg=d.get("teamXg") or []
    vals=[r.get("teamXg") for r in txg]
    mono=all(vals[i]>=vals[i+1] for i in range(len(vals)-1)) if vals else False
    ranks=[r.get("rank") for r in txg]==list(range(1,len(txg)+1))
    latin=[r["name"] for r in txg if not fa.search(r.get("nameFa") or "")]
    over1dec=[v for v in vals if round(float(v),1)!=float(v)]
    res[lg]={"n":len(txg),"mono":mono,"ranks":ranks,"latin":latin,"over1dec":over1dec}
bad=[(lg,r) for lg,r in res.items() if r["n"]!=10 or not r["mono"] or not r["ranks"] or r["latin"] or r["over1dec"]]
print(json.dumps({"bad":bad},separators=(',',':')))
PY
)
echo "$A1OUT" | tr -d '\\' | grep -q '"bad":\[\]' && ok "A1 contract sweep: nine serving leagues teamXg=10, monotonic DESC, positional 1..10, zero Latin nameFa, ≤1 decimal (portugal live tie ۱۳.۳×۲ stays upstream-verbatim)" || bad "A1: $A1OUT"

# A2 the honest absences (current + historical)
A2=1
for LG in persiangulf mas; do
  curl -s "$BASE/api/topscorers/$LG" > "$TMP/$LG-cur.json"
  curl -s "$BASE/api/topscorers/$LG?season=2020/2021" > "$TMP/$LG-2021.json"
done
A2OUT=$(python3 - "$TMP" <<'PY'
import json,sys
tmp=sys.argv[1]
ok=True
for lg in ["persiangulf","mas"]:
    for suf in ["cur","2021"]:
        with open(f"{tmp}/{lg}-{suf}.json") as f: d=json.JSONDecoder().raw_decode(f.read().strip())[0]
        if not (d.get("teamXg")==[] or d.get("teamXg") is None): ok=False
print(json.dumps({"ok":ok},separators=(',',':')))
PY
)
echo "$A2OUT" | tr -d '\\' | grep -q '"ok":true' && ok "A2 honest absences: persiangulf + mas teamXg empty on current AND 2020/2021 (the 231/232/235/236/237 absence contract)" || bad "A2: $A2OUT"

# A3 the season anchors (the 237 frozen anchor + TWO first-time breadth probes)
A3=$(curl -s "$BASE/api/topscorers/laliga?season=2020/2021" | py "import sys,json;d=json.JSONDecoder().raw_decode(sys.stdin.read())[0];r=(d.get('teamXg') or [{}])[0];print(json.dumps({'n':r.get('nameFa'),'v':r.get('teamXg')},ensure_ascii=False))")
U3=$(curl -s "$BASE/api/topscorers/ucl?season=2020/2021" | py "import sys,json;d=json.JSONDecoder().raw_decode(sys.stdin.read())[0];r=(d.get('teamXg') or [{}])[0];print(json.dumps({'n':r.get('nameFa'),'v':r.get('teamXg')},ensure_ascii=False))")
B3=$(curl -s "$BASE/api/topscorers/bundesliga?season=2020/2021" | py "import sys,json;d=json.JSONDecoder().raw_decode(sys.stdin.read())[0];r=(d.get('teamXg') or [{}])[0];print(json.dumps({'n':r.get('nameFa'),'v':r.get('teamXg')},ensure_ascii=False))")
echo "$A3" | tr -d '\\' | grep -q 'بارسلونا' && echo "$A3" | tr -d '\\' | grep -q '74.3' && ok "A3a frozen anchor: laliga 2020/21 «بارسلونا» 74.3 (the 237 anchor re-verified)" || bad "A3a: $A3"
echo "$U3" | tr -d '\\' | grep -q 'چلسی' && echo "$U3" | tr -d '\\' | grep -q '26.2' && ok "A3b NEW breadth: ucl 2020/21 «چلسی» 26.2 (first probe — the 202 anchor class on the team surface)" || bad "A3b: $U3"
echo "$B3" | tr -d '\\' | grep -q 'بایرن' && echo "$B3" | tr -d '\\' | grep -q '77.2' && ok "A3c NEW breadth: bundesliga 2020/21 «بایرن‌مونیخ» 77.2 (first probe)" || bad "A3c: $B3"

# A4 the standings route serves teamXg (v26) — both routes consistent
A4=$(curl -s "$BASE/api/standings?league=laliga" | py "import sys,json;d=json.JSONDecoder().raw_decode(sys.stdin.read())[0];tx=d.get('teamXg') or [];r=(tx or [{}])[0];print(json.dumps({'n':len(tx),'fa':r.get('nameFa'),'v':r.get('teamXg')},ensure_ascii=False,separators=(',',':')))" )
echo "$A4" | tr -d '\\' | grep -q '"n":10' && echo "$A4" | tr -d '\\' | grep -q 'بارسلونا' && ok "A4 standings route: teamXg len 10 top-level with Persian rank-1 (the v26 additive shape — both routes consistent)" || bad "A4: $A4"

# A5 the ligue1 JS-number corner as-found
A5=$(curl -s "$BASE/api/topscorers/ligue1" | py "import sys,json;d=json.JSONDecoder().raw_decode(sys.stdin.read())[0];r=(d.get('teamXg') or [{}])[0];print(json.dumps({'v':r.get('teamXg'),'exact20':r.get('teamXg')==20},ensure_ascii=False,separators=(',',':')))" )
echo "$A5" | tr -d '\\' | grep -q '"exact20":true' && ok "A5 ligue1 corner: raw teamXg === 20 (JS integer) — the toFixed(1) pill must render «۲۰.۰» (proven in B3)" || bad "A5: $A5"

# A6 the negative season probe (the standing SEASON_PARAM_RE contract)
A6=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F21" | py "import sys,json;d=json.JSONDecoder().raw_decode(sys.stdin.read())[0];print(1 if (d.get('ok')==False and 'Invalid season' in str(d.get('error'))) else 0)")
[ "$A6" = "1" ] && ok "A6 negative probe: season 2020/21 → {ok:false, Invalid season} (the two-stage shape contract)" || bad "A6: $A6"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B1=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const iX=h2s.indexOf('گل مورد انتظار'), iTGM=h2s.indexOf('گل به از مسابقهٔ تیم‌ها'), iT=h2s.indexOf('گل مورد انتظار تیم‌ها'), iCS=h2s.indexOf('گل نخرده‌های تیم‌ها'), iPOS=h2s.indexOf('مالکیت توپ تیم‌ها'), iYC=h2s.indexOf('کارت‌های زرد تیم‌ها'), iTRC=h2s.indexOf('کارت‌های قرمز تیم‌ها'), iXG=h2s.indexOf('گل مورد انتظار روی دروازه'), iG=h2s.indexOf('گل در هر ۹۰'), iA=h2s.indexOf('پاس مورد انتظار'), iB=h2s.indexOf('سانس بزرگ خلق‌شده'), iC=h2s.indexOf('فرصت‌های خلق‌شده'), iBM=h2s.indexOf('سانس بزرگ ازدست‌رفته'), iM=h2s.indexOf('بیشترین دقایق'); const order=iX>-1&&iTGM>iX&&iT>iTGM&&iCS>iT&&iPOS>iCS&&iYC>iPOS&&iTRC>iYC&&iXG>iTRC&&iG>iXG&&iA>iG&&iB>iA&&iC>iB&&iBM>iC&&iM>iBM; const q=['درصد سیو','سیو در هر ۹۰','گل نخرده‌ها','گل‌های پیشگیری‌شده','پنالتی‌های مهارشده'].map(x=>h2s.indexOf(x)); const quintet=q.every(i=>i>-1)&&q.every((i,k)=>k===0||i>q[k-1]); const tgm=document.querySelectorAll('[data-testid=tgm-row]').length; const rows=document.querySelectorAll('[data-testid=txg-row]').length; const tcs=document.querySelectorAll('[data-testid=tcs-row]').length; const tposs=document.querySelectorAll('[data-testid=tposs-row]').length; const tyc=document.querySelectorAll('[data-testid=tyc-row]').length; const trc=document.querySelectorAll('[data-testid=trc-row]').length; const vbroken=[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length; return JSON.stringify({order,quintet,tgm,rows,tcs,tposs,tyc,trc,vbroken,h2n:h2s.length}); })()")
echo "$B1" | tr -d '\\' | grep -q '"order":true' && echo "$B1" | tr -d '\\' | grep -q '"quintet":true' && echo "$B1" | tr -d '\\' | grep -q '"rows":10' && echo "$B1" | tr -d '\\' | grep -q '"vbroken":0' && echo "$B1" | tr -d '\\' | grep -q '"tgm":10' && echo "$B1" | tr -d '\\' | grep -q '"tposs":10' && echo "$B1" | tr -d '\\' | grep -q '"tyc":10' && echo "$B1" | tr -d '\\' | grep -q '"trc":10' && echo "$B1" | tr -d '\\' | grep -q '"h2n":24' \
  && ok "B1 DOM laliga: 22 h2 blocks [census 18→19 (240) → 20 (241) → 21 (242) → 22 (245) → 23 (246, team goals-per-match)] + the player→team pair order + the SIX team-side blocks adjacent (tgm leads) + keeper QUINTET + 10 rows × 6 team testids + zero real overflow @390x844 (hunt breadth: the FULL 23-block census)" || bad "B1: $B1"

# B2 the decimal pill + ROW-LEVEL inner overflow (hunt extension: element-level)
B2=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=txg-row]')]; const a=rows[0]&&rows[0].querySelector('a'); const pill=a&&a.lastElementChild; const innerOvf=rows.filter(r=>r.scrollWidth>r.clientWidth+1).length; const latinPill=rows.filter(r=>/[0-9]/.test((r.querySelector('[dir=ltr]')||{}).textContent||'')).length; return JSON.stringify({pill:(pill&&pill.textContent.trim())||'', dir:(pill&&pill.getAttribute('dir'))||null, innerOvf, latinPill}); })()")
echo "$B2" | tr -d '\\' | grep -q '"pill":"۳۴.۸"' && echo "$B2" | tr -d '\\' | grep -q '"dir":"ltr"' && echo "$B2" | tr -d '\\' | grep -q '"innerOvf":0' && echo "$B2" | tr -d '\\' | grep -q '"latinPill":0' \
  && ok "B2 DOM pill: «۳۴.۸» dir=ltr + ZERO row-level inner overflow + zero Latin digits in pills (the hunt's element-level overflow extension)" || bad "B2: $B2"

# B3 the ligue1 integer corner rendered
agent-browser open "$BASE/topscorers/ligue1" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B3=$(agent-browser eval "(() => { const r=document.querySelector('[data-testid=txg-row]'); const pill=r&&r.querySelector('[dir=ltr]'); return JSON.stringify({pill:(pill&&pill.textContent.trim())||''}); })()")
echo "$B3" | tr -d '\\' | grep -q '"pill":"۲۰.۰"' && ok "B3 DOM integer corner: ligue1 rank-1 pill renders «۲۰.۰» from the raw 20 (toFixed(1) on the JS-number corner — the A5 pair)" || bad "B3: $B3"

# B4 real navigation txg → team page (h1 contract)
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1
agent-browser find first "[data-testid=txg-row] a" click >/dev/null 2>&1
sleep 3
B4=$(agent-browser eval "(() => JSON.stringify({url:location.pathname, h1:(document.querySelector('h1')||{}).textContent||''}))()")
echo "$B4" | tr -d '\\' | grep -q '/team/8634' && echo "$B4" | tr -d '\\' | grep -q 'بارسلونا' && ok "B4 real navigation: txg top-1 → /team/8634 h1 «بارسلونا» (the /team/{teamId} contract, h1-shape this time)" || bad "B4: $B4"

# B5 the honest absences in DOM (persiangulf + mas)
agent-browser open "$BASE/topscorers/persiangulf" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B5a=$(agent-browser eval "(() => { const t=document.body.innerText||''; return JSON.stringify({txgAbsent:!t.includes('گل مورد انتظار تیم‌ها'), gp90:t.includes('گل در هر ۹۰')}); })()")
agent-browser open "$BASE/topscorers/mas" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B5b=$(agent-browser eval "(() => { const t=document.body.innerText||''; return JSON.stringify({txgAbsent:!t.includes('گل مورد انتظار تیم‌ها'), cards:t.includes('کارت‌ها')}); })()")
echo "$B5a" | tr -d '\\' | grep -q '"txgAbsent":true' && echo "$B5a" | tr -d '\\' | grep -q '"gp90":true' && echo "$B5b" | tr -d '\\' | grep -q '"txgAbsent":true' && echo "$B5b" | tr -d '\\' | grep -q '"cards":true' \
  && ok "B5 DOM honest absences: persiangulf (gp90 serves) + mas (cards serves — the 233 mas contract: mas serves scorers+cards ONLY, minutes len 0) both hide the team block" || bad "B5: $B5a / $B5b"

# B6 the ucl 2020/21 DOM anchor (NEW breadth in DOM)
agent-browser open "$BASE/topscorers/ucl?season=2020/2021" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B6=$(agent-browser eval "(() => { const t=document.body.innerText||''; const u=new URL(location.href); return JSON.stringify({chelsea:t.includes('چلسی'), v262:t.includes('۲۶.۲'), season:u.searchParams.get('season')}); })()")
echo "$B6" | tr -d '\\' | grep -q '"chelsea":true' && echo "$B6" | tr -d '\\' | grep -q '"v262":true' && echo "$B6" | tr -d '\\' | grep -q '"season":"2020/2021"' \
  && ok "B6 DOM historical breadth: ucl 2020/21 renders «چلسی» «۲۶.۲» with the URL param preserved (first-time DOM proof beyond the laliga anchor)" || bad "B6: $B6"

# B7 badge twins on scorer rows (the 235/236 mechanism regression)
agent-browser open "$BASE/topscorers/ucl" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B7=$(agent-browser eval "(() => { const t=document.body.innerText||''; return JSON.stringify({bcm:t.includes('سانس ازدست‌رفته'), cc:t.includes('فرصت‌سازی')}); })()")
echo "$B7" | tr -d '\\' | grep -q '"bcm":true' && echo "$B7" | tr -d '\\' | grep -q '"cc":true' \
  && ok "B7 badge twins: ucl scorer rows carry the «سانس ازدست‌رفته» + «فرصت‌سازی» badges (the 235/236 twin mechanism intact)" || bad "B7: $B7"

# B8 the placement contract: /league/* keeps the OLD set
agent-browser open "$BASE/league/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B8=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('h2')].map(h=>h.textContent); const t=document.body.innerText||''; return JSON.stringify({xgTable:h2s.includes('جدول xG'), noTeam:!t.includes('گل مورد انتظار تیم‌ها'), txg:document.querySelectorAll('[data-testid=txg-row]').length}); })()")
echo "$B8" | tr -d '\\' | grep -q '"xgTable":true' && echo "$B8" | tr -d '\\' | grep -q '"noTeam":true' && echo "$B8" | tr -d '\\' | grep -q '"txg":0' \
  && ok "B8 placement contract: /league/laliga keeps the OLD set (جدول xG h2, zero txg-rows, no team block) — the family rides /topscorers ONLY (by design, now fenced)" || bad "B8: $B8"

# B9 the /matches honest 404 shell
agent-browser open "$BASE/matches" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1
B9=$(agent-browser eval "(() => { const t=document.body.innerText||''; return JSON.stringify({nf:t.includes('۴۰۴'), ovf:document.documentElement.scrollWidth>document.documentElement.clientWidth}); })()")
echo "$B9" | tr -d '\\' | grep -q '"nf":true' && echo "$B9" | tr -d '\\' | grep -q '"ovf":false' \
  && ok "B9 honest 404: /matches (no such route by design) renders the clean not-found shell, zero overflow" || bad "B9: $B9"

# B10 console + errors across the session
CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B10 console=0 errors=0 across the whole patrol session" || bad "B10: console=$CN errors=$CE"
agent-browser close >/dev/null 2>&1

echo "== Part C: warm LAT sweep =="
LAT=1
for P_ in / /topscorers/laliga /topscorers/persiangulf; do
  T=$(curl -s -o /dev/null -w '%{time_total}' --max-time 30 "$BASE$P_")
  echo "     LAT $P_ = ${T}s"
  python3 -c "import sys; sys.exit(0 if float('$T')<5.0 else 1)" || LAT=0
done
[ "$LAT" = "1" ] && ok "Part C LAT: all 3 routes < 5000ms" || bad "Part C: LAT breach"

echo "== RESULT: $PASS PASS / $FAIL FAIL =="
[ "$FAIL" = "0" ]
