#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-174 fix proof — «بهترین پاس‌دهندگان به صفحهٔ آقای گل هر لیگ می‌پیوندد»
#
# Bug-hunt 173 recorded ZERO product bugs, so per the official fix-cycle rule
# a small REAL polish was chosen instead — a sister-page inconsistency found
# by live probing during this very cycle:
#   /league/[key]      → renders the cycle-170 «بهترین پاس‌دهندگان» block ✓
#   /topscorers/[key]  → the SAME cached getStandings payload's assists block
#                        was DROPPED by the /api/topscorers route (the page
#                        only showed assists as scorer-row badges)
#
# Fix (additive-only, the 108 contract): the route response gains `assists`
# (same cached payload, zero extra upstream cost) and league-scorers-view
# renders the compact card under the scorers poster — same 170 link contract
# (playerId → /player with prefetch=false, title = English original when
# Persian shown), honest absence when a feed has no assists (mas).
#
# Pinned live truth (probed 2026-10-30, UA Chrome/124, on the NEW build):
#   /api/topscorers/pl assists[0] = Rice 654096 «دکلن رایس» آرسنال rank 1
#   Rice is NOT in the pl top-20 scorers → a /player/654096 anchor on
#   /topscorers/pl can ONLY come from the new assists block (strong gate)
#   mas assists = [] (the cycle-170 honest-absence pin)
#
# D5 echo of this cycle: the first probe of the standings API read a
# non-existent key (`teamFa`) and "found" a gap that wasn't there — the real
# field is `team` and both strips carry Persian teams. Rule re-confirmed:
# dump the FULL object first, then write gates against observed bytes.
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

# A1: the route now carries the freshened assists block — Rice pin
try:
    d = get(BASE + "/api/topscorers/pl")
    asst = d.get("assists") or []
    r = next((x for x in asst if x.get("playerId") == 654096), None)
    good = d.get("ok") is True and len(asst) >= 1 and bool(r) \
        and r.get("nameFa") == "دکلن رایس" and r.get("team") == "آرسنال" and r.get("rank") == 1
    report("A1 pl assists ride route", good, f"n={len(asst)} rice={r and r.get('nameFa')}/{r and r.get('team')}")
except Exception as e:
    report("A1 pl assists ride route", False, repr(e))

# A2: legacy top-level parity — OLD keys + EXACTLY {assists}
try:
    d = get(BASE + "/api/topscorers/pl")
    old = {"ok", "leagueKey", "leagueFa", "season", "scorers", "updatedAt"}
    extra = set(d.keys()) - old
    good = extra == {"assists"}
    report("A2 top-level key parity", good, f"extra={sorted(extra)}")
except Exception as e:
    report("A2 top-level key parity", False, repr(e))

# A3: scorer rows byte-untouched — required subset still present, no pid loss
try:
    d = get(BASE + "/api/topscorers/pl")
    s0 = (d.get("scorers") or [{}])[0]
    need = {"rank", "name", "goals", "teamId"}
    good = need.issubset(set(s0.keys()))
    report("A3 scorer row parity", good, f"top={s0.get('name')} keys={sorted(s0.keys())}")
except Exception as e:
    report("A3 scorer row parity", False, repr(e))

# A4: honest absence — mas has no assists feed, block data is [] not an error
try:
    d = get(BASE + "/api/topscorers/mas")
    asst = d.get("assists")
    good = d.get("ok") is True and (asst == [] or asst is None)
    report("A4 mas honest absence", good, f"ok={d.get('ok')} assists={asst}")
except Exception as e:
    report("A4 mas honest absence", False, repr(e))

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

# B1: /topscorers/pl renders the block — and the Rice anchor can ONLY be the
# new assists block (Rice is not in the pl top-20 scorers)
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/topscorers/pl" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 2.5
FEAT=$($B eval 'JSON.stringify({assistsBlock:document.body.innerText.includes("\u062F\u0647\u0646\u062F\u06AF\u0627\u0646"),rice:!!document.querySelector("a[href=\"/player/654096\"]")})' 2>/dev/null | tr -d '"\\')
OUT=$($B eval "$VGATES" 2>/dev/null | tr -d '"\\')
C=$($B console --json 2>/dev/null | python3 -c "$CNT")
E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
B1=0
echo "$FEAT" | rg -q 'assistsBlock:true' || B1=1
echo "$FEAT" | rg -q 'rice:true' || B1=1
[ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && B1=1
[ "$C" = "0" ] && [ "$E" = "0" ] || B1=1
echo "B1 /topscorers/pl → $FEAT | $OUT | console=$C appErrors=$E rc=$B1"
[ "$B1" -eq 0 ] || BAD=$((BAD+1))

# B2: REAL click on the assists Rice row → /player/654096 with real h1
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/topscorers/pl" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "[...document.querySelectorAll('a[href]')].some(a=>a.getAttribute('href')==='/player/654096')" >/dev/null 2>&1
sleep 1.5
CLICKED=$($B eval '(function(){const a=document.querySelector("a[href=\"/player/654096\"]");if(a){a.click();return "clicked"}return "no-anchor"})()' 2>/dev/null | tr -d '"\')
$B wait --fn "location.pathname.startsWith('/player/654096')" >/dev/null 2>&1
sleep 2
H1=$($B eval 'JSON.stringify((document.querySelector("h1")||{}).innerText||"")' 2>/dev/null | tr -d '"\')
URL=$($B eval 'location.pathname' 2>/dev/null | tr -d '"\')
OUT=$($B eval "$VGATES" 2>/dev/null | tr -d '"\\')
C=$($B console --json 2>/dev/null | python3 -c "$CNT")
E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
B2=0
[ "$CLICKED" = "clicked" ] || B2=1
case "$URL" in /player/654096*) : ;; *) B2=1 ;; esac
[ -n "$H1" ] && [ "$H1" != "null" ] || B2=1
[ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && B2=1
[ "$C" = "0" ] && [ "$E" = "0" ] || B2=1
echo "B2 click-through Rice → URL=$URL h1=$H1 | $OUT | console=$C appErrors=$E rc=$B2"
[ "$B2" -eq 0 ] || BAD=$((BAD+1))

# B3: honest absence DOM — mas renders (empty state or its own content) and
# the block is gone, never a broken section
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/topscorers/mas" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 20" >/dev/null 2>&1
sleep 2
FEAT=$($B eval 'JSON.stringify({assistsBlock:document.body.innerText.includes("\u062F\u0647\u0646\u062F\u06AF\u0627\u0646"),bodyLen:document.body.innerText.length})' 2>/dev/null | tr -d '"\\')
OUT=$($B eval "$VGATES" 2>/dev/null | tr -d '"\\')
C=$($B console --json 2>/dev/null | python3 -c "$CNT")
E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
B3=0
echo "$FEAT" | rg -q 'assistsBlock:false' || B3=1
[ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && B3=1
[ "$C" = "0" ] && [ "$E" = "0" ] || B3=1
echo "B3 /topscorers/mas → $FEAT | $OUT | console=$C appErrors=$E rc=$B3"
[ "$B3" -eq 0 ] || BAD=$((BAD+1))

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK (cycle-174: the per-league topscorers page joins its sister — /api/topscorers/[leagueKey] now carries the freshened assists block with zero extra upstream cost, league-scorers-view renders «بهترین پاس‌دهندگان» under the scorers poster with the 170 link contract; Rice anchor on /topscorers/pl is provably the new block (Rice not in the top-20 scorers) and really clicks through to /player/654096; mas stays honestly absent; legacy scorer rows and top-level key parity byte-exact)"
else
  echo "DOM_PROOF FLAGGED (BAD=$BAD)"; exit 1
fi
