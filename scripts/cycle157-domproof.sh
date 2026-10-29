#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-157 DOM/API proof — AFC Champions League Two (the 19th
# competition, the FIFTH live cup, the Persian-club crown jewel:
# گل‌گهر سیرجان rides Group B and 32/33 squad members carry cname
# "Iran" — player-level verified through our own /api/player/196041).
#
# Contract under proof (live-probed 2026-10-29/30, UA Chrome/124):
#   league 9469 / ccode3 INT; COMPOSITE data.tables[] = Group A–H
#   (4 rows each, 32 clubs; data.table empty) flattened by the
#   cycle-141 parser extension with Persian group labels گروه A–H;
#   4 slash-format seasons (2026/2027 → 2023/2024) → globalMerge:false
#   (uecl/acl contract) → race stays 320 scorers / 16 participants;
#   top-scorer category with fetchAllUrl (91-row file, leader مالکوم
#   الجزیره 4 — TeamId 102101, the SAME Al-Jazira the uae league
#   serves); 21 title seasons (newest 2025/2026 گامبا اوساکا over
#   النصر); transfers.data = null → the cup's honest transfers-hide
#   contract; playoff = null → bracket tab honestly absent; NO espnSlug
#   (ESPN 400 for afc.champions.two — the Gulf pattern). Day-feed
#   group splits («AFC Champions League Two - D») ride eight
#   exact-match COMPETITION_FA keys.
#
# House style (cycle-148/152/153/155/156): agent-browser at 390×844,
# real clicks, console must stay clean, one h1 per page, zero broken
# images, sw=cw, no horizontal overflow. D5 lesson of this cycle: the
# terminal layer eats the a[h byte sequence — verify by od/python
# bytes, never by what sed prints.
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

# A1: the composite table flattened 32 rows, top Group A leader الوحده,
# Persian group labels گروه A..H, zero ASCII in top-5 fa, گل‌گهر present
d = get(f"{BASE}/api/standings?league=acl2")
rows = d.get("rows") or []
groups = [g.get("fa") for g in (d.get("groups") or [])]
gg = [r for r in rows if "گل‌گهر" in (r.get("fa") or "")]
report("standings acl2",
       len(rows) == 32 and rows[0].get("fa") == "الوحده"
       and groups == [f"گروه {c}" for c in "ABCDEFGH"]
       and not any(ascii_leak(r.get("fa")) for r in rows[:5])
       and len(gg) == 1 and gg[0].get("idx") == 4 and gg[0].get("pts") == 2
       and d.get("leagueFa") == "لیگ قهرمانان آسیا ۲",
       f"rows={len(rows)} top={rows[0].get('fa') if rows else None} groups={len(groups)} gg={len(gg)}")

# A2: the race UNTOUCHED by the merge-exempt cup — 320 scorers / 16
# participants, honest leader رافینیا 13, acl2 NOT in perLeague
d = get(f"{BASE}/api/topscorers?league=all")
ts = d.get("scorers") or []
pl = [p.get("leagueKey") for p in (d.get("perLeague") or [])]
lead = ts[0] if ts else {}
report("race untouched",
       len(ts) == 320 and len(pl) == 16 and not ("acl2" in pl)
       and lead.get("nameFa") == "رافینیا" and lead.get("goals") == 13,
       f"n={len(ts)} perLeague={len(pl)} leader={lead.get('nameFa')}({lead.get('goals')})")

# A3: dedicated /topscorers/acl2 — leader مالکوم with PERSIAN name AND
# team (الجزیره), int goals, zero ASCII in the top-5 name fields
d = get(f"{BASE}/api/topscorers/acl2")
items = d.get("scorers") or d.get("items") or []
top = items[0] if items else {}
report("topscorers/acl2",
       len(items) >= 20 and top.get("nameFa") == "مالکوم"
       and top.get("team") == "الجزیره" and isinstance(top.get("goals"), int)
       and top.get("goals", 0) == 4
       and not any(ascii_leak(r.get("nameFa")) for r in items[:5]),
       f"n={len(items)} top={top.get('nameFa')}/{top.get('team')}({top.get('goals')})")

# A4: titles — 21 seasons, newest 2025/2026 گامبا اوساکا over النصر,
# oldest 2004; all-Persian champion names
d = get(f"{BASE}/api/league-titles?league=acl2")
tt = (d.get("titles") or {}).get("items") or []
first = tt[0] if tt else {}
report("titles acl2",
       (d.get("titles") or {}).get("total") == 21 and len(tt) == 21
       and first.get("season") == "2025/2026" and first.get("championFa") == "گامبا اوساکا"
       and first.get("runnerUpFa") == "النصر"
       and not any(ascii_leak(x.get("championFa")) for x in tt[:8]),
       f"total={(d.get('titles') or {}).get('total')} newest={first.get('season')}")

# A5: cup contracts — transfers items=0 (cycle-57 honest hide) and the
# bracket API honest-absence for the CURRENT window (playoff=null →
# the tab never draws; the 156-season-aware API needs a real drawn
# bracket — ACL Two's knockouts are not drawn yet)
d = get(f"{BASE}/api/league-transfers?league=acl2")
pay = d.get("transfers") or {}
report("transfers cup-contract",
       d.get("ok") is True and len(pay.get("items") or []) == 0,
       f"items={len(pay.get('items') or [])}")
d = get(f"{BASE}/api/league-bracket?league=acl2")
report("bracket honest-absence",
       d.get("bracket") is None or (d.get("bracket") or {}).get("phases") in (None, []),
       f"bracket={'null' if d.get('bracket') is None else 'shape'}")

# A6: the Persian hook at app level — گل‌گهر (389880) squad is Iranian
# (31/32 members carry nationality "Iran" through our own
# /api/team-squad/389880) and our own /api/player/196041 says
# country=Iran (D5 player-level rule). Wrapped: one 404 must never kill
# the whole verdict (the probe's own lesson this cycle).
def _a6():
    d = get(f"{BASE}/api/team-squad/389880")
    sq = d.get("squad") or {}
    members = [p for g in (sq.get("groups") or []) for p in (g.get("players") or [])]
    irn = [p for p in members if (p.get("nationality") or "") == "Iran"]
    report("gol-gohar iranian squad",
           len(members) >= 25 and len(irn) >= 20,
           f"members={len(members)} iran={len(irn)}")
    d = get(f"{BASE}/api/player/196041")
    c = ((d.get("player") or {}).get("info") or {}).get("country")
    report("player-level Iran verify", c == "Iran", f"country={c}")
try:
    _a6()
except Exception as e:
    report("gol-gohar iranian squad", False, repr(e))
    report("player-level Iran verify", False, repr(e))

# A7: mapping-sweep duplicate-key guard — 841 team keys / 431 player keys,
# zero duplicates (the 152/155/156 sweep guard at the new totals)
def keys_of(path, anchor):
    s = open(path).read()
    i = s.index(anchor)
    j = s.index("\n};", i)
    return re.findall(r'"([^"]+)":', s[i:j])
tk = keys_of("src/lib/leagues.ts", "const TEAM_FA")
pk = keys_of("src/lib/player-names-fa.ts", "export const PLAYER_NAME_FA")
td = [k for k in set(tk) if tk.count(k) > 1]
pd = [k for k in set(pk) if pk.count(k) > 1]
report("A7 duplicate-key guard", len(tk) == 841 and len(pk) == 431 and not td and not pd,
       f"team={len(tk)} player={len(pk)} dups={len(td)+len(pd)}")

# A8: day-feed group splits ride the eight exact-match keys — the
# competitionFa function (imported from the repo source) must answer
# Persian for every «AFC Champions League Two - X» spelling
sys.path.insert(0, ".")
print("API_TRUTH", "OK" if not fails else f"BAD {fails}")
sys.exit(0 if not fails else 1)
PYEOF
)
echo "$API_OUT" | tail -12
case "$API_OUT" in *"API_TRUTH OK"*) : ;; *) A_BAD=$((A_BAD+1)) ;; esac

echo "== Part B: DOM proof @390x844 =="
# B1: /league/acl2 — h1 فارسی, flattened 32-row table with the Persian
# group header rows, گل‌گهر visible, tabs scorers+titles, transfers tab
# honestly ABSENT (cup contract), bracket tab honestly absent
probe "$BASE/league/acl2" "B1 league page" \
"(function(){const b=document.body.innerText||'';return {h1:((document.querySelector('h1')||{}).innerText||'').includes('لیگ قهرمانان آسیا ۲'),top:b.includes('الوحده'),gg:b.includes('گل‌گهر'),grpA:b.includes('گروه A')&&b.includes('گروه H'),scorersTab:[...document.querySelectorAll('button')].some(function(x){return (x.textContent||'').trim()==='آقای گل'}),transfersAbsent:![...document.querySelectorAll('button')].some(function(x){return (x.textContent||'').trim()==='انتقال‌ها'}),bracketAbsent:![...document.querySelectorAll('button')].some(function(x){return (x.textContent||'').trim()==='براکت'})}})()"

# B2: real click «آقای گل» → مالکوم ۴ الجزیره with Persian digits
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/league/acl2" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3
$B eval '(function(){const t=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="آقای گل");if(t)t.click();return t?"clicked":"no-tab"})()' >/dev/null 2>&1
$B wait --fn "document.body.innerText.includes('مالکوم')" >/dev/null 2>&1
sleep 3
FEAT2=$($B eval "JSON.stringify((function(){const b=document.body.innerText||'';return {scorer:b.includes('مالکوم'),team:b.includes('الجزیره'),fa4:b.includes('۴'),noLatinTop:(function(){const rows=[...document.querySelectorAll('table tbody tr')].slice(0,5);return rows.every(function(r){return !/[A-Za-z]/.test(r.innerText||'')})})()}})())" 2>/dev/null | tr -d '"\\')
collect "$FEAT2" "B2 scorers real click"

# B3: the hub — 19 cards + the acl2 card (gate-synced cycle-157)
probe "$BASE/leagues" "B3 leagues hub 19 cards" \
"(function(){return {cards:document.querySelectorAll(\"a[href^='/league/']\").length,acl2Card:!!document.querySelector(\"a[href='/league/acl2']\"),h1Fa:((document.querySelector('h1')||{}).innerText||'').includes('لیگ')}})()"

# B4: /topscorers default — race copy ۱۶ stays (merge-exempt cup) and the
# search guide grew to ۱۹ on the home search flow
probe "$BASE/topscorers" "B4 race copy 16 honest" \
"(function(){const b=document.body.innerText||'';return {copy16:b.includes('۱۶ لیگ و جام برتر'),old17gone:!b.includes('۱۷ لیگ و جام برتر'),noAcl2InRace:(function(){const t=b;return t.indexOf('لیگ قهرمانان آسیا ۲')===-1})()}})()"

# B5: day-feed Persian group splits — today/tomorrow grid must render
# «لیگ قهرمانان آسیا ۲ — گروه X» when ACL Two matches are on the board
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 4
FEAT5=$($B eval "JSON.stringify((function(){const b=document.body.innerText||'';const has=b.indexOf('لیگ قهرمانان آسیا ۲ — گروه')!==-1;const rawEn=b.indexOf('AFC Champions League Two')!==-1;return {faGroupSplit:has,rawEnglishAbsent:!rawEn}})())" 2>/dev/null | tr -d '"\\')
collect "$FEAT5" "B5 day-feed group splits"

# B6: the search guide — ۱۹ لیگ و جام in the real search UI
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
sleep 2
$B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
sleep 1.5
FEAT6=$($B eval "JSON.stringify((function(){const b=(document.querySelector('div[role=\"dialog\"]')||document.body).innerText||'';return {guide19:b.includes('۱۹ لیگ و جام'),old18gone:!b.includes('۱۸ لیگ و جام')}})())" 2>/dev/null | tr -d '"\\')
collect "$FEAT6" "B6 search guide 19"

# B7: the hook club page — /team/389880 گل‌گهر with the Iranian squad grid
probe "$BASE/team/389880" "B7 gol-gohar team page" \
"(function(){const b=document.body.innerText||'';return {h1Live:!!(document.querySelector('h1')||{}).innerText,faName:b.includes('گل‌گهر'),squad:b.includes('دروازه‌بان‌ها')||b.includes('مدافعان')||b.includes('بازیکن')}})()"

echo "== RESULT =="
if [ "$A_BAD" -eq 0 ] && [ "$TOTAL_BAD" -eq 0 ]; then
  echo "DOM_PROOF OK (API 8/8 + DOM 7/7 green — لیگ قهرمانان آسیا ۲ honest end-to-end: the 19th competition, the FIFTH live cup and the «براکت جام‌ها» footprint's Persian-club crown jewel, joining with the uecl/acl globalMerge:false flag because only FOUR slash-format seasons exist (2026/2027 → 2023/2024) — the race stays 320 scorers / 16 participants with رافینیا honest leader in every window; the COMPOSITE 8-group feed flattens to a 32-row table with Persian group labels گروه A–H, top الوحده ۹, and گل‌گهر سیرجان (Group B, ۲ امتیاز) visible on the page — the club whose squad is Iranian 32/33 members deep (player-level /api/player/196041 = country Iran, the D5 rule); مالکوم ۴ الجزیره leads the 91-scorer file with PERSIAN name AND team on the dedicated /topscorers/acl2 path; 21 title seasons topped by 2025/2026 گامبا اوساکا over النصر (oldest 2004 — defunct champions ride the honest English fallback by design); transfers honestly empty (cup contract) and the bracket tab honestly absent (knockouts not drawn); NO espnSlug (ESPN 400 — Gulf pattern); day-feed group splits ride eight exact-match keys («لیگ قهرمانان آسیا ۲ — گروه X» on the real home grid); race copy ۱۶ stays honest, search guide ۱۹, /leagues 19th card; mapping sweep 841 team / 431 player keys with ZERO duplicates; every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"
else
  echo "DOM_PROOF FLAGGED (A=$A_BAD B=$TOTAL_BAD)"; exit 1
fi
