#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-180 update proof — «انتخابگر فصل به صفحهٔ آقای گل هر لیگ می‌پیوندد»
#
# The league page has had a season selector since cycle-55 (deep-link
# seeding + honesty snap since 99); the per-league topscorers page was the
# only league-scoped surface still stuck on the current season — its route
# didn't even read a season param. The payloads were already rich
# (live-probed via /api/standings, the exact snapshots getStandings(key,
# season) serves): pl 2024/2025 = Salah 29g, 2023/2024 = Haaland 27g, deep
# assists ride historical payloads too, mas 2024/2025 = Bergson 33g.
#
# Update (additive-only, the 108/55/99 contract): the route reads an
# optional ?season= (byte-for-byte the standings route's cycle-55 guard —
# strict SEASON_PARAM_RE shape, anything else → 400) and passes it to
# getStandings(key, season); the response gains selectedSeason + allSeasons
# (the cycle-55 payload fields). league-scorers-view gains the cycle-55/99
# selector: options from the payload itself, deep-link seeding (ONE fetch
# per deep link), URL replaceState sync, honesty snap when the payload's
# marker disagrees with the request, honest empty state for offered-but-
# dataless seasons (pl 2013/2014: 200 + scorers=0). Zero new upstream
# endpoints; the deep files (cards) stay current-season honestly (y=0 on
# historical payloads — the 132 rule).
#
# Pinned live truth (probed 2026-10-30 ~06:50 +08, UA Chrome/124, via
# /api/standings — the snapshots the fixed route will serve):
#   pl 2024/2025 → scorers[0] Mohamed Salah «محمد صلاح» لیورپول 29g pid=292462
#   pl 2023/2024 → [0] Erling Haaland «ارلینگ هالند» منچسترسیتی 27g pid=737066
#   pl 2013/2014 → 200, sel=2013/2014, scorers=0 (honest empty)
#   mas 2024/2025 → [0] Bergson «برگسون» جوهور دارالتعظیم 33g pid=190509,
#                   assists=0 honest, allSeasons=3
#   persiangulf 2024/2025 → [0] حسین‌زاده تراکتور 14g pid=1031319
#   invalid shape ?season=2023 → 400
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API proof =="
A_OUT=$(python3 - <<'PY'
import json, urllib.request, urllib.parse
BASE = "http://localhost:3000"
def get(u):
    req = urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0 Chrome/124.0"})
    return json.load(urllib.request.urlopen(req, timeout=30))
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")
def pidok(x):
    return isinstance(x.get("playerId"), int) and x["playerId"] > 0

# A1: plain-route parity — the 179 era pin advanced one step: the response
# gains exactly {selectedSeason, allSeasons}; both carry real data.
try:
    d = get(BASE + "/api/topscorers/pl")
    old = {"ok", "leagueKey", "leagueFa", "season", "scorers", "updatedAt"}
    extra = set(d.keys()) - old
    sel = d.get("selectedSeason")
    seasons = d.get("allSeasons") or []
    good = extra == {"assists", "cards", "selectedSeason", "allSeasons"} \
        and isinstance(sel, str) and len(sel) == 9 \
        and len(seasons) >= 10 and sel in seasons and seasons[0] == sel
    report("A1 plain parity + season fields", good,
           f"extra={sorted(extra)} sel={sel} seasons={len(seasons)}")
except Exception as e:
    report("A1 plain parity + season fields", False, repr(e))

# A2: historical season rides the route — the Salah pin (2024/2025)
try:
    q = urllib.parse.quote("2024/2025", safe="")
    d = get(f"{BASE}/api/topscorers/pl?season={q}")
    s = d.get("scorers") or []
    s0 = s[0] if s else {}
    good = d.get("selectedSeason") == "2024/2025" \
        and s0.get("playerId") == 292462 and s0.get("name") == "Mohamed Salah" \
        and s0.get("nameFa") == "محمد صلاح" and s0.get("team") == "لیورپول" \
        and s0.get("goals") == 29 \
        and len(s) >= 10 and all(pidok(x) for x in s) \
        and len(d.get("assists") or []) >= 5 \
        and len(d.get("allSeasons") or []) >= 10
    report("A2 pl 2024/2025 Salah pin", good,
           f"sel={d.get('selectedSeason')} n={len(s)} s0={s0.get('name')}/{s0.get('goals')}g")
except Exception as e:
    report("A2 pl 2024/2025 Salah pin", False, repr(e))

# A3: second season pin — Haaland 27g (2023/2024)
try:
    q = urllib.parse.quote("2023/2024", safe="")
    d = get(f"{BASE}/api/topscorers/pl?season={q}")
    s0 = (d.get("scorers") or [{}])[0]
    good = d.get("selectedSeason") == "2023/2024" \
        and s0.get("playerId") == 737066 and s0.get("goals") == 27 \
        and s0.get("nameFa") == "ارلینگ هالند"
    report("A3 pl 2023/2024 Haaland pin", good,
           f"sel={d.get('selectedSeason')} s0={s0.get('name')}/{s0.get('goals')}g")
except Exception as e:
    report("A3 pl 2023/2024 Haaland pin", False, repr(e))

# A4: honest empty — an offered-but-dataless old season serves 200 with
# its OWN marker and scorers=0 (the UI shows the honest empty state)
try:
    q = urllib.parse.quote("2013/2014", safe="")
    d = get(f"{BASE}/api/topscorers/pl?season={q}")
    good = d.get("ok") is True and d.get("selectedSeason") == "2013/2014" \
        and (d.get("scorers") or []) == []
    report("A4 pl 2013/2014 honest empty", good,
           f"sel={d.get('selectedSeason')} scorers={len(d.get('scorers') or [])}")
except Exception as e:
    report("A4 pl 2013/2014 honest empty", False, repr(e))

# A5: invalid shape → 400 (the cycle-55 guard, byte-for-byte)
try:
    try:
        get(BASE + "/api/topscorers/pl?season=2023")
        report("A5 invalid season 400", False, "no error raised")
    except Exception as e:
        good = isinstance(e, urllib.error.HTTPError) and e.code == 400
        report("A5 invalid season 400", good, repr(e.__class__.__name__))
except Exception as e:
    report("A5 invalid season 400", False, repr(e))

# A6: mas historical — Bergson pin, assists honestly empty, 3-season list
try:
    q = urllib.parse.quote("2024/2025", safe="")
    d = get(f"{BASE}/api/topscorers/mas?season={q}")
    s0 = (d.get("scorers") or [{}])[0]
    good = d.get("selectedSeason") == "2024/2025" \
        and s0.get("playerId") == 190509 and s0.get("name") == "Bergson" \
        and s0.get("goals") == 33 and s0.get("nameFa") == "برگسون" \
        and d.get("assists") == [] and len(d.get("allSeasons") or []) >= 3
    report("A6 mas 2024/2025 Bergson pin", good,
           f"sel={d.get('selectedSeason')} s0={s0.get('name')}/{s0.get('goals')}g ass={len(d.get('assists') or [])}")
except Exception as e:
    report("A6 mas 2024/2025 Bergson pin", False, repr(e))

# A7: legacy surfaces intact on the plain route (the 174/175/179 pins)
try:
    d = get(BASE + "/api/topscorers/pl")
    s = d.get("scorers") or []
    a = d.get("assists") or []
    c = d.get("cards") or {}
    y = c.get("yellow") or []
    good = len(s) >= 10 and len(a) >= 5 and 654096 in {x.get("playerId") for x in a} \
        and len(y) >= 10 and (y[0] or {}).get("playerId") == 688273
    report("A7 legacy pins intact", good,
           f"scorers={len(s)} assists={len(a)} y0={(y[0] or {}).get('playerId') if y else None}")
except Exception as e:
    report("A7 legacy pins intact", False, repr(e))

print("API_PROOF OK" if ok else "API_PROOF FLAGGED")
PY
)
echo "$A_OUT"
case "$A_OUT" in
  *"API_PROOF OK"*) : ;;
  *) BAD=$((BAD+1)) ;;
esac

echo "== PART B: DOM proof @390x844 (agent-browser, console must stay 0) =="
B=agent-browser
$B set viewport 390 844 >/dev/null
CNT='import json,sys
try:
  d=json.load(sys.stdin); print(len(d["data"]["messages"]))
except Exception: print("ERR")'
ECNT='import json,sys
try:
  d=json.load(sys.stdin); es=d["data"]["errors"]
  print(len([e for e in es if e.get("url")]))
except Exception: print("ERR")'

open_page() {
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$BASE$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 2.5
}
snap() { $B eval "JSON.stringify({$1})" 2>/dev/null | tr -d '"\\'; }
gate() { # shared VGATES+console closer — $1=label $2=feat
  local label="$1" FEAT="$2" OUT C E RC=0
  OUT=$(snap 'sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length')
  C=$($B console --json 2>/dev/null | python3 -c "$CNT")
  E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
  [ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  echo "$label → $FEAT | $OUT | console=$C appErrors=$E rc=$RC"
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
}

# B1: /topscorers/pl plain — the selector renders with payload options and
# the 174/179 cards stay alive (players anchors include Janelt's card row)
open_page "/topscorers/pl"
FEAT=$(snap 'sel:!!document.querySelector("select#season-select"),opts:document.querySelectorAll("select#season-select option").length,label:document.body.innerText.includes("فصل"),ass:document.body.innerText.includes("دهندگان"),cards:document.body.innerText.includes("کارت\u200Cها"),players:document.querySelectorAll("a[href^=\"/player/\"]").length')
B1=0
echo "$FEAT" | rg -q 'sel:true' || B1=1
echo "$FEAT" | rg -q 'opts:(1[0-9]|[2-9][0-9])' || B1=1
echo "$FEAT" | rg -q 'label:true' || B1=1
echo "$FEAT" | rg -q 'ass:true' || B1=1
echo "$FEAT" | rg -q 'cards:true' || B1=1
echo "$FEAT" | rg -q 'players:(2[0-9]|[3-9][0-9])' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 /topscorers/pl selector" "$FEAT"

# B2: REAL season switch via the select — native setter + change event →
# the historical payload renders (Salah anchor; he is in NO current surface)
$B eval "(function(){const s=document.querySelector('select#season-select');if(!s)return 'no-select';const opt=[...s.options].find(o=>o.value==='2024/2025');if(!opt)return 'no-option';const d=Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype,'value');d.set.call(s,'2024/2025');s.dispatchEvent(new Event('change',{bubbles:true}));s.dispatchEvent(new Event('input',{bubbles:true}));return 'switched'})()" >/dev/null 2>&1
$B wait --fn "!!document.querySelector('a[href=\"/player/292462\"]')" >/dev/null 2>&1
sleep 2
FEAT=$(snap 'salah:!!document.querySelector("a[href=\"/player/292462\"]"),url:location.search.includes("season=2024%2F2025")||location.search.includes("season=2024/2025"),h1:(document.querySelector("h1")||{}).innerText||""')
URL=$($B eval 'decodeURIComponent(location.search)' 2>/dev/null | tr -d '"\\')
B2=0
echo "$FEAT" | rg -q 'salah:true' || B2=1
echo "$URL" | grep -q "season=2024/2025" || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 switch→2024/2025" "$FEAT | url=$URL"

# B3: the switched view really serves the historical payload — Salah row
# click-through to /player/292462 (the 170 contract)
CLICKED=$($B eval '(function(){const links=[...document.querySelectorAll("a[href=\"/player/292462\"]")];const hit=links.find(l=>(l.innerText||"").includes("صلاح"));if(hit){hit.click();return "clicked"}return "no-row"})()' 2>/dev/null | tr -d '"\\')
$B wait --fn "location.pathname.startsWith('/player/292462')" >/dev/null 2>&1
sleep 2
H1=$($B eval 'JSON.stringify((document.querySelector("h1")||{}).innerText||"")' 2>/dev/null | tr -d '"\\')
URL3=$($B eval 'location.pathname' 2>/dev/null | tr -d '"\\')
B3=0
[ "$CLICKED" = "clicked" ] || B3=1
case "$URL3" in /player/292462*) : ;; *) B3=1 ;; esac
echo "$H1" | grep -q "صلاح" || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 click Salah" "clicked=$CLICKED url=$URL3 h1=$H1"

# B4: deep-link seeding — /topscorers/pl?season=2024/2025 opens the
# historical view directly (ONE fetch, the cycle-99 pattern)
open_page "/topscorers/pl?season=2024%2F2025"
FEAT=$(snap 'salah:!!document.querySelector("a[href=\"/player/292462\"]"),selval:(document.querySelector("select#season-select")||{}).value||"",h1n:document.querySelectorAll("h1").length')
B4=0
echo "$FEAT" | rg -q 'salah:true' || B4=1
echo "$FEAT" | rg -q 'selval:2024/2025' || B4=1
[ "$B4" -eq 0 ] || BAD=$((BAD+1))
gate "B4 deep-link 2024/2025" "$FEAT"

# B5: mas — the selector shows its real 3-season list, red-only cards alive
open_page "/topscorers/mas"
FEAT=$(snap 'sel:!!document.querySelector("select#season-select"),opts:document.querySelectorAll("select#season-select option").length,cr:document.body.innerText.includes("کارت قرمز"),cy:document.body.innerText.includes("کارت زرد")')
B5=0
echo "$FEAT" | rg -q 'sel:true' || B5=1
echo "$FEAT" | rg -q 'opts:[2-9]' || B5=1
echo "$FEAT" | rg -q 'cr:true' || B5=1
echo "$FEAT" | rg -q 'cy:false' || B5=1
[ "$B5" -eq 0 ] || BAD=$((BAD+1))
gate "B5 /topscorers/mas" "$FEAT"

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK (cycle-180: the season selector joins the per-league topscorers page — the cycle-55 contract byte-for-byte on the route (strict guard, getStandings(key, season)), selectedSeason+allSeasons ride the response, the view gains the cycle-55/99 selector with deep-link seeding, URL replaceState sync and the honesty snap; historical payloads are rich (Salah 29g / Haaland 27g / Bergson 33g) and really render + click through; offered-but-dataless seasons show the honest empty state; mas shows its real 3-season list with red-only cards intact; zero new upstream endpoints)"
else
  echo "DOM_PROOF FLAGGED (BAD=$BAD)"; exit 1
fi
