#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-216 update gate — «گل+پاس» (the combined-participation kings). The
# deep-file family (goals 23 / assists 175 / cards 50+185 / rating 210 /
# clean sheets 215) gains its SIXTH sibling: the league payload's "Goals +
# Assists" category carries its own fetchAllUrl → data.fotmob.com
# stats/{id}/season/{sid}/_goals_and_goal_assist.json (live-probed
# 2026-10-30: laliga season/38843 = 213 ranked rows, Raphinha 16, Yamal 14,
# Mbappé 13; pl season/36781 = 186 rows, Haaland 9 — the upstream's OWN
# combined ORDER, a genuinely different leaderboard than the goals one).
# The list merges on top of the category top-3 inside the SAME cached
# getStandings payload (cache v12 → v13, the additive-shape convention),
# the topscorers route drops it as a NEW additive field (the 108 rule) and
# the per-league topscorers page renders «گل+پاس» between assists and
# ratings. Integer values (StatValue 16.0 → 16 — the goals/assists
# convention, NOT the rating decimal one).
#
# A1 laliga gPlusA: exactly 10 rows, ranks 1..10 monotonic, values
#    non-increasing INTEGERS, top ≥ 8, every row named + Persian-honest
#    (nameFa) + team-fa + playerId > 0 (the 170 link contract)
# A2 additive contract on the SAME response: cleanSheets=10, ratings=10,
#    scorers=20 (the 215/210 blocks untouched)
# A3 the winner is a REAL live anchor: the rank-1 G+A equals the raw
#    category participant's value (Raphinha — the live-probed anchor;
#    structural equality, not a byte pin)
# A4 season-aware: season=2025/2026 serves its OWN finished list (Mbappé
#    30 / Yamal 27 era — live-probed 371 rows, season/27233) — non-empty,
#    selectedSeason echoes the request (the 55 marker)
# B1 DOM @390×844: the «گل+پاس» section renders ≥5 rows; the first row's
#    fa name == the same-moment API rank-1 nameFa; the value pill is plain
#    Persian digits WITHOUT dir=ltr (the integer convention)
# B2 the first row navigates: click → /player/{same-id-as-API} with the
#    profile h1 (real 170 navigation, not just href presence)
# B3 sister sections intact on the same page: آقای گلان poster +
#    بهترین پاس‌دهندگان + گل+پاس + برترین امتیازها + گل نخرده‌ها + کارت‌ها
#    (the 174/179/210/215 family untouched)
# LAT the warm contract: the topscorers route answers well inside 5s (the
#    G+A rows ride the SAME cached payload — zero extra upstream cost warm)
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

# warm the payloads once (the gate must not depend on leftover warmth).
# cycle-215 lesson (its gate's OWN first run): the FIRST bake after a cold
# deploy can carry the 3-row category fallback — the cold build dropped the
# deep-file fetch once and the cycle-127 thin-TTL guard re-probes after 90
# SECONDS. The gate therefore re-warms in a bounded loop instead of failing
# on the honest thin bake (self-heal live-verified in 215: 3 → 10 rows).
WARM_TRIES=0
WARM_OK=0
while [ "$WARM_TRIES" -lt 8 ]; do
  WARM_TRIES=$((WARM_TRIES+1))
  curl -s "$BASE/api/topscorers/laliga" -o /tmp/c216_laliga.json
  N=$(python3 -c "
import json
try:
    d=json.load(open('/tmp/c216_laliga.json'))
    print(len(d.get('gPlusA') or []) if d.get('ok') else 0)
except Exception: print(0)
")
  case "$N" in ''|*[!0-9]*) N=0;; esac
  [ "$N" -ge 5 ] && { WARM_OK=1; break; }
  sleep 20
done
curl -s "$BASE/api/topscorers/laliga?season=2025/2026" -o /tmp/c216_laliga_2526.json
python3 -c "
import json,sys
for f in ('/tmp/c216_laliga.json','/tmp/c216_laliga_2526.json'):
    d=json.load(open(f))
    assert d.get('ok') is True, f
" || { echo "TOPSCORERS WARMUP FAILED — aborting"; exit 1; }
[ "$WARM_OK" -eq 1 ] || { echo "G+A WARMUP STAYED THIN after $WARM_TRIES tries — aborting"; exit 1; }

echo "== PART A: API proof (4 gates) =="
A_OUT=$(python3 - <<'PY'
import json, urllib.request
BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

# A1: the deep G+A list — exactly 10, monotonic ranks, non-increasing
# integer values, top >= 8, every row named + Persian-honest + team + id
try:
    d = json.load(open('/tmp/c216_laliga.json'))
    r = d.get("gPlusA") or []
    ranks = [x.get("rank") for x in r]
    vals = [int(x.get("gPlusA") or 0) for x in r]
    good = (
        len(r) == 10
        and ranks == list(range(1, 11))
        and all(vals[i] >= vals[i+1] for i in range(len(vals)-1))
        and vals[0] >= 8
        and all(x.get("name") and x.get("nameFa") and x.get("team") and (x.get("playerId") or 0) > 0 for x in r)
    )
    report("A1 laliga gPlusA: 10 rows, ranks 1..10, non-increasing ints, top>=8, named+fa+team+id", good,
           f"n={len(r)} top={vals[0] if vals else None} r1_name={(r[0] or {}).get('name') if r else None}")
except Exception as e:
    report("A1 laliga gPlusA: 10 rows, ranks 1..10, non-increasing ints, top>=8, named+fa+team+id", False, repr(e))

# A2: the additive contract — the 215/210 blocks on the SAME response
try:
    d = json.load(open('/tmp/c216_laliga.json'))
    sc = d.get("scorers") or []
    cs = d.get("cleanSheets") or []
    rt = d.get("ratings") or []
    good = len(sc) == 20 and len(cs) == 10 and len(rt) == 10
    report("A2 additive contract: scorers=20 + cleanSheets=10 + ratings=10", good,
           f"scorers={len(sc)} cleanSheets={len(cs)} ratings={len(rt)}")
except Exception as e:
    report("A2 additive contract: scorers=20 + cleanSheets=10 + ratings=10", False, repr(e))

# A3: the winner is a REAL live anchor — the deep rank-1 equals the raw
# league payload's G+A category participant (structural, not a pin)
try:
    d = json.load(open('/tmp/c216_laliga.json'))
    r0 = (d.get("gPlusA") or [{}])[0]
    req = urllib.request.Request(
        "https://www.fotmob.com/api/data/leagues?id=87&ccode3=ESP&lang=en", headers=UA)
    raw = json.load(urllib.request.urlopen(req, timeout=15))
    cat = next((c for c in (raw.get("stats") or {}).get("players") or []
                if "goals + assists" in (c.get("header") or "").lower()), {})
    p = cat.get("participant") or {}
    live_name = p.get("name")
    live_val = p.get("value")
    if live_val is None:
        live_val = (p.get("stat") or {}).get("value")
    good = (live_name is not None and live_val is not None
            and r0.get("name") == live_name
            and abs(float(r0.get("gPlusA")) - float(live_val)) < 1e-9)
    report("A3 live anchor: rank-1 == raw category participant (name+value)", good,
           f"api={r0.get('name')}/{r0.get('gPlusA')} live={live_name}/{live_val}")
except Exception as e:
    report("A3 live anchor: rank-1 == raw category participant (name+value)", False, repr(e))

# A4: season-aware — 2025/2026 serves its OWN finished list (Mbappé 30 era,
# live-probed 371 rows, season/27233) and the payload's selectedSeason
# echoes the request
try:
    d = json.load(open('/tmp/c216_laliga_2526.json'))
    r = d.get("gPlusA") or []
    good = (len(r) > 0
            and d.get("selectedSeason") == "2025/2026"
            and (r[0] or {}).get("name") == "Kylian Mbappé"
            and int((r[0] or {}).get("gPlusA") or 0) >= 25)
    report("A4 season=2025/2026: own list + selectedSeason echo + frozen Mbappé anchor", good,
           f"n={len(r)} sel={d.get('selectedSeason')} r1={(r[0] or {}).get('name') if r else None}/{(r[0] or {}).get('gPlusA') if r else None}")
except Exception as e:
    report("A4 season=2025/2026: own list + selectedSeason echo + frozen Mbappé anchor", False, repr(e))

print("API_ALL_OK" if ok else "API_FLAGGED")
PY
)
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
  # cycle-211 lesson: the PWA service worker force-reloads the page ONCE
  # right after a deploy (~4-6s in) and its stale navigation cache can
  # even serve the WRONG document — the harness runs SW-free + cache-free
  # for determinism; the PRODUCT keeps its service worker untouched.
  $B eval "(async()=>{try{const rs=await navigator.serviceWorker.getRegistrations();for(const r of rs)await r.unregister();if(window.caches){const ks=await caches.keys();for(const k of ks)await caches.delete(k);}}catch(e){}return 1})()" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  # actively wait until the browser REALLY sits on the requested path
  local i P
  for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
    P=$($B eval "location.pathname" 2>/dev/null | tr -d '"\\')
    [ "$P" = "$1" ] && break
    sleep 1
  done
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  # cycle-211 lesson: wait out the SW force-reload window (~6.5s) —
  # performance.now() resets on reload, so passing 6.5s proves THIS
  # context already survived it.
  $B wait --fn "performance.now() > 6500" >/dev/null 2>&1
  sleep 2
}
snap() { $B eval "JSON.stringify({$1})" 2>/dev/null | tr -d '"\\'; }
clean_ls() { $B eval "localStorage.clear()" >/dev/null 2>&1; }
# the G+A section is a CLIENT fetch after hydration — the first cold visit
# can still be on the skeleton when networkidle fires. Actively wait.
wait_rows() {
  local i N
  for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
    N=$($B eval "document.querySelectorAll('[data-testid=gpa-row]').length" 2>/dev/null | tr -d '"\\')
    case "${N:-0}" in ''|*[!0-9]*) N=0;; esac
    [ "${N:-0}" -ge 5 ] && return 0
    sleep 1
  done
  return 1
}
wait_path() {
  local i P
  for i in 1 2 3 4 5 6 7 8 9 10; do
    P=$($B eval "location.pathname" 2>/dev/null | tr -d '"\\')
    case "$P" in /player/*) return 0;; esac
    sleep 1
  done
  return 1
}
gate() {
  local label="$1" FEAT="$2" OUT C E RC=0
  OUT=$(snap 'sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length')
  C=$($B console --json 2>/dev/null | python3 -c "$CNT")
  E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
  [ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  echo "$label → $FEAT | $OUT | console=$C appErrors=$E rc=$RC"
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
}

# the same-moment API rank-1 fa name (the DOM must agree with the API NOW —
# the 202 lesson: same-instant comparison only)
API_FA=$(python3 -c "
import json
d=json.load(open('/tmp/c216_laliga.json'))
r=d.get('gPlusA') or []
print((r[0] or {}).get('nameFa') or '')
")
API_PID=$(python3 -c "
import json
d=json.load(open('/tmp/c216_laliga.json'))
r=d.get('gPlusA') or []
print((r[0] or {}).get('playerId') or 0)
")

# B1: the «گل+پاس» section — ≥5 rows, first row fa name == the same-moment
# API rank-1 nameFa, the value pill plain Persian digits WITHOUT dir=ltr
open_page "/topscorers/laliga"
clean_ls
wait_rows || echo "WARN: gpa rows never reached 5 (continuing with the honest snap)"
B1=$(snap "sec:!!document.querySelector('[data-testid=gpa-row]'),rows:document.querySelectorAll('[data-testid=gpa-row]').length,name0:((document.querySelector('[data-testid=gpa-row] a span.block,[data-testid=gpa-row] span.block'))||{textContent:''}).textContent,pill:((document.querySelector('[data-testid=gpa-row] span[class*=\"min-w-[36px]\"]'))||{textContent:''}).textContent,pillDir:(document.querySelector('[data-testid=gpa-row] span[dir=ltr]')||{getAttribute:()=>''}).getAttribute('dir')")
B1R=0
echo "$B1" | rg -q "sec:true" || B1R=1
echo "$B1" | rg -q "rows:([5-9]|10)" || B1R=1
echo "$B1" | rg -q "name0:${API_FA}" || B1R=1
echo "$B1" | rg -q "pillDir:ltr" && B1R=1
echo "$B1" | rg -q 'pill:[‌-￿]*[۰-۹]+[,}]' || B1R=1
[ "$B1R" -eq 0 ] || BAD=$((BAD+1))
gate "B1 G+A section: >=5 rows + same-moment fa name + Persian integer pill (no dir=ltr)" "$B1"

# B2: the first row REALLY navigates — click → /player/{same-id-as-API}
# with the profile h1 (the 170 contract, real navigation)
NAV=$($B eval "(function(){const a=document.querySelector('[data-testid=gpa-row] a');if(!a)return 'nolink';const h=a.getAttribute('href')||'';a.click();return h;})()" 2>/dev/null | tr -d '"\\')
$B wait --load networkidle >/dev/null 2>&1
wait_path || true
sleep 1
B2=$(snap "path:location.pathname,h1:!!document.querySelector('h1'),h1t:(document.querySelector('h1')||{textContent:''}).textContent.slice(0,40)")
B2R=0
echo "$NAV" | rg -q "/player/${API_PID}" || B2R=1
echo "$B2" | rg -q "path:/player/${API_PID}" || B2R=1
echo "$B2" | rg -q "h1:true" || B2R=1
[ "$B2R" -eq 0 ] || BAD=$((BAD+1))
gate "B2 first row click → /player/$API_PID with profile h1" "nav=$NAV $B2"

# B3: the sister sections intact on the same page (the 174/179/210/215
# family untouched) — back to the scorers page and count the family
open_page "/topscorers/laliga"
clean_ls
wait_rows || true
B3=$(snap "h1:!!document.querySelector('h1'),h1t:(document.querySelector('h1')||{textContent:''}).textContent.slice(0,24),asst:[...document.querySelectorAll('h2')].some(x=>x.textContent.trim()==='بهترین پاس‌دهندگان'),gpa:[...document.querySelectorAll('h2')].some(x=>x.textContent.trim()==='گل+پاس'),rate:[...document.querySelectorAll('h2')].some(x=>x.textContent.trim()==='برترین امتیازها'),cs:[...document.querySelectorAll('h2')].some(x=>x.textContent.trim()==='گل نخرده‌ها'),cards:[...document.querySelectorAll('h2')].some(x=>x.textContent.trim()==='کارت‌ها')")
B3R=0
echo "$B3" | rg -q "h1:true" || B3R=1
echo "$B3" | rg -q "آقای گلان" || B3R=1
echo "$B3" | rg -q "asst:true" || B3R=1
echo "$B3" | rg -q "gpa:true" || B3R=1
echo "$B3" | rg -q "rate:true" || B3R=1
echo "$B3" | rg -q "cs:true" || B3R=1
echo "$B3" | rg -q "cards:true" || B3R=1
[ "$B3R" -eq 0 ] || BAD=$((BAD+1))
gate "B3 sister family intact: گلان + پاس‌دهندگان + گل+پاس + امتیازها + گل نخرده‌ها + کارت‌ها" "$B3"

echo "== LAT: the warm topscorers route answers well inside 5s =="
LAT_MS=$(curl -s -o /dev/null -w '%{time_total}' "$BASE/api/topscorers/laliga" | python3 -c "import sys; print(int(float(sys.stdin.read())*1000))")
LAT_OK=0
[ "$LAT_MS" -lt 5000 ] && LAT_OK=1
[ "$LAT_OK" -eq 1 ] || BAD=$((BAD+1))
echo "LAT warm /api/topscorers/laliga = ${LAT_MS}ms (contract <5000ms) ok=$LAT_OK (1=good)"

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "CYCLE216 DOMPROOF ALL GREEN («گل+پاس» — the deep-file family's sixth sibling, the upstream's OWN combined order: 10-row integer G+A on the SAME cached payload, live anchor + season-aware, the 174/179/210/215 family untouched, the 170 navigation real — API 4/4 + DOM 3/3 + LAT @390x844)"
else
  echo "CYCLE216 DOMPROOF FAILURES: $BAD"
  exit 1
fi
