#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-184 fix — /api/topscorers stops silently mis-serving ?league=
#
# The recorded cycle-183 probe lesson turned product fix: the league is a
# PATH segment on this API family (/api/topscorers/[leagueKey]) — but a
# query-param request /api/topscorers?league=belgium used to return the
# GLOBAL merge with HTTP 200 (leagueFa=None was the only tell). The fix:
# an honest 400 pointing at the correct path form, byte-style with the
# route's own season guard (cycle-132/55).
#
# Pinned live truth (probed 2026-10-30 ~09:0x +08, UA Chrome/124,
# official start from the cycle-183 build):
#   /api/topscorers?league=belgium     BEFORE: 200 global merge (wrong);
#                                      AFTER: 400, error names the path form
#   /api/topscorers?league=pl&season=… 400 (league guard precedes season)
#   /api/topscorers?league=            400 (empty value is still present)
#   /api/topscorers                    200 scorers=400 perLeague=20
#                                      sel=2026/2027 all=12
#                                      extra=={assists,cards,selectedSeason,
#                                      allSeasons} (the 174/179/180 parity)
#   /api/topscorers?season=2023/2024   200 scorers=380 s0 Kane «هری کین»
#                                      بایرن‌مونیخ 36g pid=194165;
#                                      cards ABSENT (the 132 rule untouched)
#   /api/topscorers?season=nonsense    400 (the 132/55 guard intact)
#   /api/topscorers?bogus=1            200 (unknown params still ignored)
#   /api/topscorers/belgium            200 leagueFa «لیگ بلژیک» Eckert
#                                      892709 in rows (path form unaffected)
#   /topscorers (DOM)                  «مسابقه پاس گل» + «آقای کارت» blocks
#   /topscorers?league=belgium (DOM)   the PAGE's designed UI-filter deep
#                                      link keeps working (client-side only,
#                                      dedicated-link appears) — proof the
#                                      API guard touched nothing on the page
#   /topscorers?season=2023/2024 (DOM) Kane /player/194165 anchor
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API gates (8) =="
A_OUT=$(python3 - <<'PY'
import json, urllib.request, urllib.error
BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}
def get(u):
    req = urllib.request.Request(u, headers=UA)
    return json.load(urllib.request.urlopen(req, timeout=30))
def code_body(u):
    req = urllib.request.Request(u, headers=UA)
    try:
        r = urllib.request.urlopen(req, timeout=30)
        return r.getcode(), json.load(r)
    except urllib.error.HTTPError as e:
        return e.code, json.load(e)
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

# A1: THE FIX — query-param league on the global route → honest 400
c, d = code_body(BASE + "/api/topscorers?league=belgium")
err = d.get("error", "") if isinstance(d, dict) else ""
good = c == 400 and d.get("ok") is False and "path segment" in err \
    and "/api/topscorers/belgium" in err
report("A1 ?league=belgium -> 400+path-hint", good, f"code={c} err={err[:70]!r}")

# A2: league guard PRECEDES season handling (the primary mistake first)
c, d = code_body(BASE + "/api/topscorers?league=pl&season=2024%2F2025")
err = d.get("error", "") if isinstance(d, dict) else ""
good = c == 400 and "league" in err and "Invalid season" not in err
report("A2 ?league=pl&season -> 400 league-first", good, f"code={c} err={err[:70]!r}")

# A3: empty value is still a present param → 400
c, d = code_body(BASE + "/api/topscorers?league=")
good = c == 400 and d.get("ok") is False
report("A3 ?league= (empty) -> 400", good, f"code={c}")

# A4: plain global race — byte-untouched behavior (the 174/179/180 parity)
d = get(BASE + "/api/topscorers")
old = {"ok", "scorers", "perLeague", "updatedAt"}
extra = set(d.keys()) - old
s0 = (d.get("scorers") or [{}])[0]
good = extra == {"assists", "cards", "selectedSeason", "allSeasons"} \
    and len(d.get("scorers") or []) == 400 \
    and len(d.get("perLeague") or []) == 20 \
    and d.get("selectedSeason") == "2026/2027" \
    and len(d.get("allSeasons") or []) == 12 \
    and s0.get("playerId") == 696679
report("A4 plain race parity", good,
       f"extra={sorted(extra)} n={len(d.get('scorers') or [])} s0={s0.get('playerId')}")

# A5: historical season unchanged — Kane anchor + cards ABSENT (132 rule)
d = get(BASE + "/api/topscorers?season=2023%2F2024")
s0 = (d.get("scorers") or [{}])[0]
good = d.get("ok") is True and len(d.get("scorers") or []) == 380 \
    and s0.get("playerId") == 194165 and s0.get("goals") == 36 \
    and "cards" not in d
report("A5 hist 2023/2024 Kane+no-cards", good,
       f"n={len(d.get('scorers') or [])} s0={s0.get('playerId')}/{s0.get('goals')}")

# A6: the 132/55 season guard intact
c, d = code_body(BASE + "/api/topscorers?season=nonsense")
good = c == 400 and d.get("ok") is False
report("A6 bad season shape -> 400", good, f"code={c}")

# A7: unknown params still ignored (forward-compat unchanged)
c, d = code_body(BASE + "/api/topscorers?bogus=1")
good = c == 200 and d.get("ok") is True
report("A7 ?bogus=1 still 200", good, f"code={c}")

# A8: the PATH form unaffected — sister route with the 181 belgium pins
d = get(BASE + "/api/topscorers/belgium")
rows = d.get("scorers") or []
eck = [r for r in rows if r.get("playerId") == 892709]
good = d.get("ok") is True and d.get("leagueFa") == "لیگ بلژیک" \
    and len(rows) == 20 and len(eck) == 1
report("A8 path form /belgium intact", good,
       f"leagueFa={d.get('leagueFa')} n={len(rows)} eckert={len(eck)}")

print("API_ALL_OK" if ok else "API_BAD")
PY
) || BAD=$((BAD+1))
echo "$A_OUT"
echo "$A_OUT" | rg -q "API_ALL_OK" || BAD=$((BAD+1))

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
# D5 test-isolation (the cycle-181 lesson, gate-side): the league filter
# persists in localStorage (cycle-10 contract) — clear it on the currently
# open page BEFORE the next gate's mount reads it, and once up-front for
# leftovers from any prior run of this (or another) gate script.
clean_ls() { $B eval "localStorage.clear()" >/dev/null 2>&1; }
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

# B1: /topscorers plain — both deep blocks render (assists + cycle-50 cards)
# defensive pre-clean for leftovers from earlier runs of ANY gate script
open_page "/"
clean_ls
open_page "/topscorers"
# the cards block renders only when data && !loading — its presence means
# the full client fetch has landed; anchors then number in the hundreds
$B wait --fn "document.body.innerText.includes('آقای کارت')" >/dev/null 2>&1
sleep 1.5
FEAT=$(snap 'ass:document.body.innerText.includes("مسابقه پاس گل"),cards:document.body.innerText.includes("آقای کارت"),players:document.querySelectorAll("a[href^=\"/player/\"]").length')
B1=0
echo "$FEAT" | rg -q 'ass:true' || B1=1
echo "$FEAT" | rg -q 'cards:true' || B1=1
echo "$FEAT" | rg -q 'players:([3-9][0-9]{2,})' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 /topscorers blocks" "$FEAT"

# B2: the PAGE's designed ?league= deep link keeps working — the dedicated
# per-league link appears ONLY when the client-side filter is active; the
# URL keeps league=belgium (this UI param is never sent to the API)
open_page "/topscorers?league=belgium"
FEAT=$(snap 'ded:!!document.querySelector("a[href=\"/topscorers/belgium\"]"),chip:document.body.innerText.includes("لیگ بلژیک")')
URL=$($B eval 'decodeURIComponent(location.search)' 2>/dev/null | tr -d '"\\')
B2=0
echo "$FEAT" | rg -q 'ded:true' || B2=1
echo "$FEAT" | rg -q 'chip:true' || B2=1
echo "$URL" | grep -q "league=belgium" || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 page ?league= UI intact" "$FEAT | url=$URL"
clean_ls  # strip the belgium filter BEFORE B3's mount reads storage

# B3: the ?season= deep link end-to-end — historical race renders Kane
# (the season fetch is client-side AFTER hydration — wait for the anchor
# explicitly instead of trusting networkidle+sleep)
open_page "/topscorers?season=2023%2F2024"
$B wait --fn "!!document.querySelector('a[href=\"/player/194165\"]')" >/dev/null 2>&1
sleep 1.5
FEAT=$(snap 'kane:!!document.querySelector("a[href=\"/player/194165\"]"),selval:(document.querySelector("select")||{}).value||"none"')
B3=0
echo "$FEAT" | rg -q 'kane:true' || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 page ?season= deep link" "$FEAT"
clean_ls  # leave no filter state for whatever gate runs after this script

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK — cycle-184 fix proven (A 8/8 + B 3/3 @390x844)"
else
  echo "DOM_PROOF BAD=$BAD"
  exit 1
fi
