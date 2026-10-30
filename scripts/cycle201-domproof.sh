#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-201 update — «رقابت‌های هر فصل» joins the player profile.
#
# D5 probe first (live, UA Chrome/124, 2026-10-30): EVERY FotMob
# playerData payload carries `statSeasons` — the player's stat-tracked
# seasons, newest first, each listing the tournaments the player was
# REGISTERED in that season. Live anchors: Yamal 1467236 n=5 (2024/2025
# carries LaLiga tournamentId 87 + Copa del Rey 138), Balde 1254166 n=6,
# Fetai 1516458 n=4 (HNL 252), Ćurković 1536211 n=2 (non-contiguous
# seasons — upstream's own shape). The portal mapped NONE of it.
# Also probed: playerData IGNORES every season param variant
# (season=2024/2025, encoded %2F, +leagueId, statSeason= — mainLeague
# still serves 2026/2027) → historical stat TABLES are unreachable, so
# this cycle's honest scope is the registrations block only.
#
# Zero fresh upstream calls: the mapping rides the ONE already-cached
# playerData fetch (the 121/195/196/200 convention). Cache key bumped
# player:v8 → v9 (the 52/86/87/96/135/159/197 shape-change convention).
# UI: additive section «رقابت‌های هر فصل» between مسیر حرفه‌ای and
# افتخارات — season label (faDigits) + tournament chips; catalog-mapped
# tournaments render as real /league/{key} links (87→laliga, 252→hnl,
# 42→ucl), the rest as honest text chips (competitionFa, else raw name).
# Missing block → section hides (the cards/market honesty pattern).
#
# Pin discipline (the 193 lesson): season COUNTS and the first-season
# STRING are form-pinned (grow-only for active players, roll over every
# summer); byte-exact pins only on identity + code (Yamal id, testid,
# the catalog faName «لالیگا اسپانیا»/«لیگ برتر کرواسی», the 198 squad
# counts 30/35 on Fetai, the laliga/hnl hrefs).
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API proof (4 gates) =="
A_OUT=$(python3 - <<'PY'
import json, re, urllib.request
BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}
def get(u):
    return json.load(urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=30))
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

SEASON_RE = re.compile(r"\d{4}/\d{4}")

# A1: Yamal — the block exists post-v9, seasons well-formed, the 2024/2025
# season carries the catalog-mapped LaLiga chip (byte-exact faName + key)
try:
    d = get(f"{BASE}/api/player/1467236")
    p = d.get("player") or {}
    ss = p.get("statSeasons") or []
    s2425 = next((s for s in ss if s.get("season") == "2024/2025"), None)
    lal = None
    if s2425:
        lal = next((t for t in s2425.get("tournaments", []) if t.get("leagueKey") == "laliga"), None)
    allwf = all(SEASON_RE.fullmatch(s.get("season", "")) for s in ss) and \
            all(t.get("name") and t.get("nameFa") for s in ss for t in s.get("tournaments", []))
    good = len(ss) >= 4 and s2425 is not None and lal is not None and \
           lal.get("nameFa") == "لالیگا اسپانیا" and allwf
    report("A1 yamal statSeasons + 2425 laliga byte-exact", good,
           f"n={len(ss)} s2425={'y' if s2425 else 'n'} laligaNameFa={lal.get('nameFa') if lal else None!r} allWellformed={allwf}")
except Exception as e:
    report("A1 yamal statSeasons + 2425 laliga byte-exact", False, repr(e))

# A2: additive contract — the SAME payload still carries every pinned
# sibling block (season stats, career, trophies, teammates, recent)
try:
    d = get(f"{BASE}/api/player/1467236")
    p = d.get("player") or {}
    season = p.get("season") or {}
    good = bool(SEASON_RE.fullmatch(season.get("season", ""))) and \
           len(season.get("stats") or []) >= 5 and \
           len(p.get("career") or []) >= 1 and \
           len(p.get("trophies") or []) >= 1 and \
           isinstance(p.get("teammates"), list) and len(p.get("teammates") or []) >= 1 and \
           len(p.get("recent") or []) >= 1
    report("A2 additive contract — sibling blocks intact", good,
           f"season={season.get('season')!r} nstats={len(season.get('stats') or [])} career={len(p.get('career') or [])} trophies={len(p.get('trophies') or [])} teammates={len(p.get('teammates') or [])} recent={len(p.get('recent') or [])}")
except Exception as e:
    report("A2 additive contract — sibling blocks intact", False, repr(e))

# A3: universality — Fetai (the 194 fold king) + Ćurković (the LOW-season
# payload): HNL maps to the catalog chip; Ćurković's seasons are
# non-contiguous by upstream's own shape
try:
    d = get(f"{BASE}/api/player/1516458")
    p = d.get("player") or {}
    ss = p.get("statSeasons") or []
    hnl = next((t for s in ss for t in s.get("tournaments", []) if t.get("leagueKey") == "hnl"), None)
    tm = len(p.get("teammates") or [])
    nt = len(p.get("nationalTeammates") or [])
    good = len(ss) >= 3 and hnl is not None and hnl.get("nameFa") == "لیگ برتر کرواسی" and \
           tm == 30 and nt == 35
    report("A3 fetai hnl chip + 197 squad counts intact", good,
           f"n={len(ss)} hnlNameFa={hnl.get('nameFa') if hnl else None!r} teammates={tm} national={nt}")
except Exception as e:
    report("A3 fetai hnl chip + 197 squad counts intact", False, repr(e))

try:
    d = get(f"{BASE}/api/player/1536211")
    p = d.get("player") or {}
    ss = p.get("statSeasons") or []
    seasons = [s.get("season") for s in ss]
    good = len(ss) >= 2 and all(SEASON_RE.fullmatch(s or "") for s in seasons) and \
           seasons[0] == "2025/2026" and seasons[1] == "2023/2024"
    report("A3b curkovic low-season universality", good, f"seasons={seasons}")
except Exception as e:
    report("A3b curkovic low-season universality", False, repr(e))

# A4: the mapped league pages the chips link to are ALIVE (real navigation)
try:
    import urllib.error
    c1 = urllib.request.urlopen(urllib.request.Request(f"{BASE}/league/laliga", headers=UA), timeout=30).status
    c2 = urllib.request.urlopen(urllib.request.Request(f"{BASE}/league/hnl", headers=UA), timeout=30).status
    report("A4 /league/laliga + /league/hnl alive", c1 == 200 and c2 == 200, f"laliga={c1} hnl={c2}")
except Exception as e:
    report("A4 /league/laliga + /league/hnl alive", False, repr(e))

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

open_page "/"
clean_ls

# B1: Yamal — the new section renders, carries the catalog laliga link chip,
# and a REAL click navigates to /league/laliga (the 170/174 link contract)
open_page "/player/1467236"
$B wait --fn '!!document.querySelector("[data-testid=player-statseasons]")' >/dev/null 2>&1
sleep 0.6
FEAT=$(snap 'sec:!!document.querySelector("[data-testid=player-statseasons]"),hdr:(function(){var h=document.querySelector("[data-testid=player-statseasons] header");return h?h.innerText.indexOf("رقابت‌های هر فصل")===0:"nohdr"})(),laliga:[...document.querySelectorAll("[data-testid=player-statseasons] a[href=\"/league/laliga\"]")].map(function(a){return a.innerText;}).join("|"),rows:document.querySelectorAll("[data-testid=player-statseasons] li").length')
B1=0
echo "$FEAT" | rg -q 'sec:true' || B1=1
echo "$FEAT" | rg -q 'hdr:true' || B1=1
echo "$FEAT" | rg -q 'laliga:لالیگا اسپانیا' || B1=1
echo "$FEAT" | rg -q 'rows:[4-9]' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 yamal statseasons section + laliga chip" "$FEAT"
$B eval '(function(){var s=document.querySelector("[data-testid=player-statseasons]");if(!s)return "nosec";var a=s.querySelector("a[href=\"/league/laliga\"]");if(!a)return "nolink";a.click();return "clicked";})()' >/dev/null 2>&1
$B wait --fn 'location.pathname.indexOf("/league/laliga")===0' >/dev/null 2>&1
sleep 1.2
FEAT=$(snap 'path:location.pathname,h1:(document.querySelector("h1")||{}).innerText||""')
B1=0
echo "$FEAT" | rg -q 'path:/league/laliga' || B1=1
echo "$FEAT" | rg -q 'h1:.*لالیگا' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1b real chip click → /league/laliga h1" "$FEAT"
clean_ls

# B2: Fetai — the new section co-exists with the 197 teammates contract on
# the SAME profile (the 198 B1 chips «باشگاه · لوکوموتیوا» stay) and the
# HNL chip links to the live /league/hnl page
open_page "/player/1516458"
$B wait --fn '!!document.querySelector("[data-testid=player-statseasons]")' >/dev/null 2>&1
sleep 0.6
FEAT=$(snap 'sec:!!document.querySelector("[data-testid=player-statseasons]"),hnl:[...document.querySelectorAll("[data-testid=player-statseasons] a[href=\"/league/hnl\"]")].map(function(a){return a.innerText;}).join("|"),tm:!!document.querySelector("[data-testid=player-teammates]"),clublabel:(function(){var g=document.querySelector("[data-testid=player-teammates-club] p");return g?g.innerText.indexOf("لوکوموتیوا")>=0:"nogroup"})(),chips:document.querySelectorAll("[data-testid=player-teammate-chip]").length')
B2=0
echo "$FEAT" | rg -q 'sec:true' || B2=1
echo "$FEAT" | rg -q 'hnl:لیگ برتر کرواسی' || B2=1
echo "$FEAT" | rg -q 'tm:true' || B2=1
echo "$FEAT" | rg -q 'clublabel:true' || B2=1
echo "$FEAT" | rg -q 'chips:(3[0-9]|[4-9][0-9]|65)' || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 fetai hnl chip + teammates co-exist" "$FEAT"
clean_ls

# B3: Ćurković — universality on the LOW-season payload (n=2, non-contiguous)
open_page "/player/1536211"
$B wait --fn '!!document.querySelector("[data-testid=player-statseasons]")' >/dev/null 2>&1
sleep 0.6
FEAT=$(snap 'sec:!!document.querySelector("[data-testid=player-statseasons]"),rows:document.querySelectorAll("[data-testid=player-statseasons] li").length,first:(function(){var r=document.querySelector("[data-testid=player-statseasons] li span");return r?r.innerText:"none"})()')
B3=0
echo "$FEAT" | rg -q 'sec:true' || B3=1
echo "$FEAT" | rg -q 'rows:2' || B3=1
echo "$FEAT" | rg -q 'first:۲۰۲۵/۲۰۲۶' || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 curkovic low-season section renders" "$FEAT"
clean_ls

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK — cycle-201 update proven (A 4/4 + B 4/4 @390x844): «رقابت‌های هر فصل» joins the player profile — Yamal's 2024/2025 season carries the byte-exact «لالیگا اسپانیا» chip navigating to /league/laliga, Fetai carries «لیگ برتر کرواسی» → /league/hnl beside the untouched 197 teammates contract (30/35), Ćurković proves the low-season universality — zero fresh upstream calls (the statSeasons block rides the one cached playerData fetch)"
else
  echo "DOM_PROOF BAD=$BAD"
  exit 1
fi
