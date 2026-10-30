#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-193 bug-hunt — patrol of the 189-192 surfaces + new honesty
# dimensions. PATROL ONLY: ZERO src changes (the hunt contract —
# bug=0 is a legal result).
#
# The 188 hunt covered 184-187. Since then three cycles shipped:
#   189 (fix)  — Persian names for the historical-only kings
#   190 (update) — the whole stat table per period (statPeriods pills)
#   191 (update) — the Opta post-match reviews card
#   192 (update) — the top-5 rated players card («برترین‌های بازی»)
#
# New dimensions NO earlier gate combined:
#   D1: POTM (matchFacts.playerOfTheMatch) vs topPlayers motm=true —
#       two INDEPENDENT normalizations must agree (id + rating + name)
#   D2: direct-id player navigation for a NON-star (Lulli 1800491 —
#       outside the 400-star search pool; the 188 observation's other
#       side: the /player/[id] surface must still serve him fully)
#   D3: the 190 pills + the 187 zones co-existence on ONE payload —
#       the fh pill flips the stat table WITHOUT touching the zones
#   D4: the 191 reviews + 192 topPlayers + highlights header trio
#   D5: the 189 nameFa map reaching the 192 surface IN DOM
#
# Pinned live truth (probed 2026-10-30, official start pid=16697):
#   5749721: potm {1800491 Emanuele Lulli 8.7 Roma minutes=76} ==
#            the UNIQUE motm row (home[0]); reviews n=1 "Mora inspires";
#            topPlayers 5+5; highlights present; 4/10 mapped rows
#            (Soulé/Pisilli/Molina/Maldini)
#   5765944: potm {1358149 Luka Stojković 9.2 Dinamo Zagreb} ==
#            the UNIQUE motm row
#   5749727: statPeriods fh possession 52/48 (the 190 pin) AND
#            zones.home {53,25,22, fh{53,27,20}, sh{51,21,28}} (the
#            187 pin) — one payload, two independent surfaces
#   5868120: topPlayers null + statPeriods null + reviews null
#   /api/player/1800491: name "Emanuele Lulli", nameFa == name
#            (honest Latin fallback), positions[0].fa «دفاع کناری»
#   current race: s0 Raphinha 696679 «رافینیا» rank 1, 400 rows,
#            sel="2026/2027" — the goal count is LIVE (20g at the
#            morning's 188 pin, 13g at this hunt's bytes; drift-tolerant)
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API proof (8 gates) =="
A_OUT=$(python3 - <<'PY'
import json, re, urllib.request
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

ROWKEYS = ["id", "motm", "name", "nameFa", "pos", "rating"]
FA_RE = re.compile(r"[\u0600-\u06FF]")

def motm_rows(tp):
    return [r for side in ("home", "away") for r in ((tp or {}).get(side) or []) if r.get("motm")]

# A1: 5749721 — D1 POTM vs the unique motm row agree (id + rating + name)
try:
    d = get(BASE + "/api/match/5749721")
    potm = d.get("playerOfTheMatch") or {}
    rows = motm_rows(d.get("topPlayers"))
    good = potm.get("id") == 1800491 and potm.get("rating") == "8.7" \
        and len(rows) == 1 and rows[0]["id"] == potm["id"] \
        and rows[0]["rating"] == potm["rating"] and rows[0]["name"] == potm.get("name")
    report("A1 5749721 POTM==motm row (D1)", good,
           f"potm={potm.get('id')}/{potm.get('rating')} motmrows={[r['id'] for r in rows]}")
except Exception as e:
    report("A1 5749721 POTM==motm row (D1)", False, repr(e))

# A2: 5765944 — the same D1 consistency on the second match
try:
    d = get(BASE + "/api/match/5765944")
    potm = d.get("playerOfTheMatch") or {}
    rows = motm_rows(d.get("topPlayers"))
    good = potm.get("id") == 1358149 and potm.get("rating") == "9.2" \
        and len(rows) == 1 and rows[0]["id"] == potm["id"] \
        and rows[0]["name"] == potm.get("name")
    report("A2 5765944 POTM==motm row (D1)", good,
           f"potm={potm.get('id')}/{potm.get('rating')} motmrows={[r['id'] for r in rows]}")
except Exception as e:
    report("A2 5765944 POTM==motm row (D1)", False, repr(e))

# A3: D2 — direct-id navigation for a NON-star: the player API serves
# Lulli fully (name, honest-Latin nameFa, Persian position label)
try:
    p = get(BASE + "/api/player/1800491").get("player") or {}
    pos0 = (p.get("positions") or [{}])[0]
    good = p.get("name") == "Emanuele Lulli" and p.get("nameFa") == "Emanuele Lulli" \
        and bool(FA_RE.search(pos0.get("fa") or "")) and pos0.get("en") == "Right Wing-Back"
    report("A3 /player/1800491 non-star served (D2)", good,
           f"name={p.get('name')} pos={pos0.get('fa')}/{pos0.get('en')}")
except Exception as e:
    report("A3 /player/1800491 non-star served (D2)", False, repr(e))

# A4: D3 — 190 pills + 187 zones co-exist on ONE payload (5749727)
try:
    d = get(BASE + "/api/match/5749727")
    sp = d.get("statPeriods") or {}
    fh = sp.get("firstHalf") or []
    fh0 = fh[0]["rows"][0] if fh and fh[0].get("rows") else {}
    zh = (d.get("zones") or {}).get("home") or {}
    good = fh0.get("title") == "مالکیت توپ" and fh0.get("home") == "52" and fh0.get("away") == "48" \
        and zh.get("left") == 53 and zh.get("center") == 25 and zh.get("right") == 22 \
        and zh.get("firstHalf") == {"left": 53, "center": 27, "right": 20} \
        and zh.get("secondHalf") == {"left": 51, "center": 21, "right": 28}
    report("A4 5749727 pills+zones one payload (D3)", good,
           f"fh={fh0.get('home')}/{fh0.get('away')} zones={zh.get('left')}/{zh.get('center')}/{zh.get('right')}")
except Exception as e:
    report("A4 5749727 pills+zones one payload (D3)", False, repr(e))

# A5: D4 — the header trio's data co-exists on 5749721
try:
    d = get(BASE + "/api/match/5749721")
    rv = d.get("reviews") or []
    tp = d.get("topPlayers") or {}
    hl = d.get("highlights")
    good = len(rv) == 1 and rv[0].get("title", "").startswith("Roma 4-2 Cagliari: Mora inspires") \
        and len(tp.get("home") or []) == 5 and len(tp.get("away") or []) == 5 \
        and all(sorted(r.keys()) == ROWKEYS for r in tp["home"] + tp["away"]) \
        and bool(hl)
    report("A5 5749721 header trio data (D4)", good,
           f"reviews={len(rv)} tp=5+5 highlights={'yes' if hl else 'no'}")
except Exception as e:
    report("A5 5749721 header trio data (D4)", False, repr(e))

# A6: the upcoming triple honest absence (192/190/191 all null)
try:
    d = get(BASE + "/api/match/5868120")
    good = d.get("topPlayers") is None and d.get("statPeriods") is None and d.get("reviews") is None
    report("A6 5868120 triple honest absence", good,
           f"tp={d.get('topPlayers')} sp={d.get('statPeriods')} rv={d.get('reviews')}")
except Exception as e:
    report("A6 5868120 triple honest absence", False, repr(e))

# A7: D5 — the 189 map reaches the 192 surface: exactly 4 mapped rows,
# Persian hits + Latin names untouched
try:
    d = get(BASE + "/api/match/5749721")
    allr = ((d.get("topPlayers") or {}).get("home") or []) + ((d.get("topPlayers") or {}).get("away") or [])
    mapped = {r["name"]: r["nameFa"] for r in allr if r["nameFa"] != r["name"]}
    want = {"Matias Soulé": "ماتیاس سوله", "Niccolò Pisilli": "نیکولو پیسیلی",
            "Nahuel Molina": "ناهوئل مولینا", "Daniel Maldini": "دانیل مالدینی"}
    good = mapped == want and all(FA_RE.search(v) for v in mapped.values()) \
        and all(r["nameFa"].strip() for r in allr)
    report("A7 189 map on the 192 surface (D5)", good,
           f"mapped={len(mapped)}/10 {sorted(mapped.values())}")
except Exception as e:
    report("A7 189 map on the 192 surface (D5)", False, repr(e))

# A8: the standing current-race anchor — DRIFT-TOLERANT on the live race
# numbers: identity (playerId 696679 — the merge row's id key is
# `playerId`, not `id`), nameFa, the 400-star grid, the sel marker form
# ("2026/2027", slash), rank 1, and a sanity-bound goal count. The exact
# count moves intra-day (the 188 card pinned 20g this morning; the live
# bytes at hunt time say 13g — Opta race data is live; recorded as an
# observation, NOT a product bug — the site mirrors upstream).
try:
    d = get(BASE + "/api/topscorers")
    s0 = (d.get("scorers") or [{}])[0]
    g = s0.get("goals")
    good = s0.get("playerId") == 696679 and s0.get("name") == "Raphinha" \
        and s0.get("nameFa") == "رافینیا" and s0.get("rank") == 1 \
        and isinstance(g, int) and 1 <= g <= 60 \
        and d.get("selectedSeason") == "2026/2027" and len(d.get("scorers") or []) == 400
    report("A8 current race anchor (drift-tolerant)", good,
           f"s0={s0.get('name')}/{g}g sel={d.get('selectedSeason')} n={len(d.get('scorers') or [])}")
except Exception as e:
    report("A8 current race anchor (drift-tolerant)", False, repr(e))

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
click_stats_tab() {
  $B eval "[...document.querySelectorAll('nav[aria-label=\"بخش\u200Cهای مسابقه\"] button')].find(b => b.textContent.trim() === 'آمار')?.click()" >/dev/null 2>&1
}
gate() {
  local label="$1" OUT C E RC=0
  OUT=$(snap 'sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length')
  C=$($B console --json 2>/dev/null | python3 -c "$CNT")
  E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
  [ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  echo "$label → $OUT | console=$C appErrors=$E rc=$RC"
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
}

open_page "/"
clean_ls

# B1: D4+D5 in DOM — /match/5749721 header trio (reviews + topPlayers +
# the POTM card on the default events tab) + the Persian mapped needle
# «ماتیاس سوله» inside the 192 card + the honest-Latin Lulli needle
open_page "/match/5749721"
sleep 1
FEAT=$(snap 'rv:!!document.querySelector("[data-testid=match-reviews]"),tp:!!document.querySelector("[data-testid=match-top-players]"),potm:document.body.innerText.includes("بهترین بازیکن زمین"),fa:document.body.innerText.includes("ماتیاس سوله"),latin:document.body.innerText.includes("Emanuele Lulli")')
B1=0
echo "$FEAT" | rg -q 'rv:true' || B1=1
echo "$FEAT" | rg -q 'tp:true' || B1=1
echo "$FEAT" | rg -q 'potm:true' || B1=1
echo "$FEAT" | rg -q 'fa:true' || B1=1
echo "$FEAT" | rg -q 'latin:true' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 header trio + Persian/latin needles (D4+D5)" "$FEAT"
clean_ls

# B2: D2 end-to-end — a REAL click on the topPlayers Lulli row navigates
# to /player/1800491 and the profile renders (the 172 family, non-star)
open_page "/match/5749721"
CLICKED=$($B eval '(function(){const card=document.querySelector("[data-testid=match-top-players]");if(!card)return "no-card";const hit=[...card.querySelectorAll("a")].find(a=>(a.getAttribute("href")||"")==="/player/1800491");if(hit){hit.click();return "clicked"}return "no-row"})()' 2>/dev/null | tr -d '"\\')
$B wait --fn 'location.pathname === "/player/1800491"' >/dev/null 2>&1
sleep 2
H1=$($B eval 'JSON.stringify((document.querySelector("h1")||{}).innerText||"")' 2>/dev/null | tr -d '"\\')
URL2=$($B eval 'location.pathname' 2>/dev/null | tr -d '"\\')
B2=0
[ "$CLICKED" = "clicked" ] || B2=1
[ "$URL2" = "/player/1800491" ] || B2=1
echo "$H1" | grep -q "Lulli" || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 click Lulli row → /player/1800491 (D2)" "clicked=$CLICKED url=$URL2 h1=$H1"
clean_ls

# B3: D3 in DOM — the stats tab shows the 190 pills AND the 187 zones
# block; the fh pill flips possession «۴۲»→«۵۲» while zones STAY
open_page "/match/5749727"
click_stats_tab
$B wait --fn '!!document.querySelector("[data-testid=\"stat-period-firstHalf\"]")' >/dev/null 2>&1
sleep 1.5
first_stat_val='(function(){const hs=[...document.querySelectorAll("header")].filter(h=>h.textContent.includes("آمار کلیدی"));if(!hs.length)return "no-group";const sp=hs[0].querySelector("span");return sp?sp.textContent:"no-span"})()'
VAL_ALL=$($B eval "$first_stat_val" 2>/dev/null | tr -d '"\\')
FEAT=$(snap 'allPill:!!document.querySelector("[data-testid=\"stat-period-all\"]"),fhPill:!!document.querySelector("[data-testid=\"stat-period-firstHalf\"]"),shPill:!!document.querySelector("[data-testid=\"stat-period-secondHalf\"]"),zones:!!document.querySelector("[data-testid=match-zones]"),halves:document.querySelectorAll("[data-testid=\"zone-half\"]").length')
B3=0
echo "$FEAT" | rg -q 'allPill:true' || B3=1
echo "$FEAT" | rg -q 'fhPill:true' || B3=1
echo "$FEAT" | rg -q 'shPill:true' || B3=1
echo "$FEAT" | rg -q 'zones:true' || B3=1
echo "$FEAT" | rg -q 'halves:4' || B3=1
[ "$VAL_ALL" = "۴۲" ] || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 pills+zones co-exist, All=۴۲ (D3)" "$FEAT | val=$VAL_ALL"
# the fh pill click: possession flips to «۵۲», zones block stays alive
$B eval 'document.querySelector("[data-testid=\"stat-period-firstHalf\"]")?.click()' >/dev/null 2>&1
sleep 1
VAL_FH=$($B eval "$first_stat_val" 2>/dev/null | tr -d '"\\')
FEAT2=$(snap 'pressed:document.querySelector("[data-testid=\"stat-period-firstHalf\"]")?.getAttribute("aria-pressed"),zonesStill:!!document.querySelector("[data-testid=match-zones]")')
B3b=0
echo "$FEAT2" | rg -q 'pressed:true' || B3b=1
echo "$FEAT2" | rg -q 'zonesStill:true' || B3b=1
[ "$VAL_FH" = "۵۲" ] || B3b=1
[ "$B3b" -eq 0 ] || BAD=$((BAD+1))
gate "B3b fh pill flips ۴۲→۵۲, zones untouched (D3)" "$FEAT2 | val=$VAL_FH"
clean_ls

# B4: the upcoming triple honest absence in DOM — no top-players card,
# no reviews card, no stat-period pills; the page still renders clean
open_page "/match/5868120"
sleep 1
FEAT=$(snap 'noTp:!document.querySelector("[data-testid=match-top-players]"),noRv:!document.querySelector("[data-testid=match-reviews]"),noPills:!document.querySelector("[data-testid=\"stat-period-all\"]"),noZones:!document.querySelector("[data-testid=match-zones]")')
B4=0
echo "$FEAT" | rg -q 'noTp:true' || B4=1
echo "$FEAT" | rg -q 'noRv:true' || B4=1
echo "$FEAT" | rg -q 'noPills:true' || B4=1
echo "$FEAT" | rg -q 'noZones:true' || B4=1
[ "$B4" -eq 0 ] || BAD=$((BAD+1))
gate "B4 5868120 triple honest absence (DOM)" "$FEAT"
clean_ls

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "HUNT OK (cycle-193: patrol of the 189-192 surfaces — POTM==motm consistency on two matches, direct-id non-star navigation end-to-end, pills+zones one-payload co-existence with an independent fh flip, the header trio, the 189 map in the 192 DOM, the triple honest absence — API 8/8 + DOM 5/5 @390x844; product bugs = 0)"
else
  echo "HUNT BAD=$BAD"
  exit 1
fi
