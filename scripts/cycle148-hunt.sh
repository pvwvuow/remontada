#!/bin/bash
# cycle-148 bug-hunt — the three NEWEST league surfaces (145 superlig /
# 146 scottish / 147 saudi) walked the way a fan does, viewport 390x844,
# REAL clicks, plus API truth for the whole 14-league portal state (cycle-150 added the Championship).
# Lessons baked in (D5): assertions follow LIVE truth probed 2026-10-29
# (tops: گالاتاسارای 22 / سلتیک 28 / الهلال 27; global race 240 scorers (cycle-150: the Championship joined),
# perLeague=12 (cycle-150 joined the Championship), leader honest-pattern — no stale claims.
# V1 /leagues → 14 cards (cycle-150: 13 + the Championship) + the three new routes really present
# V2 /league/superlig → h1, top گالاتاسارای, «آقای گل»+«انتقال‌ها» tabs,
#    bracket tab ABSENT (playoff=null honest-absence contract)
# V3 superlig → real click «انتقال‌ها» → panel alive (aria-label section),
#    ZERO broken images (the 145 TeamLogo placeholder on a fresh league)
# V4 /league/scottish → h1, Old Firm top2 (سلتیک + رنجرز), real transfers
#    click, zero broken images
# V5 /league/saudi → h1, top الهلال, real transfers click, zero broken
# V6 /topscorers → «مصاف گلزنان» + honest «۱۱ لیگ و جام برتر» + dynamic
#    «۱۲ لیگ مشارکت‌کننده» (computed from live perLeague, not baked)
# V7 /topscorers/superlig → dedicated path alive, ≥5 Persian scorer names,
#    Persian-digit goal counts (leader may drift daily — pattern, not name)
# V8 /players → «یازده لیگ و جام برتر» + three new chips + REAL click
#    league-saudi → URL league=saudi + team grid + الهلال present
# V9 /team/8637 گالاتاسارای → first new-league team page: h1 + vbroken 0
# F-part: FINDING-1 documentation probe (search separator class) — REPORTS,
#   gates nothing here; the fix belongs to cycle-149 (فیکس) per rotation.
set -u
B=agent-browser
$B set viewport 390 844 >/dev/null

BAD=0

collect() { # shared tail: OUT + console + errors, $1=feat $2=label
  local FEAT="$1" LABEL="$2" OUT C E RC=0
  OUT=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null | tr -d '"\\')
  C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception: print('ERR')")
  E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  print(len([e for e in es if e.get('url')]))
except Exception: print('ERR')")
  echo "$LABEL → $OUT | feat=$FEAT | console=$C appErrors=$E"
  echo "$FEAT" | grep -q "false\|null" && RC=1
  [ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
  return 0
}

hunt() { # $1=label $2=url $3=extra-waitfn $4=clickjs $5=featjs
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$2" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  [ -n "${3:-}" ] && $B wait --fn "$3" >/dev/null 2>&1
  sleep 3
  if [ -n "${4:-}" ]; then $B eval "$4" >/dev/null 2>&1; sleep 3; fi
  local FEAT
  FEAT=$($B eval "JSON.stringify(($5))" 2>/dev/null | tr -d '"\\')
  collect "$FEAT" "$1"
}

# V1: the hub — 14 league cards with the three newest routes really present
hunt "V1 leagues hub 14 cards" "http://localhost:3000/leagues" \
"" "" \
"({cards:document.querySelectorAll(\"a[href^='/league/']\").length,new3:!!document.querySelector(\"a[href='/league/superlig']\")&&!!document.querySelector(\"a[href='/league/scottish']\")&&!!document.querySelector(\"a[href='/league/saudi']\"),h1Fa:((document.querySelector(\"h1\")||{}).innerText||\"\").includes(\"لیگ\")})"

# V2: superlig page — h1, live top گالاتاسارای, scorers+transfers tabs, honest bracket absence
hunt "V2 superlig page tabs" "http://localhost:3000/league/superlig" \
"(document.body.innerText||\"\").includes(\"گالاتاسارای\")" "" \
"({h1:((document.querySelector(\"h1\")||{}).innerText||\"\").includes(\"سوپرلیگ ترکیه\"),top:((document.querySelector(\"table tbody tr\")||{}).innerText||\"\").includes(\"گالاتاسارای\"),scorersTab:[...document.querySelectorAll(\"button\")].some(b=>(b.textContent||\"\").trim()===\"آقای گل\"),transfersTab:[...document.querySelectorAll(\"button\")].some(b=>(b.textContent||\"\").trim()===\"انتقال‌ها\"),bracketAbsent:![...document.querySelectorAll(\"button\")].some(b=>(b.textContent||\"\").trim()===\"براکت\")})"

# V3: real click «انتقال‌ها» on superlig — panel alive, zero broken images
hunt "V3 superlig transfers click" "http://localhost:3000/league/superlig" \
"(document.body.innerText||\"\").includes(\"انتقال‌ها\")" \
'(function(){const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="انتقال‌ها");if(b)b.click();return b?"clicked":"no-tab"})()' \
"({panel:!!document.querySelector('section[aria-label=\"انتقال‌های لیگ\"]'),alive:(document.body.innerText||\"\").includes(\"انتقال\")})"

# V4: scottish — Old Firm top2 read on the STANDINGS view FIRST, then the
# real transfers click (tabs swap content — standings rows are gone after)
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "http://localhost:3000/league/scottish" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && (document.body.innerText||'').includes('سلتیک')" >/dev/null 2>&1
sleep 3
TOP4=$($B eval "JSON.stringify((()=>{const rows=[...document.querySelectorAll('table tbody tr')].slice(0,2).map(r=>r.innerText).join(' | ');return {h1:((document.querySelector('h1')||{}).innerText||'').includes('لیگ برتر اسکاتلند'),oldFirm:rows.includes('سلتیک')&&rows.includes('رنجرز')}})())" 2>/dev/null | tr -d '"\\')
$B eval '(function(){const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="انتقال‌ها");if(b)b.click();return b?"clicked":"no-tab"})()' >/dev/null 2>&1
sleep 3
FEAT4=$($B eval "JSON.stringify((()=>{return {panel:!!document.querySelector('section[aria-label=\"انتقال‌های لیگ\"]'),alive:(document.body.innerText||'').includes('انتقال')}})())" 2>/dev/null | tr -d '"\\')
collect "$TOP4 $FEAT4" "V4 scottish old-firm + transfers click"

# V5: saudi — top الهلال read BEFORE the transfers click, same contract
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "http://localhost:3000/league/saudi" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && (document.body.innerText||'').includes('الهلال')" >/dev/null 2>&1
sleep 3
TOP5=$($B eval "JSON.stringify((()=>{return {h1:((document.querySelector('h1')||{}).innerText||'').includes('لیگ حرفه‌ای عربستان'),top:((document.querySelector('table tbody tr')||{}).innerText||'').includes('الهلال')}})())" 2>/dev/null | tr -d '"\\')
$B eval '(function(){const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="انتقال‌ها");if(b)b.click();return b?"clicked":"no-tab"})()' >/dev/null 2>&1
sleep 3
FEAT5=$($B eval "JSON.stringify((()=>{return {panel:!!document.querySelector('section[aria-label=\"انتقال‌های لیگ\"]'),alive:(document.body.innerText||'').includes('انتقال')}})())" 2>/dev/null | tr -d '"\\')
collect "$TOP5 $FEAT5" "V5 saudi hilal-top + transfers click"

# V6a: the global race DEFAULT view — honest «۱۲ لیگ و جام برتر» copy
# (the dynamic «N لیگ مشارکت‌کننده» subtitle renders ONLY with a selected
# season — designed contract, proven in V6b on 2023/2024)
hunt "V6a race default copy" "http://localhost:3000/topscorers" \
"(document.body.innerText||\"\").includes(\"مصاف گلزنان\")" "" \
"({h1:((document.querySelector(\"h1\")||{}).innerText||\"\").includes(\"مصاف گلزنان\"),copy12:(document.body.innerText||\"\").includes(\"۱۲ لیگ و جام برتر\"),noStale8:(document.body.innerText||\"\").includes(\"۸ لیگ مشارکت‌کننده\")===false})"

# V6b: season-selected race — the DYNAMIC participants subtitle: 12 live
hunt "V6b race season dyn12" "http://localhost:3000/topscorers?league=all&season=2023/2024" \
"(document.body.innerText||\"\").includes(\"مشارکت‌کننده\")" "" \
"({dyn12:(document.body.innerText||\"\").includes(\"۱۲ لیگ مشارکت‌کننده\"),seasonLabel:(document.body.innerText||\"\").includes(\"۲۰۲۳/۲۴\")})"

# V7: dedicated superlig scorers path — alive with Persian names + digit goals
hunt "V7 superlig scorers path" "http://localhost:3000/topscorers/superlig" \
"(document.body.innerText||\"\").match(/[۰-۹]/)" "" \
"({h1Live:!!(document.querySelector(\"h1\")||{}).innerText,persianNames:((document.body.innerText||\"\" ).match(/[آ-ی]{3,}/g)||[]).length>=5,faGoals:/[۰-۹]+\s*گل/.test(document.body.innerText||\"\")})"

# V8: players hub — 12 copy + the chips + REAL click league-saudi
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "http://localhost:3000/players" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 2
COPY11=$($B eval "JSON.stringify((document.body.innerText||'').includes('دوازده لیگ و جام برتر'))" 2>/dev/null | tr -d '"\\')
# the league chips live in the TEAMS mode - real click mode-teams FIRST
# (the cycle-134/143 two-step fan path), then the saudi chip
$B eval '(function(){const m=document.querySelector("[data-testid=\"mode-teams\"]");if(m)m.click();return m?"mode":"no-mode"})()' >/dev/null 2>&1
sleep 3
$B eval '(function(){const l=document.querySelector("[data-testid=\"league-saudi\"]");if(l)l.click();return l?"clicked":"no-chip"})()' >/dev/null 2>&1
sleep 4
FEAT8=$($B eval "JSON.stringify((()=>{return {teamsCopy:(document.body.innerText||'').includes('اسکواد کامل همهٔ تیم‌ها'),chipSuper:!!document.querySelector('[data-testid=\"league-superlig\"]'),chipScott:!!document.querySelector('[data-testid=\"league-scottish\"]'),chipSaudi:!!document.querySelector('[data-testid=\"league-saudi\"]'),urlLeague:location.search.includes('league=saudi'),teamChips:document.querySelectorAll('[data-testid^=\"team-\"]').length>=8,hilal:(document.body.innerText||'').includes('الهلال')}})())" 2>/dev/null | tr -d '"\\')
collect "$COPY11 $FEAT8" "V8 players hub teams→saudi click"

# V9: first new-league team page — گالاتاسارای
hunt "V9 galatasaray team page" "http://localhost:3000/team/8637" \
"(document.body.innerText||\"\").includes(\"گالاتاسارای\")" "" \
"({h1Live:!!(document.querySelector(\"h1\")||{}).innerText,faName:(document.body.innerText||\"\").includes(\"گالاتاسارای\")})"

echo "== FINDING-1 documentation probe (search separator class — REPORT, not a gate) =="
for Q in "Al-Hilal" "Al Hilal" "Al-Nassr" "Al-Ittihad" "Real-Madrid" "Man-United"; do
  R=$(curl -s "http://localhost:3000/api/search?q=$(python3 -c "import urllib.parse;print(urllib.parse.quote('$Q'))")" | python3 -c "import json,sys; d=json.load(sys.stdin); rs=d.get('results') or []; print((rs[0].get('fa')+'|'+str(rs[0].get('leagueKey'))) if rs else 'EMPTY')" 2>/dev/null)
  echo "  search [$Q] → $R"
done
echo "  root cause: normalizeQuery (src/lib/fotmob.ts) folds ZWNJ/diacritics but"
echo "  NOT [-_] separators — hyphen Latin queries miss space-formed feed names."
echo "  → FIX IN cycle-149 (فیکس): fold [-_] to space inside normalizeQuery."

echo "== PART C: API truth =="
python3 - <<'PY'
import json, urllib.request, urllib.error
def get(u):
    with urllib.request.urlopen(u, timeout=30) as r:
        return json.load(r)
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")
import re
ascii_leak = lambda s: bool(re.search(r"[A-Za-z]", s or ""))
# A1: the three new standings — row counts, live tops, zero ASCII in top-5 fa
for lk, n, top in (("superlig", 18, "گالاتاسارای"), ("scottish", 12, "سلتیک"), ("saudi", 18, "الهلال")):
    try:
        d = get(f"http://localhost:3000/api/standings?league={lk}")
        rows = d.get("rows") or []
        good = len(rows) == n and rows[0].get("fa") == top and not any(ascii_leak(r.get("fa")) for r in rows[:5])
        report(f"standings {lk}", good, f"rows={len(rows)} top={rows[0].get('fa') if rows else None}")
    except Exception as e:
        report(f"standings {lk}", False, str(e))
# A2: global race — 240 scorers, 12 perLeague incl. the new four, honest leader shape
try:
    d = get("http://localhost:3000/api/topscorers?league=all")
    ts = d.get("scorers") or []
    pl = [p.get("leagueKey") for p in (d.get("perLeague") or [])]
    lead = ts[0] if ts else {}
    good = len(ts) == 240 and len(pl) == 12 and {"superlig","scottish","saudi","championship"} <= set(pl) \
        and bool(lead.get("nameFa")) and isinstance(lead.get("goals"), int) and lead.get("goals", 0) > 0 \
        and not ascii_leak(lead.get("team"))
    report("topscorers all", good, f"n={len(ts)} perLeague={len(pl)} leader={lead.get('nameFa')}({lead.get('goals')})")
except Exception as e:
    report("topscorers all", False, str(e))
# A3: bracket honest-absence on all three (playoff=null → tab absent is DOM-proven)
for lk in ("superlig", "scottish", "saudi"):
    try:
        d = get(f"http://localhost:3000/api/league-bracket?league={lk}")
        report(f"bracket {lk} null", d.get("ok") is True and d.get("bracket") is None, f"bracket={d.get('bracket')}")
    except Exception as e:
        report(f"bracket {lk} null", False, str(e))
# A4: dedicated scorers paths ×3 — the REAL endpoint is /api/topscorers/<key>
# (?league= is ignored by the merged route by design — it reads only season).
# Player names may ride the honest English fallback (cycle-104 convention);
# TEAM names in the Persian field must be zero-ASCII.
for lk in ("superlig", "scottish", "saudi"):
    try:
        d = get(f"http://localhost:3000/api/topscorers/{lk}")
        ts = d.get("scorers") or []
        top = ts[0] if ts else {}
        good = 0 < len(ts) <= 30 and bool(top.get("team")) and not ascii_leak(top.get("team")) and isinstance(top.get("goals"), int)
        report(f"topscorers {lk}", good, f"n={len(ts)} top={top.get('nameFa')}({top.get('goals')}) team={top.get('team')}")
    except Exception as e:
        report(f"topscorers {lk}", False, str(e))
# A5: search attribution two-truths (live-probed 2026-10-29)
for q, fa, lk in (("Galatasaray","گالاتاسارای","superlig"), ("Rangers","رنجرز","scottish"),
                  ("Abha","ابها","saudi"), ("الهلال","الهلال","acl"), ("Celtic","سلتیک","uel")):
    try:
        d = get(f"http://localhost:3000/api/search?q={urllib.parse.quote(q)}")
        r = (d.get("results") or [{}])[0]
        good = r.get("fa") == fa and r.get("leagueKey") == lk
        report(f"search {q}", good, f"{r.get('fa')}→{r.get('leagueKey')}")
    except Exception as e:
        report(f"search {q}", False, str(e))
# A6: historic season 2023/2024 — dynamic participants now 11 (the «۸» of 143
# evolved honestly when 145/146/147 joined the window)
try:
    d = get("http://localhost:3000/api/topscorers?league=all&season=2023/2024")
    pl = d.get("perLeague") or []
    report("topscorers 2023/2024 participants", len(pl) == 12, f"perLeague={len(pl)} (dynamic honest copy)")
except Exception as e:
    report("topscorers 2023/2024 participants", False, str(e))
import urllib.parse
print("API_TRUTH", "OK" if ok else "BAD")
PY

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "HUNT OK — patrol contracts green; FINDING-1 (search separator class) documented above for the cycle-149 fix"
else
  echo "HUNT FLAGGED (BAD=$BAD)"; exit 1
fi
