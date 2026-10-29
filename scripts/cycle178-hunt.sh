#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-178 bug-hunt — «گشت‌زنی سطوح ۱۷۴-۱۷۷ و صداقت غیاب»
#
# Context (2026-10-30 ~06:10 +08:00): the rotation engine completed
# cycles 174-177 while this session slept (commits d64b5c1/97070fb/
# d1ec12b/aed4880, 05:35→06:06 +08). Three-state detection: two reads
# 50s apart — tree clean, ls-remote stable at aed4880, target card
# (cycle-178) absent from origin → per protocol the next cycle runs
# fully. 178 mod 5 = 3 → type 4 = BUG-HUNT.
#
# The hunt patrols the four surfaces added since the cycle-173 hunt,
# at viewport 390x844, PLUS the honesty-of-absence contracts (a block
# must be ABSENT where the feed has no data — the false-positive side
# no previous gate covered):
#   cycle-174  «بهترین پاس‌دهندگان» on /topscorers/[leagueKey]
#   cycle-175  deep assists (pl=10 merged rows, Rice first)
#   cycle-176  «کارت‌ها» yellow/red block on league pages
#              (mas = red-only, persiangulf = both columns)
#   cycle-177  card kings in the player search pool
#   honesty    persiangulf/mas assists=0 → «دهندگان» ABSENT;
#              mas yellow=0 → «کارت زرد» ABSENT
#
# Pinned live truth (probed 2026-10-30 ~06:12 +08, UA Chrome/124,
# full-object dumps — scripts/cycle178-probe.sh):
#   standings pl          rows=20 assists=10 (Rice 654096 first)
#                         cards yellow=15 red=14, ALL pid>0, 688273 in both
#   standings persiangulf rows=18 assists=0 (honest), yellow=15
#                         (Alizadeh 900771 value=5), red=15 (Azhir 1227402)
#   standings mas         rows=12 assists=0, yellow=0 (no category in
#                         feed — structural), red=8 (Mazlan 694010)
#   topscorers pl         scorers=20 assists=10 (0 bad pid)
#   topscorers persiangulf/mas: assists=0 (honest absence)
#   /player/688273|900771|694010 → 200
#   search یانلت → [(688273, «ویتالی یانلت»)]
# Patrol rule: assert ranges and structure, NEVER exact live counts
# (the 173 drift lesson); ZWNJ expressed as \u200C in JS evals.
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API truth (UA Chrome/124) =="
A_OUT=$(python3 - <<'PY'
import json, urllib.parse, urllib.request
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
def pidok(x):
    return isinstance(x.get("playerId"), int) and x["playerId"] > 0

# A1: page sweep — 13 routes including the three league-scoped newcomers
pages = ["/", "/leagues", "/league/pl", "/league/persiangulf", "/league/mas",
         "/topscorers", "/topscorers/pl", "/topscorers/persiangulf",
         "/topscorers/mas", "/news", "/player/688273", "/team/2182",
         "/match/5749723"]
bad = []
for p in pages:
    try:
        if code(BASE + p) != 200:
            bad.append(p)
    except Exception as e:
        bad.append(f"{p}({e.__class__.__name__})")
report("A1 pages 13x200", not bad, f"bad={bad}")

# A2: search pool — all three kinds + FA alias + legacy row (171)
try:
    def search(q):
        d = get(BASE + "/api/search?q=" + urllib.parse.quote(q))
        return d.get("players") or []
    j = next((x for x in search("Janelt") if x.get("playerId") == 688273), None)
    fa = any(x.get("playerId") == 688273 for x in search("یانلت"))
    m = next((x for x in search("Mazlan") if x.get("playerId") == 694010), None)
    r = any(x.get("playerId") == 654096 for x in search("رایس"))
    good = bool(j) and j.get("fa") == "ویتالی یانلت" and j.get("teamFa") == "برنتفورد" \
        and fa and bool(m) and m.get("fa") == "Fazly Mazlan" and r
    report("A2 search 3kind+alias+legacy", good,
           f"janelt={bool(j)} faAlias={fa} mazlan={bool(m)} rice={r}")
except Exception as e:
    report("A2 search 3kind+alias+legacy", False, repr(e))

# A3: standings pl — deep assists (175) + both card kinds (176)
try:
    d = get(BASE + "/api/standings?league=pl")
    rows = d.get("rows") or []
    ass = d.get("assists") or []
    c = d.get("cards") or {}
    y, r = c.get("yellow") or [], c.get("red") or []
    yids = {x.get("playerId") for x in y}
    good = len(rows) >= 10 and len(ass) >= 5 and all(pidok(x) for x in ass) \
        and 654096 in {x.get("playerId") for x in ass} \
        and len(y) >= 10 and all(pidok(x) and (x.get("nameFa") or x.get("name")) for x in y) \
        and 688273 in yids \
        and len(r) >= 1 and all(pidok(x) for x in r)
    report("A3 pl deep-assists+cards", good,
           f"rows={len(rows)} ass={len(ass)} y={len(y)} r={len(r)}")
except Exception as e:
    report("A3 pl deep-assists+cards", False, repr(e))

# A4: standings persiangulf — both card columns, assists honestly ABSENT
try:
    d = get(BASE + "/api/standings?league=persiangulf")
    ass = d.get("assists") or []
    c = d.get("cards") or {}
    y, r = c.get("yellow") or [], c.get("red") or []
    good = ass == [] and len(y) >= 10 and all(pidok(x) for x in y) \
        and 900771 in {x.get("playerId") for x in y} \
        and len(r) >= 10 and all(pidok(x) for x in r)
    report("A4 persiangulf cards+assists-absent", good,
           f"ass={len(ass)} y={len(y)} r={len(r)}")
except Exception as e:
    report("A4 persiangulf cards+assists-absent", False, repr(e))

# A5: standings mas — red-only honesty (yellow structurally empty)
try:
    d = get(BASE + "/api/standings?league=mas")
    ass = d.get("assists") or []
    c = d.get("cards") or {}
    y, r = c.get("yellow") or [], c.get("red") or []
    good = ass == [] and y == [] and len(r) >= 1 and all(pidok(x) for x in r)
    report("A5 mas red-only honesty", good, f"ass={len(ass)} y={len(y)} r={len(r)}")
except Exception as e:
    report("A5 mas red-only honesty", False, repr(e))

# A6: strong only-in-cards — 688273/900771 exist in NO other surface (177)
try:
    pl = get(BASE + "/api/standings?league=pl")
    pg = get(BASE + "/api/standings?league=persiangulf")
    plsid = {x.get("playerId") for x in (pl.get("scorers") or [])} | {x.get("playerId") for x in (pl.get("assists") or [])}
    pgsid = {x.get("playerId") for x in (pg.get("scorers") or [])} | {x.get("playerId") for x in (pg.get("assists") or [])}
    good = (688273 not in plsid) and (900771 not in pgsid)
    report("A6 only-in-cards strong gate", good,
           f"688273_in_pl_other={688273 in plsid} 900771_in_pg_other={900771 in pgsid}")
except Exception as e:
    report("A6 only-in-cards strong gate", False, repr(e))

# A7: topscorers API — pl assists card rows clean; others honest absence (174)
try:
    pl = get(BASE + "/api/topscorers/pl")
    plass = pl.get("assists") or []
    pg = get(BASE + "/api/topscorers/persiangulf")
    ms = get(BASE + "/api/topscorers/mas")
    good = len(plass) >= 5 and all(pidok(x) for x in plass) \
        and 654096 in {x.get("playerId") for x in plass} \
        and pg.get("assists") == [] and ms.get("assists") == []
    report("A7 topscorers assists+absence", good,
           f"pl={len(plass)} pg={len(pg.get('assists') or [])} mas={len(ms.get('assists') or [])}")
except Exception as e:
    report("A7 topscorers assists+absence", False, repr(e))

# A8: match timeline ids survive three cache bumps (172 regression)
try:
    d = get(BASE + "/api/match/5749723")
    ev = d.get("events") or []
    goals = [e for e in ev if e.get("type") == "Goal"]
    withpid = [g for g in goals if pidok(g)]
    report("A8 match goal ids", len(goals) >= 4 and len(withpid) >= 4,
           f"goals={len(goals)} with_pid={len(withpid)}")
except Exception as e:
    report("A8 match goal ids", False, repr(e))

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
# one shared feature-snapshot eval: $1 = JS object literal body
snap() { $B eval "JSON.stringify({$1})" 2>/dev/null | tr -d '"\\'; }
gate() { # $1=label $2=feat $3=extra-rc(piped checks append) — shared VGATES/console assert
  local label="$1" FEAT="$2" OUT C E RC=0
  OUT=$(snap 'sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length')
  C=$($B console --json 2>/dev/null | python3 -c "$CNT")
  E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
  [ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  echo "$label → $FEAT | $OUT | console=$C appErrors=$E rc=$RC"
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
}

# B1: /league/pl — 170 assists block AND 176 cards block both live
patrol_open "/league/pl"
FEAT=$(snap 'ass:document.body.innerText.includes("دهندگان"),cards:document.body.innerText.includes("کارت\u200Cها"),players:document.querySelectorAll("a[href^=\"/player/\"]").length')
B1=0
echo "$FEAT" | rg -q 'ass:true' || B1=1
echo "$FEAT" | rg -q 'cards:true' || B1=1
echo "$FEAT" | rg -q 'players:(1[5-9]|[2-9][0-9])' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 /league/pl" "$FEAT"

# B2: /league/persiangulf — both card columns, assists honestly ABSENT
patrol_open "/league/persiangulf"
FEAT=$(snap 'cards:document.body.innerText.includes("کارت\u200Cها"),cy:document.body.innerText.includes("کارت زرد"),cr:document.body.innerText.includes("کارت قرمز"),ass:document.body.innerText.includes("دهندگان"),players:document.querySelectorAll("a[href^=\"/player/\"]").length')
B2=0
echo "$FEAT" | rg -q 'cards:true' || B2=1
echo "$FEAT" | rg -q 'cy:true' || B2=1
echo "$FEAT" | rg -q 'cr:true' || B2=1
echo "$FEAT" | rg -q 'ass:false' || B2=1
echo "$FEAT" | rg -q 'players:[1-9][0-9]' || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 /league/persiangulf" "$FEAT"

# B3: /league/mas — red-only honesty: red label yes, yellow+assists labels NO
patrol_open "/league/mas"
FEAT=$(snap 'cr:document.body.innerText.includes("کارت قرمز"),cy:document.body.innerText.includes("کارت زرد"),ass:document.body.innerText.includes("دهندگان")')
B3=0
echo "$FEAT" | rg -q 'cr:true' || B3=1
echo "$FEAT" | rg -q 'cy:false' || B3=1
echo "$FEAT" | rg -q 'ass:false' || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 /league/mas" "$FEAT"

# B4: /topscorers/pl — 174 assists card + Rice anchor provably from it
patrol_open "/topscorers/pl"
FEAT=$(snap 'ass:document.body.innerText.includes("دهندگان"),rice:!!document.querySelector("a[href=\"/player/654096\"]")')
B4=0
echo "$FEAT" | rg -q 'ass:true' || B4=1
echo "$FEAT" | rg -q 'rice:true' || B4=1
[ "$B4" -eq 0 ] || BAD=$((BAD+1))
gate "B4 /topscorers/pl" "$FEAT"

# B5: /topscorers/mas — honest absence of the assists card, page still clean
patrol_open "/topscorers/mas"
FEAT=$(snap 'ass:document.body.innerText.includes("دهندگان"),anchors:document.querySelectorAll("a[href]").length')
B5=0
echo "$FEAT" | rg -q 'ass:false' || B5=1
echo "$FEAT" | rg -q 'anchors:([1-9][0-9])' || B5=1
[ "$B5" -eq 0 ] || BAD=$((BAD+1))
gate "B5 /topscorers/mas" "$FEAT"

# B6: search UI FA alias «یانلت» → real click → /player/688273 (177 UI path)
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 2
$B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
sleep 1
$B eval "(function(){const i=document.querySelector('div[role=\"dialog\"] input');if(!i)return 'no-input';const s=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set;s.call(i,'یانلت');i.dispatchEvent(new Event('input',{bubbles:true}));return 'typed'})()" >/dev/null 2>&1
$B wait --fn "[...document.querySelectorAll('div[role=\"dialog\"] ul li button')].some(b=>(b.innerText||'').includes('ویتالی یانلت'))" >/dev/null 2>&1
sleep 1
CLICKED=$($B eval '(function(){const btns=[...document.querySelectorAll("div[role=\"dialog\"] ul li button")];const hit=btns.find(b=>(b.innerText||"").includes("ویتالی یانلت"));if(hit){hit.click();return "clicked"}return "no-row"})()' 2>/dev/null | tr -d '"\\')
$B wait --fn "location.pathname.startsWith('/player/688273')" >/dev/null 2>&1
sleep 2
H1=$($B eval 'JSON.stringify((document.querySelector("h1")||{}).innerText||"")' 2>/dev/null | tr -d '"\\')
URL=$($B eval 'location.pathname' 2>/dev/null | tr -d '"\\')
B6=0
[ "$CLICKED" = "clicked" ] || B6=1
case "$URL" in /player/688273*) : ;; *) B6=1 ;; esac
echo "$H1" | grep -q "یانلت" || B6=1
[ "$B6" -eq 0 ] || BAD=$((BAD+1))
gate "B6 click یانلت" "clicked=$CLICKED url=$URL h1=$H1"

# B7: /player/900771 direct — cards-sourced id class resolves standalone
patrol_open "/player/900771"
H1=$($B eval 'JSON.stringify((document.querySelector("h1")||{}).innerText||"")' 2>/dev/null | tr -d '"\\')
B7=0
[ -n "$H1" ] && [ "$H1" != "null" ] || B7=1
[ "$B7" -eq 0 ] || BAD=$((BAD+1))
gate "B7 /player/900771" "h1=$H1"

# B8: home + match regression quick patrol (anchor networks intact)
patrol_open "/"
FEAT=$(snap 'anchors:document.querySelectorAll("a[href]").length')
B8=0
echo "$FEAT" | rg -q 'anchors:([1-9][0-9]{2,})' || B8=1
[ "$B8" -eq 0 ] || BAD=$((BAD+1))
gate "B8 home" "$FEAT"
patrol_open "/match/5749723"
FEAT=$(snap 'players:document.querySelectorAll("a[href^=\"/player/\"]").length')
B9=0
echo "$FEAT" | rg -q 'players:([1-9][0-9])' || B9=1
[ "$B9" -eq 0 ] || BAD=$((BAD+1))
gate "B9 /match/5749723" "$FEAT"

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "HUNT OK (cycle-178: patrol of the 174-177 surfaces — topscorers assists card, deep assists, league cards block incl. mas red-only honesty, card kings in search — plus honesty-of-absence checks, 13 pages 200, 9 DOM surfaces clean at 390x844 with console=0 appErrors=0; product bugs = 0)"
else
  echo "HUNT FLAGGED (BAD=$BAD)"; exit 1
fi
