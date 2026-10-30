#!/bin/bash
# cycle243-hunt.sh — the cycle-243 bug-hunt patrol (clean-verdict gate, whole-family focus)
# (Bug-hunt (cycle 243): the 242 card's hunt candidate — page patrol at viewport
#  390x844 across the FULL deep-file family (now 21 h2 blocks with the FOUR
#  team-side surfaces), plus the standing whole-app sweep. First hunt on the
#  242 build. Verdict: ZERO new app bugs, ZERO gate-internal live drift.
#  Patrol evidence 2026-10-31 ~00:1x +08:00 (session after the 2e57dda landing):
#  - Pre-patrol gate suite ALL GREEN on the same build: regression 28/28
#    (BASE explicit), 227-domproof 14/14 (the 239-refreshed live anchors
#    «کسری طاهری» 1.32 / سپاهان re-verified AGAIN — second consecutive green
#    since the refresh; the laliga Raphinha anchor also holds), 238-hunt 19/0
#    (census 21), 242/241/240/237/236/235-domproof 13/13 each, 234-fixproof
#    10/10. No drift for a 244 gate-maintenance refresh to absorb YET.
#  - API: ten league keys swept. Eight serving (laliga pl seriea bundesliga
#    ligue1 ucl uel portugal) carry ALL FOUR team blocks (teamXg/teamCleanSheets/
#    teamPossession/teamYellowCards) at exactly 10 rows — monotonic DESC,
#    POSITIONAL ranks 1..10, zero Latin nameFa leaks. persiangulf: all four
#    blocks honestly empty + gp90 serves 10 (the 227 contract). mas: txg/tposs/
#    tyc honestly empty, tcs=8 (the 240 league-aware floor exemption) and
#    gp90=0 (the known mas scorer contract). keys=29 on every route.
#  - Live as-found anchors tonight: laliga teamXg rank-1 «بارسلونا» 34.8 /
#    teamCleanSheets rank-1 «اتلتیک‌بیلبائو» 6 / teamPossession rank-1
#    «بارسلونا» 69.4 / teamYellowCards rank-1 «ختافه» 33. FIRST-TIME season
#    breadth probes: ucl 2020/21 teamYellowCards «پاری سن‌ژرمن» 27 and
#    teamPossession «بارسلونا» 62.5 — the 202/238 anchor class generalizes to
#    the newest two team surfaces (frozen files, distinct from current 33/69.4).
#  - DOM @390x844: /topscorers/laliga renders h2n=21 with the family order
#    [گل مورد انتظار → گل مورد انتظار تیم‌ها → گل نخرده‌های تیم‌ها → مالکیت توپ
#    تیم‌ها → کارت‌های زرد تیم‌ها → گل مورد انتظار روی دروازه → گل در هر ۹۰ → …]
#    + keeper QUINTET intact; 10 rows per each of the FOUR team testids
#    (txg/tcs/tposs/tyc); the tyc String() integer pill «۳۳» dir=ltr and the
#    tposs toFixed(1) pill «۶۹.۴» dir=ltr with zero Latin digits; zero
#    document-level AND row-level inner overflow; real navigation tyc top-1 →
#    /team/8305 h1 «ختافه»; mas renders EXACTLY [گل نخرده‌های تیم‌ها، کارت‌ها]
#    with 8 tcs-rows and rank-1 «جوهور دارالتعظیم ۶»; persiangulf renders zero
#    team h2s with gp90 serving; badge twins on ucl scorer rows intact;
#    /league/laliga keeps the OLD analytics set (zero team rows); /matches the
#    honest 404 shell; console=0 errors=0 across the patrol session.
#  - FRESH HUNT FINDING (the patrol's one new fact, NOT an app bug): the
#    persiangulf HISTORICAL 2020/21 feed serves teamCleanSheets = 10 rows —
#    first probe tonight; the 240 honest-absence contract is CURRENT-season-
#    scoped exactly as its gate asserts (pg current tcs = 0 holds; the 238
#    hunt only asserted teamXg historically). The absence does not generalize
#    backwards. Registered for the 244+ update rounds: pg historical tcs is a
#    legitimate breadth candidate if a team-side sibling round wants it.
#  - HARNESS LESSON (first-run 14/3 → fixed): json.dumps without
#    separators=(',',':') emits ": " with a space and the grep assertions
#    miss — the 238 harness already carried the lesson in its A3 prints; the
#    243 gate now carries it in every inline print.
#  REGISTERED for cycle 244 = fix (the 230→233→234→239 gate-maintenance
#  pattern): NO drift registered this patrol — every live anchor green
#  including the twice-drifted Gulf pair (second consecutive green since the
#  239 refresh). The 244 fix therefore runs the standing fixproof suite and
#  absorbs whatever drift the feed produces between now and then; if none, it
#  lands as a validation-only fixproof (the 234 class). Standing honest
#  candidates remain: the 27 other team-side files (squad_value_team —
#  historical file honestly absent / home_attendance_team / accurate_pass_team
#  / total_red_card_team — probed WIDE 6-16 rows, the yellow sibling's red
#  brother / corners / fouls_per_match…), the top-20-scorers-tails sweep (the
#  229 lesson). No app-code change is expected in 244.)
# Part A (API): A1 the FOUR-block contract sweep on the eight serving leagues
#               (len=10, monotonic DESC, positional 1..10, zero Latin nameFa)
#               A2 the honest absences (pg: all four empty on CURRENT; mas:
#               txg/tposs/tyc empty AND tcs=8 the floor exemption on both
#               seasons) + the FRESH FINDING: pg 2020/21 historical tcs EXISTS
#               (10 rows, first probe tonight — absence is current-season-
#               scoped, no app bug))
#               A3 the frozen season anchors (laliga 2020/21 tyc «ختافه» 114 +
#               tposs «بارسلونا» 65.8) + NEW first-time breadth (ucl 2020/21
#               tyc «پاری سن‌ژرمن» 27 + tposs «بارسلونا» 62.5)
#               A4 the standings route serves the four blocks top-level (v29)
#               A5 the gp90 pair (pg serves 10, mas honest 0 — the 227 contract)
#               A6 the negative season probe (2020/21 → ok:false Invalid season)
# Part B (DOM @390x844): B1 /topscorers/laliga h2n=21 + the family order with
#               the FOUR team blocks adjacent + keeper QUINTET + 10 rows ×4
#               + zero real overflow
#               B2 the tyc String() integer pill «۳۳» dir=ltr + zero Latin
#               digits + zero row-level inner overflow
#               B3 the tposs toFixed(1) pill «۶۹.۴» dir=ltr (no percent sign)
#               B4 real navigation tyc row → /team/8305 h1 «ختافه»
#               B5 the mas exact-surface DOM (h2s == [گل نخرده‌های تیم‌ها,
#               کارت‌ها], 8 tcs-rows, rank-1 جوهور دارالتعظیم) + the pg zero-
#               team-h2s DOM with gp90 serving
#               B6 badge twins on scorer rows (ucl «سانس ازدست‌رفته» present)
#               B7 the placement contract: /league/laliga keeps the OLD set
#               + the /matches honest 404 shell
#               B8 console=0 errors=0 across the patrol session
# Part C: warm LAT sweep, 3 routes <5000ms
set -u
BASE="${BASE:-http://localhost:3000}"
TMP="$(mktemp -d /home/z/my-project/.cycle243-hunt-XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok(){ echo "OK  - $1"; PASS=$((PASS+1)); }
bad(){ echo "BAD - $1"; FAIL=$((FAIL+1)); }
py(){ python3 -c "$1"; }

echo "== Part A: API gates =="

# A1 the FOUR-block contract sweep on the eight serving leagues (raw_decode on
# temp files — the 234/235 harness lesson)
A1OUT=$(python3 - "$BASE" "$TMP" <<'PY'
import json,sys,re,subprocess
base,tmp=sys.argv[1],sys.argv[2]
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
echo "$A1OUT" | tr -d '\\' | grep -q '"bad":\[\]' && ok "A1 four-block sweep: eight serving leagues carry teamXg+teamCleanSheets+teamPossession+teamYellowCards = 10 rows each, monotonic DESC, positional 1..10, zero Latin nameFa (32 block-sweeps)" || bad "A1: $A1OUT"

# A2 the honest absences: pg all four empty on CURRENT (the 240 contract is
# current-season-scoped); mas txg/tposs/tyc empty AND tcs=8 (the floor
# exemption) on BOTH seasons. FRESH HUNT FINDING (first probe tonight): pg's
# HISTORICAL 2020/21 clean-sheets file EXISTS (10 rows) — the absence does NOT
# generalize backwards; registered as breadth, NOT an app bug (the 240 gate
# asserts the current season only, so it stays green by design).
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
a2a=all(det["persiangulf-cur"][f]==0 for f in ["txg","tcs","tposs","tyc"]) and \
    all(det["mas-cur"][f]==0 for f in ["txg","tposs","tyc"]) and det["mas-cur"]["tcs"]==8
a2b=all(det["mas-hist"][f]==0 for f in ["txg","tposs","tyc"]) and det["mas-hist"]["tcs"]==8 and \
    all(det["persiangulf-hist"][f]==0 for f in ["txg","tposs","tyc"]) and det["persiangulf-hist"]["tcs"]==10
print(json.dumps({"a2a":a2a,"a2b":a2b},separators=(',',':')))
PY
)
echo "$A2OUT" | tr -d '\\' | grep -q '"a2a":true' && echo "$A2OUT" | tr -d '\\' | grep -q '"a2b":true' && ok "A2 honest absences: pg all four empty on CURRENT + mas txg/tposs/tyc empty and tcs=8 the floor exemption on both seasons; FRESH FINDING: pg 2020/21 HISTORICAL clean-sheets file EXISTS (10 rows, first probe tonight) — the 240 absence contract is current-season-scoped, no app bug" || bad "A2: $A2OUT"

# A3 the frozen season anchors + FIRST-TIME breadth probes (ucl 2020/21)
A3A=$(curl -s "$BASE/api/topscorers/laliga?season=2020/2021" | py "import sys,json;d=json.JSONDecoder().raw_decode(sys.stdin.read())[0];t=(d.get('teamYellowCards') or [{}])[0];p=(d.get('teamPossession') or [{}])[0];print(json.dumps({'t':t.get('nameFa'),'tv':t.get('teamYellowCards'),'p':p.get('nameFa'),'pv':p.get('teamPossession')},ensure_ascii=False,separators=(',',':')))")
A3B=$(curl -s "$BASE/api/topscorers/ucl?season=2020/2021" | py "import sys,json;d=json.JSONDecoder().raw_decode(sys.stdin.read())[0];t=(d.get('teamYellowCards') or [{}])[0];p=(d.get('teamPossession') or [{}])[0];print(json.dumps({'t':t.get('nameFa'),'tv':t.get('teamYellowCards'),'p':p.get('nameFa'),'pv':p.get('teamPossession')},ensure_ascii=False,separators=(',',':')))")
echo "$A3A" | tr -d '\\' | grep -q 'ختافه' && echo "$A3A" | tr -d '\\' | grep -q '"tv":114' && echo "$A3A" | tr -d '\\' | grep -q 'بارسلونا' && echo "$A3A" | tr -d '\\' | grep -q '"pv":65.8' \
  && ok "A3a frozen anchors: laliga 2020/21 tyc «ختافه» 114 + tposs «بارسلونا» 65.8 (the 242/241 anchors re-verified)" || bad "A3a: $A3A"
echo "$A3B" | tr -d '\\' | grep -q 'پاری سن‌ژرمن' && echo "$A3B" | tr -d '\\' | grep -q '"tv":27' && echo "$A3B" | tr -d '\\' | grep -q '"pv":62.5' \
  && ok "A3b NEW breadth: ucl 2020/21 tyc «پاری سن‌ژرمن» 27 + tposs «بارسلونا» 62.5 (first-time probes — the 202/238 anchor class reaches the two newest team surfaces)" || bad "A3b: $A3B"

# A4 the standings route serves the four blocks top-level (the v29 shape)
A4=$(curl -s "$BASE/api/standings?league=laliga" | py "import sys,json;d=json.JSONDecoder().raw_decode(sys.stdin.read())[0];print(json.dumps({'txg':len(d.get('teamXg') or []),'tcs':len(d.get('teamCleanSheets') or []),'tposs':len(d.get('teamPossession') or []),'tyc':len(d.get('teamYellowCards') or [])},separators=(',',':')))" )
echo "$A4" | tr -d '\\' | grep -q '"txg":10' && echo "$A4" | tr -d '\\' | grep -q '"tcs":10' && echo "$A4" | tr -d '\\' | grep -q '"tposs":10' && echo "$A4" | tr -d '\\' | grep -q '"tyc":10' \
  && ok "A4 standings route: all four team blocks len 10 top-level (the v29 additive shape — both routes consistent)" || bad "A4: $A4"

# A5 the gp90 pair (the 227 contract): pg serves 10, mas honest 0
A5=$(curl -s "$BASE/api/topscorers/persiangulf" | py "import sys,json;d=json.JSONDecoder().raw_decode(sys.stdin.read())[0];print(len(d.get('goalsPer90') or []))")
A5B=$(curl -s "$BASE/api/topscorers/mas" | py "import sys,json;d=json.JSONDecoder().raw_decode(sys.stdin.read())[0];print(len(d.get('goalsPer90') or []))")
[ "$A5" = "10" ] && [ "$A5B" = "0" ] && ok "A5 gp90 pair: persiangulf serves 10 rows, mas honest 0 (the 227 contract — mas serves scorers+cards+tcs only)" || bad "A5: pg=$A5 mas=$A5B"

# A6 the negative season probe (the standing SEASON_PARAM_RE contract)
A6=$(curl -s "$BASE/api/topscorers/laliga?season=2020%2F21" | py "import sys,json;d=json.JSONDecoder().raw_decode(sys.stdin.read())[0];print(1 if (d.get('ok')==False and 'Invalid season' in str(d.get('error'))) else 0)")
[ "$A6" = "1" ] && ok "A6 negative probe: season 2020/21 → {ok:false, Invalid season} (the two-stage shape contract)" || bad "A6: $A6"

echo "== Part B: DOM proof @390x844 =="
agent-browser set viewport 390 844 >/dev/null
agent-browser open "$BASE/topscorers/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B1=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const iX=h2s.indexOf('گل مورد انتظار'), iT=h2s.indexOf('گل مورد انتظار تیم‌ها'), iCS=h2s.indexOf('گل نخرده‌های تیم‌ها'), iPOS=h2s.indexOf('مالکیت توپ تیم‌ها'), iYC=h2s.indexOf('کارت‌های زرد تیم‌ها'), iTRC=h2s.indexOf('کارت‌های قرمز تیم‌ها'), iXG=h2s.indexOf('گل مورد انتظار روی دروازه'), iG=h2s.indexOf('گل در هر ۹۰'); const order=iX>-1&&iT>iX&&iCS>iT&&iPOS>iCS&&iYC>iPOS&&iTRC>iYC&&iXG>iTRC&&iG>iXG; const q=['درصد سیو','سیو در هر ۹۰','گل نخرده‌ها','گل‌های پیشگیری‌شده','پنالتی‌های مهارشده'].map(x=>h2s.indexOf(x)); const quintet=q.every(i=>i>-1)&&q.every((i,k)=>k===0||i>q[k-1]); const n={txg:document.querySelectorAll('[data-testid=txg-row]').length,tcs:document.querySelectorAll('[data-testid=tcs-row]').length,tposs:document.querySelectorAll('[data-testid=tposs-row]').length,tyc:document.querySelectorAll('[data-testid=tyc-row]').length,trc:document.querySelectorAll('[data-testid=trc-row]').length}; const vbroken=[...document.querySelectorAll('*')].filter(e=>e.scrollWidth>document.documentElement.clientWidth+1&&getComputedStyle(e).overflow!=='hidden'&&!e.closest('.fx-backdrop,[class*=overflow-hidden],[class*=overflow-x-auto]')).length; return JSON.stringify({order,quintet,n,vbroken,h2n:h2s.length}); })()")
echo "$B1" | tr -d '\\' | grep -q '"order":true' && echo "$B1" | tr -d '\\' | grep -q '"quintet":true' && echo "$B1" | tr -d '\\' | grep -q '"h2n":22' && echo "$B1" | tr -d '\\' | grep -q '"vbroken":0' && echo "$B1" | tr -d '\\' | grep -q '"txg":10,"tcs":10,"tposs":10,"tyc":10,"trc":10' \
  && ok "B1 DOM laliga: h2n=22 [census refreshed BY DESIGN 21→22 — the 245 red team block] + the family order with the FIVE team blocks adjacent + keeper QUINTET + 10 rows per team testid + zero real overflow @390x844" || bad "B1: $B1"

# B2 the tyc String() integer pill + ROW-LEVEL inner overflow
B2=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=tyc-row]')]; const a=rows[0]&&rows[0].querySelector('a'); const pill=a&&a.lastElementChild; const innerOvf=rows.filter(r=>r.scrollWidth>r.clientWidth+1).length; const latinPill=rows.filter(r=>/[0-9]/.test((r.querySelector('[dir=ltr]')||{}).textContent||'')).length; return JSON.stringify({pill:(pill&&pill.textContent.trim())||'', dir:(pill&&pill.getAttribute('dir'))||null, innerOvf, latinPill}); })()")
echo "$B2" | tr -d '\\' | grep -q '"pill":"۳۳"' && echo "$B2" | tr -d '\\' | grep -q '"dir":"ltr"' && echo "$B2" | tr -d '\\' | grep -q '"innerOvf":0' && echo "$B2" | tr -d '\\' | grep -q '"latinPill":0' \
  && ok "B2 DOM tyc pill: «۳۳» dir=ltr (the String() integer convention — no «۳۳.۰») + zero row-level inner overflow + zero Latin digits" || bad "B2: $B2"

# B3 the tposs toFixed(1) percent pill (no appended sign — the 221 rule)
B3=$(agent-browser eval "(() => { const rows=[...document.querySelectorAll('[data-testid=tposs-row]')]; const a=rows[0]&&rows[0].querySelector('a'); const pill=a&&a.lastElementChild; return JSON.stringify({pill:(pill&&pill.textContent.trim())||'', dir:(pill&&pill.getAttribute('dir'))||null}); })()")
echo "$B3" | tr -d '\\' | grep -q '"pill":"۶۹.۴"' && echo "$B3" | tr -d '\\' | grep -q '"dir":"ltr"' \
  && ok "B3 DOM tposs pill: «۶۹.۴» dir=ltr (toFixed(1), no appended percent sign — the 221 rendering rule)" || bad "B3: $B3"

# B4 real navigation tyc → team page (h1 contract)
agent-browser find first "[data-testid=tyc-row] a" click >/dev/null 2>&1
sleep 3
B4=$(agent-browser eval "(() => JSON.stringify({url:location.pathname, h1:(document.querySelector('h1')||{}).textContent||''}))()")
echo "$B4" | tr -d '\\' | grep -q '/team/8305' && echo "$B4" | tr -d '\\' | grep -q 'ختافه' \
  && ok "B4 real navigation: tyc top-1 → /team/8305 h1 «ختافه» (the /team/{teamId} standings-view contract, live)" || bad "B4: $B4"

# B5 the mas exact-surface DOM + the pg zero-team-h2s DOM
agent-browser open "$BASE/topscorers/mas" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B5a=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); const rows=[...document.querySelectorAll('[data-testid=tcs-row]')]; const first=rows[0]&&rows[0].querySelector('a'); return JSON.stringify({h2s, n:rows.length, first:(first&&first.textContent.includes('جوهور دارالتعظیم'))||false}); })()")
agent-browser open "$BASE/topscorers/persiangulf" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B5b=$(agent-browser eval "(() => { const h2s=[...document.querySelectorAll('main h2')].map(h=>h.textContent); return JSON.stringify({teamH2s:h2s.filter(x=>x.includes('تیم‌ها')).length, gp90:h2s.includes('گل در هر ۹۰'), h2n:h2s.length}); })()")
echo "$B5a" | tr -d '\\' | grep -q '"h2s":\["گل نخرده‌های تیم‌ها","کارت‌های قرمز تیم‌ها","کارت‌ها"\]' && echo "$B5a" | tr -d '\\' | grep -q '"n":8' && echo "$B5a" | tr -d '\\' | grep -q '"first":true' \
  && ok "B5a DOM mas exact surface: h2s == [گل نخرده‌های تیم‌ها، کارت‌های قرمز تیم‌ها، کارت‌ها] [census refreshed BY DESIGN — mas's SECOND team-surface (the 245 red block) sits between] + 8 tcs-rows + rank-1 «جوهور دارالتعظیم» (the floor-exemption block renders live)" || bad "B5a: $B5a"
echo "$B5b" | tr -d '\\' | grep -q '"teamH2s":0' && echo "$B5b" | tr -d '\\' | grep -q '"gp90":true' && echo "$B5b" | tr -d '\\' | grep -q '"h2n":3' \
  && ok "B5b DOM pg zero-team surface: zero team h2s + gp90 serving (h2n=3) — the honest-absence contract in DOM" || bad "B5b: $B5b"

# B6 badge twins on scorer rows (the 235/236 mechanism regression)
agent-browser open "$BASE/topscorers/ucl" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B6=$(agent-browser eval "(() => { const t=document.body.innerText||''; return JSON.stringify({bcm:t.includes('سانس ازدست‌رفته'), cc:t.includes('فرصت‌سازی')}); })()")
echo "$B6" | tr -d '\\' | grep -q '"bcm":true' && echo "$B6" | tr -d '\\' | grep -q '"cc":true' \
  && ok "B6 badge twins: ucl scorer rows carry the «سانس ازدست‌رفته» + «فرصت‌سازی» badges (the 235/236 twin mechanism intact)" || bad "B6: $B6"

# B7 the placement contract + the /matches honest 404 shell
agent-browser open "$BASE/league/laliga" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1.5
B7a=$(agent-browser eval "(() => { const t=document.body.innerText||''; return JSON.stringify({noTeam:!t.includes('کارت‌های زرد تیم‌ها'), tyc:document.querySelectorAll('[data-testid=tyc-row]').length}); })()")
agent-browser open "$BASE/matches" >/dev/null
agent-browser wait --load networkidle >/dev/null; sleep 1
B7b=$(agent-browser eval "(() => { const t=document.body.innerText||''; return JSON.stringify({nf:t.includes('۴۰۴'), ovf:document.documentElement.scrollWidth>document.documentElement.clientWidth}); })()")
echo "$B7a" | tr -d '\\' | grep -q '"noTeam":true' && echo "$B7a" | tr -d '\\' | grep -q '"tyc":0' && echo "$B7b" | tr -d '\\' | grep -q '"nf":true' && echo "$B7b" | tr -d '\\' | grep -q '"ovf":false' \
  && ok "B7 placement + 404: /league/laliga keeps the OLD set (zero tyc-rows, no team h2) — the family rides /topscorers ONLY; /matches renders the clean not-found shell" || bad "B7: $B7a / $B7b"

# B8 console + errors across the session
CN=$(agent-browser console | wc -l); CE=$(agent-browser errors | wc -l)
[ "$CN" = "0" ] && [ "$CE" = "0" ] && ok "B8 console=0 errors=0 across the whole patrol session" || bad "B8: console=$CN errors=$CE"
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
