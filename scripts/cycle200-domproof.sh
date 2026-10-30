#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-200 update — the 24-league catalog joins the header search
# («رقابت‌ها جست‌وجوپذیر می‌شوند»)
#
# The probed gap (live probe 2026-10-30, UA Chrome/124): «لالیگا»,
# «پریمیرلیگ», "LaLiga", "Bundesliga" all answered ZERO to /api/search
# while every catalog league has a live /league/{key} page and the
# bilingual catalog (faName/enName, 24 entries) already sits in
# src/lib/leagues.ts. Fix: searchLeagues folds the IN-MEMORY catalog —
# zero upstream fetches, the same matching mechanics as searchPlayers
# (normalizeQuery both sides, exact > prefix > includes > all-words,
# rangeOf highlight spans), ties by the catalog priority; the answer
# rides a NEW `leagues` field (the cycle-166 additive-field precedent —
# existing clients reading results/players stay untouched); the search
# dialog gains a «رقابت‌ها» section between teams and players, every row
# a real /league/{key} link with the league logo and the «رقابت» badge;
# keyboard order matches (teams → leagues → players); NO text pin moves
# (the empty-state hint «تیم‌ها و آقای گل‌های ۲۴ لیگ و جام» stays
# byte-identical — the 166 gate pins it).
#
# Pinned catalog truth (byte-safe, in-repo): laliga 87 «لالیگا اسپانیا»,
# bundesliga 54 «بوندسلیگا آلمان», ucl 42 «لیگ قهرمانان اروپا» priority 1,
# pl 47 priority 2 — the catalog is code, these are immutable.
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API proof (6 gates) =="
A_OUT=$(python3 - <<'PY'
import json, urllib.request, urllib.parse
BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}
def get(u):
    return json.load(urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=30))
def L(q):
    return get(f"{BASE}/api/search?q={urllib.parse.quote(q)}").get("leagues") or []
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

# A1: the Persian query — «لالیگا» hits laliga byte-exact with a highlight span
try:
    r = L("لالیگا")
    r0 = r[0] if r else {}
    good = (len(r) == 1 and r0.get("key") == "laliga" and r0.get("fa") == "لالیگا اسپانیا"
            and r0.get("en") == "LaLiga" and r0.get("leagueId") == 87
            and isinstance((r0.get("hl") or {}).get("fa"), list))
    report("A1 لالیگا → laliga byte-exact + hl", good,
           f"n={len(r)} r0={r0.get('key')}/{r0.get('leagueId')}/{r0.get('matchedOn')}")
except Exception as e:
    report("A1 لالیگا → laliga byte-exact + hl", False, repr(e))

# A2: the Latin query — Bundesliga (NFD-fold/lowercase both sides)
try:
    r = L("Bundesliga")
    r0 = r[0] if r else {}
    good = len(r) >= 1 and r0.get("key") == "bundesliga" and r0.get("leagueId") == 54 \
        and r0.get("fa") == "بوندسلیگا آلمان" and isinstance((r0.get("hl") or {}).get("en"), list)
    report("A2 Latin Bundesliga → bundesliga", good,
           f"n={len(r)} r0={r0.get('key')}/hl_en={(r0.get('hl') or {}).get('en')}")
except Exception as e:
    report("A2 Latin Bundesliga → bundesliga", False, repr(e))

# A3: «لیگ قهرمانان» — the cup wins, priority order respected on ties
try:
    r = L("لیگ قهرمانان")
    r0 = r[0] if r else {}
    good = len(r) >= 1 and r0.get("key") == "ucl" and r0.get("leagueId") == 42
    report("A3 لیگ قهرمانان → ucl", good, f"n={len(r)} keys={[x.get('key') for x in r]}")
except Exception as e:
    report("A3 لیگ قهرمانان → ucl", False, repr(e))

# A4: the word-split path — «لیگ انگلیس» (two words, no direct substring)
try:
    r = L("لیگ انگلیس")
    keys = [x.get("key") for x in r]
    good = "pl" in keys
    report("A4 word-split «لیگ انگلیس» → pl", good, f"keys={keys}")
except Exception as e:
    report("A4 word-split «لیگ انگلیس» → pl", False, repr(e))

# A5: the additive contract — teams and players still ride the SAME answer
try:
    d = get(f"{BASE}/api/search?q=" + urllib.parse.quote("رئال مادرید"))
    team_ok = any(r.get("teamId") == 8633 for r in (d.get("results") or []))
    d2 = get(f"{BASE}/api/search?q=" + urllib.parse.quote("فتای"))
    p = (d2.get("players") or [])
    fetai_ok = len(p) == 1 and p[0].get("playerId") == 1516458 and p[0].get("season") == "2024/2025"
    no_leak = len(L("فتای")) == 0 and len(L("رئال مادرید")) == 0
    good = team_ok and fetai_ok and no_leak
    report("A5 additive: teams+players intact, no league leak", good,
           f"realm={team_ok} fetai={fetai_ok} noLeak={no_leak}")
except Exception as e:
    report("A5 additive: teams+players intact, no league leak", False, repr(e))

# A6: the min-length guard still honest (the cycle-37 message)
try:
    d = get(f"{BASE}/api/search?q=x")
    good = d.get("ok") is True and d.get("leagues") == [] and bool(d.get("message"))
    report("A6 min-length guard shape", good,
           f"ok={d.get('ok')} leagues={d.get('leagues')} msg={'yes' if d.get('message') else 'no'}")
except Exception as e:
    report("A6 min-length guard shape", False, repr(e))

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
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 2
}
snap() { $B eval "JSON.stringify({$1})" 2>/dev/null | tr -d '"\\'; }
clean_ls() { $B eval "localStorage.clear()" >/dev/null 2>&1; }
open_search() {
  $B eval "document.querySelector('[aria-label=\"جستجوی تیم\"]').click();'opened'" >/dev/null 2>&1
  sleep 0.6
}
type_into() {
  $B eval "(function(){var i=document.querySelector('[role=dialog] input');if(!i)return 'noinput';var s=Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype,'value').set;s.call(i,'$1');i.dispatchEvent(new Event('input',{bubbles:true}));return 'typed';})()" >/dev/null 2>&1
}
wait_row() {
  $B wait --fn "[...document.querySelectorAll('[role=dialog] button')].some(function(b){return b.innerText.indexOf('$1')>=0;})" >/dev/null 2>&1
  sleep 1
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

open_page "/"
clean_ls

# B1: the FULL loop — Persian «لالیگا» → the «رقابت‌ها» section with the
# «رقابت» badge → real click → /league/laliga renders
open_search
type_into "لالیگا"
wait_row "لالیگا اسپانیا"
FEAT=$(snap 'sec:document.body.innerText.indexOf("رقابت‌ها")>=0,badge:[...document.querySelectorAll("[role=dialog] button")].some(function(b){return b.innerText.indexOf("لالیگا اسپانیا")>=0&&b.innerText.indexOf("رقابت")>=0;}),n:[...document.querySelectorAll("[role=dialog] button")].filter(function(b){return b.innerText.indexOf("لالیگا اسپانیا")>=0;}).length')
B1=0
echo "$FEAT" | rg -q 'sec:true' || B1=1
echo "$FEAT" | rg -q 'badge:true' || B1=1
echo "$FEAT" | rg -q 'n:1' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 لالیگا → رقابت‌ها section + badge" "$FEAT"
$B eval '(function(){var b=[...document.querySelectorAll("[role=dialog] button")].find(function(x){return x.innerText.indexOf("لالیگا اسپانیا")>=0;});if(!b)return "norow";b.click();return "clicked"})()' >/dev/null 2>&1
$B wait --fn 'location.pathname === "/league/laliga"' >/dev/null 2>&1
sleep 2
FEAT=$(snap 'path:location.pathname,h1:(document.querySelector("h1")||{}).innerText||""')
B1=0
echo "$FEAT" | grep -q 'path:/league/laliga' || B1=1
[ -n "$FEAT" ] || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1b click → /league/laliga renders" "$FEAT"
clean_ls

# B2: the Latin loop — "Bundesliga" → the Persian row «بوندسلیگا آلمان»
# → click → /league/bundesliga (dual-alphabet end-to-end)
open_page "/"
open_search
type_into "Bundesliga"
wait_row "بوندسلیگا آلمان"
FEAT=$(snap 'n:[...document.querySelectorAll("[role=dialog] button")].filter(function(b){return b.innerText.indexOf("بوندسلیگا آلمان")>=0;}).length,latin:document.body.innerText.indexOf("Bundesliga")>=0')
B2=0
echo "$FEAT" | rg -q 'n:1' || B2=1
echo "$FEAT" | rg -q 'latin:true' || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 Latin Bundesliga → Persian row" "$FEAT"
$B eval '(function(){var b=[...document.querySelectorAll("[role=dialog] button")].find(function(x){return x.innerText.indexOf("بوندسلیگا آلمان")>=0;});if(!b)return "norow";b.click();return "clicked"})()' >/dev/null 2>&1
$B wait --fn 'location.pathname === "/league/bundesliga"' >/dev/null 2>&1
sleep 2
FEAT=$(snap 'path:location.pathname,h1:(document.querySelector("h1")||{}).innerText||""')
B2=0
echo "$FEAT" | grep -q 'path:/league/bundesliga' || B2=1
[ -n "$FEAT" ] || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2b click → /league/bundesliga renders" "$FEAT"
clean_ls

# B3: the 194/166 loops stay byte-identical — «فتای» still EXACTLY one row
# (no league section leaks into a player query) with the season hint
open_page "/"
open_search
type_into "فتای"
wait_row "فتا فتای"
FEAT=$(snap 'n:[...document.querySelectorAll("[role=dialog] button")].filter(function(b){return b.innerText.indexOf("فتا فتای")>=0;}).length,sec:document.body.innerText.indexOf("رقابت‌ها")>=0,hint:[...document.querySelectorAll("[role=dialog] button")].some(function(b){var t=b.innerText;return t.indexOf("فتا فتای")>=0&&t.indexOf("۲۰۲۴/۲۰۲۵")>=0;})')
B3=0
echo "$FEAT" | rg -q 'n:1' || B3=1
echo "$FEAT" | rg -q 'sec:false' || B3=1
echo "$FEAT" | rg -q 'hint:true' || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 فتای loop byte-identical, no league leak" "$FEAT"
clean_ls

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK — cycle-200 update proven (A 6/6 + B 3/3 @390x844): the 24-league catalog is searchable in both alphabets with the «رقابت» badge and real /league links, teams/players loops byte-identical"
else
  echo "DOM_PROOF BAD=$BAD"
  exit 1
fi
