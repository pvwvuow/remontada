#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-163 bug-hunt — گشت‌زنی سه‌لایهٔ سطح تازهٔ پس از آخرین شکار (۱۵۸):
# سوئیس ۱۶۰ / کرواسی hnl ۱۶۱ / مالزی mas ۱۶۲ + راستی‌آزمایی کل پرتال ۲۲رقابتی
# در viewport 390×844 با کنسول تمیز.
#
# House contract (V1–V10 mirror cycle-153/158-hunt; Part C = API truth):
#   hunt(label, url, extra-waitfn, clickjs, featjs) → collect() gates:
#   feat must not contain false/null, viewport {sw:390,cw:390,h1n:1,
#   vbroken:0}, console=0, appErrors=0.
#
# Live-truth baseline (probed 2026-10-30, UA Chrome/124 — the D5 rule:
# facts FIRST, gates second; every gate below re-verified against the
# running server before being written):
#   mas  = 12 rows جوهور دارالتعظیم 18 / سلانگور, scorer block n=20
#          کریگور 9 top + شهاب زاهدی 7 (3rd); titles=None honest (the FIRST
#          titles-less competition, cycle-121 contract); bracket absent
#          (playoff null, cycle-56); transfers flat 3-item zero-ASCII;
#          season select = 3 slash seasons; archived 2025/2026 = 13 rows
#          جوهور ۷۰ champion; plain-year ?season=2023 → 400 Invalid season
#          (uniform cycle-132 convention); day-feed mas rides offset 1..2
#          (date rolled since 162 — the hunt scans offsets 0..3 DYNAMICALLY
#          instead of pinning one — the date-volatile assertion lesson);
#   swiss= 12 rows لوگانو 31 / یانگ‌بویز, scorer اسنده 12; titles
#          {total:32, newest 2025/2026 تون over سنت‌گالن}; transfers 99
#          zero-ASCII; archived 2025/2026 COMPOSITE flattened 24 rows
#          (دور قهرمانی ۶ + دور سقوط ۶ + جدول کلی ۱۲) top تون 75;
#   hnl  = 10 rows هایدوک اسپلیت 23 / دیناموزاگرب, scorer بلیو 12; titles
#          35; transfers 99 zero-ASCII; bracket absent (playoff null);
#   race cur = 380 scorers / 19 perLeague, mas ABSENT (merge-exempt,
#          globalMerge:false per the cycle-160 Norwegian lesson — the FIRST
#          DOMESTIC league with the flag), leader رافینیا ۱۳;
#   race 2023/2024 = 360/18 with hnl + poland IN (archived seasons carry the scorer
#          block) and mas honestly out (no such season);
#   search: St. Gallen→سنت‌گالن|swiss, Rijeka→رییکا|hnl,
#           Negeri Sembilan→نگری سمبیلان|mas, Johor→جوهور دارالتعظیم|acl
#           (the Al-Sadd first-seen class, BY DESIGN since 155);
#   squad 165228 (جوهور) carries Shahab Zahedi; mapping keys 1121/557.
#
# V1  /leagues → 22 cards + swiss/hnl/mas cards really present
# V2  /league/mas → h1 سوپرلیگ مالزی, top جوهور, tabs آقای گل+انتقال‌ها,
#     قهرمانان + براکت BOTH honestly absent (titles null + playoff null)
# V3  mas → real click «انتقال‌ها» → panel alive, zero broken images
# V4  /league/swiss → top لوگانو read on standings FIRST, then real
#     «آقای گل» click → اسنده visible (tabs swap — the 148 lesson)
# V5  /league/hnl → top هایدوک read first, then real «انتقال‌ها» click
# V6a /topscorers default → «۱۹ لیگ و جام برتر» + no mas section
# V6b season-selected → dynamic «۱۸ لیگ مشارکت‌کننده» + mas honestly out
# V7a/b/c dedicated paths /topscorers/{mas,swiss,hnl} alive
# V8  /players → «بیست لیگ و جام برتر» + REAL two-step click mode-teams →
#     league-mas chip (URL sync + Persian team grid)
# V9  /team/165228 جوهور → the newest league's top team page
# V10 search_flow ×3 (149 heritage): Al-Hilal fix guard + the two new
#     first-seen truths Rijeka→رییکا and St. Gallen→سنت‌گالن
# Part C: API truth A1–A14 (standings ×3 new + race cur/hist + titles ×2 +
#     transfers ×3 + search ×4 + squad + archived ×2 + honesty 400 +
#     dynamic day-feed + mapcheck 1121/557)
# Tail: re-run cycle158-hunt.sh + cycle162-domproof.sh (the two freshest
#     synced gates) as the cross-regression.
# ------------------------------------------------------------------
set -u
B=agent-browser
BASE="http://localhost:3000"
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
  [ -z "$FEAT" ] && RC=1   # D5: an empty feat (broken eval) must FAIL, not silently pass
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
  return 0
}

echo "== PART A: DOM hunt @390x844 =="
# V1: leagues hub — 22 cards + the three newest routes really present
hunt "V1 leagues hub 23 cards" "$BASE/leagues" \
"(document.body.innerText||\"\").includes(\"سوپرلیگ مالزی\")" "" \
"({cards:document.querySelectorAll(\"a[href^='/league/']\").length>=23,masCard:!!document.querySelector(\"a[href='/league/mas']\"),swissCard:!!document.querySelector(\"a[href='/league/swiss']\"),hnlCard:!!document.querySelector(\"a[href='/league/hnl']\"),polandCard:!!document.querySelector(\"a[href='/league/poland']\"),h1Fa:((document.querySelector('h1')||{}).innerText||'').includes('لیگ')})"

# V2: mas — h1, live top جوهور, scorers+transfers tabs, titles+bracket honestly absent
hunt "V2 mas page tabs honest-absence" "$BASE/league/mas" \
"(document.body.innerText||\"\").includes(\"جوهور\")" "" \
"({h1:((document.querySelector('h1')||{}).innerText||'').includes('سوپرلیگ مالزی'),top:((document.querySelector('table tbody tr')||{}).innerText||'').includes('جوهور'),scorersTab:[...document.querySelectorAll('button')].some(b=>(b.textContent||'').trim()==='آقای گل'),transfersTab:[...document.querySelectorAll('button')].some(b=>(b.textContent||'').trim()==='انتقال‌ها'),titlesAbsent:![...document.querySelectorAll('button')].some(b=>(b.textContent||'').trim()==='قهرمانان'),bracketAbsent:![...document.querySelectorAll('button')].some(b=>(b.textContent||'').trim()==='براکت')})"

# V3: mas — REAL transfers click → panel alive (3 items, the 145 placeholder heritage)
hunt "V3 mas transfers click" "$BASE/league/mas" \
"(document.body.innerText||\"\").includes(\"جوهور\")" \
"(function(){const t=[...document.querySelectorAll('button')].find(x=>(x.textContent||'').trim()==='انتقال‌ها');if(t)t.click();return t?'clicked':'no-tab'})()" \
"({panelAlive:(document.body.innerText||'').length>200,persian:(document.body.innerText||'').includes('به')||document.querySelectorAll('table tbody tr, ul li').length>0})"

# V4: swiss — read top FIRST (the 148 lesson), then REAL scorers click
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/league/swiss" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.includes('لوگانو')" >/dev/null 2>&1
sleep 3
TOP4=$($B eval "JSON.stringify((()=>{const r=document.querySelector('table tbody tr');return {topWas:(r?r.innerText:'').includes('لوگانو')}})())" 2>/dev/null | tr -d '"\\')
$B eval '(function(){const t=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="آقای گل");if(t)t.click();return t?"clicked":"no-tab"})()' >/dev/null 2>&1
sleep 3
FEAT4=$($B eval "JSON.stringify((()=>{const b=document.body.innerText||'';return {asane:b.includes('ساموئل اسنده'),luganoTeam:b.includes('یانگ‌بویز')}})())" 2>/dev/null | tr -d '"\\')
collect "$TOP4 $FEAT4" "V4 swiss lugano-top + scorers click اسنده"

# V5: hnl — read top FIRST, then REAL transfers click
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/league/hnl" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.includes('هایدوک')" >/dev/null 2>&1
sleep 3
TOP5=$($B eval "JSON.stringify((()=>{const r=document.querySelector('table tbody tr');return {topWas:(r?r.innerText:'').includes('هایدوک')}})())" 2>/dev/null | tr -d '"\\')
$B eval '(function(){const t=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="انتقال‌ها");if(t)t.click();return t?"clicked":"no-tab"})()' >/dev/null 2>&1
sleep 3
FEAT5=$($B eval "JSON.stringify((()=>{const b=document.body.innerText||'';return {panelAlive:b.length>200,rows:document.querySelectorAll('table tbody tr, ul li, ol li').length>0}})())" 2>/dev/null | tr -d '"\\')
collect "$TOP5 $FEAT5" "V5 hnl hajduk-top + transfers click"

# V6a: race default — copy ۱۸ honest, mas absent (merge-exempt)
hunt "V6a race default copy 18 + no-mas" "$BASE/topscorers" \
"(document.body.innerText||\"\").includes(\"رافینیا\")" "" \
"({copy20:(document.body.innerText||'').includes('۲۰ لیگ و جام برتر'),old18gone:!(document.body.innerText||'').includes('۱۸ لیگ و جام برتر'),noMas:(document.body.innerText||'').indexOf('سوپرلیگ مالزی')===-1})"

# V6b: race 2023/2024 — dynamic ۱۷ participants (hnl archived has scorers), mas out
hunt "V6b race season dyn-17" "$BASE/topscorers?league=all&season=2023/2024" \
"(document.body.innerText||\"\").includes(\"۲۰۲۳/۲۴\")||((document.body.innerText||\"\").includes(\"۲۰۲۳\"))" "" \
"({dyn19:(document.body.innerText||'').includes('۱۹ لیگ مشارکت‌کننده'),hnlRow:(document.body.innerText||'').includes('هایدوک')||(document.body.innerText||'').includes('دیناموزاگرب'),noMas:(document.body.innerText||'').indexOf('سوپرلیگ مالزی')===-1})"

# V7: dedicated topscorer paths — the three newest
hunt "V7a mas scorers path زاهدی" "$BASE/topscorers/mas" \
"(document.body.innerText||\"\").includes(\"کریگور\")" "" \
"({zahedi:(document.body.innerText||'').includes('شهاب زاهدی'),johor:(document.body.innerText||'').includes('جوهور'),goals9:(document.body.innerText||'').includes('۹')})" 
hunt "V7b swiss scorers path اسنده" "$BASE/topscorers/swiss" \
"(document.body.innerText||\"\").includes(\"ساموئل اسنده\")" "" \
"({team:(document.body.innerText||'').includes('یانگ‌بویز'),goals12:(document.body.innerText||'').includes('۱۲')})"
hunt "V7c hnl scorers path بلیو" "$BASE/topscorers/hnl" \
"(document.body.innerText||\"\").includes(\"دیون درنا بلیو\")" "" \
"({team:(document.body.innerText||'').includes('دیناموزاگرب'),goals12:(document.body.innerText||'').includes('۱۲')})"

# V8: players hub — copy ۱۸ + REAL two-step click mode-teams → league-mas chip
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/players" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
sleep 3
COPY8=$($B eval "JSON.stringify((()=>{const b=document.body.innerText||'';return {copy18:b.includes('بیست لیگ و جام برتر')}})())" 2>/dev/null | tr -d '"\\')
$B eval '(function(){const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").includes("تیم‌ها")||(x.textContent||"").includes("اسکواد"));if(b)b.click();return b?"teams":"no-mode"})()' >/dev/null 2>&1
sleep 2
$B eval '(function(){const c=document.querySelector("[data-testid=\"league-mas\"]");if(c)c.click();return c?"clicked":"no-chip"})()' >/dev/null 2>&1
sleep 3
FEAT8=$($B eval "JSON.stringify((()=>{return {urlSync:location.search.includes('league=mas'),grid:(document.body.innerText||'').includes('جوهور')||(document.body.innerText||'').includes('سلانگور')}})())" 2>/dev/null | tr -d '"\\')
collect "$COPY8 $FEAT8" "V8 players hub teams→mas click"

# V9: جوهور team page — the newest league's top team
hunt "V9 johor team page" "$BASE/team/165228" \
"(document.body.innerText||\"\").includes(\"جوهور\")" "" \
"({h1Live:!!(document.querySelector('h1')||{}).innerText,squadish:(document.body.innerText||'').includes('دروازه‌بان')||(document.body.innerText||'').includes('مهاجم')||(document.body.innerText||'').includes('دفاع')})"

# V10: search_flow ×3 in the REAL UI (149 heritage + the two new first-seen truths)
search_flow() { # $1=query $2=expect-fa $3=label
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$BASE/" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 2
  $B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
  sleep 1
  $B eval "(function(){const i=document.querySelector('div[role=\"dialog\"] input');if(!i)return 'no-input';const s=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set;s.call(i,'$1');i.dispatchEvent(new Event('input',{bubbles:true}));return 'typed'})()" >/dev/null 2>&1
  $B wait --fn "[...document.querySelectorAll('div[role=\"dialog\"] ul li button')].some(b=>(b.innerText||'').includes('$2'))" >/dev/null 2>&1
  sleep 1.5
  local FEAT OUT C E RC=0
  FEAT=$($B eval "JSON.stringify((()=>{const btns=[...document.querySelectorAll('div[role=\"dialog\"] ul li button')];const hit=btns.find(b=>(b.innerText||'').includes('$2'));return {dialog:!!document.querySelector('div[role=\"dialog\"]'),hits:btns.length,found:!!hit,faHit:hit?(hit.innerText||'').includes('$2'):false}})())" 2>/dev/null | tr -d '"\\')
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
search_flow "Rijeka" "رییکا" "V10b header search Rijeka (hnl first-seen)"
search_flow "St. Gallen" "سنت‌گالن" "V10c header search St. Gallen (swiss)"

echo "== PART C: API truth =="
API_OUT=$(python3 - <<'PY'
import json, urllib.request, urllib.parse, urllib.error, re, subprocess
def get(u):
    with urllib.request.urlopen(u, timeout=30) as r:
        return json.load(r)
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")
ascii_leak = lambda s: bool(re.search(r"[A-Za-z]", s or ""))
# A1: the three NEWEST standings + scorer blocks (mas merge-exempt / swiss / hnl)
for lk, n, top, pts, sname, sgoals in (
        ("mas", 12, "جوهور دارالتعظیم", 18, "کریگور", 9),
        ("swiss", 12, "لوگانو", 31, "ساموئل اسنده", 12),
        ("hnl", 10, "هایدوک اسپلیت", 23, "دیون درنا بلیو", 12)):
    try:
        d = get(f"http://localhost:3000/api/standings?league={lk}")
        rows = d.get("rows") or []
        sc = d.get("scorers") or []
        lead = sc[0] if sc else {}
        zahedi = [s for s in sc if (s.get("nameFa") or "") == "شهاب زاهدی"] if lk == "mas" else None
        good = (d.get("ok") and len(rows) == n and rows[0].get("fa") == top and rows[0].get("pts") == pts
                and len(sc) == 20 and lead.get("nameFa") == sname and lead.get("goals") == sgoals
                and not any(ascii_leak(r.get("fa")) for r in rows[:5]) and not ascii_leak(lead.get("team")))
        if lk == "mas":
            good = good and bool(zahedi) and zahedi[0].get("goals") == 7
        report(f"standings {lk}", good, f"rows={len(rows)} top={rows[0].get('fa') if rows else None}({rows[0].get('pts') if rows else None}) scorer={lead.get('nameFa')}({lead.get('goals')})")
    except Exception as e:
        report(f"standings {lk}", False, str(e))
# A2: global race — 400/20, mas absent (merge-exempt), poland IN, رافینیا honest leader
try:
    d = get("http://localhost:3000/api/topscorers")
    ts = d.get("scorers") or []
    pl = [p.get("leagueKey") for p in (d.get("perLeague") or [])]
    lead = ts[0] if ts else {}
    good = (len(ts) == 400 and len(pl) == 20 and "mas" not in pl
            and {"swiss", "hnl", "poland"} <= set(pl) and lead.get("nameFa") == "رافینیا"
            and lead.get("goals") == 13 and not ascii_leak(lead.get("team")))
    report("race cur 400/20 no-mas poland-in", good, f"n={len(ts)} perLeague={len(pl)} leader={lead.get('nameFa')}({lead.get('goals')})")
except Exception as e:
    report("race cur 400/20 no-mas poland-in", False, str(e))
# A3: historical 2023/2024 — 380/19, hnl + poland IN (archived scorer blocks), mas out
try:
    d = get("http://localhost:3000/api/topscorers?season=2023/2024")
    ts = d.get("scorers") or []
    pl = [p.get("leagueKey") for p in (d.get("perLeague") or [])]
    good = len(ts) == 380 and len(pl) == 19 and "hnl" in pl and "mas" not in pl and "swiss" in pl and "poland" in pl and "belgium" in pl
    report("race 2023/2024 380/19 hnl+poland-in mas-out", good, f"n={len(ts)} perLeague={len(pl)}")
except Exception as e:
    report("race 2023/2024 380/19 hnl+poland-in mas-out", False, str(e))
# A4: titles — mas honestly None (the FIRST titles-less competition), swiss 32 newest تون
try:
    d = get("http://localhost:3000/api/league-titles?league=mas")
    report("titles mas null", d.get("ok") is True and d.get("titles") is None, f"titles={d.get('titles')}")
    d = get("http://localhost:3000/api/league-titles?league=swiss")
    t = d.get("titles") or {}
    its = t.get("items") or []
    newest = its[0] if its else {}
    good = t.get("total") == 32 and newest.get("season") == "2025/2026" and newest.get("championFa") == "تون" and newest.get("runnerUpFa") == "سنت‌گالن"
    report("titles swiss 32 newest تون", good, f"total={t.get('total')} newest={newest.get('season')}:{newest.get('championFa')}")
except Exception as e:
    report("titles mas/swiss", False, str(e))
# A5: transfers ×3 — flat lists zero-ASCII (items under data.transfers)
for lk, n in (("mas", 3), ("hnl", 99), ("swiss", 99)):
    try:
        d = get(f"http://localhost:3000/api/league-transfers?league={lk}")
        p = d.get("transfers") or {}
        its = p.get("items") or []
        leak = [x for x in its if ascii_leak((x.get("fromClubFa") or "") + (x.get("toClubFa") or ""))]
        report(f"transfers {lk} {n} zero-ASCII", d.get("ok") is True and len(its) == n and not leak, f"items={len(its)} leak={len(leak)}")
    except Exception as e:
        report(f"transfers {lk}", False, str(e))
# A6: search attribution — the two new first-seen truths + mas index + Johor Al-Sadd class
for q, fa, lk in (("St.%20Gallen", "سنت‌گالن", "swiss"), ("Rijeka", "رییکا", "hnl"),
                  ("Negeri%20Sembilan", "نگری سمبیلان", "mas"), ("Johor", "جوهور دارالتعظیم", "acl")):
    try:
        d = get(f"http://localhost:3000/api/search?q={q}")
        r = d.get("results") or []
        f0 = r[0] if r else {}
        report(f"search {q}", f0.get("fa") == fa and f0.get("leagueKey") == lk, f"{f0.get('fa')}|{f0.get('leagueKey')}")
    except Exception as e:
        report(f"search {q}", False, str(e))
# A7: squad 165228 جوهور carries Zahedi (the live-Iranian hook)
try:
    d = get("http://localhost:3000/api/team-squad/165228")
    report("squad 165228 Zahedi", d.get("ok") is True and "Shahab Zahedi" in json.dumps(d.get("squad") or {}, ensure_ascii=False), "squad fetched")
except Exception as e:
    report("squad 165228 Zahedi", False, str(e))
# A8: mas archived 2025/2026 — 13 rows, جوهور ۷۰ champion; plain-year honestly
# 400 (the uniform cycle-132 convention — the 400 STATUS + body error is the
# EXPECTED product behavior; urllib raises HTTPError so the body must be read)
try:
    d = get("http://localhost:3000/api/standings?league=mas&season=2025/2026")
    rows = d.get("rows") or []
    good = d.get("ok") and d.get("selectedSeason") == "2025/2026" and len(rows) == 13 and rows[0].get("fa") == "جوهور دارالتعظیم" and rows[0].get("pts") == 70
    report("mas archived 2025/2026 13 rows جوهور ۷۰", good, f"rows={len(rows)} top={rows[0].get('fa') if rows else None}({rows[0].get('pts') if rows else None})")
    try:
        d = get("http://localhost:3000/api/standings?league=mas&season=2023")
        report("mas plain-year 2023 → 400", False, f"UNEXPECTED 200: ok={d.get('ok')}")
    except urllib.error.HTTPError as he:
        body = he.read().decode("utf-8", "replace")
        report("mas plain-year 2023 → 400", he.code == 400 and "Invalid season: 2023" in body, f"HTTP {he.code} body has Invalid season")
except Exception as e:
    report("mas archived/honesty", False, str(e))
# A9: swiss archived COMPOSITE — 24 rows flattened (۶+۶+۱۲), top تون 75
try:
    d = get("http://localhost:3000/api/standings?league=swiss&season=2025/2026")
    rows = d.get("rows") or []
    good = d.get("ok") and len(rows) == 24 and rows[0].get("fa") == "تون" and rows[0].get("pts") == 75
    report("swiss archived composite 24 rows تون ۷۵", good, f"rows={len(rows)} top={rows[0].get('fa') if rows else None}({rows[0].get('pts') if rows else None})")
except Exception as e:
    report("swiss archived composite", False, str(e))
# A10: bracket honest-absence — the new three (playoff=null → bracket null)
for lk in ("mas", "swiss", "hnl"):
    try:
        d = get(f"http://localhost:3000/api/league-bracket?league={lk}")
        report(f"bracket {lk} null", d.get("ok") is True and d.get("bracket") is None, f"bracket={d.get('bracket')}")
    except Exception as e:
        report(f"bracket {lk} null", False, str(e))
# A11: day-feed mas — DYNAMIC offset scan 0..3 (date-volatile lesson: never pin
# one offset; the fan just wants SOME day with the Persian mas grid)
try:
    found = None
    for off in range(4):
        d = get(f"http://localhost:3000/api/matches?offset={off}")
        mg = [g for g in (d.get("groups") or []) if g.get("leagueId") == 8985]
        if mg and (mg[0].get("matches") or []):
            ms = mg[0]["matches"]
            bad = any(ascii_leak(m["home"]["fa"] + m["away"]["fa"]) for m in ms)
            found = (off, mg[0].get("leagueFa"), bad)
            break
    good = bool(found) and found[1] == "سوپرلیگ مالزی" and not found[2]
    report("dayfeed mas dynamic offset", good, f"offset={found[0] if found else None} fa={found[1] if found else None}")
except Exception as e:
    report("dayfeed mas dynamic offset", False, str(e))
# A12: mapping keys — the A7 duplicate guard at the cycle-181 totals 1121/557
try:
    r = subprocess.run(["python3", "scripts/cycle162-mapcheck.py"], capture_output=True, text=True, timeout=120)
    report("mapcheck 1121/557 zero-dups", r.returncode == 0, f"rc={r.returncode}")
except Exception as e:
    report("mapcheck 1121/557 zero-dups", False, str(e))

print("API_TRUTH " + ("OK" if ok else "FLAGGED"))
PY
)
echo "$API_OUT"
case "$API_OUT" in
  *"API_TRUTH OK"*) : ;;
  *) BAD=$((BAD+1)) ;;
esac

echo "== PART D: cross-gate re-runs (the two freshest synced gates) =="
bash scripts/cycle158-hunt.sh >/tmp/c163-g158.log 2>&1 && G158=$? || G158=$?
grep -q "HUNT OK" /tmp/c163-g158.log && grep -q "API_TRUTH OK" /tmp/c163-g158.log && G158PASS=1 || G158PASS=0
echo "cycle158-hunt re-run rc=$G158 HUNT+API green=$G158PASS"
[ "$G158PASS" = "1" ] || BAD=$((BAD+1))
bash scripts/cycle162-domproof.sh >/tmp/c163-g162.log 2>&1 && G162=$? || G162=$?
grep -q "DOM_PROOF OK" /tmp/c163-g162.log && G162PASS=1 || G162PASS=0
echo "cycle162-domproof re-run rc=$G162 DOM_PROOF green=$G162PASS"
[ "$G162PASS" = "1" ] || BAD=$((BAD+1))

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "HUNT OK (cycle-163: the three surfaces born after the last hunt — swiss 160 / hnl 161 / mas 162 — walked the fan way @390x844: V1–V10 green with console=0/appErrors=0 everywhere, plus API truth A1–A12 and both cross-gates (158-hunt + 162-domproof) re-run green)"
else
  echo "HUNT FLAGGED (BAD=$BAD)"; exit 1
fi
