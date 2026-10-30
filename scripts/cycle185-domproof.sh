#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-185 update — the cards deep block follows the requested season
# («قانون ۱۳۲ فقط برای merge سراسری»)
#
# The cycle-132 rule declared historical card deep blocks current-only.
# Live-probing the historical raws (UA Chrome/124) disproved the upstream
# half of that claim: each season's own raw carries its OWN card
# fetchAllUrls (2023/2024 pl raw → stats/47/season/20720/yellow_card.json
# = 438 rows Palhinha 13 / red_card.json = 55 rows Bissouma 2) — reachable
# data the season-blind fetch + the build-site gate dropped. cycle-185
# threads the optional season into getLeagueCardLeaders (the cycle-124/175
# move, third and last member), lifts the build-site gate, bumps the
# standings namespace v8→v9 and extends the cycle-127 end-to-end guard to
# a MISSING cards block (the build-time transient bake incident, proven by
# the v9 purge-retest: same build healthy once warm — Janelt y15/r14).
#
# Pinned live truth (probed 2026-10-30 ~10:0x +08, official start):
#   /api/standings?league=pl&season=2023/2024  cards PRESENT y15[João
#                       Palhinha/13/pid524434] r15[Yves Bissouma/2/pid724306]
#   /api/standings?league=pl (current)         y15[Vitaly Janelt/4/pid688273]
#                       r14[.../1/pid688273] — the 176 pin byte-identical
#   /api/topscorers/pl?season=2024/2025        y15[Flynn Downes/12/pid844943]
#                       r15[Bruno Fernandes/2/pid422685]
#   /api/topscorers/belgium?season=2023/2024   y15[Hannes van der
#                       Bruggen/12/pid232299] r15[Christopher Bonsu
#                       Baah/3/pid1452385]
#   /api/topscorers/pl (current)               y15/r14 Janelt (179 intact)
#   /api/topscorers/mas (current)              y0/r8 Fazly Mazlan 694010
#                       (red-only structural — the 178 honesty, unchanged)
#   /api/topscorers?season=2023/2024 (GLOBAL)  cards ABSENT — the 132 rule
#                       SURVIVES for the global merge (Layer 2 untouched;
#                       the scope boundary is documented, not an accident)
#   /api/topscorers?season=bogus               400 (132/55 guard intact)
#   /api/topscorers?league=pl                  400 (the 184 league guard)
#   /league/pl?season=2023/2024 (DOM)          «کارت‌ها» block + Palhinha
#                       anchor — first time on a historical league page
#   /topscorers/pl?season=2024/2025 (DOM)      «کارت‌ها» + Downes anchor
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
    return json.load(urllib.request.urlopen(req, timeout=60))
def code(u):
    req = urllib.request.Request(u, headers=UA)
    try:
        return urllib.request.urlopen(req, timeout=60).getcode()
    except urllib.error.HTTPError as e:
        return e.code
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")
def cardhead(d):
    c = d.get("cards")
    if not c: return None
    y = c.get("yellow") or []; r = c.get("red") or []
    return (y[0] if y else None, len(y), r[0] if r else None, len(r))

# A1: THE FEATURE — historical standings carry the season's own card kings
d = get(BASE + "/api/standings?league=pl&season=2023%2F2024")
h = cardhead(d)
y0, yn, r0, rn = h if h else (None, 0, None, 0)
good = d.get("ok") is True and h is not None \
    and y0 and y0.get("name") == "João Palhinha" and y0.get("value") == 13 \
    and y0.get("playerId") == 524434 and yn == 15 \
    and r0 and r0.get("name") == "Yves Bissouma" and r0.get("value") == 2 \
    and r0.get("playerId") == 724306
report("A1 hist standings cards", good,
       f"y{yn}[{y0 and y0.get('name')}/{y0 and y0.get('value')}] r{rn}[{r0 and r0.get('name')}/{r0 and r0.get('value')}]")

# A2: current standings — the 176 surface byte-identical (Janelt y15/r14)
d = get(BASE + "/api/standings?league=pl")
h = cardhead(d)
y0, yn, r0, rn = h if h else (None, 0, None, 0)
good = h is not None and y0 and y0.get("name") == "Vitaly Janelt" \
    and y0.get("value") == 4 and y0.get("playerId") == 688273 and yn == 15 and rn == 14
report("A2 current standings cards intact", good,
       f"y{yn}[{y0 and y0.get('name')}/{y0 and y0.get('value')}] r{rn}")

# A3: historical topscorers/pl 2024/2025 — the 179 block joins the season
d = get(BASE + "/api/topscorers/pl?season=2024%2F2025")
h = cardhead(d)
y0, yn, r0, rn = h if h else (None, 0, None, 0)
good = d.get("ok") is True and h is not None \
    and y0 and y0.get("name") == "Flynn Downes" and y0.get("value") == 12 \
    and y0.get("playerId") == 844943 \
    and r0 and r0.get("name") == "Bruno Fernandes" and r0.get("value") == 2 \
    and r0.get("playerId") == 422685
report("A3 topscorers/pl hist cards", good,
       f"y{yn}[{y0 and y0.get('name')}] r{rn}[{r0 and r0.get('name')}]")

# A4: historical topscorers/belgium 2023/2024 — the 181 league joins too
d = get(BASE + "/api/topscorers/belgium?season=2023%2F2024")
h = cardhead(d)
y0, yn, r0, rn = h if h else (None, 0, None, 0)
good = d.get("ok") is True and h is not None \
    and y0 and y0.get("name") == "Hannes van der Bruggen" and y0.get("value") == 12 \
    and y0.get("playerId") == 232299 \
    and r0 and r0.get("name") == "Christopher Bonsu Baah" and r0.get("value") == 3 \
    and r0.get("playerId") == 1452385
report("A4 topscorers/belgium hist cards", good,
       f"y{yn}[{y0 and y0.get('name')}] r{rn}[{r0 and r0.get('name')}]")

# A5: current topscorers/pl — the 179 surface intact
d = get(BASE + "/api/topscorers/pl")
h = cardhead(d)
y0, yn, r0, rn = h if h else (None, 0, None, 0)
good = h is not None and y0 and y0.get("playerId") == 688273 and yn == 15 and rn == 14
report("A5 topscorers/pl current intact", good, f"y{yn} r{rn} y0={y0 and y0.get('playerId')}")

# A6: mas current — red-only structural honesty (178) unchanged
d = get(BASE + "/api/topscorers/mas")
c = d.get("cards")
y = (c or {}).get("yellow") or []; r = (c or {}).get("red") or []
r0 = r[0] if r else {}
good = c is not None and len(y) == 0 and len(r) == 8 \
    and r0.get("playerId") == 694010
report("A6 mas red-only intact", good, f"y{len(y)} r{len(r)} r0={r0.get('playerId')}")

# A7: THE SCOPE BOUNDARY — the global historical merge still omits cards
# (Layer 2 untouched by design; the 132 rule now lives ONLY here)
d = get(BASE + "/api/topscorers?season=2023%2F2024")
s0 = (d.get("scorers") or [{}])[0]
good = d.get("ok") is True and len(d.get("scorers") or []) == 380 \
    and s0.get("playerId") == 194165 and "cards" not in d
report("A7 global hist cards still absent", good,
       f"n={len(d.get('scorers') or [])} s0={s0.get('playerId')} cards={'cards' in d}")

# A8: the 132/55 season guard + the 184 league guard both intact
c1 = code(BASE + "/api/topscorers?season=nonsense")
c2 = code(BASE + "/api/topscorers?league=pl")
good = c1 == 400 and c2 == 400
report("A8 season+league guards intact", good, f"season={c1} league={c2}")

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
# D5 test-isolation (the cycle-184 lesson): clear localStorage between gates
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

# defensive pre-clean (the 184 lesson: leftovers from ANY earlier gate run)
open_page "/"
clean_ls

# B1: /league/pl?season=2023/2024 — the 176 block renders on a HISTORICAL
# league page for the first time; the Palhinha anchor is the file's top row
open_page "/league/pl?season=2023%2F2024"
$B wait --fn "document.body.innerText.includes('کارت\u200Cها')" >/dev/null 2>&1
sleep 1.5
FEAT=$(snap 'cards:document.body.innerText.includes("کارت\u200Cها"),palhinha:!!document.querySelector("a[href=\"/player/524434\"]"),sel:(document.querySelector("select#season-select")||{}).value||""')
B1=0
echo "$FEAT" | rg -q 'cards:true' || B1=1
echo "$FEAT" | rg -q 'palhinha:true' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 /league/pl hist cards block" "$FEAT"
clean_ls

# B2: /topscorers/pl?season=2024/2025 — the 179 block historical: Downes
open_page "/topscorers/pl?season=2024%2F2025"
$B wait --fn "!!document.querySelector('a[href=\"/player/844943\"]')" >/dev/null 2>&1
sleep 1.5
FEAT=$(snap 'cards:document.body.innerText.includes("کارت\u200Cها"),downes:!!document.querySelector("a[href=\"/player/844943\"]"),salah:!!document.querySelector("a[href=\"/player/292462\"]"),selval:(document.querySelector("select#season-select")||{}).value||""')
B2=0
echo "$FEAT" | rg -q 'cards:true' || B2=1
echo "$FEAT" | rg -q 'downes:true' || B2=1
echo "$FEAT" | rg -q 'salah:true' || B2=1
echo "$FEAT" | rg -q 'selval:2024/2025' || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 /topscorers/pl hist cards" "$FEAT"
clean_ls

# B3: REAL click on the historical yellow row (Downes) → /player/844943
# with the mapped h1 (the 167/170 link contract on HISTORICAL rows)
open_page "/topscorers/pl?season=2024%2F2025"
$B wait --fn "!!document.querySelector('a[href=\"/player/844943\"]')" >/dev/null 2>&1
sleep 1
$B eval "(function(){const a=document.querySelector('a[href=\"/player/844943\"]');if(!a)return 'no-link';a.click();return 'clicked'})()" >/dev/null 2>&1
$B wait --fn "location.pathname === '/player/844943'" >/dev/null 2>&1
sleep 2
FEAT=$(snap 'path:location.pathname==="player/844943"||location.pathname,h1:(document.querySelector("h1")||{}).textContent||""')
URL=$($B eval 'location.pathname' 2>/dev/null | tr -d '"\\')
B3=0
echo "$URL" | grep -q "player/844943" || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 click hist card row → /player/844943" "$FEAT | url=$URL"
clean_ls

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK — cycle-185 update proven (A 8/8 + B 3/3 @390x844)"
else
  echo "DOM_PROOF BAD=$BAD"
  exit 1
fi
