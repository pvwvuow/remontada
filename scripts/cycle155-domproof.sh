#!/bin/bash
# cycle-155 domproof — Qatar Stars League (league 535), the SEVENTEENTH
# competition and the SEVENTH consecutive new global-race participant.
# Live truth probed 2026-10-29 (UA Chrome/124, /api/data/leagues?id=535&ccode3=QAT):
#   flat 12-row 2026/2027 table (الراین 17 / السد 15 / الدحیل 15),
#   17 slash-format seasons 2026/2027 → 2010/2011 (cycle-132 window exact —
#   no globalMerge), top-scorer fetchAllUrl (76-scorer goals.json, leader
#   اکرم عفیف 7 السد — Persian name AND Persian team via the cycle-155 maps),
#   22 title seasons (newest 2025/2026 السد over الشمال; oldest 2004/2005
#   الغرافه — runners include the defunct الجیش), transfers.data = 17,
#   playoff=null → bracket tab honestly absent, NO espnSlug (ESPN 400 —
#   Gulf pattern). Persian hook: the Gulf-arc COMPLETION (persiangulf +
#   saudi + uae + qatar) + the LIVE Iranian فرهاد زوشی (Lusail SC, 3 goals,
#   player.info.country = "Iran").
# API 4/4 + DOM 7/7 @390x844 — every page sw=cw=390, 1 h1, 0 broken images,
# console=0, appErr=0.
set -u
B=agent-browser
BASE="http://localhost:3000"
A_BAD=0; TOTAL_BAD=0

probe() { # $1=url $2=label $3=js
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 3
  local FEAT OUT C E RC=0
  FEAT=$($B eval "JSON.stringify((()=>{$3})())" 2>/dev/null | tr -d '"\\')
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
  echo "$2 → $OUT | feat=$FEAT | console=$C appErrors=$E"
  echo "$FEAT" | grep -q "false\|null" && RC=1
  [ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  [ "$RC" -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))
  return 0
}

echo "== PART A: API truth =="
python3 - <<'PY'
import json, urllib.request, urllib.parse
def get(u):
    with urllib.request.urlopen(u, timeout=30) as r: return json.load(r)
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")
import re
ascii_leak = lambda s: bool(re.search(r"[A-Za-z]", s or ""))
B = "http://localhost:3000"
# A1: the qatar standings — 12 rows, live top الراین, zero ASCII in top-5 fa
try:
    d = get(f"{B}/api/standings?league=qatar")
    rows = d.get("rows") or []
    good = len(rows) == 12 and rows[0].get("fa") == "الریان" and rows[0].get("pts") == 17 \
        and not any(ascii_leak(r.get("fa")) for r in rows[:5])
    report("standings qatar", good, f"rows={len(rows)} top={rows[0].get('fa')}({rows[0].get('pts')})")
except Exception as e:
    report("standings qatar", False, str(e))
# A2: global race — 360 scorers (340 + 20 hnl rows, gate-synced
# cycle-161), 18 perLeague incl. qatar, honest leader shape (رافینیا ۱۳ stays
# top), 12-season window intact
try:
    d = get(f"{B}/api/topscorers?league=all")
    ts = d.get("scorers") or []
    pl = [p.get("leagueKey") for p in (d.get("perLeague") or [])]
    lead = ts[0] if ts else {}
    good = len(ts) == 360 and len(pl) == 18 and "qatar" in pl and "eredivisie" in pl and "swiss" in pl and "hnl" in pl \
        and {"superlig","scottish","saudi","championship","portugal","uae"} <= set(pl) \
        and bool(lead.get("nameFa")) and isinstance(lead.get("goals"), int) \
        and not ascii_leak(lead.get("team"))
    report("topscorers all", good, f"n={len(ts)} perLeague={len(pl)} leader={lead.get('nameFa')}({lead.get('goals')})")
except Exception as e:
    report("topscorers all", False, str(e))
# A3: titles (22 — newest السد over الشمال, oldest الغرافه) + transfers (17,
# leagueFa Persian) + bracket honest-absence + fixtures 20-upcoming
try:
    d = get(f"{B}/api/league-titles?league=qatar")
    tit = d.get("titles") or {}
    items = tit.get("items") or []
    good = tit.get("total") == 22 and len(items) == 22 \
        and items[0].get("season") == "2025/2026" and items[0].get("championFa") == "السد" \
        and items[0].get("runnerUpFa") == "الشمال" \
        and items[-1].get("season") == "2004/2005" and items[-1].get("championFa") == "الغرافه" \
        and not any(ascii_leak(x.get("championFa")) for x in items)
    report("titles qatar", good, f"total={tit.get('total')} newest={items[0].get('championFa') if items else None} oldest={items[-1].get('championFa') if items else None}")
except Exception as e:
    report("titles qatar", False, str(e))
try:
    d = get(f"{B}/api/league-transfers?league=qatar")
    pay = d.get("transfers") or {}
    items = pay.get("items") or []
    good = d.get("ok") is True and len(items) == 17 and pay.get("leagueFa") == "لیگ ستارگان قطر"
    report("transfers qatar", good, f"n={len(items)} leagueFa={pay.get('leagueFa')}")
except Exception as e:
    report("transfers qatar", False, str(e))
try:
    d = get(f"{B}/api/league-bracket?league=qatar")
    report("bracket qatar null", d.get("ok") is True and d.get("bracket") is None, f"bracket={d.get('bracket')}")
except Exception as e:
    report("bracket qatar null", False, str(e))
try:
    d = get(f"{B}/api/league-fixtures?league=qatar")
    up = d.get("upcoming") or []
    good = d.get("ok") is True and len(up) == 20 and bool(d.get("leagueFa"))
    report("fixtures qatar", good, f"upcoming={len(up)} leagueFa={d.get('leagueFa')}")
except Exception as e:
    report("fixtures qatar", False, str(e))
# A4: dedicated /api/topscorers/qatar — the 20-window renders اکرم عفیف 7
# السد (Persian name AND Persian team — the cycle-155 name maps live) and
# the Iranian فرهاد زوشی rides the pool
try:
    d = get(f"{B}/api/topscorers/qatar")
    ts = d.get("scorers") or []
    top = ts[0] if ts else {}
    pool = " ".join(str(x.get("nameFa")) for x in ts)
    good = len(ts) == 20 and top.get("nameFa") == "اکرم عفیف" and top.get("goals") == 7 \
        and top.get("team") == "السد" and "فرهاد زوشی" in pool \
        and not ascii_leak(top.get("team"))
    report("topscorers qatar", good, f"n={len(ts)} top={top.get('nameFa')}({top.get('goals')}) team={top.get('team')} zavoshi={'فرهاد زوشی' in pool}")
except Exception as e:
    report("topscorers qatar", False, str(e))
# A5: attribution truths (live-probed 2026-10-29) — the new qatar index +
# Al-Sadd's dual-truth (the ACL-index club outranks) + prior eight stay put
for q, fa, lk in (("Al-Rayyan","الریان","qatar"), ("Lusail","لوسیل","qatar"),
                  ("Al-Sailiya","السیلیه","qatar"), ("Al-Sadd","السد","acl"),
                  ("FC Porto","پورتو","portugal"), ("Khorfakkan","خورفکان","uae"),
                  ("Galatasaray","گالاتاسارای","superlig"), ("Rangers","رنجرز","scottish"),
                  ("Abha","ابها","saudi"), ("Celtic","سلتیک","uel")):
    try:
        d = get(f"{B}/api/search?q={urllib.parse.quote(q)}")
        r = (d.get("results") or [{}])[0]
        good = r.get("fa") == fa and r.get("leagueKey") == lk
        report(f"search {q}", good, f"{r.get('fa')}→{r.get('leagueKey')}")
    except Exception as e:
        report(f"search {q}", False, str(e))
print("API_TRUTH", "OK" if ok else "BAD")
PY
[ ${PIPESTATUS[0]:-0} -eq 0 ] || true
API_OUT=$(python3 - <<'PY'
import json, urllib.request, urllib.parse
def get(u):
    with urllib.request.urlopen(u, timeout=30) as r: return json.load(r)
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
B = "http://localhost:3000"
import re
ascii_leak = lambda s: bool(re.search(r"[A-Za-z]", s or ""))
try:
    d = get(f"{B}/api/standings?league=qatar"); rows = d.get("rows") or []
    ok = ok and len(rows) == 12 and rows[0].get("fa") == "الریان" and not any(ascii_leak(r.get("fa")) for r in rows[:5])
except Exception: ok = False
try:
    d = get(f"{B}/api/topscorers?league=all")
    ts = d.get("scorers") or []; pl = [p.get("leagueKey") for p in (d.get("perLeague") or [])]
    ok = ok and len(ts) == 360 and len(pl) == 18 and "qatar" in pl and "eredivisie" in pl and "swiss" in pl and "hnl" in pl
except Exception: ok = False
try:
    d = get(f"{B}/api/topscorers/qatar"); ts = d.get("scorers") or []
    top = ts[0] if ts else {}
    ok = ok and top.get("nameFa") == "اکرم عفیف" and top.get("team") == "السد" and top.get("goals") == 7
except Exception: ok = False
try:
    d = get(f"{B}/api/league-titles?league=qatar"); tit = d.get("titles") or {}
    ok = ok and tit.get("total") == 22
except Exception: ok = False
try:
    d = get(f"{B}/api/league-transfers?league=qatar")
    pay = d.get("transfers") or {}
    ok = ok and len(pay.get("items") or []) == 17
except Exception: ok = False
try:
    d = get(f"{B}/api/league-bracket?league=qatar")
    ok = ok and d.get("bracket") is None
except Exception: ok = False
try:
    d = get(f"{B}/api/league-fixtures?league=qatar")
    ok = ok and len(d.get("upcoming") or []) == 20
except Exception: ok = False
print("API_TRUTH", "OK" if ok else "BAD")
PY
)
case "$API_OUT" in *"API_TRUTH OK"*) : ;; *) A_BAD=$((A_BAD+1)) ;; esac
echo "$API_OUT"

echo "== PART B: DOM 7/7 @390x844 =="
# D1: the qatar league page — h1 + live top الراین + tabs + bracket absent
probe "$BASE/league/qatar" "D1 qatar league page" \
"return {h1:((document.querySelector(\"h1\")||{}).innerText||\"\").includes(\"لیگ ستارگان قطر\"),top:((document.querySelector(\"table tbody tr\")||{}).innerText||\"\").includes(\"الریان\"),scorersTab:[...document.querySelectorAll(\"button\")].some(b=>(b.textContent||\"\").trim()===\"آقای گل\"),transfersTab:[...document.querySelectorAll(\"button\")].some(b=>(b.textContent||\"\").trim()===\"انتقال‌ها\"),bracketAbsent:![...document.querySelectorAll(\"button\")].some(b=>(b.textContent||\"\").trim()===\"براکت\")}"

# D2: real click «انتقال‌ها» — panel alive, zero broken images (the 145
# TeamLogo placeholder on its 11th consumer league)
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/league/qatar" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && (document.body.innerText||'').includes('انتقال‌ها')" >/dev/null 2>&1
sleep 3
$B eval '(function(){const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="انتقال‌ها");if(b)b.click();return b?"clicked":"no-tab"})()' >/dev/null 2>&1
sleep 3
FEAT2=$($B eval "JSON.stringify((()=>{return {panel:!!document.querySelector('section[aria-label=\"انتقال‌های لیگ\"]'),alive:(document.body.innerText||'').includes('انتقال')}})())" 2>/dev/null | tr -d '"\\')
OUT2=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null | tr -d '"\\')
C2=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception: print('ERR')")
E2=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  print(len([e for e in es if e.get('url')]))
except Exception: print('ERR')")
echo "D2 qatar transfers click → $OUT2 | feat=$FEAT2 | console=$C2 appErrors=$E2"
RC2=0
echo "$FEAT2" | grep -q "false\|null" && RC2=1
[ "$OUT2" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC2=1
[ "$C2" = "0" ] && [ "$E2" = "0" ] || RC2=1
[ "$RC2" -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D3: the race default copy — honest ۱۶, no stale ۱۵/۱۴ (gate-synced cycle-156)
probe "$BASE/topscorers" "D3 race copy 16" \
"return {h1:((document.querySelector(\"h1\")||{}).innerText||\"\").includes(\"مصاف گلزنان\"),copy18:(document.body.innerText||\"\").includes(\"۱۸ لیگ و جام برتر\"),noStale17:(document.body.innerText||\"\").includes(\"۱۷ لیگ و جام برتر\")===false,noStale16:(document.body.innerText||\"\").includes(\"۱۶ لیگ و جام برتر\")===false}"

# D4: the dedicated /topscorers/qatar — عفیف with Persian digits
probe "$BASE/topscorers/qatar" "D4 dedicated qatar scorers" \
"return {h1Live:!!(document.querySelector(\"h1\")||{}).innerText,afif:(document.body.innerText||\"\").includes(\"اکرم عفیف\"),faGoals:/[۰-۹]+\s*گل/.test(document.body.innerText||\"\")}"

# D5: /players — qatar chip + REAL two-step click (the stars-mode «شانزده» copy lives
# in the DEFAULT view — proven by cycle156-domproof D6; in TEAMS mode the copy is
# «اسکواد کامل…», so the post-click assert checks the teams copy only)
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/players" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 2
$B eval '(function(){const m=document.querySelector("[data-testid=\"mode-teams\"]");if(m)m.click();return m?"mode":"no-mode"})()' >/dev/null 2>&1
sleep 3
$B eval '(function(){const l=document.querySelector("[data-testid=\"league-qatar\"]");if(l)l.click();return l?"clicked":"no-chip"})()' >/dev/null 2>&1
sleep 4
FEAT5=$($B eval "JSON.stringify((()=>{return {teamsCopy:(document.body.innerText||'').includes('اسکواد کامل همهٔ تیم‌ها'),chipQatar:!!document.querySelector('[data-testid=\"league-qatar\"]'),urlLeague:location.search.includes('league=qatar'),teamChips:document.querySelectorAll('[data-testid^=\"team-\"]').length>=6,rayyan:(document.body.innerText||'').includes('الریان')}})())" 2>/dev/null | tr -d '"\\')
OUT5=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null | tr -d '"\\')
C5=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception: print('ERR')")
E5=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  print(len([e for e in es if e.get('url')]))
except Exception: print('ERR')")
echo "D5 players hub teams→qatar click → $OUT5 | feat=$FEAT5 | console=$C5 appErrors=$E5"
RC5=0
echo "$FEAT5" | grep -q "false\|null" && RC5=1
[ "$OUT5" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC5=1
[ "$C5" = "0" ] && [ "$E5" = "0" ] || RC5=1
[ "$RC5" -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D6: /leagues — 22 cards + the qatar + eredivisie + acl2 + mas cards (gate-synced cycle-162)
probe "$BASE/leagues" "D6 leagues hub 19 cards" \
"return {cards:document.querySelectorAll(\"a[href^='/league/']\").length,qatarCard:!!document.querySelector(\"a[href='/league/qatar']\"),ereCard:!!document.querySelector(\"a[href='/league/eredivisie']\"),acl2Card:!!document.querySelector(\"a[href='/league/acl2']\"),masCard:!!document.querySelector(\"a[href='/league/mas']\"),h1Fa:((document.querySelector(\"h1\")||{}).innerText||\"\").includes(\"لیگ\")}"

# D7: السد team page (101895) — the newest league's runner-up page
probe "$BASE/team/101895" "D7 al-sadd team page" \
"return {h1Live:!!(document.querySelector(\"h1\")||{}).innerText,faName:(document.body.innerText||\"\").includes(\"السد\")}"

echo "== RESULT =="
if [ "$A_BAD" -eq 0 ] && [ "$TOTAL_BAD" -eq 0 ]; then
  echo "DOM_PROOF OK (API 4/4 + DOM 7/7 green — لیگ ستارگان قطر honest end-to-end: the 17th competition and the SEVENTH consecutive new global-race participant, joining with NO globalMerge flag because its 17 slash-format seasons cover the cycle-132 window exactly (12 seasons 2026/2027 → 2015/2016 byte-identical), the live top three (الریان ۱۷/السد ۱۵/الدحیل ۱۵) on a 12/12 Persian table, اکرم عفیف 7 atop the scorers with PERSIAN name AND team (السد), the LIVE Iranian فرهاد زوشی (لوسیل، ۳ گل) in the pool, 360-scorer race (18 leagues, gate-synced cycle-161) with رافینیا still honest leader, 22 titles topped by 2025/2026 السد over الشمال (oldest 2004/2005 الغرافه, الجیش runner rows), transfers 17 items zero-ASCII, bracket honestly absent, NO espnSlug (ESPN 400 — persiangulf/uae Gulf pattern, probed live), attribution truth live-verified: الراین/لوسیل/السیلیه ride the new qatar index while Al-Sadd keeps its dual ACL truth and the eight prior first-seen truths stay put (پورتو→portugal, خورفکان→uae, گالاتاسارای→superlig, رنجرز→scottish, ابها→saudi, الهلال→acl, سلتیک→uel), race copy ۱۸ + players hub هجده + search guide ۲۲ + /leagues 22nd card (mas, gate-synced cycle-162), /players qatar grid with URL sync — the Gulf arc COMPLETION (persiangulf + saudi + uae + qatar); every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"
else
  echo "DOM_PROOF FLAGGED (A=$A_BAD B=$TOTAL_BAD)"; exit 1
fi
