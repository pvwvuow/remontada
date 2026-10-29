#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-172 update proof — «تایم‌لاین مسابقه به شبکهٔ پروفایل‌ها می‌پیوندد»
#
# Live-probed gap (2026-10-30, old build + upstream /api/data/matchDetails,
# UA Chrome/124): the events/scorers/shootout mapper kept NAMES but dropped
# every upstream player id — while the upstream payload carries them all:
#   Goal event    → player {id: 1670272, name: 'Matteo Cichella'} +
#                   assistPlayerId: 1523327 (Farès Ghedjemis)
#   Substitution  → swap: [{name:'Amar Fatah', id:'1311977'}, …] (STRING ids)
#   Shootout      → same player ref shape
# So the match timeline, the scorers strip and the shootout card were the
# LAST dead-name surfaces on the match page (lineups + player stats + POTM
# already linked since 104/106/47).
#
# Additive contract: events[] gain playerId/assistId/swapInId/swapOutId;
# scorers[] gain playerId/assistId; shootout attempts gain playerId (the
# posId coercion: number OR string → positive int, else omitted — the 167
# dead-id guard). UI renders the same text with PlayerNameLink — id>0 →
# /player Link (prefetch=false, title = English original when Persian shown,
# the PotmCard rule); no/dead id → the SAME span as before. Shots stay
# tooltip-only (a map dot cannot carry a link) — untouched.
#
# Live-truth baseline (pinned from the NEW build BEFORE the gates — D5 rule),
# match 5749723 (Frosinone 5–1 Lecce, finished):
#   goals 6/6 carry playerId (Bîrligea 1135820 ×2, Monteiro 1187691,
#          Cichella 1670272, Calò 746829, Raimondo 1256534); 5/6 carry
#          assistId (Kvernadze 1342748 ×2, Schmid 749488, Gorter 1414124,
#          Ghedjemis 1523327); Calò's goal honestly assist-less;
#   subs   Kaba in 1299869 / Monteiro out 1187699-family (pinned per event);
#   scorers[0] = Cichella 1670272 + Ghedjemis 1523327.
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API proof =="
# Warmup: fresh process — the FIRST matchDetails fetch can be cold (25s cache
# window). Warm on the control match itself; gates judge the settled truth.
python3 - <<'PY'
import json, time, urllib.request
def get(u):
    req = urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0 Chrome/124.0"})
    return json.load(urllib.request.urlopen(req, timeout=30))
for i in range(10):
    try:
        d = get("http://localhost:3000/api/match/5749723")
        ev = d.get("events") or []
        if any(e.get("playerId") for e in ev if e.get("type") == "Goal"):
            print("WARMUP OK"); break
    except Exception:
        pass
    time.sleep(5)
PY

A_OUT=$(python3 - <<'PY'
import json, urllib.request
def get(u):
    req = urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0 Chrome/124.0"})
    return json.load(urllib.request.urlopen(req, timeout=30))
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

try:
    d = get("http://localhost:3000/api/match/5749723")
except Exception as e:
    report("fetch", False, str(e)); raise SystemExit

ev = d.get("events") or []
goals = [e for e in ev if e.get("type") == "Goal"]
subs = [e for e in ev if e.get("type") == "Substitution"]
sc = d.get("scorers") or []

# A1: EVERY goal event carries a live playerId; 5/6 carry assistId
g1 = len(goals) == 6 and all(isinstance(g.get("playerId"), int) and g["playerId"] > 0 for g in goals)
aids = [g.get("assistId") for g in goals if g.get("assistId")]
g2 = len(aids) == 5 and all(isinstance(a, int) and a > 0 for a in aids)
report("A1 goal ids (6 pid + 5 aid)", g1 and g2, f"goals={len(goals)} pid_ok={sum(1 for g in goals if g.get('playerId'))} aid_n={len(aids)}")

# A2: exact pin — Cichella goal = 1670272, assist Ghedjemis = 1523327 (the
# upstream probe values, forwarded byte-exact)
g = next((x for x in goals if x.get("player") == "Matteo Cichella"), None)
good = bool(g) and g.get("playerId") == 1670272 and g.get("assist") == "Farès Ghedjemis" and g.get("assistId") == 1523327
report("A2 Cichella pin", good, f"pid={g and g.get('playerId')} aid={g and g.get('assistId')}")

# A3: substitution STRING ids coerced — Kaba in 1299869, Monteiro out 1187691
s = next((x for x in subs if x.get("swapIn") == "Mohamed Kaba"), None)
good = bool(s) and s.get("swapInId") == 1299869 and s.get("swapOut") == "Joël Monteiro" and s.get("swapOutId") == 1187691
report("A3 sub string-id coercion", good, f"in={s and s.get('swapInId')} out={s and s.get('swapOutId')}")

# A4: scorers strip ids — Cichella 1670272 + assist 1523327; Calò honestly aid-less
s0 = next((x for x in sc if x.get("player") == "Matteo Cichella"), None)
s1 = next((x for x in sc if x.get("player") == "Giacomo Calò"), None)
good = bool(s0) and s0.get("playerId") == 1670272 and s0.get("assistId") == 1523327 \
    and bool(s1) and s1.get("playerId") == 746829 and s1.get("assistId") is None and s1.get("assist") is None
report("A4 scorers strip ids", good, f"cichella={s0 and s0.get('playerId')} calo_aid={s1 and s1.get('assistId')}")

# A5: legacy byte-parity — the goal-event key set is the OLD 12 + exactly the
# 2 new id fields; neutral events (Half) carry NO player keys at all
old_keys = {"type", "typeFa", "minute", "side", "player", "playerFa", "card",
            "ownGoal", "penalty", "swapIn", "swapInFa", "swapOut", "swapOutFa",
            "homeScore", "awayScore", "assist", "assistFa"}
g = next(x for x in goals if x.get("player") == "Matteo Cichella")
extra = set(g.keys()) - old_keys
good = extra == {"playerId", "assistId"}
half = next((x for x in ev if x.get("type") == "Half"), None)
good = good and bool(half) and "player" not in half and "playerId" not in half
report("A5 legacy key parity", good, f"extra={sorted(extra)} half_clean={half is not None}")

# A6: dead-id guard — no timeline id anywhere is ≤0 or non-int
bad = []
for e in ev:
    for k in ("playerId", "assistId", "swapInId", "swapOutId"):
        v = e.get(k)
        if v is not None and (not isinstance(v, int) or v <= 0):
            bad.append((e.get("type"), k, v))
report("A6 dead-id sweep", not bad, f"events={len(ev)} bad={len(bad)}")

print("API_PROOF OK" if ok else "API_PROOF FLAGGED")
PY
)
echo "$A_OUT"
case "$A_OUT" in
  *"API_PROOF OK"*) : ;;
  *) BAD=$((BAD+1)) ;;
esac

cat > /tmp/c172-shootout-test.ts <<'TS'
import { buildShootout } from "/home/z/my-project/remontada/src/lib/shootout";
const out = buildShootout([
  { type: "Goal", isHome: true, player: { name: "Taker One", id: 999 } },
  { type: "Save", isHome: false, player: { name: "Taker Two", id: "12345" } },
  { type: "Miss", isHome: true, player: { name: "Dead Id", id: 0 } },
  { type: "Post", isHome: false, player: { name: "No Id" } },
]);
if (!out) { console.error("SHOOTOUT_UNIT BAD: null"); process.exit(1); }
const a = out.attempts;
const good =
  a[0].playerId === 999 &&
  a[1].playerId === 12345 &&
  a[2].playerId === undefined &&
  a[3].playerId === undefined &&
  a[0].playerFa === "Taker One" &&
  out.home === 1 && out.away === 0;
console.log(good ? "SHOOTOUT_UNIT OK" : `SHOOTOUT_UNIT BAD: ${JSON.stringify(a)}`);
process.exit(good ? 0 : 1);
TS
SU=$(bun run /tmp/c172-shootout-test.ts 2>&1 | tail -1)
echo "A7 shootout unit: $SU"
case "$SU" in
  *"SHOOTOUT_UNIT OK"*) : ;;
  *) BAD=$((BAD+1)) ;;
esac
if [ $((BAD)) -gt 0 ]; then echo "API_PART FLAGGED (BAD=$BAD)"; fi

echo "== PART B: DOM proof @390x844 (real match page) =="
B=agent-browser
$B set viewport 390 844 >/dev/null
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/match/5749723" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3
# B1: the timeline really links — Cichella goal + Ghedjemis assist + Kaba sub
FEAT=$($B eval "JSON.stringify((()=>{const as=[...document.querySelectorAll('a[href]')].map(a=>a.getAttribute('href'));return {cichella:as.includes('/player/1670272'),ghedjemis:as.includes('/player/1523327'),kaba:as.includes('/player/1299869'),total:as.filter(h=>(h||'').startsWith('/player/')).length}})())" 2>/dev/null | tr -d '"\\')
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
echo "B1 timeline links → feat=$FEAT | $OUT | console=$C appErrors=$E"
B1_RC=0
echo "$FEAT" | grep -q "cichella:true" || B1_RC=1
echo "$FEAT" | grep -q "ghedjemis:true" || B1_RC=1
echo "$FEAT" | grep -q "kaba:true" || B1_RC=1
[ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && B1_RC=1
[ "$C" = "0" ] && [ "$E" = "0" ] || B1_RC=1
[ "$B1_RC" -eq 0 ] || BAD=$((BAD+1))

# B2: REAL click on the Cichella link → /player/1670272 with a real h1
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/match/5749723" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "[...document.querySelectorAll('a[href]')].some(a=>a.getAttribute('href')==='/player/1670272')" >/dev/null 2>&1
sleep 1.5
CLICKED=$($B eval '(function(){const a=document.querySelector("a[href=\"/player/1670272\"]");if(a){a.click();return "clicked"}return "no-anchor"})()' 2>/dev/null | tr -d '"\')
$B wait --fn "location.pathname.startsWith('/player/1670272')" >/dev/null 2>&1
sleep 2
H1=$($B eval 'JSON.stringify((document.querySelector("h1")||{}).innerText||"")' 2>/dev/null | tr -d '"\')
URL=$($B eval 'location.pathname' 2>/dev/null | tr -d '"\')
OUT=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null | tr -d '"\')
C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception: print('ERR')")
E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  print(len([e for e in es if e.get('url')]))
except Exception: print('ERR')")
B2_RC=0
[ "$CLICKED" = "clicked" ] || B2_RC=1
case "$URL" in /player/1670272*) : ;; *) B2_RC=1 ;; esac
[ -n "$H1" ] && [ "$H1" != "null" ] || B2_RC=1
[ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && B2_RC=1
[ "$C" = "0" ] && [ "$E" = "0" ] || B2_RC=1
echo "B2 click-through Cichella → URL=$URL h1=$H1 | $OUT | console=$C appErrors=$E rc=$B2_RC"
[ "$B2_RC" -eq 0 ] || BAD=$((BAD+1))

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK (cycle-172: the match timeline/scorers-strip/shootout family joins the /player link network — goal/assist/sub ids flow from upstream through posId coercion, string sub-ids included; legacy key parity byte-exact; dead-id guard sweep clean; real click Cichella → /player/1670272)"
else
  echo "DOM_PROOF FLAGGED (BAD=$BAD)"; exit 1
fi
