#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-181 update proof — «لیگ بلژیک — رقابت بیست‌وسوم» (24th competition)
#
# The runner-up list (Denmark 46 / Greece 135 / Belgium 40 / Egypt 519 —
# probed complete by cycle-157) got re-swept live per the D5 rule
# (scripts/cycle181-probe.py, 2026-10-30): Greece is ZERO-Iranian — memory
# said Taremi, the squad dump said no (he is not in Olympiacos' squad).
# The winner is BELGIUM (fotmobId 40, ccode3 BEL): Standard Liège's
# Dennis Eckert (892709) carries ccode=IRN + nationalTeamId=6711 in the
# data/teams squad AND ParticipantCountryCode="IRN" on the goals.json row
# itself (rank 11 in the file, 4g+1a, rating 6.91, #10) — the same
# player-level-country standard as Zoushi (152) / Haidari (160) /
# Mohammadi (161) / Zahedi (162) / Sayyadmanesh (165).
#
# Update (additive-only, the 108/140/152/156/165 contract): ONE LEAGUES
# entry + COMPETITION_FA (belgian pro league → لیگ بلژیک, reusing the
# established pro league|BEL translation; first division b — the second
# tier has live matches today) + 44 TEAM_FA (1 table club RAAL + 7
# goals/card-file spellings + 12 title clubs incl. the OLDEST champion
# of any portal FC Liège 1895/1896 + 24 transfer sides) + 24
# PLAYER_NAME_FA (the full top-20 race window + assists leaders + Denkey)
# + the 4 copy numbers (24 competitions / بیست hub / 24 search guide / 20
# race copy). espnSlug bel.1 answers live (big-league pattern). Zero
# existing field touched; zero new upstream endpoints.
#
# Pinned live truth (probed 2026-10-30 ~07:2x +08, UA Chrome/124, via the
# OFFICIAL START + fresh build):
#   /api/standings?league=belgium → 18 rows, خنت 25 صدر, scorers=20,
#     Eckert row {rank:9, دنیس اکرت, استاندارد لیژ, 4g, ccode:IRN, pid 892709},
#     assists=10 (Forbs 5), cards y=15/r=15, allSeasons=12, sel=2026/2027
#   /api/topscorers → race 400/20 belgium-in mas-out
#   /api/topscorers?season=2023/2024 → 380/19 belgium-in (Denkey top)
#   /api/standings?league=belgium&season=2023/2024 → 32 composite rows
#   /api/topscorers/belgium → parity extra {assists,cards,selectedSeason,allSeasons}
#   /api/search?q=Eckert → pid 892709 fa دنیس اکرت teamFa استاندارد لیژ
#   /api/league-titles?league=belgium → 123 (2025/2026 کلوب بروژ … 1895/1896 اف‌سی لیژ)
#   /api/league-transfers?league=belgium → 100 items, Persian sides
#   /player/892709 → 200, h1 "Dennis Eckert", info.country="Iran"
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API proof =="
A_OUT=$(python3 - <<'PY'
import json, urllib.request, urllib.parse
BASE = "http://localhost:3000"
def get(u):
    req = urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0 Chrome/124.0"})
    return json.load(urllib.request.urlopen(req, timeout=30))
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

# A1: the belgium portal serves the full standings contract — table +
# scorers window with the IRN hook + deep assists + both card kinds + the
# cycle-132 season fields (12-season intersection UNCHANGED — belgium's 17
# seasons cover it, the cycle-145 pin class survives untouched)
try:
    d = get(BASE + "/api/standings?league=belgium")
    rows = d.get("rows") or []
    sc = d.get("scorers") or []
    ek = next((x for x in sc if x.get("playerId") == 892709), None)
    a = d.get("assists") or []
    c = d.get("cards") or {}
    good = d.get("ok") is True and len(rows) == 18 \
        and rows[0].get("fa") == "خنت" and rows[0].get("pts") == 25 \
        and len(sc) == 20 and ek is not None \
        and ek.get("nameFa") == "دنیس اکرت" and ek.get("team") == "استاندارد لیژ" \
        and ek.get("goals") == 4 and ek.get("ccode") == "IRN" \
        and len(a) == 10 and (a[0] or {}).get("playerId") == 1186529 \
        and len(c.get("yellow") or []) == 15 and len(c.get("red") or []) == 15 \
        and len(d.get("allSeasons") or []) == 12 \
        and d.get("selectedSeason") == "2026/2027"
    report("A1 belgium portal full contract", good,
           f"rows={len(rows)} r0={rows[0].get('fa')}/{rows[0].get('pts')} sc={len(sc)} "
           f"ek={ek.get('rank') if ek else None} ass={len(a)} y={len(c.get('yellow') or [])} "
           f"r={len(c.get('red') or [])} seas={len(d.get('allSeasons') or [])}")
except Exception as e:
    report("A1 belgium portal full contract", False, repr(e))

# A2: the race merged — 400/20, belgium IN, mas still out, Eckert rides it
try:
    d = get(BASE + "/api/topscorers")
    ts = d.get("scorers") or []
    pl = [p.get("leagueKey") for p in (d.get("perLeague") or [])]
    ek = [x for x in ts if x.get("playerId") == 892709]
    good = len(ts) == 400 and len(pl) == 20 and "belgium" in pl and "mas" not in pl \
        and len(ek) >= 1 and (ek[0] or {}).get("leagueKey") == "belgium"
    report("A2 race 400/20 belgium-in mas-out", good,
           f"ts={len(ts)} pl={len(pl)} belgium={'belgium' in pl} mas={'mas' in pl} ekinrace={bool(ek)}")
except Exception as e:
    report("A2 race 400/20 belgium-in mas-out", False, repr(e))

# A3: the HISTORICAL race joins too — the archived 2023/2024 payload
# carries its own goals file (season/20957, 233 rows → 20-window, Denkey)
try:
    q = urllib.parse.quote("2023/2024", safe="")
    d = get(f"{BASE}/api/topscorers?season={q}")
    ts = d.get("scorers") or []
    pl = d.get("perLeague") or []
    bel = next((p for p in pl if p.get("leagueKey") == "belgium"), None)
    good = len(ts) == 380 and len(pl) == 19 and bel is not None \
        and len(bel.get("scorers") or []) == 20 \
        and ((bel.get("scorers") or [{}])[0] or {}).get("name") == "Kévin Denkey"
    report("A3 hist race 380/19 belgium-in Denkey", good,
           f"ts={len(ts)} pl={len(pl)} belrows={len(bel.get('scorers') or []) if bel else None}")
except Exception as e:
    report("A3 hist race 380/19 belgium-in Denkey", False, repr(e))

# A4: the historical standings are COMPOSITE (Championship/ECL/Relegation
# groups — the cycle-141 parser flattens to 32 rows: 6+6+4+16)
try:
    q = urllib.parse.quote("2023/2024", safe="")
    d = get(f"{BASE}/api/standings?league=belgium&season={q}")
    rows = d.get("rows") or []
    good = d.get("ok") is True and len(rows) == 32 \
        and d.get("selectedSeason") == "2023/2024"
    report("A4 hist composite 32 rows", good,
           f"rows={len(rows)} sel={d.get('selectedSeason')}")
except Exception as e:
    report("A4 hist composite 32 rows", False, repr(e))

# A5: per-league topscorers route parity — the 178/180-era extra pin, now
    # on the NEW league: old keys + exactly {assists, cards, selectedSeason,
    # allSeasons}, and the 180 season fields ride belgium too
try:
    d = get(BASE + "/api/topscorers/belgium")
    old = {"ok", "leagueKey", "leagueFa", "season", "scorers", "updatedAt"}
    extra = set(d.keys()) - old
    good = extra == {"assists", "cards", "selectedSeason", "allSeasons"} \
        and d.get("leagueKey") == "belgium" and d.get("leagueFa") == "لیگ بلژیک" \
        and len(d.get("scorers") or []) == 20 \
        and (d.get("selectedSeason")) == "2026/2027" \
        and len(d.get("allSeasons") or []) == 12
    report("A5 topscorers/belgium parity", good,
           f"extra={sorted(extra)} sc={len(d.get('scorers') or [])}")
except Exception as e:
    report("A5 topscorers/belgium parity", False, repr(e))

# A6: search discovers the hook BOTH ways — latin keyboard + the Persian
# name (the 166/169/171 contract: pool from scorers, diacritic-free query)
try:
    g = get(BASE + "/api/search?q=Eckert")
    p1 = [x for x in (g.get("players") or []) if x.get("playerId") == 892709]
    g2 = get(BASE + "/api/search?q=" + urllib.parse.quote("اکرت"))
    p2 = [x for x in (g2.get("players") or []) if x.get("playerId") == 892709]
    good = bool(p1) and p1[0].get("fa") == "دنیس اکرت" \
        and p1[0].get("teamFa") == "استاندارد لیژ" \
        and p1[0].get("leagueKey") == "belgium" and bool(p2)
    report("A6 search Eckert + اکرت", good,
           f"en={len(p1)} fa={len(p2)} top={p1[0].get('fa') if p1 else None}")
except Exception as e:
    report("A6 search Eckert + اکرت", False, repr(e))

# A7: titles — 123 seasons, the OLDEST of any portal (1895/1896), both
# sides Persian-mapped
try:
    d = get(BASE + "/api/league-titles?league=belgium")
    tt = (d.get("titles") or {}).get("items") or []
    t0 = tt[0] if tt else {}
    tn = tt[-1] if tt else {}
    good = len(tt) == 123 and t0.get("season") == "2025/2026" \
        and t0.get("championFa") == "کلوب بروژ" \
        and t0.get("runnerUpFa") == "یونیون سنت‌ژیلوآز" \
        and tn.get("season") == "1895/1896" and tn.get("championFa") == "اف‌سی لیژ"
    report("A7 titles 123 oldest 1895/1896", good,
           f"n={len(tt)} newest={t0.get('season')}/{t0.get('championFa')} oldest={tn.get('season')}/{tn.get('championFa')}")
except Exception as e:
    report("A7 titles 123 oldest 1895/1896", False, repr(e))

# A8: transfers — 100 items, Persian sides on the sampled rows (the 167
# link contract means every name must at least be ASCII-free when mapped;
# honest fallback keeps English — assert no RAW latin leaks on sides that
# the sweep mapped)
try:
    d = get(BASE + "/api/league-transfers?league=belgium")
    items = (d.get("transfers") or {}).get("items") or []
    sample = items[:40]
    mapped_sides = [x for x in sample if (x.get("from") or {}).get("fa")]
    leaks = [x for x in mapped_sides
             if any("a" <= ch.lower() <= "z" for ch in (x["from"]["fa"] or ""))]
    good = d.get("ok") is True and len(items) == 100 and len(mapped_sides) > 0 \
        and not leaks
    report("A8 transfers 100 Persian sides", good,
           f"items={len(items)} sampled={len(mapped_sides)} leaks={leaks[:2]}")
except Exception as e:
    report("A8 transfers 100 Persian sides", False, repr(e))

# A9: legacy pins survive the merge — pl scorers/assists/cards untouched
try:
    d = get(BASE + "/api/topscorers/pl")
    s = d.get("scorers") or []
    a = d.get("assists") or []
    y = ((d.get("cards") or {}).get("yellow")) or []
    good = len(s) >= 10 and len(a) >= 5 \
        and 654096 in {x.get("playerId") for x in a} \
        and len(y) >= 10 and (y[0] or {}).get("playerId") == 688273
    report("A9 pl legacy pins intact", good,
           f"sc={len(s)} ass={len(a)} y0={(y[0] or {}).get('playerId') if y else None}")
except Exception as e:
    report("A9 pl legacy pins intact", False, repr(e))

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

# B1: /league/belgium renders the portal — Gent on top, table rows, the
# 170/176 blocks (assists + cards), enough player anchors for the 174-era
# link contract
open_page "/league/belgium"
FEAT=$(snap 'gent:document.body.innerText.includes("خنت"),tbl:document.body.innerText.includes("رده\u200Cبندی"),ass:document.body.innerText.includes("دهندگان"),cards:document.body.innerText.includes("کارت\u200Cها"),players:document.querySelectorAll("a[href^=\"/player/\"]").length,eklink:!!document.querySelector("a[href=\"/player/892709\"]")')
B1=0
echo "$FEAT" | rg -q 'gent:true' || B1=1
echo "$FEAT" | rg -q 'tbl:true' || B1=1
echo "$FEAT" | rg -q 'ass:true' || B1=1
echo "$FEAT" | rg -q 'cards:true' || B1=1
echo "$FEAT" | rg -q 'players:(1[5-9]|[2-9][0-9])' || B1=1
echo "$FEAT" | rg -q 'eklink:true' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 /league/belgium portal" "$FEAT"

# B2: /topscorers/belgium — the sister page parity: scorers + assists +
# cards + the 180 season selector with payload options
open_page "/topscorers/belgium"
FEAT=$(snap 'sel:!!document.querySelector("select#season-select"),opts:document.querySelectorAll("select#season-select option").length,ass:document.body.innerText.includes("دهندگان"),cards:document.body.innerText.includes("کارت\u200Cها"),ek:!!document.querySelector("a[href=\"/player/892709\"]"),players:document.querySelectorAll("a[href^=\"/player/\"]").length')
B2=0
echo "$FEAT" | rg -q 'sel:true' || B2=1
echo "$FEAT" | rg -q 'opts:(1[0-9]|[2-9][0-9])' || B2=1
echo "$FEAT" | rg -q 'ass:true' || B2=1
echo "$FEAT" | rg -q 'cards:true' || B2=1
echo "$FEAT" | rg -q 'ek:true' || B2=1
echo "$FEAT" | rg -q 'players:(2[0-9]|[3-9][0-9])' || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 /topscorers/belgium parity" "$FEAT"

# B3: the global race page — «۲۰ لیگ و جام برتر» copy, the belgium chip,
# Eckert's row in the merged table, the ۱۹ copy GONE
$B eval "try{localStorage.removeItem('remontada:topscorers-filter')}catch(e){}" >/dev/null 2>&1
open_page "/topscorers"
FEAT=$(snap 'copy20:document.body.innerText.includes("۲۰ لیگ و جام برتر"),old19gone:!document.body.innerText.includes("۱۹ لیگ و جام برتر"),chip:document.body.innerText.includes("لیگ بلژیک"),ek:!!document.querySelector("a[href=\"/player/892709\"]")')
B3=0
echo "$FEAT" | rg -q 'copy20:true' || B3=1
echo "$FEAT" | rg -q 'old19gone:true' || B3=1
echo "$FEAT" | rg -q 'chip:true' || B3=1
echo "$FEAT" | rg -q 'ek:true' || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 /topscorers race copy+chip" "$FEAT"

# B4: the search UI — REAL trigger + type + click path to the hook player
# (the exact 178 B6 pattern: dialog opens via the «جستجوی تیم» trigger,
# rows are div[role=dialog] ul li button): type Eckert, click the row →
# /player/892709 h1 Dennis Eckert
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 2
$B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
sleep 1
$B eval "(function(){const i=document.querySelector('div[role=\"dialog\"] input');if(!i)return 'no-input';const s=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set;s.call(i,'Eckert');i.dispatchEvent(new Event('input',{bubbles:true}));return 'typed'})()" >/dev/null 2>&1
$B wait --fn "[...document.querySelectorAll('div[role=\"dialog\"] ul li button')].some(b=>(b.innerText||'').includes('اکرت'))" >/dev/null 2>&1
sleep 1
CLICKED=$($B eval '(function(){const btns=[...document.querySelectorAll("div[role=\"dialog\"] ul li button")];const hit=btns.find(b=>(b.innerText||"").includes("اکرت"));if(hit){hit.click();return "clicked"}return "no-row"})()' 2>/dev/null | tr -d '"\\')
$B wait --fn "location.pathname.startsWith('/player/892709')" >/dev/null 2>&1
sleep 2
H1=$($B eval 'JSON.stringify((document.querySelector("h1")||{}).innerText||"")' 2>/dev/null | tr -d '"\\')
URL4=$($B eval 'location.pathname' 2>/dev/null | tr -d '"\\')
B4=0
[ "$CLICKED" = "clicked" ] || B4=1
case "$URL4" in /player/892709*) : ;; *) B4=1 ;; esac
# the client-rendered h1 carries the cycle-106 honest Persian display name
# (SSG shell shows the EN original — the mapped h1 is دنیس اکرت)
echo "$H1" | grep -q "اکرت" || B4=1
[ "$B4" -eq 0 ] || BAD=$((BAD+1))
gate "B4 search→click Eckert" "clicked=$CLICKED url=$URL4 h1=$H1"

# B5: /players hub — the بیست copy (the stars mode counts race
# participants: 19→20), the old نوزده copy GONE
open_page "/players"
FEAT=$(snap 'copy20:document.body.innerText.includes("ستاره‌های بیست لیگ و جام برتر"),old19gone:!document.body.innerText.includes("ستاره‌های نوزده"),cards:document.querySelectorAll("a[href^=\"/player/\"]").length')
B5=0
echo "$FEAT" | rg -q 'copy20:true' || B5=1
echo "$FEAT" | rg -q 'old19gone:true' || B5=1
echo "$FEAT" | rg -q 'cards:([5-9][0-9]|[1-9][0-9]{2})' || B5=1
[ "$B5" -eq 0 ] || BAD=$((BAD+1))
gate "B5 /players hub copy" "$FEAT"

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK (cycle-181: Belgian Pro League — the 24th competition joins as the 20th race participant on ONE live Iranian hook: Dennis Eckert 892709, ccode=IRN in the Standard Liège squad AND ParticipantCountryCode=IRN on the goals.json row (rank 11 file / rank 9 window, 4g+1a); D5 re-sweep of the 157 runner-up list caught Greece at zero Iranians — memory said Taremi, the squad dump said no; flat 18-row table (خنت 25 صدر), 17 slash seasons merge the race 380→400/19→20, the archived 2023/2024 composite payload carries its own goals file (Denkey) so the HISTORICAL race joins too (360→380/18→19), 123 title seasons with the OLDEST champion of any portal (اف‌سی لیژ 1895/1896), transfers 100 items with Persian sides, card files live (y=15/r=15), espnSlug bel.1 answers; mappings 44 TEAM_FA + 24 PLAYER_NAME_FA + 2 COMPETITION_FA with zero duplicate-key collisions; search discovers the hook both ways (Eckert + اکرت) and a REAL search click rides to /player/892709; the four copy numbers advance (24 competitions / بیست hub / ۲۴ guide / ۲۰ race) — zero existing field touched, zero new upstream endpoints)"
else
  echo "DOM_PROOF FLAGGED (BAD=$BAD)"; exit 1
fi
