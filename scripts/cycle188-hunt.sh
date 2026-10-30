#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-188 bug-hunt — patrol of the 184-187 surfaces (since the
# cycle-183 hunt, which covered 179-182) + new DOM dimensions
#
# The four cycles since the last hunt:
#   184  honest-400 guard: ?league= on the global /api/topscorers root
#        (the league is a PATH segment; the page's ?league= deep link is
#        the cycle-10 client-side UI filter, never forwarded)
#   185  per-league HISTORICAL cards — getLeagueCardLeaders(season?),
#        cards:v2:{league}:{kind}:{season||cur}, standings v9
#   186  global HISTORICAL cards merge — getAllCardLeaders(season?) +
#        getAllTopScorers season gate lifted; the 132 rule retired
#   187  attacking zones join the halves — firstHalf/secondHalf optional
#        keys after the legacy triple {left,center,right}
# Patrol only — ZERO src changes (the bug-hunt contract). New dimensions
# no prior gate covered together:
#   - the 186 merge's SECOND season (2024/2025: Gyökeres 39g + Fetai/
#     Radakovic cards) — 186 DOM only proved 2023/2024
#   - merge-source consistency: the global y0 row must equal the hnl
#     per-league y0 (the merge aggregates per-league files)
#   - the 185 surface on a NON-pl league via DOM (belgium 2023/2024 —
#     185 DOM only proved pl)
#   - the 187 halves DOM on the SECOND match (5749721 Roma–Cagliari —
#     187 DOM only proved 5749727) + the exact legacy-first key order
#   - the 184 guard vs the PAGE deep-link contract both live at once
# Honest observations recorded (not gates, not bugs): the historical
# kings Fetai/Alejo/van der Bruggen/Downes are outside the search pool
# (the pool is the current-season 400-star grid — scope, not defect).
#
# Pinned live truth (probed 2026-10-30 ~10:5x +08, UA Chrome/124,
# official cycle-187 build, HTTP 200):
#   /api/topscorers?league=belgium              400 + path hint
#   /api/topscorers?league=…&season=2023/2024   400 (guard precedes)
#   /api/topscorers?season=2024/2025            380 sc, s0 Viktor
#                                               Gyökeres 664500 39g
#                                               «ویکتور یوکرش»؛ y0 Feta
#                                               Fetai 1516458/14 hnl؛
#                                               r0 Uros Radakovic
#                                               364855/4 superlig
#   /api/topscorers/hnl?season=2024/2025        y0 Feta Fetai 1516458/14
#                                               (merge source == merge)
#   /api/topscorers/belgium?season=2023/2024    s0 Denkey 820477/27g؛
#                                               y0 van der Bruggen
#                                               232299/12؛ r0 Bonsu Baah
#                                               1452385/3
#   /api/match/5749721                          zones key order EXACT
#                                               [left,center,right,
#                                               firstHalf,secondHalf]؛
#                                               home 40/22/38 + halves
#                                               (39,21,40)/(41,22,37)؛
#                                               away 38/40/22 + halves
#                                               (37,41,22)/(40,39,21)؛
#                                               هر نیمه مجموع ۱۰۰؛
#                                               statGroups=7 events=22
#   /api/match/5868120 + 5765944                zones null (honest)
#   /api/topscorers?season=2013/2014            honest empty, cards absent
#   /api/topscorers                             s0 Raphinha 696679,
#                                               400/20 sel=2026/2027
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API patrol (8 gates) =="
A_OUT=$(python3 - <<'PY'
import json, urllib.request, urllib.parse, urllib.error
BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}
def get(u):
    req = urllib.request.Request(u, headers=UA)
    return json.load(urllib.request.urlopen(req, timeout=30))
def code(u):
    req = urllib.request.Request(u, headers=UA)
    try:
        return urllib.request.urlopen(req, timeout=30).getcode(), None
    except urllib.error.HTTPError as e:
        try:
            body = json.load(e)
        except Exception:
            body = None
        return e.code, body
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

# A1: the 184 guard — honest 400 with the path hint, and the guard
# precedes season handling (league+season together still 400)
try:
    c1, b1 = code(BASE + "/api/topscorers?league=belgium")
    c2, b2 = code(BASE + "/api/topscorers?league=belgium&season=2023%2F2024")
    hint = "use /api/topscorers/belgium"
    good = c1 == 400 and isinstance(b1, dict) and b1.get("ok") is False \
        and hint in (b1.get("error") or "") \
        and c2 == 400 and isinstance(b2, dict) and b2.get("ok") is False \
        and hint in (b2.get("error") or "")
    report("A1 the 184 guard both forms", good,
           f"c1={c1} c2={c2} hint1={hint in ((b1 or {}).get('error') or '')} "
           f"hint2={hint in ((b2 or {}).get('error') or '')}")
except Exception as e:
    report("A1 the 184 guard both forms", False, repr(e))

# A2: the 186 merge's SECOND season — Gyökeres race + Fetai/Radakovic
# cards (no prior DOM or API gate pinned 2024/2025 end-to-end)
try:
    q = urllib.parse.quote("2024/2025", safe="")
    d = get(f"{BASE}/api/topscorers?season={q}")
    s0 = (d.get("scorers") or [{}])[0]
    y0 = ((d.get("cards") or {}).get("yellow") or [{}])[0]
    r0 = ((d.get("cards") or {}).get("red") or [{}])[0]
    good = d.get("selectedSeason") == "2024/2025" \
        and len(d.get("scorers") or []) == 380 \
        and s0.get("playerId") == 664500 and s0.get("name") == "Viktor Gyökeres" \
        and s0.get("nameFa") == "ویکتور یوکرش" and s0.get("goals") == 39 \
        and len(d.get("assists") or []) == 10 \
        and y0.get("playerId") == 1516458 and y0.get("value") == 14 \
        and y0.get("leagueKey") == "hnl" \
        and r0.get("playerId") == 364855 and r0.get("value") == 4 \
        and r0.get("leagueKey") == "superlig"
    report("A2 hist 2024/2025 Gyokeres+Fetai (186 2nd season)", good,
           f"s0={s0.get('playerId')}/{s0.get('goals')}g "
           f"y0={y0.get('playerId')}/{y0.get('value')} r0={r0.get('playerId')}/{r0.get('value')}")
except Exception as e:
    report("A2 hist 2024/2025 Gyokeres+Fetai (186 2nd season)", False, repr(e))

# A3: merge-source consistency — the global 2024/2025 yellow king IS the
# hnl per-league yellow king (the merge aggregates per-league files)
try:
    q = urllib.parse.quote("2024/2025", safe="")
    g = get(f"{BASE}/api/topscorers?season={q}")
    l = get(f"{BASE}/api/topscorers/hnl?season={q}")
    gy0 = ((g.get("cards") or {}).get("yellow") or [{}])[0]
    ly0 = ((l.get("cards") or {}).get("yellow") or [{}])[0]
    gr0 = ((g.get("cards") or {}).get("red") or [{}])[0]
    lr0 = ((l.get("cards") or {}).get("red") or [{}])[0]
    # the global yellow king's leagueKey must be hnl and the row identity
    # must match the hnl league surface byte-for-byte on the shared fields
    good = gy0.get("leagueKey") == "hnl" \
        and gy0.get("playerId") == ly0.get("playerId") == 1516458 \
        and gy0.get("value") == ly0.get("value") == 14 \
        and gy0.get("name") == ly0.get("name") \
        and gr0.get("leagueKey") == "superlig" \
        and gr0.get("playerId") == 364855 and gr0.get("value") == 4
    report("A3 merge-source consistency hnl", good,
           f"g={gy0.get('playerId')}/{gy0.get('value')}/{gy0.get('leagueKey')} "
           f"l={ly0.get('playerId')}/{ly0.get('value')} r_league={lr0.get('playerId')}/{lr0.get('value')}")
except Exception as e:
    report("A3 merge-source consistency hnl", False, repr(e))

# A4: the 185 surface on a NON-pl league — belgium 2023/2024 hist cards
try:
    q = urllib.parse.quote("2023/2024", safe="")
    d = get(f"{BASE}/api/topscorers/belgium?season={q}")
    s0 = (d.get("scorers") or [{}])[0]
    y0 = ((d.get("cards") or {}).get("yellow") or [{}])[0]
    r0 = ((d.get("cards") or {}).get("red") or [{}])[0]
    good = d.get("leagueKey") == "belgium" \
        and d.get("leagueFa") == "لیگ بلژیک" \
        and d.get("selectedSeason") == "2023/2024" \
        and len(d.get("scorers") or []) == 20 \
        and s0.get("playerId") == 820477 and s0.get("name") == "Kévin Denkey" \
        and s0.get("goals") == 27 \
        and y0.get("playerId") == 232299 and y0.get("value") == 12 \
        and r0.get("playerId") == 1452385 and r0.get("value") == 3
    report("A4 belgium hist 2023/2024 (185 non-pl)", good,
           f"s0={s0.get('playerId')}/{s0.get('goals')}g "
           f"y0={y0.get('playerId')}/{y0.get('value')} r0={r0.get('playerId')}/{r0.get('value')}")
except Exception as e:
    report("A4 belgium hist 2023/2024 (185 non-pl)", False, repr(e))

# A5: the 187 halves on the SECOND match — exact key order + all six
# triples byte-pinned + every half sums to 100
try:
    d = get(BASE + "/api/match/5749721")
    z = d.get("zones") or {}
    h, a = z.get("home") or {}, z.get("away") or {}
    trip = lambda t: (t.get("left"), t.get("center"), t.get("right"))
    sm = lambda t: (t.get("left") or 0) + (t.get("center") or 0) + (t.get("right") or 0)
    good = list(h.keys()) == ["left", "center", "right", "firstHalf", "secondHalf"] \
        and list(a.keys()) == ["left", "center", "right", "firstHalf", "secondHalf"] \
        and trip(h) == (40, 22, 38) and trip(h.get("firstHalf") or {}) == (39, 21, 40) \
        and trip(h.get("secondHalf") or {}) == (41, 22, 37) \
        and trip(a) == (38, 40, 22) and trip(a.get("firstHalf") or {}) == (37, 41, 22) \
        and trip(a.get("secondHalf") or {}) == (40, 39, 21) \
        and sm(h.get("firstHalf") or {}) == 100 and sm(h.get("secondHalf") or {}) == 100 \
        and sm(a.get("firstHalf") or {}) == 100 and sm(a.get("secondHalf") or {}) == 100 \
        and len(d.get("statGroups") or []) == 7 and len(d.get("events") or []) >= 20 \
        and bool(d.get("lineups"))
    report("A5 zones halves 5749721 (187 2nd match)", good,
           f"hk={list(h.keys())} h={trip(h)} h1={trip(h.get('firstHalf') or {})} "
           f"h2={trip(h.get('secondHalf') or {})}")
except Exception as e:
    report("A5 zones halves 5749721 (187 2nd match)", False, repr(e))

# A6: honest absence — upcoming + uncovered finished both keep zones null
try:
    d1 = get(BASE + "/api/match/5868120")
    d2 = get(BASE + "/api/match/5765944")
    good = d1.get("ok") is True and d1.get("zones") is None \
        and d2.get("ok") is True and d2.get("zones") is None
    report("A6 honest zones absence both", good,
           f"z1={d1.get('zones')} z2={d2.get('zones')}")
except Exception as e:
    report("A6 honest zones absence both", False, repr(e))

# A7: the dataless 2013/2014 season keeps its honest omission (the 176
# contract untouched by 185/186)
try:
    q = urllib.parse.quote("2013/2014", safe="")
    d = get(f"{BASE}/api/topscorers?season={q}")
    good = d.get("ok") is True and d.get("selectedSeason") == "2013/2014" \
        and (d.get("scorers") or []) == [] and "cards" not in d
    report("A7 2013/2014 honest empty stays", good,
           f"sel={d.get('selectedSeason')} sc={len(d.get('scorers') or [])} cards={'cards' in d}")
except Exception as e:
    report("A7 2013/2014 honest empty stays", False, repr(e))

# A8: current-race parity on the fresh baseline (the 182 route untouched)
try:
    d = get(BASE + "/api/topscorers")
    s0 = (d.get("scorers") or [{}])[0]
    extra = set(d.keys()) - {"ok", "scorers", "perLeague", "updatedAt"}
    good = extra == {"assists", "cards", "selectedSeason", "allSeasons"} \
        and len(d.get("scorers") or []) == 400 \
        and len(d.get("perLeague") or []) == 20 \
        and d.get("selectedSeason") == "2026/2027" \
        and s0.get("playerId") == 696679 and s0.get("name") == "Raphinha"
    report("A8 current race parity", good,
           f"s0={s0.get('playerId')} sc={len(d.get('scorers') or [])} "
           f"pl={len(d.get('perLeague') or [])} sel={d.get('selectedSeason')}")
except Exception as e:
    report("A8 current race parity", False, repr(e))

print("API_HUNT OK" if ok else "API_HUNT FLAGGED")
PY
)
echo "$A_OUT"
case "$A_OUT" in
  *"API_HUNT OK"*) : ;;
  *) BAD=$((BAD+1)) ;;
esac

echo "== PART B: DOM patrol @390x844 (agent-browser, console must stay 0) =="
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
# D5 test-isolation (the cycle-181/184 standing rule): clear storage
# up-front, between gates, and at exit — no leftover UI state leaks.
clean_ls() { $B eval "localStorage.clear()" >/dev/null 2>&1; }
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
click_stats_tab() {
  $B eval "[...document.querySelectorAll('nav[aria-label=\"بخش\u200Cهای مسابقه\"] button')].find(b => b.textContent.trim() === 'آمار')?.click()" >/dev/null 2>&1
  sleep 1.5
}

open_page "/"
clean_ls

# B1: the 186 merge's SECOND season via DOM — /topscorers?season=2024/2025
# renders Gyökeres at the top of the race AND Feta Fetai as the yellow
# king («آقای کارت» block); anchors are the data-driven needles (the
# 186 h2-scoped-needle lesson: static copy also contains «آقای کارت»)
open_page "/topscorers?season=2024%2F2025"
$B wait --fn '!!document.querySelector("a[href=\"/player/1516458\"]")' >/dev/null 2>&1
sleep 1.5
FEAT=$(snap 'gyk:!!document.querySelector("a[href=\"/player/664500\"]"),fetai:!!document.querySelector("a[href=\"/player/1516458\"]"),selval:(document.querySelector("select#season-select")||{}).value||"",players:document.querySelectorAll("a[href^=\"/player/\"]").length')
B1=0
echo "$FEAT" | rg -q 'gyk:true' || B1=1
echo "$FEAT" | rg -q 'fetai:true' || B1=1
echo "$FEAT" | rg -q 'selval:2024/2025' || B1=1
echo "$FEAT" | rg -q 'players:([1-9][0-9]{2,})' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 /topscorers 2024/2025 (186 2nd season)" "$FEAT"
clean_ls

# B2: click-through — the historical yellow king Fetai → /player/1516458
# ADVANCED by cycle-189 (the in-gate-comment convention): the 189 fix mapped
# the historical kings' Persian names (the 188 observation), so the h1 is
# now the mapped «فتا فتای» — the honest-Latin fallback «Feta Fetai» this
# gate originally pinned lives only in the gate's own history.
CLICKED=$($B eval '(function(){const links=[...document.querySelectorAll("a[href=\"/player/1516458\"]")];const hit=links.find(l=>(l.innerText||"").includes("Feta")||(l.innerText||"").includes("فتا"));if(hit){hit.click();return "clicked"}return "no-row"})()' 2>/dev/null | tr -d '"\\')
$B wait --fn 'location.pathname === "/player/1516458"' >/dev/null 2>&1
sleep 2
H1=$($B eval 'JSON.stringify((document.querySelector("h1")||{}).innerText||"")' 2>/dev/null | tr -d '"\\')
URL2=$($B eval 'location.pathname' 2>/dev/null | tr -d '"\\')
B2=0
[ "$CLICKED" = "clicked" ] || B2=1
[ "$URL2" = "/player/1516458" ] || B2=1
echo "$H1" | grep -q "فتا" || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 click Fetai → player page" "clicked=$CLICKED url=$URL2 h1=$H1"
clean_ls

# B3: the 185 surface on a NON-pl league via DOM — /topscorers/belgium
# historical 2023/2024: van der Bruggen yellow king + Denkey race top +
# the pre-set selector (185 DOM only proved pl)
open_page "/topscorers/belgium?season=2023%2F2024"
$B wait --fn '!!document.querySelector("a[href=\"/player/232299\"]")' >/dev/null 2>&1
sleep 1.5
FEAT=$(snap 'bruggen:!!document.querySelector("a[href=\"/player/232299\"]"),denkey:!!document.querySelector("a[href=\"/player/820477\"]"),cards:document.body.innerText.includes("کارت\u200Cها"),cr:document.body.innerText.includes("کارت قرمز"),selval:(document.querySelector("select#season-select")||{}).value||"",lg:document.body.innerText.includes("لیگ بلژیک")')
B3=0
echo "$FEAT" | rg -q 'bruggen:true' || B3=1
echo "$FEAT" | rg -q 'denkey:true' || B3=1
echo "$FEAT" | rg -q 'cards:true' || B3=1
echo "$FEAT" | rg -q 'cr:true' || B3=1
echo "$FEAT" | rg -q 'selval:2023/2024' || B3=1
echo "$FEAT" | rg -q 'lg:true' || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 belgium hist cards (185 non-pl)" "$FEAT"
clean_ls

# B4: the 187 halves DOM on the SECOND match — Roma–Cagliari stats tab:
# zones block + both half labels + exactly 4 zone-half sub-rows (187 DOM
# only proved 5749727; the tab click + explicit post-click wait is the
# 187 gate-side lesson)
open_page "/match/5749721"
click_stats_tab
$B wait --fn '!!document.querySelector("[data-testid=\"match-zones\"]")' >/dev/null 2>&1
sleep 1.5
FEAT=$(snap 'zones:!!document.querySelector("[data-testid=\"match-zones\"]"),hdr:document.body.innerText.includes("جهت حملات"),h1:document.body.innerText.includes("نیمهٔ اول"),h2:document.body.innerText.includes("نیمهٔ دوم"),halves:document.querySelectorAll("[data-testid=\"zone-half\"]").length')
B4=0
echo "$FEAT" | rg -q 'zones:true' || B4=1
echo "$FEAT" | rg -q 'hdr:true' || B4=1
echo "$FEAT" | rg -q 'h1:true' || B4=1
echo "$FEAT" | rg -q 'h2:true' || B4=1
echo "$FEAT" | rg -q 'halves:4' || B4=1
[ "$B4" -eq 0 ] || BAD=$((BAD+1))
gate "B4 Roma-Cagliari halves DOM (187 2nd match)" "$FEAT"
clean_ls

# B5: the 184 guard vs the PAGE deep-link contract — /topscorers?league=
# belgium is the cycle-10 client-side UI filter (never forwarded to the
# API): the page must still render the belgium-scoped view cleanly
open_page "/topscorers?league=belgium"
$B wait --fn '!!document.querySelector("a[href=\"/player/892709\"]")' >/dev/null 2>&1
sleep 1.5
FEAT=$(snap 'lg:document.body.innerText.includes("لیگ بلژیک"),eckert:!!document.querySelector("a[href=\"/player/892709\"]"),urlok:location.search.includes("league=belgium")')
URLB=$($B eval 'decodeURIComponent(location.search)' 2>/dev/null | tr -d '"\\')
B5=0
echo "$FEAT" | rg -q 'lg:true' || B5=1
echo "$FEAT" | rg -q 'eckert:true' || B5=1
echo "$FEAT" | rg -q 'urlok:true' || B5=1
[ "$B5" -eq 0 ] || BAD=$((BAD+1))
gate "B5 page deep-link vs 184 guard" "$FEAT | url=$URLB"
clean_ls

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "HUNT OK (cycle-188: patrol of the 184-187 surfaces — the honest-400 league guard, per-league historical cards on a non-pl league, the global hist merge's second season + merge-source consistency, the attacking-zones halves on the second match — API 8/8 + DOM 5/5 @390x844; honest absence both matches + the dataless season stay; the page deep-link contract rides the 184 guard; product bugs = 0; observation: historical-only kings (Fetai/Alejo/van der Bruggen/Downes) are outside the current-season 400-star search pool by design)"
else
  echo "HUNT FLAGGED (BAD=$BAD)"; exit 1
fi
