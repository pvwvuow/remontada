#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-173 bug-hunt — «گشت‌زنی پس از بازیابی سندباکس»
#
# Context (2026-10-30 ~05:22 +08:00): the sandbox was restored from an old
# snapshot (remontada tree back at the cycle-44 clone, .git missing every
# object after 52169b7, a stray scaffold next-server squatting :3000 with
# HTTP 500). PROTOCOL-recovery executed first: fresh clone of origin/main
# (= 02a8bff, the cycle-172 card) + bun install --frozen-lockfile + prisma
# db push (dev.db recreated empty) + prisma generate + bun run build +
# official scripts/start-remontada.sh (HTTP 200) + regression 28/28 with
# explicit BASE. FRESHNESS GATE = 1 verified.
#
# This hunt then patrols the recovery result at viewport 390x844 — the
# three newest feature surfaces must survive a from-scratch clone with an
# EMPTY L2 cache (cold upstream fetches, cold player index):
#   cycle-170  league «بهترین پاس‌دهندگان» block      → /league/pl DOM
#   cycle-171  assists joined the player search pool  → /api/search Rice
#   cycle-172  match timeline /player links           → /match/5749723
#
# Pinned live truth (probed 2026-10-30 on the recovered build, UA Chrome/124):
#   /api/search?q=رایس       → players[0] playerId 654096 fa «دکلن رایس»
#                               teamFa «آرسنال» rank 1 hl.fa [5,9]
#   /api/standings?league=pl → rows=20 (drifted from the old 18 — patrol
#                               asserts >=10, never exact live counts),
#                               assists=3, assist0 Rice 654096
#   /league/pl DOM           → h1 «پریمیرلیگ انگلیس», 23 /player anchors,
#                               «دهندگان» present (ZWNJ-safe substring)
#   match 5749723            → Frosinone 5-1 Lecce (finished, stable),
#                               6 goals all carrying playerId (cycle-172 pin)
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API truth (UA Chrome/124) =="
A_OUT=$(python3 - <<'PY'
import json, urllib.request
BASE = "http://localhost:3000"
def get(u):
    req = urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0 Chrome/124.0"})
    return json.load(urllib.request.urlopen(req, timeout=30))
def code(u):
    req = urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0 Chrome/124.0"})
    return urllib.request.urlopen(req, timeout=30).getcode()
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

# A1: page sweep — every main route 200 on the recovered clone
pages = ["/", "/leagues", "/league/pl", "/topscorers", "/topscorers/pl",
         "/news", "/player/654096", "/team/2182", "/match/5749723"]
bad = []
for p in pages:
    try:
        if code(BASE + p) != 200:
            bad.append(p)
    except Exception as e:
        bad.append(f"{p}({e.__class__.__name__})")
report("A1 pages 9x200", not bad, f"bad={bad}")

# A2: cycle-171 surface — assists in the search pool survive the cold rebuild
try:
    d = get(BASE + "/api/search?q=%D8%B1%D8%A7%DB%8C%D8%B3")
    ps = d.get("players") or []
    r = next((x for x in ps if x.get("playerId") == 654096), None)
    good = bool(r) and r.get("fa") == "دکلن رایس" and r.get("teamFa") == "آرسنال"
    report("A2 search Rice", good, f"pid={r and r.get('playerId')} fa={r and r.get('fa')}")
except Exception as e:
    report("A2 search Rice", False, repr(e))

# A3: cycle-170 surface — assists block rides the standings payload
try:
    d = get(BASE + "/api/standings?league=pl")
    rows = d.get("rows") or []
    assists = d.get("assists") or []
    good = len(rows) >= 10 and len(assists) >= 1 and all(
        isinstance(a.get("playerId"), int) and a["playerId"] > 0
        and (a.get("nameFa") or a.get("name")) for a in assists)
    report("A3 pl rows+assists", good, f"rows={len(rows)} assists={len(assists)}")
except Exception as e:
    report("A3 pl rows+assists", False, repr(e))

# A4: cycle-172 surface — timeline goal ids flow on the cold clone
try:
    d = get(BASE + "/api/match/5749723")
    ev = d.get("events") or []
    goals = [e for e in ev if e.get("type") == "Goal"]
    withpid = [g for g in goals if isinstance(g.get("playerId"), int) and g["playerId"] > 0]
    report("A4 match goal ids", len(goals) >= 4 and len(withpid) >= 4,
           f"goals={len(goals)} with_pid={len(withpid)}")
except Exception as e:
    report("A4 match goal ids", False, repr(e))

print("HUNT_API OK" if ok else "HUNT_API FLAGGED")
PY
)
echo "$A_OUT"
case "$A_OUT" in
  *"HUNT_API OK"*) : ;;
  *) BAD=$((BAD+1)) ;;
esac

echo "== PART B: DOM patrol @390x844 (agent-browser, console must stay 0) =="
B=agent-browser
$B set viewport 390 844 >/dev/null
VGATES='JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})'
CNT='import json,sys
try:
  d=json.load(sys.stdin); print(len(d["data"]["messages"]))
except Exception: print("ERR")'
ECNT='import json,sys
try:
  d=json.load(sys.stdin); es=d["data"]["errors"]
  print(len([e for e in es if e.get("url")]))
except Exception: print("ERR")'

patrol_open() {
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$BASE$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 2.5
}

# B1: home — renders with a populated anchor network
patrol_open "/"
FEAT=$($B eval 'JSON.stringify({anchors:document.querySelectorAll("a[href]").length})' 2>/dev/null | tr -d '"\\')
OUT=$($B eval "$VGATES" 2>/dev/null | tr -d '"\\')
C=$($B console --json 2>/dev/null | python3 -c "$CNT")
E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
B1=0
echo "$FEAT" | rg -q 'anchors:([1-9][0-9])' || B1=1
[ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && B1=1
[ "$C" = "0" ] && [ "$E" = "0" ] || B1=1
echo "B1 home → $FEAT | $OUT | console=$C appErrors=$E rc=$B1"
[ "$B1" -eq 0 ] || BAD=$((BAD+1))

# B2: /league/pl — cycle-170 assists block live in DOM (ZWNJ-safe substring)
patrol_open "/league/pl"
FEAT=$($B eval 'JSON.stringify({assistsBlock:document.body.innerText.includes("\u062F\u0647\u0646\u062F\u06AF\u0627\u0646"),players:document.querySelectorAll("a[href^=\"/player/\"]").length})' 2>/dev/null | tr -d '"\\')
OUT=$($B eval "$VGATES" 2>/dev/null | tr -d '"\\')
C=$($B console --json 2>/dev/null | python3 -c "$CNT")
E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
B2=0
echo "$FEAT" | rg -q 'assistsBlock:true' || B2=1
echo "$FEAT" | rg -q 'players:[1-9][0-9]' || B2=1
[ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && B2=1
[ "$C" = "0" ] && [ "$E" = "0" ] || B2=1
echo "B2 /league/pl → $FEAT | $OUT | console=$C appErrors=$E rc=$B2"
[ "$B2" -eq 0 ] || BAD=$((BAD+1))

# B3: /match/5749723 — cycle-172 timeline /player network live
patrol_open "/match/5749723"
FEAT=$($B eval 'JSON.stringify({players:document.querySelectorAll("a[href^=\"/player/\"]").length})' 2>/dev/null | tr -d '"\\')
OUT=$($B eval "$VGATES" 2>/dev/null | tr -d '"\\')
C=$($B console --json 2>/dev/null | python3 -c "$CNT")
E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
B3=0
echo "$FEAT" | rg -q 'players:[1-9][0-9]' || B3=1
[ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && B3=1
[ "$C" = "0" ] && [ "$E" = "0" ] || B3=1
echo "B3 /match/5749723 → $FEAT | $OUT | console=$C appErrors=$E rc=$B3"
[ "$B3" -eq 0 ] || BAD=$((BAD+1))

# B4: /player/654096 — Rice profile h1 real
patrol_open "/player/654096"
H1=$($B eval 'JSON.stringify((document.querySelector("h1")||{}).innerText||"")' 2>/dev/null | tr -d '"\\')
OUT=$($B eval "$VGATES" 2>/dev/null | tr -d '"\\')
C=$($B console --json 2>/dev/null | python3 -c "$CNT")
E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
B4=0
[ -n "$H1" ] && [ "$H1" != "null" ] || B4=1
[ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && B4=1
[ "$C" = "0" ] && [ "$E" = "0" ] || B4=1
echo "B4 /player/654096 → h1=$H1 | $OUT | console=$C appErrors=$E rc=$B4"
[ "$B4" -eq 0 ] || BAD=$((BAD+1))

# B5: /team/2182 — team page intact
patrol_open "/team/2182"
FEAT=$($B eval 'JSON.stringify({anchors:document.querySelectorAll("a[href]").length})' 2>/dev/null | tr -d '"\\')
OUT=$($B eval "$VGATES" 2>/dev/null | tr -d '"\\')
C=$($B console --json 2>/dev/null | python3 -c "$CNT")
E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
B5=0
echo "$FEAT" | rg -q 'anchors:([1-9][0-9])' || B5=1
[ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && B5=1
[ "$C" = "0" ] && [ "$E" = "0" ] || B5=1
echo "B5 /team/2182 → $FEAT | $OUT | console=$C appErrors=$E rc=$B5"
[ "$B5" -eq 0 ] || BAD=$((BAD+1))

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "HUNT OK (cycle-173: post-recovery patrol — 9 pages 200, search-pool assists / standings assists block / timeline player links all alive on a cold from-scratch clone, 5 DOM surfaces clean at 390x844 with console=0 appErrors=0; product bugs = 0)"
else
  echo "HUNT FLAGGED (BAD=$BAD)"; exit 1
fi
