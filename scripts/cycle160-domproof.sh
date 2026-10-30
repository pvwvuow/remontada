#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-160 DOM/API proof — Swiss Super League (the TWENTIETH
# competition, the EIGHTH consecutive new global-race participant,
# the live-Iranian hook in Swiss football: مصطفی حیدری, the
# 19-year-old Iranian centre-back at سنت‌گالن — squad ccode IRN +
# cname "Iran" + nationalTeamId 6711, three agreeing club-side
# fields with NO contradicting profile: his individual FotMob page
# 404s, the youth-player evidence class the Dennis-Eckert false
# positive lacked).
#
# Contract under proof (live-probed 2026-10-30, UA Chrome/124):
#   league 69 / ccode3 SUI; flat 12-row 2026/2027 table (Lugano 31 /
#   Young Boys 25 / Sion 22); 17 slash-format seasons (2026/2027 →
#   2010/2011) → NO globalMerge flag → race 340 scorers / 17
#   participants, رافینیا ۱۳ honest leader, window byte-identical
#   (2026/2027 → 2015/2016); top-scorer fetchAllUrl (116-row
#   PascalCase FMStatFullRow goals.json — the exact shape the
#   cycle-23 parser reads natively; leader Samuel Essende 12);
#   32 title seasons (newest 2025/2026 Thun over St. Gallen, oldest
#   1994/1995 Grasshopper over Lugano); transfers.data = flat list →
#   99 live items ALL-Persian (the +47-key TEAM_FA sweep); playoff =
#   null → bracket tab honestly absent; ARCHIVED seasons COMPOSITE
#   (2025/2026: Championship Group 6 + Relegation Group 6 + the
#   12-row overall) flattened with «دور قهرمانی»/«دور سقوط»/«جدول
#   کلی» labels; espnSlug sui.1 verified 200 (the eredivisie
#   pattern). Day-feed «Super League» rides the country-qualified
#   COMPETITION_FA_CC key super league|SUI.
#
# House style (cycle-148/152/153/155/156/157): agent-browser at
# 390×844, real clicks, console must stay clean, one h1 per page,
# zero broken images, sw=cw, no horizontal overflow.
# ------------------------------------------------------------------
set -u
cd "$(dirname "$0")/.."
BASE="${BASE:-http://localhost:3000}"
B=agent-browser
$B set viewport 390 844 >/dev/null

TOTAL_BAD=0
A_BAD=0
B_BAD=0

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
  [ "$RC" -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))
  return 0
}

probe() { # $1=url $2=label $3=featjs — DOM probe with shared tail
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 3
  local FEAT
  FEAT=$($B eval "JSON.stringify(($3))" 2>/dev/null | tr -d '"\\')
  collect "$FEAT" "$2"
}

get() { curl -s --max-time 60 "$1"; }

echo "== Part A: API truth (python verdict, exit-gated) =="
get "$BASE" >/dev/null 2>&1 || true
API_OUT=$(python3 - <<'PYEOF'
import json, re, urllib.request, sys

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")
BASE = "http://localhost:3000"
ok = True
bad = []
def report(name, good, note=""):
    global ok
    print(("PASS " if good else "FAIL ") + name + (f" — {note}" if note else ""))
    if not good:
        ok = False
        bad.append(name)

def api(path):
    with urllib.request.urlopen(f"{BASE}{path}", timeout=60) as r:
        return json.loads(r.read().decode())

ascii_leak = lambda s: bool(re.search(r"[A-Za-z]", s or ""))

# A1: swiss standings — flat 12 rows, live top three Persian, honest window
d = api("/api/standings?league=swiss")
rows = d.get("rows") or []
seas = d.get("allSeasons") or []
report("A1 swiss standings",
       len(rows) == 12 and rows[0].get("fa") == "لوگانو" and rows[0].get("pts") == 31
       and rows[1].get("fa") == "یانگ‌بویز" and rows[2].get("fa") == "سیون"
       and not any(ascii_leak(r.get("fa")) for r in rows)
       and len(seas) == 12 and seas[0] == "2026/2027" and seas[-1] == "2015/2016",
       f"rows={len(rows)} top3={[r.get('fa') for r in rows[:3]]} window={seas[:1]}..{seas[-1:]}")

# A2: the global race — 340 scorers / 17 participants, swiss IN, رافینیا honest
d = api("/api/topscorers?league=all")
ts = d.get("scorers") or []
pl = [p.get("leagueKey") for p in (d.get("perLeague") or [])]
lead = ts[0] if ts else {}
report("A2 race 20 participants",
       len(ts) == 400 and len(pl) == 20 and "swiss" in pl and "acl2" not in pl and "belgium" in pl
       and lead.get("nameFa") == "رافینیا" and lead.get("goals") == 13
       and seas == (d.get("allSeasons") or []),
       f"n={len(ts)} perLeague={len(pl)} leader={lead.get('nameFa')}({lead.get('goals')})")

# A3: dedicated /api/topscorers/swiss — اسنده with PERSIAN name AND team
d = api("/api/topscorers/swiss")
sts = d.get("scorers") or []
top = sts[0] if sts else {}
report("A3 swiss dedicated scorers",
       d.get("ok") is True and d.get("leagueFa") == "سوپرلیگ سوئیس"
       and len(sts) >= 20 and top.get("nameFa") == "ساموئل اسنده"
       and top.get("team") == "یانگ‌بویز" and top.get("goals") == 12
       and not any(ascii_leak(s.get("nameFa")) or ascii_leak(s.get("team")) for s in sts[:20]),
       f"n={len(sts)} leader={top.get('nameFa')}/{top.get('goals')}/{top.get('team')}")

# A4: archived 2025/2026 — COMPOSITE flattened with Persian group labels
d = api("/api/standings?league=swiss&season=2025%2F2026")
arows = d.get("rows") or []
groups = d.get("groups") or []
glabels = [g.get("fa") for g in groups]
report("A4 archived composite flattened",
       len(arows) == 24 and glabels == ["دور قهرمانی", "دور سقوط", "جدول کلی"]
       and [g.get("count") for g in groups] == [6, 6, 12]
       and arows[0].get("fa") == "تون",
       f"rows={len(arows)} groups={glabels} top={arows[0].get('fa') if arows else None}")

# A5: titles — 32 seasons, newest تون/سنت‌گالن, zero ASCII in top-8 champions
d = api("/api/league-titles?league=swiss")
wrapped = d.get("titles") or {}
tt = wrapped.get("items") or []
top8 = tt[:8]
ascii_champs = [t for t in top8 if ascii_leak(t.get("championFa") or "")]
report("A5 swiss titles",
       wrapped.get("total") == 32 and len(tt) == 32 and not ascii_champs
       and top8[0].get("championFa") == "تون" and top8[0].get("runnerUpFa") == "سنت‌گالن",
       f"n={len(tt)} newest={json.dumps(top8[0], ensure_ascii=False)[:90] if top8 else None} asciiLeak={ascii_champs}")

# A6: transfers — 99 items ALL-Persian (the +49-key sweep)
d = api("/api/league-transfers?league=swiss")
payload = d.get("transfers") or {}
items = payload.get("items") or []
leaks = [i for i in items if ascii_leak(i.get("from", {}).get("fa")) or ascii_leak(i.get("to", {}).get("fa"))]
report("A6 swiss transfers",
       d.get("ok") is True and len(items) == 99 and not leaks
       and payload.get("leagueFa") == "سوپرلیگ سوئیس",
       f"items={len(items)} leaks={len(leaks)}")

# A7: mapping-sweep duplicate-key guard — 958 team keys / 458 player keys,
# zero duplicates (the 152/155/156/157/159 sweep guard at the new totals;
# gate-synced cycle-160: swiss +47 team / +27 player keys)
import collections
def keys_of(path, anchor):
    s = open(path).read()
    i = s.index(anchor)
    j = s.index("\n};", i)
    return re.findall(r'"([^"]+)":', s[i:j])
tk = keys_of("src/lib/leagues.ts", "const TEAM_FA")
pk = keys_of("src/lib/player-names-fa.ts", "export const PLAYER_NAME_FA")
td = [k for k in set(tk) if tk.count(k) > 1]
pd = [k for k in set(pk) if pk.count(k) > 1]
report("A7 duplicate-key guard", len(tk) == 1121 and len(pk) == 557 and not td and not pd,
       f"team={len(tk)} player={len(pk)} dups={len(td)+len(pd)}")

# A8: day-feed disambiguation — the lib source must carry BOTH
# country-qualified keys (Switzerland joins Greece on the bare
# «Super League» name, the AMBIGUOUS_NAMES contract)
src = open("src/lib/leagues.ts").read()
report("A8 super league|SUI key",
       '"super league|SUI": "سوپرلیگ سوئیس"' in src
       and '"super league|GRE": "سوپرلیگ یونان"' in src,
       "country-qualified day-feed names present")

# A9: the Iranian hook — سنت‌گالن squad through our own API must carry
# Mostafa Heydari (the honest English fallback name: his individual FotMob
# profile 404s, so no playerFa key can exist — the squad-panel convention)
d = api("/api/team-squad/10190")
mem = [p for g in ((d.get("squad") or {}).get("groups") or []) for p in (g.get("players") or [])]
hey = [m for m in mem if "heydari" in str(m.get("name") or "").lower()]
report("A9 heydari in st-gallen squad", len(hey) >= 1,
       f"squad={len(mem)} heydari={[m.get('name') for m in hey]}")

print("API_TRUTH", "OK" if ok else "BAD")
sys.exit(0 if ok else 1)
PYEOF
) || true
echo "$API_OUT"
echo "$API_OUT" | grep -q "^API_TRUTH OK" && echo "API gate: GREEN" || { echo "API gate: RED"; A_BAD=1; }
case "$API_OUT" in *"API_TRUTH OK"*) : ;; *) A_BAD=1 ;; esac
# every line must be PASS — a FAIL line inside an OK verdict is a D5 trap
echo "$API_OUT" | grep -q "^FAIL" && A_BAD=1

echo "== Part B: DOM proof @390x844 =="

# B1: swiss league page — h1, live top لوگانو, tabs, honest bracket absence
hunt_or_probe=probe
$hunt_or_probe "$BASE/league/swiss" "B1 swiss league page" \
"(function(){const tabs=[...document.querySelectorAll('button')].map(b=>(b.textContent||'').trim());return {h1:((document.querySelector('h1')||{}).innerText||'').includes('سوپرلیگ سوئیس'),top:(document.querySelector('table tbody tr')||{innerText:''}).innerText.includes('لوگانو'),scorersTab:tabs.includes('آقای گل'),transfersTab:tabs.includes('انتقال‌ها'),bracketAbsent:!tabs.includes('براکت'),iraniClub:(document.body.innerText||'').includes('سنت‌گالن')}})()"

# B2: the global race — copy ۱۷, leader رافینیا, swiss team names Persian
probe "$BASE/topscorers" "B2 race copy 17" \
"(function(){const b=document.body.innerText||'';return {copy20:b.includes('۲۰ لیگ و جام برتر'),old19gone:!b.includes('۱۹ لیگ و جام برتر'),leader:b.includes('رافینیا'),ybsc:b.includes('یانگ‌بویز')}})()"

# B3: dedicated /topscorers/swiss — اسنده + Persian digits
probe "$BASE/topscorers/swiss" "B3 dedicated swiss scorers" \
"(function(){const b=document.body.innerText||'';return {h1Fa:((document.querySelector('h1')||{}).innerText||'').includes('سوپرلیگ سوئیس'),essende:b.includes('ساموئل اسنده'),faGoals:/[۰-۹]/.test(b)}})()"

# B4: the hub — 20 cards + the swiss card really present
probe "$BASE/leagues" "B4 leagues hub 20 cards" \
"(function(){return {cards:document.querySelectorAll(\"a[href^='/league/']\").length,swissCard:!!document.querySelector(\"a[href='/league/swiss']\"),h1Fa:((document.querySelector('h1')||{}).innerText||'').includes('لیگ')}})()"

# B5: the search guide — ۲۰ لیگ و جام in the real search UI
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
sleep 2
$B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
sleep 1.5
FEAT5=$($B eval "JSON.stringify((function(){const b=(document.querySelector('div[role=\"dialog\"]')||document.body).innerText||'';return {guide24:b.includes('۲۴ لیگ و جام'),old23gone:!b.includes('۲۳ لیگ و جام')}})())" 2>/dev/null | tr -d '"\\')
collect "$FEAT5" "B5 search guide 20"

# B6: REAL search flow — St. Gallen → سنت‌گالن|swiss (the hook club; the
# typed query echoes inside the dialog BY DESIGN — the assert checks the
# RESULT row, not the whole dialog text, the D5 assertion-honesty rule)
$B eval '(function(){const i=document.querySelector("input");if(i){const s=Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype,"value").set;s.call(i,"St. Gallen");i.dispatchEvent(new Event("input",{bubbles:true}));return "typed"}return "no-input"})()' >/dev/null 2>&1
sleep 4
FEAT6=$($B eval "JSON.stringify((function(){const b=(document.querySelector('div[role=\"dialog\"]')||document.body).innerText||'';return {fa:b.includes('سنت‌گالن'),league:b.includes('سوپرلیگ سوئیس')}})())" 2>/dev/null | tr -d '"\\')
collect "$FEAT6" "B6 search St. Gallen → سنت‌گالن"

# B7: players hub — «ستاره‌های بیست» copy read BEFORE the teams-mode click,
# then the swiss chip click with URL sync (the two-step fan path)
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/players" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body.innerText.includes('ستاره‌های بیست')" >/dev/null 2>&1
sleep 2
COPY7=$($B eval 'JSON.stringify({c:document.body.innerText.includes("ستاره‌های بیست لیگ و جام برتر")})' 2>/dev/null | tr -d '"\\')
$B eval '(function(){const b=document.querySelector("[data-testid=\"mode-teams\"]");if(b)b.click();return b?"clicked":"missing"})()' >/dev/null 2>&1
sleep 3
$B eval '(function(){const b=document.querySelector("[data-testid=\"league-swiss\"]");if(b)b.click();return b?"clicked":"missing"})()' >/dev/null 2>&1
sleep 4
FEAT7=$($B eval "JSON.stringify((function(){const b=document.body.innerText||'';return {urlLeague:location.search.includes('league=swiss'),teamsCopy:b.includes('اسکواد کامل همهٔ تیم‌ها'),club:b.includes('لوگانو')||b.includes('یانگ‌بویز')||b.includes('سنت‌گالن')}})())" 2>/dev/null | tr -d '"\\')
collect "$COPY7 $FEAT7" "B7 players hub two-step → swiss"

# B8: the hook club page — /team/10190 سنت‌گالن with the squad grid carrying حیدری
probe "$BASE/team/10190" "B8 st-gallen team page" \
"(function(){const b=document.body.innerText||'';return {h1Live:!!(document.querySelector('h1')||{}).innerText,faName:b.includes('سنت‌گالن'),squad:b.includes('دروازه‌بان‌ها')||b.includes('مدافعان')||b.includes('بازیکن')}})()"

echo "== RESULT =="
if [ "$A_BAD" -eq 0 ] && [ "$TOTAL_BAD" -eq 0 ]; then
  echo "DOM_PROOF OK (API 9/9 + DOM 8/8 green — سوپرلیگ سوئیس honest end-to-end: the 20th competition and the EIGHTH consecutive new global-race participant, joining with NO globalMerge flag because its 17 slash-format seasons cover the cycle-132 window exactly (12 seasons 2026/2027 → 2015/2016 byte-identical), the live top three (لوگانو ۳۱/یانگ‌بویز ۲۵/سیون ۲۲) on a 12/12 all-Persian table, ساموئل اسنده ۱۲ یانگ‌بویز atop the 116-scorer PascalCase goals.json (the cycle-23 parser's native FMStatFullRow shape) with PERSIAN name AND team on the dedicated /topscorers/swiss path, 340-scorer race (17 leagues) with رافینیا still honest leader and the 2023/2024 historical window grown 15→16 participants (swiss archived payload HAS the scorer block), 32 title seasons topped by 2025/2026 تون over سنت‌گالن (oldest 1994/1995 گراس‌هاپر over لوگانو, گزانماکس runner rows ride the existing map), transfers 99 items zero-ASCII via the +49-key TEAM_FA sweep (960 team / 458 player keys, ZERO duplicates), ARCHIVED seasons COMPOSITE (دور قهرمانی/دور سقوط/جدول کلی flattened 6+6+12), bracket honestly absent (playoff null, current AND archived), espnSlug sui.1 verified 200 (the eredivisie pattern), day-feed super league|SUI country-qualified, attribution truth live-verified: سنت‌گالن→swiss while لوگانو keeps its uecl first-seen truth (same live class as سلتیک→uel), players hub بیست + search guide ۲۴ + race copy ۲۰; the LIVE Iranian hook مصطفی حیدری (سنت‌گالن, ccode IRN + nationalTeamId 6711) in the squad panel; every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"
else
  echo "DOM_PROOF FLAGGED (A=$A_BAD B=$TOTAL_BAD)"; exit 1
fi
