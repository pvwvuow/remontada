#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-186 update — the global historical race joins the cards era
# («قانون ۱۳۲ بازنشسته شد — سر‌به‌سر»)
#
# The 185 card documented the global-merge boundary as the declared
# remainder: the cycle-132 rule survived for Layer 2 (getAllTopScorers
# omitted cards for every historical season). Cycle-186 closes it: the
# optional season threads into getAllCardLeaders (whose per-league calls
# have carried season-scoped cache keys since 185), the merge-side gate
# is lifted, and the 176 both-empty contract keeps a dataless season
# (2013/2014) byte-honest with NO cards key.
#
# Pinned live truth (probed 2026-10-30 ~10:4x +08, official start, UA
# Chrome/124; laliga 23/24 yellow top verified against the upstream file
# directly — 454 rows, Iván Alejo 17, pid 640089):
#   /api/topscorers?season=2023/2024  380 scorers s0 Kane 194165/36g;
#                                     cards y10[Iván Alejo/17/pid640089/
#                                     laliga] r10[Christopher Bonsu
#                                     Baah/3/pid1452385/belgium]
#   /api/topscorers?season=2024/2025  cards y10[Feta Fetai/14/pid1516458/
#                                     hnl] r10[Uros Radakovic/4/pid364855/
#                                     superlig]
#   /api/topscorers (current)         y10[Klemenz/6/poland] r10[Edimilson
#                                     Fernandes/2/swiss] — byte-identical
#   /api/topscorers?season=2013/2014  200 scorers=0 AND cards ABSENT
#                                     (the 176 contract — no fake empty)
#   /api/topscorers/pl?season=2024/2025  the 185 surface intact (Downes)
#   /api/standings?league=pl&season=2023/2024  the 185 surface (Palhinha)
#   ?season=nonsense → 400 (55/132);  ?league=pl → 400 (184)
#   /topscorers?season=2023/2024 (DOM)  «آقای کارت» renders + Alejo anchor
#                                       — first time on the historical race
#   /topscorers?season=2013/2014 (DOM)  honest empty WITHOUT the cards block
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API gates (7) =="
A_OUT=$(python3 - <<'PY'
import json, urllib.request, urllib.error
BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}
def get(u):
    req = urllib.request.Request(u, headers=UA)
    return json.load(urllib.request.urlopen(req, timeout=90))
def code(u):
    req = urllib.request.Request(u, headers=UA)
    try:
        return urllib.request.urlopen(req, timeout=60).getcode()
    except urllib.error.HTTPError as e:
        return e.code
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")
def head(d, kind):
    c = d.get("cards") or {}
    rows = c.get(kind) or []
    r0 = rows[0] if rows else {}
    return r0, len(rows)

# A1: THE FEATURE — the historical global race carries its own card kings
d = get(BASE + "/api/topscorers?season=2023%2F2024")
y0, yn = head(d, "yellow"); r0, rn = head(d, "red")
s0 = (d.get("scorers") or [{}])[0]
good = d.get("ok") is True and len(d.get("scorers") or []) == 380 \
    and s0.get("playerId") == 194165 and s0.get("goals") == 36 \
    and y0.get("name") == "Iván Alejo" and y0.get("value") == 17 \
    and y0.get("playerId") == 640089 and y0.get("leagueKey") == "laliga" and yn == 10 \
    and r0.get("name") == "Christopher Bonsu Baah" and r0.get("value") == 3 \
    and r0.get("playerId") == 1452385 and r0.get("leagueKey") == "belgium" and rn == 10
report("A1 global hist 23/24 cards", good,
       f"y{yn}[{y0.get('name')}/{y0.get('value')}/{y0.get('leagueKey')}] "
       f"r{rn}[{r0.get('name')}/{r0.get('value')}/{r0.get('leagueKey')}] s0={s0.get('playerId')}")

# A2: another historical season — 2024/2025 (different kings)
d = get(BASE + "/api/topscorers?season=2024%2F2025")
y0, yn = head(d, "yellow"); r0, rn = head(d, "red")
good = y0.get("name") == "Feta Fetai" and y0.get("value") == 14 \
    and y0.get("playerId") == 1516458 and y0.get("leagueKey") == "hnl" \
    and r0.get("name") == "Uros Radakovic" and r0.get("value") == 4 \
    and r0.get("playerId") == 364855 and r0.get("leagueKey") == "superlig" \
    and yn == 10 and rn == 10
report("A2 global hist 24/25 cards", good,
       f"y{yn}[{y0.get('name')}/{y0.get('value')}/{y0.get('leagueKey')}] "
       f"r{rn}[{r0.get('name')}/{r0.get('value')}/{r0.get('leagueKey')}]")

# A3: the dataless season stays byte-honest — no cards key at all (176)
d = get(BASE + "/api/topscorers?season=2013%2F2014")
good = d.get("ok") is True and d.get("selectedSeason") == "2013/2014" \
    and (d.get("scorers") or []) == [] and "cards" not in d
report("A3 2013/2014 honest omission", good,
       f"sc={len(d.get('scorers') or [])} cards={'cards' in d}")

# A4: the current race byte-identical (the cycle-50 surface untouched)
d = get(BASE + "/api/topscorers")
old = {"ok", "scorers", "perLeague", "updatedAt"}
extra = set(d.keys()) - old
y0, yn = head(d, "yellow"); r0, rn = head(d, "red")
good = extra == {"assists", "cards", "selectedSeason", "allSeasons"} \
    and len(d.get("scorers") or []) == 400 \
    and y0.get("name") == "Lukas Klemenz" and y0.get("playerId") == 617234 \
    and r0.get("name") == "Edimilson Fernandes" and r0.get("playerId") == 451335
report("A4 current race byte-identical", good,
       f"extra={sorted(extra)} y{yn}[{y0.get('name')}] r{rn}[{r0.get('name')}]")

# A5: the 185 per-league surfaces intact
d = get(BASE + "/api/topscorers/pl?season=2024%2F2025")
y0, yn = head(d, "yellow")
good = y0.get("name") == "Flynn Downes" and y0.get("playerId") == 844943 and y0.get("value") == 12
d2 = get(BASE + "/api/standings?league=pl&season=2023%2F2024")
p0, pn = head(d2, "yellow")
good = good and p0.get("name") == "João Palhinha" and p0.get("playerId") == 524434
report("A5 185 per-league surfaces intact", good,
       f"ts/pl y0={y0.get('playerId')} st/pl y0={p0.get('playerId')}")

# A6: the guards — invalid season 400 (55/132) + league query 400 (184)
c1 = code(BASE + "/api/topscorers?season=nonsense")
c2 = code(BASE + "/api/topscorers?league=pl")
good = c1 == 400 and c2 == 400
report("A6 season+league guards", good, f"season={c1} league={c2}")

# A7: the merge shape — cards rows keep the 50 contract (rank dense, fa names)
d = get(BASE + "/api/topscorers?season=2023%2F2024")
y = (d.get("cards") or {}).get("yellow") or []
ranks = [r.get("rank") for r in y]
good = ranks == list(range(1, len(ranks) + 1)) \
    and all(r.get("nameFa") for r in y) \
    and all(r.get("leagueFa") for r in y)
report("A7 merged rows contract", good, f"ranks={ranks[:4]}... fa={all(r.get('nameFa') for r in y)}")

print("API_ALL_OK" if ok else "API_BAD")
PY
) || BAD=$((BAD+1))
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

open_page "/"
clean_ls

# B1: the historical race renders the «آقای کارت» block for the FIRST time
# (Alejo anchor + Kane anchor + the selector pre-set to 2023/2024)
open_page "/topscorers?season=2023%2F2024"
$B wait --fn "document.body.innerText.includes('آقای کارت')" >/dev/null 2>&1
sleep 1.5
FEAT=$(snap 'cards:[...document.querySelectorAll("h2")].some(h=>h.textContent.includes("آقای کارت")),alejo:!!document.querySelector("a[href=\"/player/640089\"]"),kane:!!document.querySelector("a[href=\"/player/194165\"]"),selval:(document.querySelector("select")||{}).value||""')
B1=0
echo "$FEAT" | rg -q 'cards:true' || B1=1
echo "$FEAT" | rg -q 'alejo:true' || B1=1
echo "$FEAT" | rg -q 'kane:true' || B1=1
echo "$FEAT" | rg -q 'selval:2023/2024' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 hist race cards block" "$FEAT"
clean_ls

# B2: REAL click on the historical yellow king → /player/640089 (the
# 167/170 link contract on the MERGED historical rows)
open_page "/topscorers?season=2023%2F2024"
$B wait --fn "!!document.querySelector('a[href=\"/player/640089\"]')" >/dev/null 2>&1
sleep 1
$B eval "(function(){const a=document.querySelector('a[href=\"/player/640089\"]');if(!a)return 'no-link';a.click();return 'clicked'})()" >/dev/null 2>&1
$B wait --fn "location.pathname === '/player/640089'" >/dev/null 2>&1
sleep 2
URL=$($B eval 'location.pathname' 2>/dev/null | tr -d '"\\')
FEAT=$(snap 'h1:(document.querySelector("h1")||{}).textContent||""')
B2=0
echo "$URL" | grep -q "player/640089" || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 click hist yellow king" "$FEAT | url=$URL"
clean_ls

# B3: the dataless season — honest empty WITHOUT the cards BLOCK and
# WITHOUT the fake error. The h2-scoped check matters: the page's static
# explainer paragraph ALSO contains «آقای کارت» (a naive innerText needle
# false-positived on the first draft — the D5 bytes-before-gates lesson).
open_page "/topscorers?season=2013%2F2014"
sleep 1.5
FEAT=$(snap 'cards:[...document.querySelectorAll("h2")].some(h=>h.textContent.includes("آقای کارت")),err:document.body.innerText.includes("داده\u200Cای برای نمایش نیست"),empty:document.body.innerText.includes("منتشر نشده"),selval:(document.querySelector("select")||{}).value||""')
B3=0
echo "$FEAT" | rg -q 'cards:false' || B3=1
echo "$FEAT" | rg -q 'err:false' || B3=1
echo "$FEAT" | rg -q 'empty:true' || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 2013/2014 honest empty" "$FEAT"
clean_ls

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK — cycle-186 update proven (A 7/7 + B 3/3 @390x844)"
else
  echo "DOM_PROOF BAD=$BAD"
  exit 1
fi
