#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-195 update — the daily feed's teams join the team search index
# («تیم‌های فید روزانه جست‌وجوپذیر می‌شوند»)
#
# The probed gap (scripts/cycle195-probe.py, 2026-10-30, UA Chrome/124):
# the team index = the 24 portal tables + 7 hand-pinned 79-fallbacks, while
# the ALREADY-cached daily matches feed carried 94 competitions / 340 unique
# teams that day — 37 of 40 sampled out-of-portal teams (MLS, Brasileirão
# Série B, Thai League 2, SWPL Cup…) answered ZERO to /api/search even
# though /team/{id} fully serves them (HTTP 200 both page and API — no dead
# links). Fix: getTeamIndex folds the TODAY feed's teams AFTER the portal
# sweep and the fallbacks, behind the seen-set (portal rows win — rank/pts
# intact), rank 0 = the no-hint convention, leagueFa from the feed group,
# ZERO extra upstream fetches (the feed rides its own 45s cache), a feed
# failure never takes the core index down (try/catch).
#
# This gate is FEED-DRIVEN on purpose (the 193 drift lesson): today's pin
# (Criciúma 7729 / Thai League 2 sides) drifts tomorrow, so the gate derives
# its expectations from the live feed at run time and pins only the
# invariants: out-of-portal feed teams become searchable with their group's
# Persian label; portal anchors stay single-listed and byte-identical;
# the 194 kings fold survives.
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

PORTAL = {"LaLiga","Premier League","Serie A","Bundesliga","Ligue 1","UEFA Champions League",
          "UEFA Europa League","UEFA Conference League","Persian Gulf Pro League","Saudi Pro League",
          "Süper Lig","Scottish Premiership","EFL Championship","Liga Portugal","UAE Pro League",
          "Qatar Stars League","Eredivisie","AFC Champions League Elite","AFC Champions League Two",
          "Croatian HNL","Belgian Pro League","Ekstraklasa"}
feed = get(f"{BASE}/api/matches")
groups = feed.get("groups") or []
feed_teams = {}
for g in groups:
    for m in g.get("matches") or []:
        for side in (m.get("home"), m.get("away")):
            if side and side.get("id") and side["id"] not in feed_teams:
                feed_teams[side["id"]] = {"name": side.get("name"), "fa": side.get("fa"),
                                          "leagueFa": g.get("leagueFa"), "leagueName": g.get("leagueName")}

# A1: a NON-portal feed team is searchable NOW (row exists — any rank;
# the seen-set means a portal-table team like Slaven Belupo keeps its
# standings rank), with ≥80% of a 12-team sample landing
non_portal = [t for t in feed_teams.items()
              if t[1]["leagueName"] not in PORTAL and len((t[1]["fa"] or t[1]["name"] or "")) >= 3]
non_portal.sort(key=lambda kv: kv[0])
found = 0; checked = 0; sample = None
for tid, t in non_portal[:12]:
    q = t["fa"] or t["name"]
    d = get(f"{BASE}/api/search?q={urllib.parse.quote(q)}")
    row = next((r for r in (d.get("results") or []) if r.get("teamId") == tid), None)
    checked += 1
    if row:
        found += 1
        if row.get("rank") == 0 and sample is None:
            sample = {"q": q, "row": row, "want": t}
good = checked > 0 and found >= max(1, int(checked * 0.8))
report("A1 non-portal feed teams searchable (>=80% of 12)", good,
       f"{found}/{checked} fold-sample={'none (all portal — portal wins by design)' if sample is None else sample['q']!r}")

# A2: a TRUE fold row (rank 0 / pts 0 — the no-hint convention) carries the
# group's Persian competition label and a logo; feed teams whose side also
# rides a portal table (e.g. Croatian HNL clubs) legitimately keep rank>0
if sample is None:
    # fall back: scan wider until a rank-0 row appears (today: 37/40 were fold rows)
    for tid, t in non_portal[12:60]:
        q = t["fa"] or t["name"]
        d = get(f"{BASE}/api/search?q={urllib.parse.quote(q)}")
        row = next((r for r in (d.get("results") or []) if r.get("teamId") == tid and r.get("rank") == 0), None)
        if row:
            sample = {"q": q, "row": row, "want": t}
            break
good = sample is not None \
    and sample["row"].get("rank") == 0 and sample["row"].get("pts") == 0 \
    and bool(sample["row"].get("logo")) and bool(sample["row"].get("name")) \
    and bool(sample["row"].get("fa")) \
    and sample["row"].get("leagueFa") == sample["want"]["leagueFa"]
report("A2 true fold row honest shape + group label", good,
       f"q={sample['q']!r} rank={sample['row'].get('rank')} pts={sample['row'].get('pts')} leagueFa={sample['row'].get('leagueFa')!r}" if sample else "no fold row found")

# A3: portal anchors stay SINGLE-LISTED (the seen-set) and byte-identical
d = get(f"{BASE}/api/search?q={urllib.parse.quote('رئال مادرید')}")
rm = [r for r in (d.get("results") or []) if r.get("teamId") == 8633]
good = len(rm) == 1 and rm[0].get("leagueFa") == "لالیگا اسپانیا" and rm[0].get("rank", 0) > 0
report("A3 Real Madrid single-listed portal row", good,
       f"n={len(rm)} leagueFa={rm[0].get('leagueFa') if rm else None} rank={rm[0].get('rank') if rm else None}")

d = get(f"{BASE}/api/search?q={urllib.parse.quote('پرسپولیس')}")
pp = [r for r in (d.get("results") or []) if r.get("teamId") == 101610]
good = len(pp) == 1 and pp[0].get("leagueFa") == "لیگ خلیج فارس ایران"
report("A4 Persepolis fallback row intact", good,
       f"n={len(pp)} leagueFa={pp[0].get('leagueFa') if pp else None}")

# A5: the 79 fallback (Celtic) still answers — whatever league label the
# sweep serves today (drift-tolerant: FOUND + non-empty label)
d = get(f"{BASE}/api/search?q=Celtic")
ce = [r for r in (d.get("results") or []) if r.get("teamId") == 9925]
good = len(ce) == 1 and bool(ce[0].get("leagueFa"))
report("A5 Celtic 79-fallback intact", good,
       f"n={len(ce)} leagueFa={ce[0].get('leagueFa') if ce else None}")

# A6: women's same-name clubs do not collide (SWPL Hearts 1716177, fa
# «هارتس», vs the men's 9860 fallback, fa «هارت») — the seen-set keys on id,
# so a query matching BOTH spellings lists BOTH ids, each exactly once
d = get(f"{BASE}/api/search?q={urllib.parse.quote('هارتس')}")
rows = [r for r in (d.get("results") or []) if r.get("teamId") in (9860, 1716177)]
ids = [r.get("teamId") for r in rows]
good = sorted(ids) == [9860, 1716177]
report("A6 same-name club no collision (both Hearts)", good,
       f"ids={ids}")

# A7: the 194 kings fold survives on the same index machinery
d = get(f"{BASE}/api/search?q={urllib.parse.quote('فتای')}")
fk = [p for p in (d.get("players") or []) if p.get("playerId") == 1516458]
good = len(fk) == 1 and fk[0].get("season") == "2024/2025"
report("A7 194 kings fold survives", good,
       f"n={len(fk)} season={fk[0].get('season') if fk else None}")

# A8: the route contract unchanged — short query message + shape
d = get(f"{BASE}/api/search?q=%D9%81")
good = d.get("ok") is True and "results" in d and "players" in d \
    and isinstance(d.get("message"), str) and len(d["message"]) > 5
report("A8 route contract (short query message)", good,
       f"msg={str(d.get('message'))[:40]!r}")
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

# pick TODAY's non-portal team dynamically (the 193 drift lesson)
read -r T_ID T_NAME T_LGFA < <(python3 - <<'PY'
import json, urllib.request, urllib.parse
BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}
def get(u):
    return json.load(urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=30))
PORTAL = {"LaLiga","Premier League","Serie A","Bundesliga","Ligue 1","UEFA Champions League",
          "UEFA Europa League","UEFA Conference League","Persian Gulf Pro League","Saudi Pro League",
          "Süper Lig","Scottish Premiership","EFL Championship","Liga Portugal","UAE Pro League",
          "Qatar Stars League","Eredivisie","AFC Champions League Elite","AFC Champions League Two",
          "Croatian HNL","Belgian Pro League","Ekstraklasa"}
d = get(f"{BASE}/api/matches")
teams = {}
for g in d.get("groups") or []:
    for m in g.get("matches") or []:
        for side in (m.get("home"), m.get("away")):
            if side and side.get("id") and side["id"] not in teams:
                teams[side["id"]] = (g.get("leagueName"), g.get("leagueFa"),
                                     side.get("fa") or side.get("name") or "", side.get("name") or "")
for tid in sorted(teams):
    lgn, lgf, fa, name = teams[tid]
    if lgn not in PORTAL and name and len(name) >= 5 and any(ch.isascii() and ch.isalpha() for ch in name):
        # the search types the LATIN name — normalizeQuery folds case/diacritics
        latin = name.replace("'", "").replace(".", " ")
        print(tid, latin.replace(" ", "_"), (lgf or "").replace(" ", "_"))
        break
PY
)
T_NAME="${T_NAME//_/ }"; T_LGFA="${T_LGFA//_/ }"
echo "feed-driven team: id=$T_ID name=$T_NAME leagueFa=$T_LGFA"
[ -n "$T_ID" ] || { echo "no feed team picked"; exit 1; }

open_page "/"
clean_ls

# B1: the full loop — type the Latin name → the feed team's row renders with
# its competition label → real click → /team/{id} (no dead links)
open_search
type_into "$T_NAME"
wait_row "$T_NAME"
FEAT=$(snap 'n:[...document.querySelectorAll("[role=dialog] button")].filter(function(b){return b.innerText.indexOf("'"$T_NAME"'")>=0;}).length,lg:[...document.querySelectorAll("[role=dialog] button")].some(function(b){return b.innerText.indexOf("'"$T_NAME"'")>=0&&b.innerText.indexOf("'"$T_LGFA"'")>=0;})')
B1=0
echo "$FEAT" | rg -q 'n:[1-9]' || B1=1
echo "$FEAT" | rg -q 'lg:true' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 feed team row + competition label" "$FEAT | team=$T_NAME lg=$T_LGFA"
$B eval "(function(){var b=[...document.querySelectorAll('[role=dialog] button')].find(function(x){return x.innerText.indexOf('$T_NAME')>=0;});if(!b)return 'norow';b.click();return 'clicked';})()" >/dev/null 2>&1
$B wait --fn "location.pathname==='/team/$T_ID'" >/dev/null 2>&1
sleep 2
FEAT=$(snap 'path:location.pathname,h1:(document.querySelector("h1")||{}).innerText||""')
B1=0
echo "$FEAT" | rg -q "path:/team/$T_ID" || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1b click → /team/$T_ID live page" "$FEAT"
clean_ls

# B2: a portal anchor in DOM — the display name is «رئال‌مادرید» with a ZWNJ
# (the API matched word-level), so the DOM needle is «مادرید» — the row must
# be exactly ONE and carry the rank badge («رتبه»)
open_page "/"
open_search
type_into "رئال مادرید"
wait_row "مادرید"
FEAT=$(snap 'n:[...document.querySelectorAll("[role=dialog] button")].filter(function(b){return b.innerText.indexOf("مادرید")>=0;}).length,ranked:[...document.querySelectorAll("[role=dialog] button")].some(function(b){return b.innerText.indexOf("مادرید")>=0&&b.innerText.indexOf("رتبه")>=0;})')
B2=0
echo "$FEAT" | rg -q 'n:1' || B2=1
echo "$FEAT" | rg -q 'ranked:true' || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+2))
gate "B2 Real Madrid single row + rank badge" "$FEAT"
clean_ls

# B3: the 194 king row still renders in the players section (co-existence)
open_page "/"
open_search
type_into "فتای"
wait_row "فتا فتای"
FEAT=$(snap 'n:[...document.querySelectorAll("[role=dialog] button")].filter(function(b){return b.innerText.indexOf("فتا فتای")>=0;}).length,hint:[...document.querySelectorAll("[role=dialog] button")].some(function(b){return b.innerText.indexOf("فتا فتای")>=0&&b.innerText.indexOf("۲۰۲۴/۲۰۲۵")>=0;})')
B3=0
echo "$FEAT" | rg -q 'n:1' || B3=1
echo "$FEAT" | rg -q 'hint:true' || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 194 king row co-exists" "$FEAT"
clean_ls

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK — cycle-195 update proven (A 8/8 + B 3/3 @390x844, feed-driven team $T_NAME)"
else
  echo "DOM_PROOF BAD=$BAD"
  exit 1
fi
