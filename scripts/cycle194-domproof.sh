#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-194 fix — the historical card kings join the search pool
# («شاه‌های تاریخی جست‌وجوپذیر می‌شوند»)
#
# The OPEN half of the cycle-188 honest observation: the five historical-only
# kings (Feta Fetai hnl 2024/2025 yellow 14؛ Uros Radakovic superlig
# 2024/2025 red 4؛ Iván Alejo laliga 2023/2024 yellow 17؛ Hannes van der
# Bruggen belgium 2023/2024 yellow 12؛ Flynn Downes pl 2024/2025 yellow 12)
# never ride a CURRENT standings payload, so the cycle-166 player pool — fed
# only by the current sweep (scorers+assists+cards) — never contained them.
# Cycle-189 closed the nameFa half (their profiles/rows render Persian); the
# searchability half lands here: FIVE ZERO-fetch static fold rows pinned from
# the live historical payloads (scripts/cycle194-probe.py, 2026-10-30, UA
# Chrome/124 — P1 defect 10/10 absent؛ P2 exact block bytes؛ P4 no current
# collision), folded AFTER the sweep behind the seen-set (a live row always
# wins, single-listed). fa rides playerFa (the 104 map contract); rank 0 =
# the no-hint convention; goals stays UNDEFINED (card counts are not goals);
# each fold carries season («۲۰۲۴/۲۰۲۵») — the search box renders the honest
# finished-season hint «لیگ برتر کرواسی · ۲۰۲۴/۲۰۲۵» while current rows
# (no season field) render byte-identically.
#
# Pinned AFTER-fix truth this gate asserts:
#   /api/search?q=فتای|Fetai          → 1516458 «فتا فتای» hnl 2024/2025
#   /api/search?q=داونز|Downes        → 844943 «فلیین داونز» pl 2024/2025
#   /api/search?q=آلخو                → 640089 «ایوان آلخو» laliga 2023/2024
#   /api/search?q=بروخن|Van der...    → 232299 «هانس فان در بروخن» belgium
#   /api/search?q=راداکوویچ|Radaković → 364855 «اوروش راداکوویچ» superlig
#   current rows carry NO season key (Raphinha 696679 unchanged)
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API proof (8 gates) =="
A_OUT=$(python3 - <<'PY'
import json, urllib.request, urllib.parse, urllib.error
BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}
def get(u):
    req = urllib.request.Request(u, headers=UA)
    return json.load(urllib.request.urlopen(req, timeout=30))
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")
def hit(q, pid):
    d = get(f"{BASE}/api/search?q={urllib.parse.quote(q)}")
    rows = [p for p in (d.get("players") or []) if p.get("playerId") == pid]
    return (rows[0] if rows else None), len(rows)

# A1: Fetai — both alphabets, the pinned fold bytes (name/teamFa/season/
# leagueKey) and exactly ONE row per query
try:
    r1, n1 = hit("فتای", 1516458)
    r2, n2 = hit("Fetai", 1516458)
    good = r1 and r2 and n1 == 1 and n2 == 1 \
        and r1.get("fa") == "فتا فتای" and r1.get("name") == "Feta Fetai" \
        and r1.get("teamFa") == "لوکوموتیوا" and r1.get("teamId") == 175388 \
        and r1.get("season") == "2024/2025" and r1.get("leagueKey") == "hnl" \
        and r1.get("leagueFa") == "لیگ برتر کرواسی"
    report("A1 Fetai searchable both alphabets", good,
           f"fa={r1.get('fa') if r1 else None} n={n1}/{n2} season={r1.get('season') if r1 else None}")
except Exception as e:
    report("A1 Fetai searchable both alphabets", False, repr(e))

# A2: Downes — Persian query, pl fold bytes
try:
    r, n = hit("داونز", 844943)
    good = r and n == 1 and r.get("fa") == "فلیین داونز" \
        and r.get("name") == "Flynn Downes" and r.get("teamFa") == "ساوتهمپتون" \
        and r.get("season") == "2024/2025" and r.get("leagueKey") == "pl"
    report("A2 Downes searchable (fa query)", good,
           f"fa={r.get('fa') if r else None} team={r.get('teamFa') if r else None}")
except Exception as e:
    report("A2 Downes searchable (fa query)", False, repr(e))

# A3: Alejo — the 2023/2024 laliga fold bytes
try:
    r, n = hit("آلخو", 640089)
    good = r and n == 1 and r.get("fa") == "ایوان آلخو" \
        and r.get("name") == "Iván Alejo" and r.get("teamFa") == "کادیز" \
        and r.get("season") == "2023/2024" and r.get("leagueKey") == "laliga"
    report("A3 Alejo searchable (fa query)", good,
           f"fa={r.get('fa') if r else None} team={r.get('teamFa') if r else None}")
except Exception as e:
    report("A3 Alejo searchable (fa query)", False, repr(e))

# A4: Van der Bruggen — fa + Latin queries, belgium fold bytes
try:
    r1, n1 = hit("بروخن", 232299)
    r2, n2 = hit("Van Der Bruggen", 232299)
    good = r1 and r2 and n1 == 1 and n2 == 1 \
        and r1.get("fa") == "هانس فان در بروخن" \
        and r1.get("name") == "Hannes van der Bruggen" \
        and r1.get("teamFa") == "سرکل بروژ" and r1.get("season") == "2023/2024"
    report("A4 Bruggen searchable both alphabets", good,
           f"fa={r1.get('fa') if r1 else None} n={n1}/{n2}")
except Exception as e:
    report("A4 Bruggen searchable both alphabets", False, repr(e))

# A5: Radakovic — fa + DIACRITIC Latin query (Radaković NFD-folds onto the
# ASCII row spelling — the 189 two-keys lesson, now on the search side)
try:
    r1, n1 = hit("راداکوویچ", 364855)
    r2, n2 = hit("Radaković", 364855)
    good = r1 and r2 and n1 == 1 and n2 == 1 \
        and r1.get("fa") == "اوروش راداکوویچ" \
        and r1.get("name") == "Uros Radakovic" \
        and r1.get("teamFa") == "سیواس‌اسپور" and r1.get("season") == "2024/2025"
    report("A5 Radakovic searchable incl diacritic", good,
           f"fa={r1.get('fa') if r1 else None} n={n1}/{n2}")
except Exception as e:
    report("A5 Radakovic searchable incl diacritic", False, repr(e))

# A6: the fold rows never LIE — no goals key (card counts), rank 0, and the
# diacritic profile spelling never leaks into the index row
try:
    rows = []
    for q, pid in (("فتای", 1516458), ("داونز", 844943), ("آلخو", 640089),
                   ("بروخن", 232299), ("راداکوویچ", 364855)):
        r, n = hit(q, pid)
        rows.append((r, n))
    good = all(r is not None and n == 1 and "goals" not in r and r.get("rank") == 0
               and r.get("season") in ("2023/2024", "2024/2025")
               for r, n in rows)
    report("A6 fold rows honest (no goals/rank0/season)", good,
           f"ok={[(r.get('rank'), 'goals' in r, r.get('season')) for r, n in rows]}")
except Exception as e:
    report("A6 fold rows honest (no goals/rank0/season)", False, repr(e))

# A7: the additive contract — current rows carry NO season key (Raphinha
# renders exactly as before) and the current race byte-parity holds
try:
    d = get(f"{BASE}/api/search?q={urllib.parse.quote('رافینیا')}")
    rp = [p for p in (d.get("players") or []) if p.get("playerId") == 696679]
    t = get(BASE + "/api/topscorers")
    s0 = (t.get("scorers") or [{}])[0]
    good = len(rp) == 1 and "season" not in rp[0] \
        and len(t.get("scorers") or []) == 400 and len(t.get("perLeague") or []) == 20 \
        and t.get("selectedSeason") == "2026/2027" \
        and s0.get("playerId") == 696679 and s0.get("nameFa") == "رافینیا"
    report("A7 current rows season-free + race parity", good,
           f"raphinha_season={'season' in rp[0] if rp else '?'} s0={s0.get('playerId')}")
except Exception as e:
    report("A7 current rows season-free + race parity", False, repr(e))

# A8: the 188/189 pins survive — hist merge kings intact (the fold must not
# have touched the historical surfaces themselves)
try:
    q = urllib.parse.quote("2024/2025", safe="")
    d = get(f"{BASE}/api/topscorers?season={q}")
    s0 = (d.get("scorers") or [{}])[0]
    y0 = ((d.get("cards") or {}).get("yellow") or [{}])[0]
    r0 = ((d.get("cards") or {}).get("red") or [{}])[0]
    q2 = urllib.parse.quote("2023/2024", safe="")
    d2 = get(f"{BASE}/api/topscorers?season={q2}")
    y02 = ((d2.get("cards") or {}).get("yellow") or [{}])[0]
    good = len(d.get("scorers") or []) == 380 \
        and s0.get("playerId") == 664500 and s0.get("goals") == 39 \
        and y0.get("playerId") == 1516458 and y0.get("nameFa") == "فتا فتای" \
        and r0.get("playerId") == 364855 and r0.get("value") == 4 \
        and y02.get("playerId") == 640089 and y02.get("value") == 17
    report("A8 188/189 hist pins survive", good,
           f"s0={s0.get('playerId')}/{s0.get('goals')} y0={y0.get('nameFa')}")
except Exception as e:
    report("A8 188/189 hist pins survive", False, repr(e))

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
row_stat() {
  $B eval "JSON.stringify({n:[...document.querySelectorAll('[role=dialog] button')].filter(function(b){return b.innerText.indexOf('$1')>=0;}).length,hint:[...document.querySelectorAll('[role=dialog] button')].some(function(b){var t=b.innerText;return t.indexOf('$1')>=0&&t.indexOf('$2')>=0;})})" 2>/dev/null | tr -d '"\\'
}
click_row() {
  $B eval "(function(){var b=[...document.querySelectorAll('[role=dialog] button')].find(function(x){return x.innerText.indexOf('$1')>=0;});if(!b)return 'norow';b.click();return 'clicked';})()" >/dev/null 2>&1
}

open_page "/"
clean_ls

# B1: the FULL loop for Fetai — Persian query → exactly one row with the
# finished-season hint → real row click → /player/1516458 h1 «فتا فتای»
open_search
type_into "فتای"
wait_row "فتا فتای"
FEAT=$(row_stat "فتا فتای" "۲۰۲۴/۲۰۲۵")
B1=0
echo "$FEAT" | rg -q 'n:1' || B1=1
echo "$FEAT" | rg -q 'hint:true' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 search فتای → 1 row + season hint" "$FEAT"
click_row "فتا فتای"
$B wait --fn "location.pathname==='/player/1516458'" >/dev/null 2>&1
sleep 1.5
FEAT=$(snap 'path:location.pathname,h1:(document.querySelector("h1")||{}).innerText||""')
B1=0
echo "$FEAT" | rg -q 'path:/player/1516458' || B1=1
echo "$FEAT" | grep -q "فتا فتای" || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1b click → /player/1516458 Persian h1" "$FEAT"
clean_ls

# B2: Radakovic — the diacritic-profile player found via the Persian query
# (the ASCII standings spelling rides the fold; the map unifies both)
open_page "/"
open_search
type_into "راداکوویچ"
wait_row "اوروش راداکوویچ"
FEAT=$(row_stat "اوروش راداکوویچ" "۲۰۲۴/۲۰۲۵")
B2=0
echo "$FEAT" | rg -q 'n:1' || B2=1
echo "$FEAT" | rg -q 'hint:true' || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 search راداکوویچ → 1 row + hint" "$FEAT"
clean_ls

# B3: Downes via LATIN query → the PERSIAN row renders (cross-alphabet)
open_page "/"
open_search
type_into "Downes"
wait_row "فلیین داونز"
FEAT=$(row_stat "فلیین داونز" "ساوتهمپتون")
B3=0
echo "$FEAT" | rg -q 'n:1' || B3=1
echo "$FEAT" | rg -q 'hint:true' || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 search Downes → Persian row + team" "$FEAT"
clean_ls

# B4: Bruggen — the 2023/2024 hint (the other season byte)
open_page "/"
open_search
type_into "بروخن"
wait_row "هانس فان در بروخن"
FEAT=$(row_stat "هانس فان در بروخن" "۲۰۲۳/۲۰۲۴")
B4=0
echo "$FEAT" | rg -q 'n:1' || B4=1
echo "$FEAT" | rg -q 'hint:true' || B4=1
[ "$B4" -eq 0 ] || BAD=$((BAD+1))
gate "B4 search بروخن → 1 row + 2023/2024 hint" "$FEAT"
clean_ls

# B5: the additive contract IN DOM — the current star's row exists and
# carries NO finished-season hint (current rows render byte-identically)
open_page "/"
open_search
type_into "رافینیا"
wait_row "رافینیا"
FEAT=$(snap 'n:[...document.querySelectorAll("[role=dialog] button")].filter(function(b){return b.innerText.indexOf("رافینیا")>=0;}).length,noseason:[...document.querySelectorAll("[role=dialog] button")].filter(function(b){return b.innerText.indexOf("رافینیا")>=0;}).every(function(b){return b.innerText.indexOf("۲۰۲۳/۲۰۲۴")<0&&b.innerText.indexOf("۲۰۲۴/۲۰۲۵")<0;})')
B5=0
echo "$FEAT" | rg -q 'n:1' || B5=1
echo "$FEAT" | rg -q 'noseason:true' || B5=1
[ "$B5" -eq 0 ] || BAD=$((BAD+1))
gate "B5 Raphinha row season-free (additive)" "$FEAT"
clean_ls

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK — cycle-194 fix proven (A 8/8 + B 5/5 @390x844)"
else
  echo "DOM_PROOF BAD=$BAD"
  exit 1
fi
