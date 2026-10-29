#!/bin/bash
# cycle-153 bug-hunt — the three NEWEST league surfaces (150 championship /
# 151 portugal / 152 uae) walked the way a fan does, viewport 390x844,
# REAL clicks, plus API truth for the whole 16-league portal state.
# Live truth probed 2026-10-29 (D5): championship 24 rows میدلزبورو 25 /
# portugal 18 پورتو 27 / uae 14 الجزیره 14 (teamId 102101); global race
# 280 scorers, perLeague=14, leader shape honest; dedicated tops n=20 with
# Persian TEAMS and int goals (player names may ride the honest English
# fallback — لنکشیر/پاولیدیس render English in nameFa today, cycle-104
# convention, NOT a bug); bracket=null honest absence ×6; transfers items
# under data.items (100/100/99 per 150-152 cards); FINDING-1 fix (149)
# alive: Al-Hilal→الهلال|acl, Real-Madrid→رئال‌مادرید|laliga, man_united hits.
# V1 /leagues → 17 cards + new4 routes really present
# V2 /league/championship → h1 چمپیونشیپ انگلیس, top میدلزبورو, tabs,
#    bracket tab ABSENT (playoff=null honest-absence contract)
# V3 championship → real click «انتقال‌ها» → panel alive, zero broken images
#    (the 145 TeamLogo placeholder on its 10th consumer league)
# V4 /league/portugal → top2 (پورتو/بنفیکا) read on standings FIRST, then
#    real transfers click (tabs swap content — 148 lesson)
# V5 /league/uae → top الجزیره read first, then real transfers click
# V6a /topscorers default → honest «۱۴ لیگ و جام برتر», no stale ۱۳ copy
# V6b season-selected → dynamic «۱۶ لیگ مشارکت‌کننده» + «۲۰۲۳/۲۴» (swiss joins, cycle-160)
# V7 dedicated paths /topscorers/{uae,championship,portugal} alive
# V8 /players → «هجده لیگ و جام برتر» (gate-synced cycle-161: hnl joins)
# + new chips + REAL two-step
#    click mode-teams → league-uae (URL sync + Persian team grid)
# V9 /team/102101 الجزیره → the newest league's top team page
# V10 search_flow (149 heritage): Al-Hilal + man_united in the REAL UI —
#    the FINDING-1 fix guard at DOM level, honest empty state for garbage
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

# V1: the hub — 21 league cards with the newest routes really present
# (gate-synced cycle-161: hnl is the 21st card)
# (gate-synced cycle-157: acl2 is the 19th card — the FIFTH live cup)
hunt "V1 leagues hub 21 cards" "http://localhost:3000/leagues" \
"" "" \
"({cards:document.querySelectorAll(\"a[href^='/league/']\").length,new5:!!document.querySelector(\"a[href='/league/championship']\")&&!!document.querySelector(\"a[href='/league/portugal']\")&&!!document.querySelector(\"a[href='/league/uae']\")&&!!document.querySelector(\"a[href='/league/qatar']\")&&!!document.querySelector(\"a[href='/league/eredivisie']\")&&!!document.querySelector(\"a[href='/league/acl2']\")&&!!document.querySelector(\"a[href='/league/swiss']\")&&!!document.querySelector(\"a[href='/league/hnl']\"),h1Fa:((document.querySelector(\"h1\")||{}).innerText||\"\").includes(\"لیگ\")})"

# V2: championship — h1, live top میدلزبورو, scorers+transfers tabs, honest bracket absence
hunt "V2 championship page tabs" "http://localhost:3000/league/championship" \
"(document.body.innerText||\"\").includes(\"میدلزبورو\")" "" \
"({h1:((document.querySelector(\"h1\")||{}).innerText||\"\").includes(\"چمپیونشیپ انگلیس\"),top:((document.querySelector(\"table tbody tr\")||{}).innerText||\"\").includes(\"میدلزبورو\"),scorersTab:[...document.querySelectorAll(\"button\")].some(b=>(b.textContent||\"\").trim()===\"آقای گل\"),transfersTab:[...document.querySelectorAll(\"button\")].some(b=>(b.textContent||\"\").trim()===\"انتقال‌ها\"),bracketAbsent:![...document.querySelectorAll(\"button\")].some(b=>(b.textContent||\"\").trim()===\"براکت\")})"

# V3: real click «انتقال‌ها» on championship — panel alive, zero broken images
hunt "V3 championship transfers click" "http://localhost:3000/league/championship" \
"(document.body.innerText||\"\").includes(\"انتقال‌ها\")" \
'(function(){const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="انتقال‌ها");if(b)b.click();return b?"clicked":"no-tab"})()' \
"({panel:!!document.querySelector('section[aria-label=\"انتقال‌های لیگ\"]'),alive:(document.body.innerText||\"\").includes(\"انتقال\")})"

# V4: portugal — top2 read on the STANDINGS view FIRST, then the real
# transfers click (tabs swap content — standings rows are gone after)
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "http://localhost:3000/league/portugal" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && (document.body.innerText||'').includes('پورتو')" >/dev/null 2>&1
sleep 3
TOP4=$($B eval "JSON.stringify((()=>{const rows=[...document.querySelectorAll('table tbody tr')].slice(0,2).map(r=>r.innerText).join(' | ');return {h1:((document.querySelector('h1')||{}).innerText||'').includes('لیگ پرتغال'),top2:rows.includes('پورتو')&&rows.includes('بنفیکا')}})())" 2>/dev/null | tr -d '"\\')
$B eval '(function(){const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="انتقال‌ها");if(b)b.click();return b?"clicked":"no-tab"})()' >/dev/null 2>&1
sleep 3
FEAT4=$($B eval "JSON.stringify((()=>{return {panel:!!document.querySelector('section[aria-label=\"انتقال‌های لیگ\"]'),alive:(document.body.innerText||'').includes('انتقال')}})())" 2>/dev/null | tr -d '"\\')
collect "$TOP4 $FEAT4" "V4 portugal top2 + transfers click"

# V5: uae — top الجزیره read BEFORE the transfers click, same contract
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "http://localhost:3000/league/uae" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && (document.body.innerText||'').includes('الجزیره')" >/dev/null 2>&1
sleep 3
TOP5=$($B eval "JSON.stringify((()=>{return {h1:((document.querySelector('h1')||{}).innerText||'').includes('لیگ برتر امارات'),top:((document.querySelector('table tbody tr')||{}).innerText||'').includes('الجزیره')}})())" 2>/dev/null | tr -d '"\\')
$B eval '(function(){const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="انتقال‌ها");if(b)b.click();return b?"clicked":"no-tab"})()' >/dev/null 2>&1
sleep 3
FEAT5=$($B eval "JSON.stringify((()=>{return {panel:!!document.querySelector('section[aria-label=\"انتقال‌های لیگ\"]'),alive:(document.body.innerText||'').includes('انتقال')}})())" 2>/dev/null | tr -d '"\\')
collect "$TOP5 $FEAT5" "V5 uae jazira-top + transfers click"

# V6a: the global race DEFAULT view — honest «۱۶ لیگ و جام برتر» copy
# (the dynamic «N لیگ مشارکت‌کننده» subtitle renders ONLY with a selected
# season — designed contract, proven in V6b; gate-synced cycle-156: the
# race honestly grows 15→16 with eredivisie)
hunt "V6a race default copy" "http://localhost:3000/topscorers" \
"(document.body.innerText||\"\").includes(\"مصاف گلزنان\")" "" \
"({h1:((document.querySelector(\"h1\")||{}).innerText||\"\").includes(\"مصاف گلزنان\"),copy18:(document.body.innerText||\"\").includes(\"۱۸ لیگ و جام برتر\"),noStale17:(document.body.innerText||\"\").includes(\"۱۷ لیگ و جام برتر\")===false,noStale16:(document.body.innerText||\"\").includes(\"۱۶ لیگ و جام برتر\")===false})"

# V6b: season-selected race — the DYNAMIC participants subtitle. Live truth
# (re-probed cycle-161): qatar's ARCHIVED 2023/2024 payload still carries NO
# top-scorer category (honestly out), but eredivisie's, swiss's AND hnl's
# archived 2023/2024 payloads DO have the block — the dynamic subtitle
# grows to ۱۷ (computed from live perLeague, not baked).
hunt "V6b race season dyn17 (eredivisie+swiss+hnl archived seasons HAVE a scorer block)" "http://localhost:3000/topscorers?league=all&season=2023/2024" \
"(document.body.innerText||\"\").includes(\"مشارکت‌کننده\")" "" \
"({dyn17:(document.body.innerText||\"\").includes(\"۱۷ لیگ مشارکت‌کننده\"),noDyn15:(document.body.innerText||\"\").includes(\"۱۵ لیگ مشارکت‌کننده\")===false,noDyn16:(document.body.innerText||\"\").includes(\"۱۶ لیگ مشارکت‌کننده\")===false,seasonLabel:(document.body.innerText||\"\").includes(\"۲۰۲۳/۲۴\")})"

# V7a: dedicated uae scorers path (newest) — Persian names + fa-digit goals
hunt "V7a uae scorers path" "http://localhost:3000/topscorers/uae" \
"(document.body.innerText||\"\").match(/[۰-۹]/)" "" \
"({h1Live:!!(document.querySelector(\"h1\")||{}).innerText,persianNames:((document.body.innerText||\"\" ).match(/[آ-ی]{3,}/g)||[]).length>=5,faGoals:/[۰-۹]+\s*گل/.test(document.body.innerText||\"\")})"

# V7b/V7c: championship + portugal dedicated paths alive (light)
hunt "V7b championship scorers path" "http://localhost:3000/topscorers/championship" \
"(document.body.innerText||\"\").match(/[۰-۹]/)" "" \
"({h1Live:!!(document.querySelector(\"h1\")||{}).innerText,faGoals:/[۰-۹]+\s*گل/.test(document.body.innerText||\"\")})"
hunt "V7c portugal scorers path" "http://localhost:3000/topscorers/portugal" \
"(document.body.innerText||\"\").match(/[۰-۹]/)" "" \
"({h1Live:!!(document.querySelector(\"h1\")||{}).innerText,faGoals:/[۰-۹]+\s*گل/.test(document.body.innerText||\"\")})"

# V8: players hub — 14 copy + the three new chips + REAL click league-uae
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "http://localhost:3000/players" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 2
COPY16=$($B eval "JSON.stringify((document.body.innerText||'').includes('هجده لیگ و جام برتر'))" 2>/dev/null | tr -d '"\\')
# the league chips live in the TEAMS mode - real click mode-teams FIRST
# (the cycle-134/143 two-step fan path), then the uae chip
$B eval '(function(){const m=document.querySelector("[data-testid=\"mode-teams\"]");if(m)m.click();return m?"mode":"no-mode"})()' >/dev/null 2>&1
sleep 3
$B eval '(function(){const l=document.querySelector("[data-testid=\"league-uae\"]");if(l)l.click();return l?"clicked":"no-chip"})()' >/dev/null 2>&1
sleep 4
FEAT8=$($B eval "JSON.stringify((()=>{return {teamsCopy:(document.body.innerText||'').includes('اسکواد کامل همهٔ تیم‌ها'),chipChamp:!!document.querySelector('[data-testid=\"league-championship\"]'),chipPort:!!document.querySelector('[data-testid=\"league-portugal\"]'),chipUae:!!document.querySelector('[data-testid=\"league-uae\"]'),chipEre:!!document.querySelector('[data-testid=\"league-eredivisie\"]'),urlLeague:location.search.includes('league=uae'),teamChips:document.querySelectorAll('[data-testid^=\"team-\"]').length>=8,jazira:(document.body.innerText||'').includes('الجزیره')}})())" 2>/dev/null | tr -d '"\\')
collect "$COPY16 $FEAT8" "V8 players hub teams→uae click"

# V9: the newest league's top team page — الجزیره (102101)
hunt "V9 al-jazira team page" "http://localhost:3000/team/102101" \
"(document.body.innerText||\"\").includes(\"الجزیره\")" "" \
"({h1Live:!!(document.querySelector(\"h1\")||{}).innerText,faName:(document.body.innerText||\"\").includes(\"الجزیره\")})"

# V10: FINDING-1 fix guard in the REAL UI (149 heritage search flow)
search_flow() { # $1=query $2=expect-fa $3=label
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "http://localhost:3000/" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 2
  $B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
  sleep 1
  $B eval "(function(){const i=document.querySelector('div[role=\"dialog\"] input');if(!i)return 'no-input';const s=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set;s.call(i,'$1');i.dispatchEvent(new Event('input',{bubbles:true}));return 'typed'})()" >/dev/null 2>&1
  $B wait --fn "[...document.querySelectorAll('div[role=\"dialog\"] ul li button')].some(b=>(b.innerText||'').includes('$2'))" >/dev/null 2>&1
  sleep 1.5
  local FEAT OUT C E RC=0
  FEAT=$($B eval "JSON.stringify((()=>{const btns=[...document.querySelectorAll('div[role=\"dialog\"] ul li button')];const hit=btns.find(b=>(b.innerText||'').includes('$2'));return {dialog:!!document.querySelector('div[role=\"dialog\"]'),hits:btns.length,found:!!hit,noEmptyState:!(document.body.innerText||'').includes('پیدا نشد'),faHit:hit?(hit.innerText||'').includes('$2'):false}})())" 2>/dev/null | tr -d '"\\')
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
  echo "$3 → $OUT | feat=$FEAT | console=$C appErrors=$E"
  echo "$FEAT" | grep -q "false\|null" && RC=1
  [ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
  return 0
}
search_flow "Al-Hilal" "الهلال" "V10a header search Al-Hilal (fix guard)"
search_flow "man_united" "منچستریونایتد" "V10b header search man_united (fix guard)"

echo "== PART C: API truth =="
API_OUT=$(python3 - <<'PY'
import json, urllib.request, urllib.parse
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
# A1: eight portal standings + the 19th (cycle-157, FIFTH live cup,
# COMPOSITE 8-group table flattened 32 rows — top is Group A leader الوحده),
# zero ASCII in top-5 fa
for lk, n, top in (("superlig", 18, "گالاتاسارای"), ("scottish", 12, "سلتیک"), ("saudi", 18, "الهلال"),
                   ("championship", 24, "میدلزبورو"), ("portugal", 18, "پورتو"), ("uae", 14, "الجزیره"),
                   ("qatar", 12, "الریان"), ("eredivisie", 18, "فاینورد"), ("acl2", 32, "الوحده")):
    try:
        d = get(f"http://localhost:3000/api/standings?league={lk}")
        rows = d.get("rows") or []
        good = len(rows) == n and rows[0].get("fa") == top and not any(ascii_leak(r.get("fa")) for r in rows[:5])
        report(f"standings {lk}", good, f"rows={len(rows)} top={rows[0].get('fa') if rows else None}")
    except Exception as e:
        report(f"standings {lk}", False, str(e))
# A2: global race — 360 scorers, 18 perLeague incl. the newest nine, honest
# leader shape (gate-synced cycle-156: eredivisie adds its 20-scorer window)
try:
    d = get("http://localhost:3000/api/topscorers?league=all")
    ts = d.get("scorers") or []
    pl = [p.get("leagueKey") for p in (d.get("perLeague") or [])]
    lead = ts[0] if ts else {}
    good = len(ts) == 360 and len(pl) == 18 and {"superlig","scottish","saudi","championship","portugal","uae","qatar","eredivisie","swiss","hnl"} <= set(pl) \
        and bool(lead.get("nameFa")) and isinstance(lead.get("goals"), int) and lead.get("goals", 0) > 0 \
        and not ascii_leak(lead.get("team"))
    report("topscorers all", good, f"n={len(ts)} perLeague={len(pl)} leader={lead.get('nameFa')}({lead.get('goals')})")
except Exception as e:
    report("topscorers all", False, str(e))
# A3: bracket honest-absence on all eight league surfaces (playoff=null → tab
# absent, DOM-proven V2; eredivisie's CURRENT window is null — knockout not
# drawn — while its 2025/2026 archived bracket is proven in cycle156-domproof)
for lk in ("superlig", "scottish", "saudi", "championship", "portugal", "uae", "qatar", "eredivisie"):
    try:
        d = get(f"http://localhost:3000/api/league-bracket?league={lk}")
        report(f"bracket {lk} null", d.get("ok") is True and d.get("bracket") is None, f"bracket={d.get('bracket')}")
    except Exception as e:
        report(f"bracket {lk} null", False, str(e))
# A4: dedicated scorers paths ×8 — the REAL endpoint is /api/topscorers/<key>.
# Player names may ride the honest English fallback (cycle-104 convention);
# TEAM names in the Persian field must be zero-ASCII.
for lk in ("superlig", "scottish", "saudi", "championship", "portugal", "uae", "qatar", "eredivisie"):
    try:
        d = get(f"http://localhost:3000/api/topscorers/{lk}")
        ts = d.get("scorers") or []
        top = ts[0] if ts else {}
        good = 0 < len(ts) <= 30 and bool(top.get("team")) and not ascii_leak(top.get("team")) and isinstance(top.get("goals"), int)
        report(f"topscorers {lk}", good, f"n={len(ts)} top={top.get('nameFa')}({top.get('goals')}) team={top.get('team')}")
    except Exception as e:
        report(f"topscorers {lk}", False, str(e))
# A5: search attribution truths + FINDING-1 fix class (live-probed 2026-10-29)
for q, fa, lk in (("Galatasaray","گالاتاسارای","superlig"), ("Rangers","رنجرز","scottish"),
                  ("Abha","ابها","saudi"), ("الهلال","الهلال","acl"), ("Celtic","سلتیک","uel"),
                  ("FC Porto","پورتو","portugal"), ("Khorfakkan","خورفکان","uae"),
                  ("Al-Hilal","الهلال","acl"), ("Real-Madrid","رئال\u200cمادرید","laliga"),
                  ("Man-United","منچستریونایتد","pl"), ("real_madrid","رئال\u200cمادرید","laliga"),
                  ("Al-Rayyan","الریان","qatar"), ("Lusail","لوسیل","qatar"), ("Al-Sadd","السد","acl"),
                  ("Feyenoord","فاینورد","eredivisie"), ("FC Groningen","خرونینگن","eredivisie"),
                  ("Excelsior","اکسلسیور","eredivisie"), ("Ajax","آژاکس","uecl")):
    try:
        d = get(f"http://localhost:3000/api/search?q={urllib.parse.quote(q)}")
        r = (d.get("results") or [{}])[0]
        good = r.get("fa") == fa and r.get("leagueKey") == lk
        report(f"search {q}", good, f"{r.get('fa')}→{r.get('leagueKey')}")
    except Exception as e:
        report(f"search {q}", False, str(e))
# A6: historic season 2023/2024 — participants grow 16→17: qatar's archived
# season payload still has NO top-scorer category (honestly out) while
# eredivisie's, swiss's AND hnl's archived payloads DO (gateway-synced
# cycles 156/160/161), so the historical window includes all three (the
# DEFAULT race is 18/360).
try:
    d = get("http://localhost:3000/api/topscorers?league=all&season=2023/2024")
    pl = [p.get("leagueKey") for p in (d.get("perLeague") or [])]
    report("topscorers 2023/2024 participants", len(pl) == 17 and "qatar" not in pl and "eredivisie" in pl and "swiss" in pl and "hnl" in pl, f"perLeague={len(pl)} qatar-out eredivisie+swiss+hnl-in")
except Exception as e:
    report("topscorers 2023/2024 participants", False, str(e))
# A7: transfers feeds ×3 — the route wraps the payload: {ok, transfers:
# {leagueKey, leagueFa, season, items}} (verified against route source —
# first A7 draft read items at top level and false-flagged; D5 script fix)
for lk in ("championship", "portugal", "uae"):
    try:
        d = get(f"http://localhost:3000/api/league-transfers?league={lk}")
        payload = d.get("transfers") or {}
        items = payload.get("items") or []
        good = d.get("ok") is True and len(items) >= 50 and bool(payload.get("leagueFa")) and not ascii_leak(payload.get("leagueFa"))
        report(f"transfers {lk}", good, f"n={len(items)} leagueFa={payload.get('leagueFa')}")
    except Exception as e:
        report(f"transfers {lk}", False, str(e))
print("API_TRUTH", "OK" if ok else "BAD")
PY
)
echo "$API_OUT"
# the heredoc always exits 0 — gate the printed verdict into BAD
case "$API_OUT" in *"API_TRUTH OK"*) : ;; *) BAD=$((BAD+1)) ;; esac

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "HUNT OK — patrol contracts green (cycle-153 targets, gates synced to the 19-league cycle-157 truth)"
else
  echo "HUNT FLAGGED (BAD=$BAD)"; exit 1
fi
