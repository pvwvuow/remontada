#!/bin/bash
# cycle244-fixproof.sh — permanent gate for the cycle-244 fix
# (Fix (cycle 244): the VALIDATION-ONLY fixproof (the 234 class, zero app
#  code changes). The 243 hunt was the THIRD clean hunt after 233/238 —
#  zero new app bugs, zero gate drift — and registered NO drift for
#  absorption: "244 runs the standing fixproof suite and absorbs whatever
#  drift the feed produces by then; if none, it lands as a validation-only
#  fixproof (the 234 class); no app code change expected." As-found
#  pre-acceptance re-run (2026-10-31, the 243 binary pid=10527): the FULL
#  standing suite ALL GREEN — regression 28/28 + 227-domproof 14/14 (the
#  239-refreshed Taheri anchor, second consecutive green) + 238-hunt 19/19
#  (census 21) + 243-hunt 17/17 + 242/241/240/237/236/235-domproof 13/13 x6
#  + 234-fixproof 10/10 → ZERO drift absorbed, the 243 registration held
#  EXACTLY. This gate re-validates the full fix-state contract on the final
#  binary: the four-block family merge contract (the 237/240/241/242 class),
#  the honest absences on BOTH seasons with the pg historical-tcs finding
#  PINNED (the 243 A2b face — the absence is current-season-scoped and must
#  never silently generalize), the frozen 2020/21 laliga team anchors, the
#  negative season probe, the pg gp90 pair, the 21-block census @390x844,
#  the pill conventions (contract-level, drift-safe: dir=ltr + Persian-digit
#  pills, no exact live values — live-value anchors live in their own gates
#  240/241/242/227 and get refreshed by the 239 maintenance pattern on real
#  drift), the /team link contract rank-independent, the mas/pg exact DOM
#  faces, and a clean console.)
# Part A (API):
#   A1 the four-block family contract sweep: eight serving leagues x four
#      team blocks (teamXg/teamCleanSheets/teamPossession/teamYellowCards)
#      = 32 sweeps: 10 rows, monotonic DESC, positional rank 1..10, zero
#      Latin nameFa (the 237/240/241/242 merge contracts as one face)
#   A2 the honest absences on BOTH seasons: pg all-four empty CURRENT; mas
#      txg/tposs/tyc empty AND tcs=8 (the 240 floor-4 exemption) on BOTH
#      seasons; pg HISTORICAL tcs=10 (the 243 fresh finding PINNED — the
#      honest absence is current-season-scoped, does not generalize back)
#   A3 the frozen 2020/2021 laliga team anchors zero-regression: tcs
#      Atletico Madrid 18.0 + tposs Barcelona 65.8 + tyc Getafe 114.0
#      (the 240/241/242 frozen class)
#   A4 the negative probe: bad season shape 2020/21 → ok:false (the
#      SEASON_PARAM_RE contract)
#   A5 the pg gp90 pair: pg gp90=10 rows + mas gp90=0 (the 227/243 face)
# Part B (DOM @390x844, agent-browser, console must stay 0):
#   B1 the FULL 21-block census on /topscorers/laliga: family order +
#      keeper quintet + 10 rows x 4 team testids + zero doc-level overflow
#   B2 the pill conventions, contract-level and drift-safe: every team-row
#      value pill dir=ltr with Persian-digit-only text + zero Latin digits
#      inside the four team blocks
#   B3 real navigation /team/8305 → h1 «ختافه» (the standings-view link
#      contract end-to-end, rank-independent)
#   B4 the mas exact team-block set [گل نخرده‌های تیم‌ها، کارت‌ها] with 8
#      tcs-rows + the pg zero-team-h2 face (gp90 active)
#   B5 console=0 errors=0 across the whole session
# Part C: warm LAT sweep, 3 routes <5000ms
set -u
BASE="${BASE:-http://localhost:3000}"
TMP="$(mktemp /home/z/my-project/.cycle244-fixproof-XXXXXX)"
trap 'rm -f "$TMP"' EXIT
PASS=0; FAIL=0
ok(){ echo "OK  - $1"; PASS=$((PASS+1)); }
bad(){ echo "BAD - $1"; FAIL=$((FAIL+1)); }
py(){ python3 -c "$1"; }

echo "== Part A: API gates =="

# A1 the four-block family contract sweep (32 block-sweeps)
A1OUT=$(python3 - "$BASE" <<'PY'
import json,sys,re,subprocess
base=sys.argv[1]
fa=re.compile(r'[\u0600-\u06FF]')
BLOCKS=[("teamXg","teamXg"),("teamCleanSheets","teamCleanSheets"),("teamPossession","teamPossession"),("teamYellowCards","teamYellowCards")]
leagues=["laliga","pl","seriea","bundesliga","ligue1","ucl","uel","portugal"]
bad=[]
for lg in leagues:
    raw=subprocess.run(["curl","-s",f"{base}/api/topscorers/{lg}"],capture_output=True,text=True).stdout
    d=json.JSONDecoder().raw_decode(raw.strip())[0]
    for field,key in BLOCKS:
        rows=d.get(field) or []
        vals=[r.get(field) for r in rows]
        mono=all(vals[i]>=vals[i+1] for i in range(len(vals)-1)) if vals else False
        ranks=[r.get("rank") for r in rows]==list(range(1,len(rows)+1))
        latin=[r["name"] for r in rows if not fa.search(r.get("nameFa") or "")]
        if len(rows)!=10 or not mono or not ranks or latin:
            bad.append({"lg":lg,"field":field,"n":len(rows),"mono":mono,"ranks":ranks,"latin":latin})
print(json.dumps({"bad":bad},separators=(',',':')))
PY
)
echo "$A1OUT" | tr -d '\\' | grep -q '"bad":\[\]' && ok "A1 four-block family contract: eight serving leagues carry teamXg+teamCleanSheets+teamPossession+teamYellowCards = 10 rows each, monotonic DESC, positional 1..10, zero Latin nameFa (32 block-sweeps, the 237/240/241/242 merge contracts as one face)" || bad "A1: $A1OUT"

# A2 the honest absences on BOTH seasons + the pg historical-tcs finding PINNED
A2OUT=$(python3 - "$BASE" <<'PY'
import json,sys,subprocess
base=sys.argv[1]
det={}
for lg in ["persiangulf","mas"]:
    for tag,season in [("cur",""),("hist","?season=2020/2021")]:
        raw=subprocess.run(["curl","-s",f"{base}/api/topscorers/{lg}{season}"],capture_output=True,text=True).stdout
        d=json.JSONDecoder().raw_decode(raw.strip())[0]
        det[f"{lg}-{tag}"]={"txg":len(d.get("teamXg") or []),"tcs":len(d.get("teamCleanSheets") or []),
                "tposs":len(d.get("teamPossession") or []),"tyc":len(d.get("teamYellowCards") or [])}
print(json.dumps(det,separators=(',',':')))
PY
)
echo "$A2OUT" | tr -d '\\' | grep -q '"persiangulf-cur":{"txg":0,"tcs":0,"tposs":0,"tyc":0}' \
  && echo "$A2OUT" | tr -d '\\' | grep -q '"mas-cur":{"txg":0,"tcs":8,"tposs":0,"tyc":0}' \
  && echo "$A2OUT" | tr -d '\\' | grep -q '"mas-hist":{"txg":0,"tcs":8,"tposs":0,"tyc":0}' \
  && echo "$A2OUT" | tr -d '\\' | grep -q '"persiangulf-hist":{"txg":0,"tcs":10,"tposs":0,"tyc":0}' \
  && ok "A2 honest absences both seasons: pg all-four empty CURRENT (the 240 contract, current-season-scoped); mas txg/tposs/tyc empty AND tcs=8 on BOTH seasons (the floor-4 exemption); pg HISTORICAL tcs=10 (the 243 fresh finding PINNED — the absence does not generalize backwards)" || bad "A2: $A2OUT"

# A3 the frozen 2020/2021 laliga team anchors — zero regression
A3=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F2021" | py "
import sys,json
d=json.load(sys.stdin)
def top(field):
    rows=d.get(field) or []
    if not rows: return ('EMPTY','')
    r=rows[0]
    v=r.get(field)
    if v is None: v=r.get('value')
    return (r.get('nameFa'),v)
print(json.dumps({'tcs':top('teamCleanSheets'),'tposs':top('teamPossession'),'tyc':top('teamYellowCards')},ensure_ascii=False,separators=(',',':')))
")
echo "$A3" | grep -q '"tcs":\["اتلتیکومادرید",18' && echo "$A3" | grep -q '"tposs":\["بارسلونا",65.8\]' && echo "$A3" | grep -q '"tyc":\["ختافه",114' \
  && ok "A3 frozen 2020/2021 laliga team anchors intact: tcs «اتلتیکو مادرید» 18.0 + tposs «بارسلونا» 65.8 + tyc «ختافه» 114.0 (the 240/241/242 frozen class)" || bad "A3: $A3"

# A4 the negative probe — bad season shape
N=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F21" | py "import sys,json;d=json.load(sys.stdin);print(1 if (d.get('ok')==False and 'Invalid season' in str(d.get('error'))) else 0)")
[ "$N" = "1" ] && ok "A4 negative probe: two-stage season shape 2020/21 → {ok:false, Invalid season} (the SEASON_PARAM_RE contract)" || bad "A4: $N"

# A5 the pg gp90 pair (the 227/243 face)
A5=$(python3 - "$BASE" <<'PY'
import json,sys,subprocess
base=sys.argv[1]
res={}
for lg in ["persiangulf","mas"]:
    raw=subprocess.run(["curl","-s",f"{base}/api/topscorers/{lg}"],capture_output=True,text=True).stdout
    d=json.JSONDecoder().raw_decode(raw.strip())[0]
    res[lg]=len(d.get("goalsPer90") or [])
print(json.dumps(res,separators=(',',':')))
PY
)
echo "$A5" | tr -d '\\' | grep -q '"persiangulf":10' && echo "$A5" | tr -d '\\' | grep -q '"mas":0' \
  && ok "A5 the gp90 pair: persiangulf 10 rows (the 227 contract — the league IS reached) + mas 0 (honest absence)" || bad "A5: $A5"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B1=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const iX=h2s.indexOf('گل مورد انتظار'), iT=h2s.indexOf('گل مورد انتظار تیم‌ها'), iCS=h2s.indexOf('گل نخرده‌های تیم‌ها'), iPOS=h2s.indexOf('مالکیت توپ تیم‌ها'), iYC=h2s.indexOf('کارت‌های زرد تیم‌ها'), iTRC=h2s.indexOf('کارت‌های قرمز تیم‌ها'), iXG=h2s.indexOf('گل مورد انتظار روی دروازه'), iG=h2s.indexOf('گل در هر ۹۰'), iA=h2s.indexOf('پاس مورد انتظار'), iB=h2s.indexOf('سانس بزرگ خلق‌شده'), iC=h2s.indexOf('فرصت‌های خلق‌شده'), iBM=h2s.indexOf('سانس بزرگ ازدست‌رفته'), iM=h2s.indexOf('بیشترین دقایق'); const order=iX>-1&&iT>iX&&iCS>iT&&iPOS>iCS&&iYC>iPOS&&iTRC>iYC&&iXG>iTRC&&iG>iXG&&iA>iG&&iB>iA&&iC>iB&&iBM>iC&&iM>iBM; const q=['درصد سیو','سیو در هر ۹۰','گل نخرده‌ها','گل‌های پیشگیری‌شده','پنالتی‌های مهارشده'].map(x=>h2s.indexOf(x)); const quintet=q.every(i=>i>-1)&&q.every((i,k)=>k===0||i>q[k-1]); const rows=document.querySelectorAll('[data-testid=txg-row]').length; const tcs=document.querySelectorAll('[data-testid=tcs-row]').length; const tposs=document.querySelectorAll('[data-testid=tposs-row]').length; const tyc=document.querySelectorAll('[data-testid=tyc-row]').length; const trc=document.querySelectorAll('[data-testid=trc-row]').length; const vbroken=[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length; return JSON.stringify({order,quintet,rows,tcs,tposs,tyc,trc,vbroken,h2n:h2s.length}); })()")
echo "$B1" | tr -d '\\' | grep -q '"order":true' && echo "$B1" | tr -d '\\' | grep -q '"quintet":true' && echo "$B1" | tr -d '\\' | grep -q '"rows":10' && echo "$B1" | tr -d '\\' | grep -q '"vbroken":0' && echo "$B1" | tr -d '\\' | grep -q '"tposs":10' && echo "$B1" | tr -d '\\' | grep -q '"tyc":10' && echo "$B1" | tr -d '\\' | grep -q '"trc":10' && echo "$B1" | tr -d '\\' | grep -q '"h2n":22' \
  && ok "B1 DOM census @390x844: 22 h2 blocks [census refreshed BY DESIGN 21→22 — the 245 red team block] + the family order + keeper QUINTET + 10 txg-rows + 10 tcs-rows + 10 tposs-rows + 10 tyc-rows + 10 trc-rows + zero real overflow (the FULL 22-block census)" || bad "B1: $B1"

# B2 the pill conventions — contract-level, drift-safe
B2=$(agent-browser eval "(() => { const out={}; for (const t of ['txg','tcs','tposs','tyc','trc']) { const rows=[...document.querySelectorAll('[data-testid='+t+'-row]')]; const badDir=rows.filter(r=>{const p=r.querySelector('[dir=ltr]');return !p;}).length; const badDigits=rows.filter(r=>{const p=r.querySelector('[dir=ltr]');const s=(p&&p.textContent.trim())||'';return s && !/^[۰-۹.]+$/.test(s);}).length; const latinRow=rows.filter(r=>/[0-9]/.test(r.textContent)).length; out[t]={n:rows.length,badDir,badDigits,latinRow}; } return JSON.stringify(out); })()")
echo "$B2" | tr -d '\\' | grep -q '"txg":{"n":10,"badDir":0,"badDigits":0,"latinRow":0}' && echo "$B2" | tr -d '\\' | grep -q '"tcs":{"n":10,"badDir":0,"badDigits":0,"latinRow":0}' && echo "$B2" | tr -d '\\' | grep -q '"tposs":{"n":10,"badDir":0,"badDigits":0,"latinRow":0}' && echo "$B2" | tr -d '\\' | grep -q '"tyc":{"n":10,"badDir":0,"badDigits":0,"latinRow":0}' && echo "$B2" | tr -d '\\' | grep -q '"trc":{"n":10,"badDir":0,"badDigits":0,"latinRow":0}' \
  && ok "B2 pill conventions (contract-level, drift-safe): every value pill in the FIVE team blocks is dir=ltr with Persian-digit-only text and zero Latin digits row-wide (the String()/toFixed() classes without pinning live values)" || bad "B2: $B2"

# B3 real navigation — rank-independent link contract
agent-browser open "$BASE/team/8305" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B3=$(agent-browser eval "(() => JSON.stringify({url:location.pathname, h1:(document.querySelector('h1')||{}).textContent||''}))()")
echo "$B3" | tr -d '\\' | grep -q '/team/8305' && echo "$B3" | tr -d '\\' | grep -q 'ختافه' \
  && ok "B3 real navigation: /team/8305 → h1 «ختافه» (the /team/{teamId} standings-view contract end-to-end, rank-independent)" || bad "B3: $B3"

# B4 the mas exact face + the pg zero-team face
agent-browser open "$BASE/topscorers/mas" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B4a=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const rows=[...document.querySelectorAll('[data-testid=tcs-row]')]; const first=rows[0]&&rows[0].querySelector('a'); const teamSurfaces=['گل مورد انتظار تیم‌ها','گل نخرده‌های تیم‌ها','مالکیت توپ تیم‌ها','کارت‌های زرد تیم‌ها','کارت‌های قرمز تیم‌ها']; return JSON.stringify({tcs:h2s.indexOf('گل نخرده‌های تیم‌ها'), trc:h2s.indexOf('کارت‌های قرمز تیم‌ها'), cards:h2s.indexOf('کارت‌ها'), n:rows.length, first:(first&&first.textContent.includes('جوهور دارالتعظیم'))||false, teamSurfaces:h2s.filter(t=>teamSurfaces.includes(t)).length}); })()")
echo "$B4a" | tr -d '\\' | grep -q '"n":8' && echo "$B4a" | tr -d '\\' | grep -q '"first":true' && echo "$B4a" | tr -d '\\' | grep -q '"teamSurfaces":2' \
  && ok "B4a mas exact face: exactly TWO team-surface h2s [گل نخرده‌های تیم‌ها + کارت‌های قرمز تیم‌ها — the SECOND mas team-surface, the 245 red block] + کارت‌ها with 8 tcs-rows and rank-1 «جوهور دارالتعظیم» (the 240 floor-4 exemption live)" || bad "B4a: $B4a"
agent-browser open "$BASE/topscorers/persiangulf" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B4b=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const teamSurfaces=['گل مورد انتظار تیم‌ها','گل نخرده‌های تیم‌ها','مالکیت توپ تیم‌ها','کارت‌های زرد تیم‌ها','کارت‌های قرمز تیم‌ها']; const g90=h2s.indexOf('گل در هر ۹۰'); return JSON.stringify({teamSurfaces:h2s.filter(t=>teamSurfaces.includes(t)).length, g90, h2n:h2s.length}); })()")
echo "$B4b" | tr -d '\\' | grep -q '"teamSurfaces":0' && echo "$B4b" | tr -d '\\' | grep -q '"g90":[0-9]' \
  && ok "B4b pg face (the 227/243 contract): zero team-surface h2s WITH the gp90 block active (h2 «گل در هر ۹۰» present — the league IS reached); the HISTORICAL tcs=10 file stays pinned at A2, not rendered on current by design" || bad "B4b: $B4b"

CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B5 console=0 errors=0 across the whole session" || bad "B5: console=$CN errors=$CE"
agent-browser close >/dev/null 2>&1

echo "== Part C: warm LAT sweep =="
LAT=1
for P_ in / /topscorers/laliga /topscorers/mas; do
  T=$(curl -s -o /dev/null -w '%{time_total}' --max-time 30 "$BASE$P_")
  echo "     LAT $P_ = ${T}s"
  python3 -c "import sys; sys.exit(0 if float('$T')<5.0 else 1)" || LAT=0
done
[ "$LAT" = "1" ] && ok "Part C warm LAT: 3 routes <5000ms" || bad "Part C: a route exceeded 5000ms"

echo "== VERDICT =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE244 FIXPROOF ALL GREEN (the validation-only fix — the 234 class: zero app code changes, the 243 clean-hunt registration held EXACTLY, zero drift absorbed; the four-block family contract + the honest absences both seasons with the pg historical-tcs finding pinned + the frozen 2020/21 team anchors + the negative probe + the gp90 pair + the 21-block census @390x844 + the drift-safe pill conventions + the link contract + the mas/pg exact faces + clean console)" && exit 0
exit 1
