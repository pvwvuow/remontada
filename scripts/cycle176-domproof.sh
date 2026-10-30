#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-176 update proof — «کارت‌ها به صفحهٔ لیگ می‌پیوندند»
#
# The book gaps (season selector 55/99, cup brackets 56/139-141, transfers
# 136/167) were long closed; live probing found the REAL remaining gap:
# the cycle-50 card pipeline (getLeagueCardLeaders — fetchAllUrl deep files
# + cycle-127 thin-TTL + freshCardNames) had exactly ONE consumer (the
# global /topscorers merge). The league page never surfaced its own
# league's yellow/red leaders, even though /api/standings already carried
# scorers + assists (170/175). Update (additive-only, the 108 contract):
# getStandings plucks cards (limit 15, file rank order, current-season only
# — the cycle-132 rule) into the mapped payload; league-view renders the
# compact «کارت‌ها» card (two columns زرد/قرمز, top 5, same 170/174 link
# contract: playerId → /player prefetch=false, title = English when Persian
# shown, id>0 guard); standings cache v7→v8 (additive-shape convention);
# thin-TTL guard extended to thin-but-nonempty YELLOW only (red files are
# naturally short: pl=14, persiangulf=19, mas=8 rows — a red guard would
# re-probe forever).
#
# Pinned live truth (probed 2026-10-30, UA Chrome/124):
#   pl (47) yellow_card.json = 204 rows, leader Vitaly Janelt 688273 (4)
#           red_card.json   = 14 rows
#   persiangulf (523) yellow = 178 rows, leader Alireza Alizadeh 900771
#           (Gol Gohar, 5 — the Persian hook) red = 19 rows
#   mas (8985) has ONLY "Red cards" (8 rows) → yellow [] honest per-kind
#           absence → the league page shows the red-only column
#   Janelt/Thiago/Alizadeh appear in NO other pl payload surface (scorers /
#           assists / boards — verified against the live payload), so a
#           /player/688273 anchor on /league/pl can ONLY come from the new
#           cards block (the 174 strong-gate pattern)
#   assists[0] = Rice 654096 «دکلن رایس» (the 175 deep merge must survive
#           the v8 rebuild)
#
# D5 discipline: bash -n before every run; multi-alternative assertions in
# ONE pattern (the 173 lesson); Read/od is truth — the terminal display eats
# brackets.
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
    return json.load(urllib.request.urlopen(req, timeout=60))
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

# A1: pl cards ride the mapped payload — Janelt pin + row hygiene
try:
    d = get(BASE + "/api/standings?league=pl")
    c = d.get("cards") or {}
    y = c.get("yellow") or []
    r = c.get("red") or []
    y0 = y[0] if y else {}
    hyg = all(
        isinstance(x.get("playerId"), int) and x["playerId"] > 0
        and x.get("name") and x.get("nameFa") and x.get("value", 0) >= 1
        for x in (y + r)
    )
    mono = len(y) >= 5 and y0.get("value", 0) >= y[4].get("value", 0)
    good = (
        d.get("ok") is True and len(y) >= 5 and len(r) >= 1 and hyg and mono
        and y0.get("playerId") == 688273 and y0.get("value", 0) >= 4
    )
    report("A1 pl cards block", good,
           f"yellow={len(y)} red={len(r)} y0={y0.get('name')}/{y0.get('playerId')}/{y0.get('value')} hyg={hyg}")
except Exception as e:
    report("A1 pl cards block", False, repr(e))

# A2: the Janelt anchor can ONLY come from the new block — he appears in NO
# other player-id surface of the same payload (the 174 strong-gate pattern)
try:
    d = get(BASE + "/api/standings?league=pl")
    ids = set()
    for s in d.get("scorers") or []: ids.add(s.get("playerId"))
    for a in d.get("assists") or []: ids.add(a.get("playerId"))
    for b in d.get("boards") or []:
        for row in b.get("rows") or []: ids.add(row.get("playerId"))
    good = 688273 not in ids
    report("A2 Janelt absent elsewhere", good, f"payload player ids={len(ids)}")
except Exception as e:
    report("A2 Janelt absent elsewhere", False, repr(e))

# A3: top-level parity — allowed documented keys + EXACTLY {cards} extra
try:
    d = get(BASE + "/api/standings?league=pl")
    allowed = {"ok", "leagueKey", "leagueFa", "season", "selectedSeason",
               "allSeasons", "rows", "groups", "home", "away", "scorers",
               "assists", "boards", "legend", "matchday", "ttlMinutes",
               "updatedAt", "stale"}
    extra = set(d.keys()) - allowed
    good = "cards" in d and extra == {"cards"}
    report("A3 top-level key parity", good, f"extra={sorted(extra)}")
except Exception as e:
    report("A3 top-level key parity", False, repr(e))

# A4: ADVANCED by cycle-185 (the in-gate-comment convention — the 179 A2
# precedent): this gate pinned the cycle-132 current-only rule, but the 185
# live probe disproved the upstream half of it — each season's own raw
# carries its own card fetchAllUrls (2023/2024 pl → season/20720 files).
# Historical standings now CARRY the season's card kings: yellow João
# Palhinha 13 (pid 524434), red Yves Bissouma 2 (pid 724306).
try:
    d = get(BASE + "/api/standings?league=pl&season=2023/2024")
    c = d.get("cards") or {}
    y0 = (c.get("yellow") or [{}])[0]
    r0 = (c.get("red") or [{}])[0]
    good = (d.get("ok") is True and len(d.get("rows") or []) >= 10
            and y0.get("name") == "João Palhinha" and y0.get("value") == 13
            and y0.get("playerId") == 524434
            and r0.get("name") == "Yves Bissouma" and r0.get("value") == 2
            and r0.get("playerId") == 724306)
    report("A4 historical season carries its own cards (185)", good,
           f"rows={len(d.get('rows') or [])} y0={y0.get('name')}/{y0.get('value')} r0={r0.get('name')}/{r0.get('value')}")
except Exception as e:
    report("A4 historical season carries its own cards (185)", False, repr(e))

# A5: mas per-kind honesty — no Yellow category → yellow [] + red rows
try:
    d = get(BASE + "/api/standings?league=mas")
    c = d.get("cards") or {}
    y = c.get("yellow")
    r = c.get("red") or []
    good = (d.get("ok") is True and y == [] and len(r) >= 1
            and all(x.get("playerId", 0) > 0 for x in r))
    report("A5 mas yellow [] + red alive", good,
           f"yellow={y} red={len(r)}")
except Exception as e:
    report("A5 mas yellow [] + red alive", False, repr(e))

# A6: the Persian hook — persiangulf yellow leader = Alizadeh (Gol Gohar)
try:
    d = get(BASE + "/api/standings?league=persiangulf")
    c = d.get("cards") or {}
    y = c.get("yellow") or []
    r = c.get("red") or []
    y0 = y[0] if y else {}
    good = (d.get("ok") is True and len(y) >= 5 and len(r) >= 1
            and y0.get("playerId") == 900771 and y0.get("value", 0) >= 5
            and all(x.get("playerId", 0) > 0 for x in y + r))
    report("A6 persiangulf Alizadeh hook", good,
           f"yellow={len(y)} red={len(r)} y0={y0.get('name')}/{y0.get('value')}")
except Exception as e:
    report("A6 persiangulf Alizadeh hook", False, repr(e))

# A7: the 175 deep assists merge must survive the v8 rebuild — Rice pin
try:
    d = get(BASE + "/api/standings?league=pl")
    a0 = (d.get("assists") or [{}])[0]
    s0 = (d.get("scorers") or [{}])[0]
    r0 = (d.get("rows") or [{}])[0]
    good = (a0.get("playerId") == 654096 and a0.get("nameFa") == "دکلن رایس"
            and {"rank", "name", "goals", "teamId"}.issubset(s0.keys())
            and {"idx", "teamId", "name", "played", "pts"}.issubset(r0.keys()))
    report("A7 legacy surfaces byte-stable", good,
           f"assists0={a0.get('nameFa')}/{a0.get('playerId')}")
except Exception as e:
    report("A7 legacy surfaces byte-stable", False, repr(e))

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

# B1: /league/pl renders the cards block (ZWNJ-escaped pins) and the Janelt
# anchor — which per A2 can only originate in the new block
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/league/pl" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 2.5
FEAT=$($B eval 'JSON.stringify({cards:document.body.innerText.includes("\u06a9\u0627\u0631\u062a\u200c\u0647\u0627"),yellow:document.body.innerText.includes("\u06a9\u0627\u0631\u062a \u0632\u0631\u062f"),red:document.body.innerText.includes("\u06a9\u0627\u0631\u062a \u0642\u0631\u0645\u0632"),janelt:!!document.querySelector("a[href=\"/player/688273\"]")})' 2>/dev/null | tr -d '"\\')
OUT=$($B eval "$VGATES" 2>/dev/null | tr -d '"\\')
C=$($B console --json 2>/dev/null | python3 -c "$CNT")
E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
B1=0
echo "$FEAT" | rg -q 'cards:true' || B1=1
echo "$FEAT" | rg -q 'yellow:true' || B1=1
echo "$FEAT" | rg -q 'red:true' || B1=1
echo "$FEAT" | rg -q 'janelt:true' || B1=1
[ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && B1=1
[ "$C" = "0" ] && [ "$E" = "0" ] || B1=1
echo "B1 /league/pl → $FEAT | $OUT | console=$C appErrors=$E rc=$B1"
[ "$B1" -eq 0 ] || BAD=$((BAD+1))

# B2: REAL click on the Janelt cards row → /player/688273 with real h1
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/league/pl" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "[...document.querySelectorAll('a[href]')].some(a=>a.getAttribute('href')==='/player/688273')" >/dev/null 2>&1
sleep 1.5
CLICKED=$($B eval '(function(){const a=document.querySelector("a[href=\"/player/688273\"]");if(a){a.click();return "clicked"}return "no-anchor"})()' 2>/dev/null | tr -d '"\')
$B wait --fn "location.pathname.startsWith('/player/688273')" >/dev/null 2>&1
sleep 2
H1=$($B eval 'JSON.stringify((document.querySelector("h1")||{}).innerText||"")' 2>/dev/null | tr -d '"\')
URL=$($B eval 'location.pathname' 2>/dev/null | tr -d '"\')
OUT=$($B eval "$VGATES" 2>/dev/null | tr -d '"\\')
C=$($B console --json 2>/dev/null | python3 -c "$CNT")
E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
B2=0
[ "$CLICKED" = "clicked" ] || B2=1
case "$URL" in /player/688273*) : ;; *) B2=1 ;; esac
[ -n "$H1" ] && [ "$H1" != "null" ] || B2=1
[ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && B2=1
[ "$C" = "0" ] && [ "$E" = "0" ] || B2=1
echo "B2 click-through Janelt → URL=$URL h1=$H1 | $OUT | console=$C appErrors=$E rc=$B2"
[ "$B2" -eq 0 ] || BAD=$((BAD+1))

# B3: the Persian hook — /league/persiangulf block + Alizadeh anchor + click
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/league/persiangulf" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "[...document.querySelectorAll('a[href]')].some(a=>a.getAttribute('href')==='/player/900771')" >/dev/null 2>&1
sleep 1.5
FEAT=$($B eval 'JSON.stringify({cards:document.body.innerText.includes("\u06a9\u0627\u0631\u062a\u200c\u0647\u0627"),alizadeh:!!document.querySelector("a[href=\"/player/900771\"]")})' 2>/dev/null | tr -d '"\\')
CLICKED=$($B eval '(function(){const a=document.querySelector("a[href=\"/player/900771\"]");if(a){a.click();return "clicked"}return "no-anchor"})()' 2>/dev/null | tr -d '"\')
$B wait --fn "location.pathname.startsWith('/player/900771')" >/dev/null 2>&1
sleep 2
H1=$($B eval 'JSON.stringify((document.querySelector("h1")||{}).innerText||"")' 2>/dev/null | tr -d '"\')
URL=$($B eval 'location.pathname' 2>/dev/null | tr -d '"\')
OUT=$($B eval "$VGATES" 2>/dev/null | tr -d '"\\')
C=$($B console --json 2>/dev/null | python3 -c "$CNT")
E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
B3=0
echo "$FEAT" | rg -q 'cards:true' || B3=1
echo "$FEAT" | rg -q 'alizadeh:true' || B3=1
[ "$CLICKED" = "clicked" ] || B3=1
case "$URL" in /player/900771*) : ;; *) B3=1 ;; esac
[ -n "$H1" ] && [ "$H1" != "null" ] || B3=1
[ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && B3=1
[ "$C" = "0" ] && [ "$E" = "0" ] || B3=1
echo "B3 click-through Alizadeh → URL=$URL h1=$H1 | $FEAT | console=$C appErrors=$E rc=$B3"
[ "$B3" -eq 0 ] || BAD=$((BAD+1))

# B4: mas per-kind honesty DOM — red-only column, no yellow label
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/league/mas" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 20" >/dev/null 2>&1
sleep 2
FEAT=$($B eval 'JSON.stringify({red:document.body.innerText.includes("\u06a9\u0627\u0631\u062a \u0642\u0631\u0645\u0632"),yellow:document.body.innerText.includes("\u06a9\u0627\u0631\u062a \u0632\u0631\u062f"),bodyLen:document.body.innerText.length})' 2>/dev/null | tr -d '"\\')
OUT=$($B eval "$VGATES" 2>/dev/null | tr -d '"\\')
C=$($B console --json 2>/dev/null | python3 -c "$CNT")
E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
B4=0
echo "$FEAT" | rg -q 'red:true' || B4=1
echo "$FEAT" | rg -q 'yellow:false' || B4=1
[ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && B4=1
[ "$C" = "0" ] && [ "$E" = "0" ] || B4=1
echo "B4 /league/mas red-only → $FEAT | $OUT | console=$C appErrors=$E rc=$B4"
[ "$B4" -eq 0 ] || BAD=$((BAD+1))

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK (cycle-176: the league page joins its own cards — getStandings plucks the cycle-50 pipeline's yellow/red leaders into the mapped payload (file rank order, limit 15; season-aware since cycle-185), league-view renders the compact «کارت‌ها» card with two زرد/قرمز columns and the 170/174 link contract; the Janelt anchor on /league/pl is provably the new block (absent from every other payload surface) and really clicks through to /player/688273; the Persian hook Alizadeh (گل‌گهر) anchors /league/persiangulf and clicks through to /player/900771; mas shows the honest red-only column (no Yellow category); historical seasons carry their OWN cards since 185 (A4 advanced); legacy rows/scorers/assists byte-stable incl. the 175 Rice pin)"
else
  echo "DOM_PROOF FLAGGED (BAD=$BAD)"; exit 1
fi
