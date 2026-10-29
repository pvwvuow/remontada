#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-179 fix proof — «بهترین کارت‌گیرندگان لیگ به صفحهٔ آقای گل می‌پیوندد»
#
# The 174 sister-page pattern, one surface over: the /api/topscorers/
# [leagueKey] route returns {scorers, assists} from the SAME cached
# getStandings payload, but dropped that payload's cycle-176 cards block —
# so the per-league topscorers page was the ONLY league-scoped surface
# without the yellow/red leaders (the league page got them in 176, the
# global /topscorers has had «آقای کارت» since cycle-50).
#
# Live probe BEFORE code (2026-10-30 ~06:30 +08, UA Chrome/124, the D5
# rule — observed bytes only):
#   /api/topscorers/pl keys = [assists, leagueFa, leagueKey, ok, scorers,
#   season, updatedAt] — NO cards — while /api/standings?league=pl (the
#   same cached payload) carries cards y=15/r=14. q=Azhir sanity → the
#   177 fold healthy (1227402 hit).
#
# Fix (additive-only, the 108/174 contract): the route response gains
# cards (same cached payload, ZERO extra upstream calls); league-scorers-
# view renders the compact «کارت‌ها» card (two زرد/قرمز columns, top 5
# each — same 176 link contract: playerId → /player prefetch=false,
# title = English original when Persian shown, id>0 guard — the 167
# lesson), per-kind honest absence (mas yellow=0 structural → red-only
# column), whole card hidden when the payload omits cards (old seasons).
# Top-level keys: OLD keys + EXACTLY {assists, cards} — the 174 A2 parity
# pin deliberately advanced (documented in that gate).
#
# Pinned live truth (probed 2026-10-30, the 178 hunt pins):
#   pl cards yellow[0] = Vitaly Janelt 688273 «ویتالی یانلت» (tops with 4;
#     value drifts only if the season file does — gate pins pid+fa, value>0)
#   Janelt is in NO pl surface except cards (the 174 strong-gate pattern)
#   mas cards yellow=[] structural, red=8 (Mazlan 694010 first)
#   persiangulf yellow=15 (Alizadeh 900771) red=15 (Azhir 1227402)
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
def pidok(x):
    return isinstance(x.get("playerId"), int) and x["playerId"] > 0

# A1: pl route now carries cards — Janelt pin rides the SAME cached payload
try:
    d = get(BASE + "/api/topscorers/pl")
    c = d.get("cards") or {}
    y, r = c.get("yellow") or [], c.get("red") or []
    y0 = y[0] if y else None
    good = len(y) >= 10 and len(r) >= 1 and all(pidok(x) for x in y + r) \
        and y0 and y0.get("playerId") == 688273 and y0.get("nameFa") == "ویتالی یانلت" \
        and isinstance(y0.get("value"), int) and y0["value"] > 0
    report("A1 pl cards ride route", good,
           f"y={len(y)} r={len(r)} y0={y0 and y0.get('playerId')}/{y0 and y0.get('nameFa')}/{y0 and y0.get('value')}")
except Exception as e:
    report("A1 pl cards ride route", False, repr(e))

# A2: top-level parity — OLD keys + the additive era line (the 174 A2 pin
# advanced twice: 179 added cards, 180 added selectedSeason + allSeasons
# for the season selector).
try:
    d = get(BASE + "/api/topscorers/pl")
    old = {"ok", "leagueKey", "leagueFa", "season", "scorers", "updatedAt"}
    extra = set(d.keys()) - old
    good = extra == {"assists", "cards", "selectedSeason", "allSeasons"}
    report("A2 top-level parity", good, f"extra={sorted(extra)}")
except Exception as e:
    report("A2 top-level parity", False, repr(e))

# A3: the 174 surface byte-alive on the same response — assists ≥5 + Rice
try:
    d = get(BASE + "/api/topscorers/pl")
    a = d.get("assists") or []
    s = d.get("scorers") or []
    good = len(a) >= 5 and 654096 in {x.get("playerId") for x in a} \
        and len(s) >= 10 and all(pidok(x) for x in a)
    report("A3 assists surface intact", good, f"ass={len(a)} scorers={len(s)}")
except Exception as e:
    report("A3 assists surface intact", False, repr(e))

# A4: mas red-only honesty — yellow structurally [] , red rows clean
try:
    d = get(BASE + "/api/topscorers/mas")
    c = d.get("cards") or {}
    y, r = c.get("yellow") or [], c.get("red") or []
    good = d.get("ok") is True and y == [] and len(r) >= 1 and all(pidok(x) for x in r)
    report("A4 mas red-only honesty", good, f"y={len(y)} r={len(r)}")
except Exception as e:
    report("A4 mas red-only honesty", False, repr(e))

# A5: persiangulf — both kinds ride, Alizadeh pin in yellow
try:
    d = get(BASE + "/api/topscorers/persiangulf")
    c = d.get("cards") or {}
    y, r = c.get("yellow") or [], c.get("red") or []
    good = len(y) >= 10 and len(r) >= 10 and all(pidok(x) for x in y + r) \
        and 900771 in {x.get("playerId") for x in y}
    report("A5 persiangulf both kinds", good, f"y={len(y)} r={len(r)}")
except Exception as e:
    report("A5 persiangulf both kinds", False, repr(e))

# A6: strong gate — the Janelt anchor on /topscorers/pl can ONLY come from
# the new card (he is in no other surface of this route's response)
try:
    d = get(BASE + "/api/topscorers/pl")
    sids = {x.get("playerId") for x in (d.get("scorers") or [])}
    aids = {x.get("playerId") for x in (d.get("assists") or [])}
    c = d.get("cards") or {}
    cids = {x.get("playerId") for x in (c.get("yellow") or [])} | {x.get("playerId") for x in (c.get("red") or [])}
    good = (688273 not in sids) and (688273 not in aids) and (688273 in cids)
    report("A6 Janelt only-in-cards", good,
           f"scorers={688273 in sids} assists={688273 in aids} cards={688273 in cids}")
except Exception as e:
    report("A6 Janelt only-in-cards", False, repr(e))

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

# B1: /topscorers/pl — the new «کارت‌ها» card renders both columns +
# the Janelt anchor (provably the NEW card: he is not a scorer/assister row)
open_page "/topscorers/pl"
FEAT=$(snap 'cards:document.body.innerText.includes("کارت\u200Cها"),cy:document.body.innerText.includes("کارت زرد"),cr:document.body.innerText.includes("کارت قرمز"),ass:document.body.innerText.includes("دهندگان"),janelt:!!document.querySelector("a[href=\"/player/688273\"]"),players:document.querySelectorAll("a[href^=\"/player/\"]").length')
B1=0
echo "$FEAT" | rg -q 'cards:true' || B1=1
echo "$FEAT" | rg -q 'cy:true' || B1=1
echo "$FEAT" | rg -q 'cr:true' || B1=1
echo "$FEAT" | rg -q 'ass:true' || B1=1
echo "$FEAT" | rg -q 'janelt:true' || B1=1
echo "$FEAT" | rg -q 'players:(2[0-9]|[3-9][0-9])' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 /topscorers/pl" "$FEAT"

# B2: REAL click-through — Janelt card row → /player/688273 Persian h1
CLICKED=$($B eval '(function(){const links=[...document.querySelectorAll("a[href=\"/player/688273\"]")];const hit=links.find(l=>(l.innerText||"").includes("یانلت"));if(hit){hit.click();return "clicked"}return "no-row"})()' 2>/dev/null | tr -d '"\\')
$B wait --fn "location.pathname.startsWith('/player/688273')" >/dev/null 2>&1
sleep 2
H1=$($B eval 'JSON.stringify((document.querySelector("h1")||{}).innerText||"")' 2>/dev/null | tr -d '"\\')
URL=$($B eval 'location.pathname' 2>/dev/null | tr -d '"\\')
B2=0
[ "$CLICKED" = "clicked" ] || B2=1
case "$URL" in /player/688273*) : ;; *) B2=1 ;; esac
echo "$H1" | grep -q "یانلت" || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 click Janelt" "clicked=$CLICKED url=$URL h1=$H1"

# B3: /topscorers/mas — red-only honesty: «کارت قرمز» yes, «کارت زرد» NO
open_page "/topscorers/mas"
FEAT=$(snap 'cr:document.body.innerText.includes("کارت قرمز"),cy:document.body.innerText.includes("کارت زرد"),anchors:document.querySelectorAll("a[href]").length')
B3=0
echo "$FEAT" | rg -q 'cr:true' || B3=1
echo "$FEAT" | rg -q 'cy:false' || B3=1
echo "$FEAT" | rg -q 'anchors:([1-9][0-9])' || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 /topscorers/mas" "$FEAT"

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK (cycle-179: the per-league topscorers page joins its sister on cards — /api/topscorers/[leagueKey] now carries the cycle-176 cards block with zero extra upstream cost, league-scorers-view renders the compact «کارت‌ها» card under the assists card with the 170/176 link contract; the Janelt anchor on /topscorers/pl is provably the new card (only-in-cards) and really clicks through to /player/688273; mas stays red-only honest; legacy assists card + scorer rows untouched)"
else
  echo "DOM_PROOF FLAGGED (BAD=$BAD)"; exit 1
fi
