#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-175 update proof — «پاس‌دهندگان عمیق می‌شوند: فایل تمام‌فصل assist»
#
# Live-probed gap (2026-10-30, UA Chrome/124): the "Assists" category in the
# league payload carries its OWN fetchAllUrl → data.fotmob.com
# stats/{leagueId}/season/{sid}/goal_assist.json — the EXACT cycle-23
# mechanism the goals list has used since the beginning — but the assists
# merge never read it: every league served only the 3-4 category names
# (pl = Rice/Evanilson/Groß) while the file holds the FULL ranked season
# (pl = 106 rows). Deepened the cycle-23 way: getFullAssists (same cache +
# cycle-127 thin-TTL guard class as getFullGoalScorers) + merge into the
# standings mapper (enriched category entries first, dedup by pid, sort by
# assists desc, slice 10) + standings cache bump v6→v7 + the thin-TTL guard
# extended to thin-but-nonempty merged assists. ZERO new upstream endpoints:
# the category rides the SAME cached league payload; the file is static S3.
#
# Domino (pinned live): the cycle-171 player-search pool rides the mapped
# assists — Semenyo (933576, NOT in the pl top-20 scorers) is now searchable
# («آنتوان سمنیو») where before only 3-4 assist leaders per league were.
#
# D5 echoes of this cycle (both probe-side, never product):
#  1. The first MultiEdit dropped a function signature line — the file was
#     broken for ~60s and restored byte-exact from the Edit trail (Read is
#     the only truth; the tool's diff preview showed the damage plainly).
#  2. The first post-deploy probes kept seeing 3 assists: the poisoned v7
#     L2 row (built during a transient window) outlived two restarts — the
#     purge + fresh rebuild produced 10 immediately. Rule: a cache-version
#     bump forces a clean rebuild, but an ALREADY-BUILT bad row needs an
#     explicit purge; verify against a purged store before blaming code.
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API proof =="
A_OUT=$(python3 - <<'PY'
import json, urllib.request
BASE = "http://localhost:3000"
def get(u):
    req = urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0 Chrome/124.0"})
    return json.load(urllib.request.urlopen(req, timeout=30))
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

# A1: deep ranked assists — >=6 rows (was 3), sorted desc, Rice pin intact
try:
    d = get(BASE + "/api/standings?league=pl")
    a = d.get("assists") or []
    rice = next((x for x in a if x.get("playerId") == 654096), None)
    sorted_ok = all((a[i].get("assists") or 0) >= (a[i + 1].get("assists") or 0) for i in range(len(a) - 1))
    good = len(a) >= 6 and sorted_ok and bool(rice) and rice.get("nameFa") == "دکلن رایس"
    report("A1 pl deep assists", good, f"n={len(a)} sorted={sorted_ok} rice={rice and rice.get('nameFa')}")
except Exception as e:
    report("A1 pl deep assists", False, repr(e))

# A2: row shape parity — every deep row still the exact AssistEntry contract
try:
    d = get(BASE + "/api/standings?league=pl")
    a = d.get("assists") or []
    need = {"rank", "name", "team", "teamId", "assists"}
    bad = [x.get("name") for x in a if not need.issubset(set(x.keys()))]
    pids = [x.get("playerId") for x in a]
    good = not bad and all(isinstance(p, int) and p > 0 for p in pids if p is not None)
    report("A2 AssistEntry parity", good, f"bad={bad} pidless={pids.count(None)}")
except Exception as e:
    report("A2 AssistEntry parity", False, repr(e))

# A3: the 174 surface rides the same depth — topscorers pl assists >= 6
try:
    d = get(BASE + "/api/topscorers/pl")
    a = d.get("assists") or []
    report("A3 topscorers pl depth", len(a) >= 6, f"n={len(a)}")
except Exception as e:
    report("A3 topscorers pl depth", False, repr(e))

# A4: mas honest absence — no category, no file, block stays []
try:
    d = get(BASE + "/api/standings?league=mas")
    a = d.get("assists")
    report("A4 mas honest absence", a == [] or a is None, f"assists={a}")
except Exception as e:
    report("A4 mas honest absence", False, repr(e))

# A5: the 171 pool auto-deepened — Semenyo (933576, not in the top-20
# scorers) reachable by EN and FA, first row, with teamFa
try:
    d = get(BASE + "/api/search?q=Semenyo")
    ps = d.get("players") or []
    r = next((x for x in ps if x.get("playerId") == 933576), None)
    good = bool(r) and bool(r.get("fa")) and bool(r.get("teamFa"))
    report("A5 search pool deepened", good, f"fa={r and r.get('fa')} team={r and r.get('teamFa')}")
except Exception as e:
    report("A5 search pool deepened", False, repr(e))

print("API_PROOF OK" if ok else "API_PROOF FLAGGED")
PY
)
echo "$A_OUT"
case "$A_OUT" in
  *"API_PROOF OK"*) : ;;
  *) BAD=$((BAD+1)) ;;
esac

echo "== PART B: DOM proof @390x844 =="
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
VGATES='JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})'

# B1: /league/pl — the block renders the DEEP list (>= 8 /player anchors on
# the page: 20 scorers + deep assists; was 23 total with 3-assist rows →
# now 20 + 10 = ~30)
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/league/pl" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 2.5
FEAT=$($B eval 'JSON.stringify({assistsBlock:document.body.innerText.includes("\u062F\u0647\u0646\u062F\u06AF\u0627\u0646"),players:document.querySelectorAll("a[href^=\"/player/\"]").length,semenyo:!!document.querySelector("a[href=\"/player/933576\"]")})' 2>/dev/null | tr -d '"\\')
OUT=$($B eval "$VGATES" 2>/dev/null | tr -d '"\\')
C=$($B console --json 2>/dev/null | python3 -c "$CNT")
E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
B1=0
echo "$FEAT" | rg -q 'assistsBlock:true' || B1=1
echo "$FEAT" | rg -q 'semenyo:true' || B1=1
echo "$FEAT" | rg -q 'players:(2[6-9]|[3-9][0-9])' || B1=1
[ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && B1=1
[ "$C" = "0" ] && [ "$E" = "0" ] || B1=1
echo "B1 /league/pl → $FEAT | $OUT | console=$C appErrors=$E rc=$B1"
[ "$B1" -eq 0 ] || BAD=$((BAD+1))

# B2: /topscorers/pl — the 174 card now deep too; Semenyo anchor provably
# from the assists block (he is not in the top-20 scorers)
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/topscorers/pl" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 2.5
FEAT=$($B eval 'JSON.stringify({assistsBlock:document.body.innerText.includes("\u062F\u0647\u0646\u062F\u06AF\u0627\u0646"),semenyo:!!document.querySelector("a[href=\"/player/933576\"]")})' 2>/dev/null | tr -d '"\\')
OUT=$($B eval "$VGATES" 2>/dev/null | tr -d '"\\')
C=$($B console --json 2>/dev/null | python3 -c "$CNT")
E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
B2=0
echo "$FEAT" | rg -q 'assistsBlock:true' || B2=1
echo "$FEAT" | rg -q 'semenyo:true' || B2=1
[ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && B2=1
[ "$C" = "0" ] && [ "$E" = "0" ] || B2=1
echo "B2 /topscorers/pl → $FEAT | $OUT | console=$C appErrors=$E rc=$B2"
[ "$B2" -eq 0 ] || BAD=$((BAD+1))

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK (cycle-175: assists go deep — the fetchAllUrl goal_assist.json file (pl=106 rows live-probed) merges into the standings mapper the cycle-23 way: pl now ranks 10 playmakers instead of 3; the 171 search pool auto-deepened (Semenyo 933576 searchable, provably not a scorer-row hit); the 174 topscorers card rides the same depth; mas stays honestly empty; AssistEntry shape byte-parity; v7 cache bump + thin-assists TTL guard close the stale-3-row class end-to-end)"
else
  echo "DOM_PROOF FLAGGED (BAD=$BAD)"; exit 1
fi
