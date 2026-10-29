#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-158 bug-hunt — گشت‌زنی سه‌لایهٔ سطح تازهٔ ۱۵۷ (لیگ قهرمانان آسیا ۲)
# + رگرسیون سطوح قدیمی، راستی‌آزمایی ۳۹۰×۸۴۴ با کنسول تمیز.
#
# House contract (V1–V10 mirror cycle-153-hunt; Part C = API truth):
#   hunt(label, url, extra-waitfn, clickjs, featjs) → collect() gates:
#   feat must not contain false/null, viewport {sw:390,cw:390,h1n:1,
#   vbroken:0}, console=0, appErrors=0.
#
# Live-truth baseline (probed 2026-10-29 23:4x, UA Chrome/124 — the D5
# rule: facts FIRST, gates second):
#   acl2 = league 9469, composite 8 groups → flattened 32 rows, top
#   الوحده ۹ (Group A), گل‌گهر Group B idx4 ۲ امتیاز, group labels
#   «گروه A»..«گروه H»; tabs «آقای گل»+«قهرمانان» present,
#   «انتقال‌ها»+«براکت» honestly absent (cup contracts);
#   race cur 320 scorers / 16 participants, leader رافینیا ۱۳, acl2 NOT
#   in perLeague; race 2023/2024 = 300/15 with acl2 out (merge-exempt);
#   acl2 fixtures upcoming=20 recent=10 total=99; titles 21, newest
#   2025/2026 گامبا اوساکا over النصر, all-Persian top-8;
#   search API truths: «Gol Gohar»→گل‌گهر|persiangulf (389880 — the
#   club's DOMESTIC league owns the first-branch attribution, the
#   الهلال→acl convention), «Al-Hilal»→الهلال|acl (FINDING-1 guard,
#   149), «Feyenoord»→فاینورد|eredivisie; real UI search flow: 2 hits,
#   گل‌گهر hit carries «خلیج فارس»;
#   players hub: «ستاره‌های شانزده لیگ و جام برتر» stays, chips appear
#   in TEAMS mode (mode-teams click first — the 153 two-step pattern),
#   league-acl2 chip + URL sync ?league=acl2 + گل‌گهر/الجزیره grid;
#   /team/389880 squad 31/32 Iran; /api/match/6054514 → ایست بنگال vs
#   السیب (Persian sides of an ACL Two fixture).
#
# D5 byte-lesson of cycle-157: judge selectors by od/grep bytes, never
# by what sed/terminal displays (the a[h sequence gets eaten).
# ------------------------------------------------------------------
set -u
cd "$(dirname "$0")/.."
BASE="${BASE:-http://localhost:3000}"
B=agent-browser
$B set viewport 390 844 >/dev/null

BAD=0
PASS_NAME="${1:-warm}"

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

echo "== PASS ($PASS_NAME) — DOM patrol @390x844 =="

# V1: the hub — 19 league cards, the acl2 card really present
hunt "V1 leagues hub 19 cards" "$BASE/leagues" \
"" "" \
"({cards:document.querySelectorAll(\"a[href^='/league/']\").length,acl2:!!document.querySelector(\"a[href='/league/acl2']\"),ere:!!document.querySelector(\"a[href='/league/eredivisie']\"),h1Fa:((document.querySelector(\"h1\")||{}).innerText||\"\").includes(\"لیگ\")})"

# V2: acl2 league page — h1, flattened composite with Persian group labels,
# top الوحده, گل‌گهر visible, tabs honest (scorers+titles in, transfers+bracket out)
hunt "V2 acl2 page honest tabs" "$BASE/league/acl2" \
"document.body.innerText.includes('الوحده')" "" \
"({h1:((document.querySelector(\"h1\")||{}).innerText||\"\").includes(\"لیگ قهرمانان آسیا ۲\"),top:document.body.innerText.includes(\"الوحده\"),gg:document.body.innerText.includes(\"گل‌گهر\"),grpA:document.body.innerText.includes(\"گروه A\"),grpH:document.body.innerText.includes(\"گروه H\"),scorersTab:[...document.querySelectorAll(\"button\")].some(b=>(b.textContent||\"\").trim()===\"آقای گل\"),titlesTab:[...document.querySelectorAll(\"button\")].some(b=>(b.textContent||\"\").trim()===\"قهرمانان\"),transfersAbsent:![...document.querySelectorAll(\"button\")].some(b=>(b.textContent||\"\").trim()===\"انتقال‌ها\"),bracketAbsent:![...document.querySelectorAll(\"button\")].some(b=>(b.textContent||\"\").trim()===\"براکت\")})"

# V3: real click «آقای گل» on acl2 — مالکوم/الجزیره/۴ with Persian digits,
# zero Latin in the top-5 scorer rows (read-first pattern: V2 read the top)
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/league/acl2" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body.innerText.includes('الوحده')" >/dev/null 2>&1
sleep 2
TOP2=$($B eval 'JSON.stringify({t:document.querySelector("table tbody tr").innerText.slice(0,40)})' 2>/dev/null | tr -d '"\\')
$B eval '(function(){const t=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="آقای گل");if(t)t.click();return t?"clicked":"no-tab"})()' >/dev/null 2>&1
$B wait --fn "document.body.innerText.includes('مالکوم')" >/dev/null 2>&1
sleep 3
FEAT3=$($B eval "JSON.stringify((function(){const b=document.body.innerText||'';const rows=[...document.querySelectorAll('table tbody tr')].slice(0,5);return {topWas:$TOP2,scorer:b.includes('مالکوم'),team:b.includes('الجزیره'),fa4:b.includes('۴'),noLatinTop:rows.every(function(r){return !/[A-Za-z]/.test(r.innerText||'')})}})())" 2>/dev/null | tr -d '"\\')
collect "$FEAT3" "V3 acl2 scorers real click"

# V4: eredivisie regression — read top فاینورد first, then REAL transfers
# click (the tab replaces the standings content — the cycle-148 lesson)
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/league/eredivisie" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body.innerText.includes('فاینورد')" >/dev/null 2>&1
sleep 2
TOP4=$($B eval 'JSON.stringify({t:document.querySelector("table tbody tr").innerText.includes("فاینورد")})' 2>/dev/null | tr -d '"\\')
$B eval '(function(){const t=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="انتقال‌ها");if(t)t.click();return t?"clicked":"no-tab"})()' >/dev/null 2>&1
sleep 3
FEAT4=$($B eval "JSON.stringify((function(){const b=document.body.innerText||'';return {topWas:$TOP4,panel:b.includes('انتقال')||b.includes('ورود')||b.includes('خروج'),noBroken:(function(){return [...document.images].filter(function(i){return i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=='hidden'}).length})()===0}})())" 2>/dev/null | tr -d '"\\')
collect "$FEAT4" "V4 eredivisie transfers click"

# V5: qatar regression — read top الراین first, then REAL transfers click
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/league/qatar" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body.innerText.includes('الریان')" >/dev/null 2>&1
sleep 2
TOP5=$($B eval 'JSON.stringify({t:document.querySelector("table tbody tr").innerText.includes("الریان")})' 2>/dev/null | tr -d '"\\')
$B eval '(function(){const t=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="انتقال‌ها");if(t)t.click();return t?"clicked":"no-tab"})()' >/dev/null 2>&1
sleep 3
FEAT5=$($B eval "JSON.stringify((function(){const b=document.body.innerText||'';return {topWas:$TOP5,panel:b.includes('انتقال')||b.includes('ورود')||b.includes('خروج')}})())" 2>/dev/null | tr -d '"\\')
collect "$FEAT5" "V5 qatar transfers click"

# V6a: race page — honest ۱۶ copy, no stale copies, NO acl2 section
hunt "V6a race copy 16 honest" "$BASE/topscorers" \
"document.body.innerText.includes('۱۶ لیگ و جام برتر')" "" \
"({copy16:document.body.innerText.includes(\"۱۶ لیگ و جام برتر\"),old17gone:!document.body.innerText.includes(\"۱۷ لیگ و جام برتر\"),leader:document.body.innerText.includes(\"رافینیا\"),noAcl2Section:document.body.innerText.indexOf(\"لیگ قهرمانان آسیا ۲\")===-1})"

# V6b: season-selected 2023/2024 — dynamic «۱۵ لیگ مشارکت‌کننده» (acl2
# merge-exempt even in the historical window)
hunt "V6b historical race 15" "$BASE/topscorers?season=2023%2F2024" \
"document.body.innerText.includes('۲۰۲۳/۲۴')" "" \
"({dyn15:document.body.innerText.includes(\"۱۵ لیگ مشارکت‌کننده\"),season:document.body.innerText.includes(\"۲۰۲۳/۲۴\")})"

# V7a/b/c: dedicated topscorers paths alive and Persian
hunt "V7a /topscorers/acl2" "$BASE/topscorers/acl2" \
"document.body.innerText.includes('مالکوم')" "" \
"({leader:document.body.innerText.includes(\"مالکوم\"),team:document.body.innerText.includes(\"الجزیره\"),h1Fa:((document.querySelector(\"h1\")||{}).innerText||\"\").length>0})"
hunt "V7b /topscorers/uae" "$BASE/topscorers/uae" \
"document.body.innerText.length > 60" "" \
"({h1Fa:((document.querySelector(\"h1\")||{}).innerText||\"\").includes(\"لیگ برتر امارات\"),persian:(document.body.innerText||\"\").includes(\"الجزیره\")})"
hunt "V7c /topscorers/eredivisie" "$BASE/topscorers/eredivisie" \
"document.body.innerText.length > 60" "" \
"({h1Fa:((document.querySelector(\"h1\")||{}).innerText||\"\").includes(\"اردیویزه\"),persian:(document.body.innerText||\"\").includes(\"فاینورد\")})"

# V8: players hub — «ستاره‌های شانزده» copy + REAL two-step click
# mode-teams → league-acl2 (URL sync + the ACL Two team grid)
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/players" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body.innerText.includes('ستاره‌های شانزده')" >/dev/null 2>&1
sleep 2
# read-first (the cycle-148/153 lesson + this cycle's own V8 find): the
# «ستاره‌های شانزده» copy belongs to STARS mode — clicking mode-teams
# replaces it BY DESIGN, so the copy must be read before the click and the
# teams-mode assert checks the TEAMS copy instead
COPY8=$($B eval 'JSON.stringify({c:document.body.innerText.includes("ستاره‌های شانزده لیگ و جام برتر")})' 2>/dev/null | tr -d '"\\')
$B eval '(function(){const b=document.querySelector("[data-testid=\"mode-teams\"]");if(b)b.click();return b?"clicked":"missing"})()' >/dev/null 2>&1
sleep 3
$B eval '(function(){const b=document.querySelector("[data-testid=\"league-acl2\"]");if(b)b.click();return b?"clicked":"missing"})()' >/dev/null 2>&1
sleep 4
FEAT8=$($B eval "JSON.stringify((function(){const b=document.body.innerText||'';return {starsCopyBefore:$COPY8,teamsCopyNow:b.includes(\"اسکواد کامل همهٔ تیم‌ها\"),urlSync:location.search.indexOf(\"league=acl2\")!==-1,gg:b.includes(\"گل‌گهر\"),jazira:b.includes(\"الجزیره\"),wahda:b.includes(\"الوحده\")}})())" 2>/dev/null | tr -d '"\\')
collect "$FEAT8" "V8 players hub acl2 two-step"

# V9: the hook club page — /team/389880 with the Iranian squad grid
hunt "V9 gol-gohar team page" "$BASE/team/389880" \
"document.body.innerText.includes('گل‌گهر')" "" \
"({h1Live:!!(document.querySelector(\"h1\")||{}).innerText,faName:document.body.innerText.includes(\"گل‌گهر\"),squad:document.body.innerText.includes(\"دروازه‌بان‌ها\")||document.body.innerText.includes(\"مدافعان\")})"

# V10: search_flow in the REAL UI — «Gol Gohar» → گل‌گهر hit with the
# persiangulf attribution + the FINDING-1 guard «Al-Hilal» → الهلال
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 2
$B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
sleep 1
$B eval "(function(){const i=document.querySelector('div[role=\"dialog\"] input');if(!i)return 'no-input';const s=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set;s.call(i,'Gol Gohar');i.dispatchEvent(new Event('input',{bubbles:true}));return 'typed'})()" >/dev/null 2>&1
$B wait --fn "[...document.querySelectorAll('div[role=\"dialog\"] ul li button')].some(x=>(x.innerText||'').includes('گل‌گهر'))" >/dev/null 2>&1
sleep 1.5
FEAT10=$($B eval "JSON.stringify((function(){const btns=[...document.querySelectorAll('div[role=\"dialog\"] ul li button')];const hit=btns.find(x=>(x.innerText||'').includes('گل‌گهر'));return {dialog:!!document.querySelector('div[role=\"dialog\"]'),hits:btns.length,faHit:!!hit,gulf:hit?hit.innerText.includes('خلیج فارس'):false}})())" 2>/dev/null | tr -d '"\\')
collect "$FEAT10" "V10a search Gol Gohar real UI"
# second query in the same dialog — FINDING-1 guard (149)
$B eval "(function(){const i=document.querySelector('div[role=\"dialog\"] input');if(!i)return 'no-input';const s=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set;s.call(i,'Al-Hilal');i.dispatchEvent(new Event('input',{bubbles:true}));return 'typed'})()" >/dev/null 2>&1
$B wait --fn "[...document.querySelectorAll('div[role=\"dialog\"] ul li button')].some(x=>(x.innerText||'').includes('الهلال'))" >/dev/null 2>&1
sleep 1.5
FEAT10B=$($B eval "JSON.stringify((function(){const btns=[...document.querySelectorAll('div[role=\"dialog\"] ul li button')];const hit=btns.find(x=>(x.innerText||'').includes('الهلال'));return {hits:btns.length,faHit:!!hit}})())" 2>/dev/null | tr -d '"\\')
collect "$FEAT10B" "V10b search Al-Hilal guard"

echo "== Part C — API truth (python verdict, exit-gated) =="
API_OUT=$(python3 - <<'PYEOF'
import json, re, urllib.request, urllib.parse, sys

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
BASE = "http://localhost:3000"

def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode("utf-8"))

fails = []
def report(name, good, detail=""):
    print(f"{name}: {'OK' if good else 'BAD'} {detail}")
    if not good:
        fails.append(name)

ascii_leak = lambda s: bool(re.search(r"[A-Za-z]", s or ""))
Q = urllib.parse.quote

# A1: acl2 composite flatten + the two spot re-checks, zero ASCII top-5
d = get(f"{BASE}/api/standings?league=acl2")
rows = d.get("rows") or []
groups = [g.get("fa") for g in (d.get("groups") or [])]
gg = [r for r in rows if "گل‌گهر" in (r.get("fa") or "")]
report("standings acl2",
       len(rows) == 32 and rows[0].get("fa") == "الوحده"
       and groups == [f"گروه {c}" for c in "ABCDEFGH"]
       and not any(ascii_leak(r.get("fa")) for r in rows[:5])
       and len(gg) == 1 and gg[0].get("idx") == 4 and gg[0].get("pts") == 2,
       f"rows={len(rows)} top={rows[0].get('fa') if rows else None} gg={len(gg)}")
d = get(f"{BASE}/api/standings?league=qatar")
rows = d.get("rows") or []
report("standings qatar spot", len(rows) == 12 and rows[0].get("fa") == "الریان",
       f"rows={len(rows)} top={rows[0].get('fa') if rows else None}")
d = get(f"{BASE}/api/standings?league=eredivisie")
rows = d.get("rows") or []
report("standings eredivisie spot", len(rows) == 18 and rows[0].get("fa") == "فاینورد",
       f"rows={len(rows)} top={rows[0].get('fa') if rows else None}")

# A2: current race untouched — 320/16, رافینیا 13, acl2 NOT in perLeague
d = get(f"{BASE}/api/topscorers?league=all")
ts = d.get("scorers") or []
pl = [p.get("leagueKey") for p in (d.get("perLeague") or [])]
lead = ts[0] if ts else {}
report("race current",
       len(ts) == 320 and len(pl) == 16 and "acl2" not in pl
       and lead.get("nameFa") == "رافینیا" and lead.get("goals") == 13,
       f"n={len(ts)} perLeague={len(pl)} leader={lead.get('nameFa')}({lead.get('goals')})")

# A3: historical 2023/2024 window — 300/15 with acl2 honestly out
d = get(f"{BASE}/api/topscorers?league=all&season={Q('2023/2024')}")
ts = d.get("scorers") or []
pl = [p.get("leagueKey") for p in (d.get("perLeague") or [])]
report("race 2023/2024",
       len(ts) == 300 and len(pl) == 15 and "acl2" not in pl,
       f"n={len(ts)} perLeague={len(pl)}")

# A4: titles — acl2 21 (newest گامبا اوساکا/النصر) + eredivisie 127 spot,
# zero ASCII in the top-8 champions of each
d = get(f"{BASE}/api/league-titles?league=acl2")
tt = (d.get("titles") or {}).get("items") or []
first = tt[0] if tt else {}
report("titles acl2",
       (d.get("titles") or {}).get("total") == 21 and len(tt) == 21
       and first.get("season") == "2025/2026" and first.get("championFa") == "گامبا اوساکا"
       and first.get("runnerUpFa") == "النصر"
       and not any(ascii_leak(x.get("championFa")) for x in tt[:8]),
       f"total={(d.get('titles') or {}).get('total')} newest={first.get('season')}")
d = get(f"{BASE}/api/league-titles?league=eredivisie")
tt = (d.get("titles") or {}).get("items") or []
report("titles eredivisie spot", (d.get("titles") or {}).get("total") == 127,
       f"total={(d.get('titles') or {}).get('total')}")

# A5: acl2 fixtures — upcoming 20 / recent 10 / total 99, Persian league name
d = get(f"{BASE}/api/league-fixtures?league=acl2")
report("fixtures acl2",
       d.get("ok") is True and d.get("leagueFa") == "لیگ قهرمانان آسیا ۲"
       and len(d.get("upcoming") or []) == 20 and len(d.get("recent") or []) == 10
       and d.get("total") == 99,
       f"upcoming={len(d.get('upcoming') or [])} recent={len(d.get('recent') or [])} total={d.get('total')}")

# A6: search attribution truths — GolGohar→persiangulf (first-branch
# domestic convention, the الهلال→acl class), Al-Hilal→acl (FINDING-1),
# Feyenoord→eredivisie
d = get(f"{BASE}/api/search?q={Q('Gol Gohar')}")
res = d.get("results") or d.get("teams") or []
t0 = res[0] if res else {}
report("search gol-gohar",
       t0.get("teamId") == 389880 and t0.get("fa") == "گل‌گهر"
       and t0.get("leagueKey") == "persiangulf",
       f"fa={t0.get('fa')} league={t0.get('leagueKey')}")
d = get(f"{BASE}/api/search?q={Q('Al-Hilal')}")
res = d.get("results") or d.get("teams") or []
t0 = res[0] if res else {}
report("search al-hilal guard",
       t0.get("fa") == "الهلال" and t0.get("leagueKey") == "acl",
       f"fa={t0.get('fa')} league={t0.get('leagueKey')}")
d = get(f"{BASE}/api/search?q={Q('Feyenoord')}")
res = d.get("results") or d.get("teams") or []
t0 = res[0] if res else {}
report("search feyenoord",
       t0.get("fa") == "فاینورد" and t0.get("leagueKey") == "eredivisie",
       f"fa={t0.get('fa')} league={t0.get('leagueKey')}")

# A7: the Persian hook at app level — 31/32 Iran members through our own
# squad API + player-level country=Iran (the D5 rule)
d = get(f"{BASE}/api/team-squad/389880")
sq = d.get("squad") or {}
members = [p for g in (sq.get("groups") or []) for p in (g.get("players") or [])]
irn = [p for p in members if (p.get("nationality") or "") == "Iran"]
report("gol-gohar iranian squad", len(members) == 32 and len(irn) == 31,
       f"members={len(members)} iran={len(irn)}")
d = get(f"{BASE}/api/player/196041")
c = ((d.get("player") or {}).get("info") or {}).get("country")
report("player-level Iran verify", c == "Iran", f"country={c}")

# A8: an ACL Two fixture through the match API — Persian sides (ایست بنگال
# vs السیب, the Nov 3 Group D game probed live)
d = get(f"{BASE}/api/match/6054514")
m = d.get("match") or {}
report("match acl2 persian sides",
       (m.get("home") or {}).get("fa") == "ایست بنگال"
       and (m.get("away") or {}).get("fa") == "السیب",
       f"home={(m.get('home') or {}).get('fa')} away={(m.get('away') or {}).get('fa')}")

# A9: duplicate-key guard — 841 team / 431 player keys, zero duplicates
def keys_of(path, anchor):
    s = open(path).read()
    i = s.index(anchor)
    j = s.index("\n};", i)
    return re.findall(r'"([^"]+)":', s[i:j])
tk = keys_of("src/lib/leagues.ts", "const TEAM_FA")
pk = keys_of("src/lib/player-names-fa.ts", "export const PLAYER_NAME_FA")
td = [k for k in set(tk) if tk.count(k) > 1]
pd = [k for k in set(pk) if pk.count(k) > 1]
report("A9 duplicate-key guard", len(tk) == 841 and len(pk) == 431 and not td and not pd,
       f"team={len(tk)} player={len(pk)} dups={len(td)+len(pd)}")

print("API_TRUTH", "OK" if not fails else f"BAD {fails}")
sys.exit(0 if not fails else 1)
PYEOF
)
echo "$API_OUT" | tail -16
case "$API_OUT" in *"API_TRUTH OK"*) : ;; *) BAD=$((BAD+1)) ;; esac

echo "== RESULT ($PASS_NAME) =="
if [ "$BAD" -eq 0 ]; then
  echo "HUNT OK — patrol contracts green (cycle-158 targets: the acl2 surface end-to-end + older-surface regressions, gates on the cycle-157 live truth)"
else
  echo "HUNT FLAGGED (BAD=$BAD)"; exit 1
fi
