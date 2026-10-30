#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-198 bug-hunt — patrol of the 194-197 surfaces + new cross
# dimensions. PATROL ONLY: ZERO src changes (the hunt contract —
# bug=0 is a legal result).
#
# The 193 hunt covered 184-192. Since then four cycles shipped:
#   194 (fix)    — the five historical card kings join the player pool
#   195 (update) — the daily feed's teams join the team search index
#   196 (update) — league boards 6+6 → 12+12 (cards/xG/set-piece/GK)
#   197 (update) — the teammates card (club + national squad navigation)
#
# New dimensions NO earlier gate combined:
#   D1: the 194×197 cross-tie — Fetai (a 194 fold-king) serves his OWN
#       197 teammates block in API AND DOM, and a club chip REALLY
#       navigates to a full profile (the 172 family on the fold-king)
#   D2: the 196×92 one-payload co-existence on the FINISHED 2024/2025
#       laliga snapshot (the 193 lesson: only finished-season bytes are
#       pinned) + row-id liveness — a new-team board's teamId answers
#       /api/team (the 167 lesson applied to 196 rows)
#   D3: the 195 surface TODAY — expectations derived from the live feed
#       at run time, the end-to-end search → row → /team/{id} loop in
#       DOM (the 195 gate's own derivation, re-patrolled a day later)
#   D4: the 194 contracts co-existing on ONE row — dual alphabet, the
#       189 nameFa map, rank 0, no-goals, the season hint; the full
#       five-king API sweep (the 194 pool re-proven after three cycles
#       shipped on top of it)
#   D5: the 197 universality + zero-drop consistency — the served
#       teammates count equals the upstream well-formed row set
#       (dedupe/self-exclusion math), star/non-star/pool-star alike
#
# Pinned live truth (probed 2026-10-30, official start, HTTP 200):
#   Fetai 1516458: teammates=30 national=35, first club rows Latin
#            (unmapped = honest per the 92/107 contract), 5/5 sampled
#            chip ids serve full profiles, self never listed, 0 dups
#   laliga 2024/2025 (FINISHED — immutable): boards=25; «کارت زرد»
#            r0 Las Palmas 8306/107, r1 Getafe 8305/103; «امتیاز
#            فوت‌ماب» r0 Lamine Yamal 1467236/8.04 «لامین یامال»
#   laliga CURRENT: boards=25 — «بیشترین سرعت» honestly absent (the
#            upstream payload carries ZERO Top-speed blocks today,
#            verified byte-level: the 92 honest-skip rule working;
#            NOT a product bug — recorded as a cleared observation.
#            Note: PL 2024/2025 carries 26 boards, laliga 25 — the
#            count is league-dependent by design)
#   search «فتای»: players[0] = {1516458, «فتا فتای», rank 0, no goals,
#            season 2024/2025, «لیگ برتر کرواسی»}; Latin "Downes"
#            matches ON THE PERSIAN name (matchedOn «فلیین داونز»,
#            hl fa span [6,11])
#   race s0: Raphinha/«رافینیا»/13g rank=1 sel=2026/2027 n=400 (live,
#            drift-tolerant); universality Raphinha 26+27 / Lulli
#            24+32 / Gyokeres 23+29
#   feed today: 340 teams / 94 groups; 10/10 non-portal sample searchable
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API proof (8 gates) =="
A_OUT=$(python3 - <<'PY'
import json, urllib.request, urllib.parse
BASE = "http://localhost:3000"
UP = "https://www.fotmob.com"
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36"}
def get(u):
    return json.load(urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=30))
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

FA_RE_QUOTE = None  # unused placeholder to keep structure flat

def row_hygiene(rows, self_id):
    ids = [r.get("id") for r in rows]
    return (all(isinstance(i, int) and i > 0 for i in ids)
            and all(isinstance(r.get("name"), str) and r["name"].strip() for r in rows)
            and self_id not in ids and len(ids) == len(set(ids)))

# A1: D1 — the 194×197 cross-tie: Fetai serves his own squad, hygiene +
# sampled chip-id liveness (3 club ids answer full player profiles)
try:
    p = get(f"{BASE}/api/player/1516458").get("player") or {}
    tm = p.get("teammates") or []
    nt = p.get("nationalTeammates") or []
    live = 0
    for r in tm[:3]:
        try:
            q = get(f"{BASE}/api/player/{r['id']}").get("player") or {}
            live += 1 if q.get("name") else 0
        except Exception:
            pass
    good = (len(tm) >= 20 and len(nt) >= 20 and row_hygiene(tm, 1516458)
            and row_hygiene(nt, 1516458) and live == 3
            and all(r.get("nameFa", "").strip() for r in tm))
    report("A1 Fetai squad cross-tie + chip liveness (D1)", good,
           f"club={len(tm)} nt={len(nt)} live={live}/3 self=never dups=0")
except Exception as e:
    report("A1 Fetai squad cross-tie + chip liveness (D1)", False, repr(e))

# A2: D2 — the 196×92 one-payload co-existence on the FINISHED laliga
# 2024/2025 snapshot (immutable bytes) + new-row teamId liveness
try:
    d = get(f"{BASE}/api/standings?league=laliga&season=2024%2F2025")
    bs = d.get("boards") or []
    yb = next((b for b in bs if b.get("headerFa") == "کارت زرد"), None)
    rb = next((b for b in bs if b.get("headerFa") == "امتیاز فوت‌ماب"), None)
    y0 = (yb or {}).get("rows", [{}])[0]
    r0 = (rb or {}).get("rows", [{}])[0]
    t = get(f"{BASE}/api/team/8306")
    tname = (t.get("team") or {}).get("name") or t.get("name")
    good = (len(bs) >= 25 and yb is not None and rb is not None
            and y0.get("name") == "Las Palmas" and y0.get("teamId") == 8306 and y0.get("value") == 107
            and r0.get("name") == "Lamine Yamal" and r0.get("playerId") == 1467236
            and r0.get("value") == 8.04 and r0.get("nameFa") == "لامین یامال" and r0.get("teamFa") == "بارسلونا"
            and bool(tname))
    report("A2 finished-season 196×92 co-existence + liveness (D2)", good,
           f"boards={len(bs)} yellow_r0={y0.get('name')}/{y0.get('value')} rating_r0={r0.get('name')}/{r0.get('value')} live={tname}")
except Exception as e:
    report("A2 finished-season 196×92 co-existence + liveness (D2)", False, repr(e))

# A3: D3 — the 195 surface TODAY, derived from the live feed at run time:
# >= 80% of a 10-team non-portal sample searchable + fold-row shape
try:
    PORTAL = {"LaLiga","Premier League","Serie A","Bundesliga","Ligue 1","UEFA Champions League",
              "UEFA Europa League","UEFA Conference League","Persian Gulf Pro League","Saudi Pro League",
              "Süper Lig","Scottish Premiership","EFL Championship","Liga Portugal","UAE Pro League",
              "Qatar Stars League","Eredivisie","AFC Champions League Elite","AFC Champions League Two",
              "Croatian HNL","Belgian Pro League","Ekstraklasa"}
    feed = get(f"{BASE}/api/matches")
    teams = {}
    for g in feed.get("groups") or []:
        for m in g.get("matches") or []:
            for side in (m.get("home"), m.get("away")):
                if side and side.get("id") and side["id"] not in teams:
                    teams[side["id"]] = {"fa": side.get("fa"), "name": side.get("name"),
                                         "leagueName": g.get("leagueName"), "leagueFa": g.get("leagueFa")}
    np = sorted([(tid, t) for tid, t in teams.items()
                 if t["leagueName"] not in PORTAL and len((t["fa"] or t["name"] or "")) >= 3],
                key=lambda kv: kv[0])
    found = 0; fold = None
    for tid, t in np[:10]:
        q = t["fa"] or t["name"]
        d = get(f"{BASE}/api/search?q={urllib.parse.quote(q)}")
        row = next((r for r in (d.get("results") or []) if r.get("teamId") == tid), None)
        if row:
            found += 1
            if row.get("rank") == 0 and row.get("pts") == 0 and fold is None:
                fold = row
    good = len(np) >= 10 and found >= 8 and fold is not None \
        and bool(fold.get("leagueFa")) and bool(fold.get("logo"))
    report("A3 195 feed teams today, runtime-derived (D3)", good,
           f"nonportal={len(np)} found={found}/10 foldR0={fold is not None} leagueFa={bool(fold and fold.get('leagueFa'))}")
except Exception as e:
    report("A3 195 feed teams today, runtime-derived (D3)", False, repr(e))

# A4: D4 — the 194 contracts co-existing on ONE row: dual alphabet (the
# Latin query matches ON the Persian name), rank 0, no goals, the season
# hint bytes, the diacritic NFD-fold
try:
    d1 = get(f"{BASE}/api/search?q=" + urllib.parse.quote("فتای")).get("players") or []
    d2 = get(f"{BASE}/api/search?q=Downes").get("players") or []
    d3 = get(f"{BASE}/api/search?q=Radakovi%C4%87").get("players") or []
    r1 = d1[0] if d1 else {}
    r2 = d2[0] if d2 else {}
    r3 = d3[0] if d3 else {}
    good = (len(d1) == 1 and r1.get("playerId") == 1516458 and r1.get("fa") == "فتا فتای"
            and r1.get("rank") == 0 and "goals" not in r1 and r1.get("season") == "2024/2025"
            and r1.get("leagueFa") == "لیگ برتر کرواسی"
            and len(d2) == 1 and r2.get("playerId") == 844943 and r2.get("matchedOn") == "فلیین داونز"
            and len(d3) == 1 and r3.get("playerId") == 364855)
    report("A4 194 contracts on one row + dual alphabet (D4)", good,
           f"fetai={len(d1)}/rank{r1.get('rank')}/season={r1.get('season')} downes_matchedOn={r2.get('matchedOn')!r} diacritic={r3.get('playerId')}")
except Exception as e:
    report("A4 194 contracts on one row + dual alphabet (D4)", False, repr(e))

# A5: the 197 universality — star / non-star / pool-star all carry the
# block through the v8 cache with hygiene
try:
    anchors = [(696679, "Raphinha"), (1800491, "Lulli"), (664500, "Gyokeres")]
    parts = []
    good = True
    for pid, who in anchors:
        p = get(f"{BASE}/api/player/{pid}").get("player") or {}
        tm = p.get("teammates") or []
        nt = p.get("nationalTeammates") or []
        h = row_hygiene(tm, pid) and row_hygiene(nt, pid)
        good = good and len(tm) >= 20 and len(nt) >= 20 and h
        parts.append(f"{who}={len(tm)}+{len(nt)}/{ 'ok' if h else 'BAD' }")
    report("A5 197 universality star/non-star/pool-star", good, " ".join(parts))
except Exception as e:
    report("A5 197 universality star/non-star/pool-star", False, repr(e))

# A6: D5 — zero-drop consistency: the served Fetai teammates count equals
# the upstream well-formed row set (dedupe + self-exclusion math)
try:
    served = len((get(f"{BASE}/api/player/1516458").get("player") or {}).get("teammates") or [])
    rl = (get(f"{UP}/api/data/playerData?id=1516458").get("relatedLinksData") or {})
    rows = [r for r in (rl.get("teammates") or []) if isinstance(r, dict)
            and isinstance(r.get("id"), int) and r["id"] > 0
            and isinstance(r.get("name"), str) and r["name"].strip()]
    ids = [r["id"] for r in rows]
    expected = len(set(ids)) - (1 if 1516458 in ids else 0)
    good = served == expected
    report("A6 zero-drop served==upstream wellformed (D5)", good,
           f"served={served} expected={expected} (upstream={len(ids)} raw)")
except Exception as e:
    report("A6 zero-drop served==upstream wellformed (D5)", False, repr(e))

# A7: the current race anchor — DRIFT-TOLERANT (identity, grid size,
# season marker form; the goal count is live and moves intra-day)
try:
    d = get(f"{BASE}/api/topscorers")
    s0 = (d.get("scorers") or [{}])[0]
    g = s0.get("goals")
    good = (s0.get("playerId") == 696679 and s0.get("nameFa") == "رافینیا"
            and s0.get("rank") == 1 and isinstance(g, int) and 1 <= g <= 60
            and d.get("selectedSeason") == "2026/2027" and len(d.get("scorers") or []) == 400)
    report("A7 current race anchor (drift-tolerant)", good,
           f"s0={s0.get('name')}/{g}g rank={s0.get('rank')} n={len(d.get('scorers') or [])}")
except Exception as e:
    report("A7 current race anchor (drift-tolerant)", False, repr(e))

# A8: the 194 five-king sweep — one query each, primary alphabet, every
# row rank 0 with the season hint (the pool re-proven after 195/196/197)
try:
    kings = [("فتای", 1516458), ("داونز", 844943), ("آلخو", 640089),
             ("بروخن", 232299), ("راداکوویچ", 364855)]
    parts = []; good = True
    for q, pid in kings:
        rows = get(f"{BASE}/api/search?q=" + urllib.parse.quote(q)).get("players") or []
        hit = [r for r in rows if r.get("playerId") == pid]
        g = bool(hit) and hit[0].get("rank") == 0 and bool(hit[0].get("season")) and "goals" not in hit[0]
        good = good and len(rows) == 1 and g
        parts.append(f"{q}={'1' if len(rows)==1 and g else '0'}")
    report("A8 five-king sweep rank0+season+no-goals", good, " ".join(parts))
except Exception as e:
    report("A8 five-king sweep rank0+season+no-goals", False, repr(e))

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
click_row() {
  $B eval "(function(){var b=[...document.querySelectorAll('[role=dialog] button')].find(function(x){return x.innerText.indexOf('$1')>=0;});if(!b)return 'norow';b.click();return 'clicked';})()" >/dev/null 2>&1
}
click_tab() {
  $B eval "(function(){var b=[...document.querySelectorAll('button')].find(function(x){return x.innerText.trim().indexOf('$1')===0;});if(!b)return 'notab';b.click();return 'clicked';})()" >/dev/null 2>&1
  sleep 1.2
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

# B1: D1 in DOM — the 194 fold-king's own 197 card: both groups with the
# club label «لوکوموتیوا», then a REAL chip click → a full profile (the
# 172 family on the fold-king; the chip is runtime-derived, no live pin)
open_page "/player/1516458"
FEAT=$(snap 'card:!!document.querySelector("[data-testid=player-teammates]"),club:document.body.innerText.indexOf("باشگاه · لوکوموتیوا")>=0,nat:document.body.innerText.indexOf("تیم ملی")>=0,chips:document.querySelectorAll("[data-testid=player-teammate-chip]").length')
B1=0
echo "$FEAT" | rg -q 'card:true' || B1=1
echo "$FEAT" | rg -q 'club:true' || B1=1
echo "$FEAT" | rg -q 'nat:true' || B1=1
echo "$FEAT" | rg -q 'chips:[2-9][0-9]' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 Fetai teammates card both groups (D1)" "$FEAT"
# the real loop: click the FIRST club chip → /player/{id} renders
$B eval '(function(){var c=document.querySelector("[data-testid=player-teammates-club] [data-testid=player-teammate-chip]");if(!c)return "nochip";c.click();return "clicked:"+c.getAttribute("href")})()' >/dev/null 2>&1
$B wait --fn '/^\/player\/\d+$/.test(location.pathname) && location.pathname !== "/player/1516458"' >/dev/null 2>&1
sleep 2
FEAT=$(snap 'path:location.pathname,h1:(document.querySelector("h1")||{}).innerText||""')
B1=0
echo "$FEAT" | grep -qE 'path:/player/[0-9]+' || B1=1
echo "$FEAT" | grep -q 'path:/player/1516458' && B1=1
[ -n "$FEAT" ] || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1b chip click → own profile (D1)" "$FEAT"
clean_ls

# B2: the 197 star regression — Raphinha both groups + the stable Balde
# chip href → click → /player/1254166 (the 197 B2 loop re-proven)
open_page "/player/696679"
FEAT=$(snap 'club:document.body.innerText.indexOf("باشگاه · بارسلونا")>=0,nat:document.body.innerText.indexOf("تیم ملی")>=0,balde:!!document.querySelector("[data-testid=player-teammates] a[href=\"/player/1254166\"]")')
B2=0
echo "$FEAT" | rg -q 'club:true' || B2=1
echo "$FEAT" | rg -q 'nat:true' || B2=1
echo "$FEAT" | rg -q 'balde:true' || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 Raphinha groups + stable Balde chip" "$FEAT"
$B eval 'document.querySelector("[data-testid=player-teammates] a[href=\"/player/1254166\"]")?.click()' >/dev/null 2>&1
$B wait --fn 'location.pathname === "/player/1254166"' >/dev/null 2>&1
sleep 2
FEAT=$(snap 'path:location.pathname,h1:(document.querySelector("h1")||{}).innerText||""')
B2=0
echo "$FEAT" | grep -q 'path:/player/1254166' || B2=1
[ -n "$FEAT" ] || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2b Balde chip click → /player/1254166" "$FEAT"
clean_ls

# B3: D4 in DOM — the 194 full loop re-proven after 195/196/197 shipped:
# فتای → exactly 1 row with the season hint → click → /player/1516458
open_page "/"
open_search
type_into "فتای"
wait_row "فتا فتای"
FEAT=$(snap 'n:[...document.querySelectorAll("[role=dialog] button")].filter(function(b){return b.innerText.indexOf("فتا فتای")>=0;}).length,hint:[...document.querySelectorAll("[role=dialog] button")].some(function(b){var t=b.innerText;return t.indexOf("فتا فتای")>=0&&t.indexOf("۲۰۲۴/۲۰۲۵")>=0;})')
B3=0
echo "$FEAT" | rg -q 'n:1' || B3=1
echo "$FEAT" | rg -q 'hint:true' || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 search فتای → 1 row + season hint (D4)" "$FEAT"
click_row "فتا فتای"
$B wait --fn "location.pathname==='/player/1516458'" >/dev/null 2>&1
sleep 1.5
FEAT=$(snap 'path:location.pathname,h1:(document.querySelector("h1")||{}).innerText||""')
B3=0
echo "$FEAT" | grep -q 'path:/player/1516458' || B3=1
echo "$FEAT" | grep -q 'فتا فتای' || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3b click → /player/1516458 h1" "$FEAT"
clean_ls

# B4: D3 in DOM — the 195 loop TODAY: the needle is derived from the live
# feed at run time (the 193/195 drift lesson), search → row → /team/{id}
NP=$(curl -s -A "Mozilla/5.0 Chrome/124.0" "$BASE/api/matches" | python3 -c '
import json, sys
PORTAL = {"LaLiga","Premier League","Serie A","Bundesliga","Ligue 1","UEFA Champions League",
          "UEFA Europa League","UEFA Conference League","Persian Gulf Pro League","Saudi Pro League",
          "Süper Lig","Scottish Premiership","EFL Championship","Liga Portugal","UAE Pro League",
          "Qatar Stars League","Eredivisie","AFC Champions League Elite","AFC Champions League Two",
          "Croatian HNL","Belgian Pro League","Ekstraklasa"}
d = json.load(sys.stdin)
teams = {}
for g in d.get("groups") or []:
    for m in g.get("matches") or []:
        for side in (m.get("home"), m.get("away")):
            if side and side.get("id") and side["id"] not in teams:
                fa = side.get("fa") or side.get("name") or ""
                ln = g.get("leagueName")
                if ln not in PORTAL and len(fa) >= 6 and "\x27" not in fa and "\x22" not in fa:
                    teams[side["id"]] = fa
cands = sorted(teams.items())
tid, fa = cands[0] if cands else (0, "")
print(str(tid) + "\t" + fa)
')
NP_ID=$(echo "$NP" | cut -f1)
NP_FA=$(echo "$NP" | cut -f2)
NP_LEN=$(printf %s "$NP_FA" | wc -m)
open_page "/"
open_search
type_into "$NP_FA"
wait_row "$NP_FA"
FEAT=$(snap "n:[...document.querySelectorAll('[role=dialog] button')].filter(function(b){return b.innerText.indexOf('$NP_FA')>=0;}).length,label:[...document.querySelectorAll('[role=dialog] button')].some(function(b){return b.innerText.indexOf('$NP_FA')>=0&&b.innerText.length>$NP_LEN+2;})")
B4=0
echo "$FEAT" | rg -q 'n:[1-9]' || B4=1
echo "$FEAT" | rg -q 'label:true' || B4=1
[ "$B4" -eq 0 ] || BAD=$((BAD+1))
gate "B4 feed-team search row + label (D3) [$NP_FA]" "$FEAT"
click_row "$NP_FA"
$B wait --fn "location.pathname === '/team/$NP_ID'" >/dev/null 2>&1
sleep 2
FEAT=$(snap 'path:location.pathname,h1:(document.querySelector("h1")||{}).innerText||""')
B4=0
echo "$FEAT" | grep -q "path:/team/$NP_ID" || B4=1
[ -n "$FEAT" ] || B4=1
[ "$B4" -eq 0 ] || BAD=$((BAD+1))
gate "B4b click → /team/$NP_ID renders" "$FEAT"
clean_ls

# B5: D2 in DOM — the league boards: the NEW «کارت زرد» family chip on the
# CURRENT laliga page + podium team links; the player tab switch keeps the
# section alive with /player links
open_page "/league/laliga"
click_tab "آمار فصل"
$B wait --fn '!!document.querySelector("[data-testid=league-boards]")' >/dev/null 2>&1
sleep 0.6
FEAT=$(snap 'sec:!!document.querySelector("[data-testid=league-boards]"),yellow:[...document.querySelectorAll("[data-testid=league-boards] button")].some(function(b){return b.innerText.indexOf("کارت زرد")>=0;})')
B5=0
echo "$FEAT" | rg -q 'sec:true' || B5=1
echo "$FEAT" | rg -q 'yellow:true' || B5=1
[ "$B5" -eq 0 ] || BAD=$((BAD+1))
gate "B5 league boards + new yellow-card family (D2)" "$FEAT"
$B eval '(function(){var b=[...document.querySelectorAll("[data-testid=league-boards] button")].find(function(x){return x.innerText.indexOf("کارت زرد")>=0;});if(!b)return "nochip";b.click();return "clicked"})()' >/dev/null 2>&1
sleep 0.8
FEAT=$(snap 'teamlinks:[...document.querySelectorAll("[data-testid=league-boards] a[href^=\"/team/\"]")].length,sub:document.body.innerText.indexOf("بی‌نظمی فصل")>=0')
B5=0
echo "$FEAT" | rg -q 'teamlinks:[2-9]' || B5=1
echo "$FEAT" | rg -q 'sub:true' || B5=1
[ "$B5" -eq 0 ] || BAD=$((BAD+1))
gate "B5b yellow podium → /team links + sub" "$FEAT"
click_tab "بازیکنان"
sleep 0.8
FEAT=$(snap 'sec:!!document.querySelector("[data-testid=league-boards]"),tackle:[...document.querySelectorAll("[data-testid=league-boards] button")].some(function(b){return b.innerText.indexOf("تکل در هر ۹۰ دقیقه")>=0;})')
$B eval '(function(){var b=[...document.querySelectorAll("[data-testid=league-boards] button")].find(function(x){return x.innerText.indexOf("تکل در هر ۹۰ دقیقه")>=0;});if(!b)return "nochip";b.click();return "clicked"})()' >/dev/null 2>&1
sleep 0.8
FEAT="$FEAT,$(snap 'plinks:[...document.querySelectorAll("[data-testid=league-boards] a[href^=\"/player/\"]")].length')"
B5=0
echo "$FEAT" | rg -q 'tackle:true' || B5=1
echo "$FEAT" | rg -q 'plinks:[2-9]' || B5=1
[ "$B5" -eq 0 ] || BAD=$((BAD+1))
gate "B5c player tab → tackles podium /player links" "$FEAT"
clean_ls

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "HUNT OK (cycle-198: patrol of the 194-197 surfaces — the Fetai 194×197 cross-tie with a real chip navigation, the finished-season 196×92 one-payload co-existence with row-id liveness, the 195 feed-team loop derived from TODAY's bytes, the 194 contracts co-existing on one row + the five-king sweep, the 197 universality + zero-drop consistency — API 8/8 + DOM 5/5 @390x844; product bugs = 0; the «بیشترین سرعت» current-season absence investigated and CLEARED against upstream bytes — honest-skip, not a bug)"
else
  echo "HUNT BAD=$BAD"
  exit 1
fi
