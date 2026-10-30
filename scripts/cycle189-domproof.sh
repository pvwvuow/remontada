#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-189 fix — the historical kings get their Persian names
# («شاه‌های تاریخی نام فارسی می‌گیرند»)
#
# The cycle-188 hunt recorded one honest observation (by design, not a
# defect): the historical-only kings — Feta Fetai (hnl 2024/2025 yellow),
# Uros Radakovic (superlig 2024/2025 red), Iván Alejo (laliga 2023/2024
# yellow), Hannes van der Bruggen (belgium 2023/2024 yellow), Flynn Downes
# (pl 2024/2025 yellow) — never enter the current standings, so their rows
# fell back to the raw upstream Latin name on EVERY surface that renders
# nameFa: the profile h1/metadata, the کارت‌ها rows, the global merge.
# Kane escaped only because he is ALSO a current star («هری کین»).
#
# Fix (additive-only, the 104→109 map convention): six keys in
# PLAYER_NAME_FA (Radakovic needs BOTH upstream spellings — the standings
# topscorer files spell him ASCII «Uros Radakovic» while the playerData
# profile spells «Uroš Radaković»; probed 2026-10-30 both bytes). No cache
# namespace bumps needed: the cycle-109 read-time fresheners
# (freshenHonestNames + freshCardNames) and the merge-time playerFa calls
# (getAllCardLeaders line ~3279, getPlayerData) re-apply the map on every
# read — an already-Persian string never matches and falls back to itself.
#
# Pinned live truth (probed 2026-10-30 ~10:5x +08, UA Chrome/124, official
# cycle-187 build BEFORE the fix — all five nameFa == name in Latin):
#   /api/topscorers?season=2024/2025  y0 Feta Fetai 1516458/14 hnl؛
#                                     r0 Uros Radakovic 364855/4 superlig
#   /api/topscorers?season=2023/2024  y0 Iván Alejo 640089/17 laliga
#   /api/topscorers/belgium?2023/2024 y0 Hannes van der Bruggen 232299/12
#   /api/topscorers/pl?2024/2025      y0 Flynn Downes 844943/12
#   /api/topscorers/hnl?2024/2025     y0 Feta Fetai 1516458/14
#   /player/{1516458,640089,232299,844943,364855} SSR h1 = raw Latin
#   (364855 h1 = «Uroš Radaković» WITH diacritics — the second spelling)
# AFTER the fix every one of those renders the mapped Persian:
#   فتا فتای / اوروش راداکوویچ / ایوان آلخو / هانس فان در بروخن /
#   فلیین داونز — while the CURRENT race stays byte-identical
#   (s0 Raphinha 696679 «رافینیا», 400/20 sel=2026/2027).
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API proof (7 gates) =="
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

# A1: global 2024/2025 — the merge's own playerFa: Fetai + Radakovic rows
# now carry the mapped Persian nameFa; the Latin `name` stays untouched
# (the honest upstream identity, pinned by 185/186/188 gates)
try:
    q = urllib.parse.quote("2024/2025", safe="")
    d = get(f"{BASE}/api/topscorers?season={q}")
    y0 = (d.get("cards") or {}).get("yellow") or [{}]
    r0 = (d.get("cards") or {}).get("red") or [{}]
    y0, r0 = (y0 or [{}])[0], (r0 or [{}])[0]
    good = y0.get("playerId") == 1516458 and y0.get("name") == "Feta Fetai" \
        and y0.get("nameFa") == "فتا فتای" and y0.get("value") == 14 \
        and r0.get("playerId") == 364855 and r0.get("name") == "Uros Radakovic" \
        and r0.get("nameFa") == "اوروش راداکوویچ" and r0.get("value") == 4
    report("A1 global hist 2024/2025 kings mapped", good,
           f"y0={y0.get('nameFa')}/{y0.get('value')} r0={r0.get('nameFa')}/{r0.get('value')}")
except Exception as e:
    report("A1 global hist 2024/2025 kings mapped", False, repr(e))

# A2: global 2023/2024 — Iván Alejo (diacritic key) joins the merge Persian
try:
    q = urllib.parse.quote("2023/2024", safe="")
    d = get(f"{BASE}/api/topscorers?season={q}")
    y0 = ((d.get("cards") or {}).get("yellow") or [{}])[0]
    good = y0.get("playerId") == 640089 and y0.get("name") == "Iván Alejo" \
        and y0.get("nameFa") == "ایوان آلخو" and y0.get("value") == 17
    report("A2 global hist 2023/2024 Alejo mapped", good,
           f"y0={y0.get('nameFa')}/{y0.get('value')}")
except Exception as e:
    report("A2 global hist 2023/2024 Alejo mapped", False, repr(e))

# A3: the 185 per-league surface — belgium 2023/2024 read-time freshCardNames
try:
    q = urllib.parse.quote("2023/2024", safe="")
    d = get(f"{BASE}/api/topscorers/belgium?season={q}")
    y0 = ((d.get("cards") or {}).get("yellow") or [{}])[0]
    good = y0.get("playerId") == 232299 \
        and y0.get("name") == "Hannes van der Bruggen" \
        and y0.get("nameFa") == "هانس فان در بروخن" and y0.get("value") == 12
    report("A3 belgium hist Bruggen mapped", good,
           f"y0={y0.get('nameFa')}/{y0.get('value')}")
except Exception as e:
    report("A3 belgium hist Bruggen mapped", False, repr(e))

# A4: the 185 per-league surface — pl 2024/2025 Downes (the 185 gate pin,
# now Persian on the nameFa field)
try:
    q = urllib.parse.quote("2024/2025", safe="")
    d = get(f"{BASE}/api/topscorers/pl?season={q}")
    y0 = ((d.get("cards") or {}).get("yellow") or [{}])[0]
    good = y0.get("playerId") == 844943 and y0.get("name") == "Flynn Downes" \
        and y0.get("nameFa") == "فلیین داونز" and y0.get("value") == 12
    report("A4 pl hist Downes mapped", good,
           f"y0={y0.get('nameFa')}/{y0.get('value')}")
except Exception as e:
    report("A4 pl hist Downes mapped", False, repr(e))

# A5: merge-source consistency kept Persian — hnl 2024/2025 y0 == the
# global yellow king's identity AND nameFa
try:
    q = urllib.parse.quote("2024/2025", safe="")
    g = get(f"{BASE}/api/topscorers?season={q}")
    l = get(f"{BASE}/api/topscorers/hnl?season={q}")
    gy0 = ((g.get("cards") or {}).get("yellow") or [{}])[0]
    ly0 = ((l.get("cards") or {}).get("yellow") or [{}])[0]
    good = gy0.get("playerId") == ly0.get("playerId") == 1516458 \
        and gy0.get("nameFa") == ly0.get("nameFa") == "فتا فتای"
    report("A5 merge-source Persian parity hnl", good,
           f"g={gy0.get('nameFa')} l={ly0.get('nameFa')}")
except Exception as e:
    report("A5 merge-source Persian parity hnl", False, repr(e))

# A6: CURRENT race byte-identical — the five keys touch no current row
# (Raphinha's map entry predates the fix; count/parity pins intact)
try:
    d = get(BASE + "/api/topscorers")
    s0 = (d.get("scorers") or [{}])[0]
    good = len(d.get("scorers") or []) == 400 \
        and len(d.get("perLeague") or []) == 20 \
        and d.get("selectedSeason") == "2026/2027" \
        and s0.get("playerId") == 696679 and s0.get("name") == "Raphinha" \
        and s0.get("nameFa") == "رافینیا"
    report("A6 current race byte-parity", good,
           f"s0={s0.get('playerId')}/{s0.get('nameFa')} sc={len(d.get('scorers') or [])}")
except Exception as e:
    report("A6 current race byte-parity", False, repr(e))

# A7: the 188 hunt's second season pins survive — Gyökeres race top +
# scorers count + assists length (the rows A1's cards ride)
try:
    q = urllib.parse.quote("2024/2025", safe="")
    d = get(f"{BASE}/api/topscorers?season={q}")
    s0 = (d.get("scorers") or [{}])[0]
    good = d.get("selectedSeason") == "2024/2025" \
        and len(d.get("scorers") or []) == 380 \
        and s0.get("playerId") == 664500 and s0.get("goals") == 39 \
        and s0.get("nameFa") == "ویکتور یوکرش" \
        and len(d.get("assists") or []) == 10
    report("A7 188 pins survive (Gyokeres race)", good,
           f"s0={s0.get('playerId')}/{s0.get('goals')}g sc={len(d.get('scorers') or [])}")
except Exception as e:
    report("A7 188 pins survive (Gyokeres race)", False, repr(e))

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
  sleep 2.5
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

# B1: the profile h1 — Fetai now renders «فتا فتای» (getPlayerData applies
# playerFa at read time; the page is fully SSR so the h1 is in the HTML)
open_page "/player/1516458"
FEAT=$(snap 'h1:(document.querySelector("h1")||{}).innerText||""')
B1=0
echo "$FEAT" | grep -q "فتا فتای" || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 /player/1516458 h1 Persian" "$FEAT"
clean_ls

# B2: the diacritic spelling — /player/364855 profile is «Uroš Radaković»
# upstream; the second map key covers it → the SAME Persian rendering
open_page "/player/364855"
FEAT=$(snap 'h1:(document.querySelector("h1")||{}).innerText||""')
B2=0
echo "$FEAT" | grep -q "اوروش راداکوویچ" || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 /player/364855 diacritic key" "$FEAT"
clean_ls

# B3: Alejo profile — the 186 historical yellow king
open_page "/player/640089"
FEAT=$(snap 'h1:(document.querySelector("h1")||{}).innerText||""')
B3=0
echo "$FEAT" | grep -q "ایوان آلخو" || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 /player/640089 h1 Persian" "$FEAT"
clean_ls

# B4: the historical race page — the cards block renders the mapped
# «فتا فتای» AND the race table renders Gyökeres (the 186 surface, second
# season; anchors + innerText needles are data-driven)
open_page "/topscorers?season=2024%2F2025"
$B wait --fn '!!document.querySelector("a[href=\"/player/1516458\"]")' >/dev/null 2>&1
sleep 1.5
FEAT=$(snap 'fetaiFa:document.body.innerText.includes("فتا فتای"),fetai:!!document.querySelector("a[href=\"/player/1516458\"]"),gyk:!!document.querySelector("a[href=\"/player/664500\"]"),selval:(document.querySelector("select#season-select")||{}).value||""')
B4=0
echo "$FEAT" | rg -q 'fetaiFa:true' || B4=1
echo "$FEAT" | rg -q 'fetai:true' || B4=1
echo "$FEAT" | rg -q 'gyk:true' || B4=1
echo "$FEAT" | rg -q 'selval:2024/2025' || B4=1
[ "$B4" -eq 0 ] || BAD=$((BAD+1))
gate "B4 /topscorers 2024/2025 Persian cards" "$FEAT"
clean_ls

# B5: the 185 league surface — belgium historical 2023/2024 renders
# «هانس فان در بروخن» inside the کارت‌ها block (read-time freshener)
open_page "/topscorers/belgium?season=2023%2F2024"
$B wait --fn '!!document.querySelector("a[href=\"/player/232299\"]")' >/dev/null 2>&1
sleep 1.5
FEAT=$(snap 'bruggenFa:document.body.innerText.includes("هانس فان در بروخن"),bruggen:!!document.querySelector("a[href=\"/player/232299\"]"),cards:document.body.innerText.includes("کارت\u200Cها")')
B5=0
echo "$FEAT" | rg -q 'bruggenFa:true' || B5=1
echo "$FEAT" | rg -q 'bruggen:true' || B5=1
echo "$FEAT" | rg -q 'cards:true' || B5=1
[ "$B5" -eq 0 ] || BAD=$((BAD+1))
gate "B5 belgium hist Persian cards" "$FEAT"
clean_ls

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK — cycle-189 fix proven (A 7/7 + B 5/5 @390x844)"
else
  echo "DOM_PROOF BAD=$BAD"
  exit 1
fi
