#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-182 update proof — «انتخابگر فصل به هاب بازیکنان می‌پیوندد»
#
# The stars mode of /players was the LAST /api/topscorers consumer still
# stuck on the current season: the merge route has served historical
# seasons since cycle-132 (live-probed: 2023/2024 → 380 scorers, Kane 36g
# top, 10 assists; 2013/2014 → honest 200-with-zero) and both sister
# surfaces already carry the selector (global race page cycle-132, league
# page cycle-55/99, per-league topscorers cycle-180). The task's stale
# remaining-gaps list (season selector / cups bracket / transfers) was
# already dissolved — found by live probing, the 180 discovery pattern.
#
# Update (additive-only, the 108/132/180 contract): players-view gains the
# proven selector byte-style — deep-link ?season= seeding (ONE fetch per
# deep link, strict SEASON_PARAM_RE, anything else loads the current race),
# honesty snap (the payload's selectedSeason marker is the truth anchor; on
# disagreement snap back + strip the stale param), URL replaceState sync
# (also on the stars-mode syncUrl branch), options from the payload's own
# allSeasons, the cycle-99 append invariant, and the season-aware honest
# empty state («ستاره‌ای برای فصل ... ثبت نشده است»). Squads stay current by
# nature. ZERO route changes — /api/topscorers byte-untouched.
#
# Pinned live truth (probed 2026-10-30 ~08:4x +08, UA Chrome/124, official
# start pid after fresh build):
#   /api/topscorers            extra == {assists,cards,selectedSeason,
#                              allSeasons}, 400 scorers / 20 perLeague,
#                              sel=2026/2027, allSeasons=12
#   /api/topscorers?2023/2024  s0 Harry Kane «هری کین» بایرن‌مونیخ 36g
#                              pid=194165 rank=1; assists=10 (Leif Davis
#                              18, pid 980381); cards key ABSENT (132)
#   /api/topscorers?2013/2014  200 + scorers=0 + sel=2013/2014
#   /api/topscorers?2023       400 (the cycle-55 guard)
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API truth (route byte-untouched) =="
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
        return urllib.request.urlopen(req, timeout=30).getcode()
    except urllib.error.HTTPError as e:
        return e.code
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

# A1: current-race parity — the global route keys are untouched (old keys +
# exactly the 132-era extras; the UI change is client-only)
try:
    d = get(BASE + "/api/topscorers")
    old = {"ok", "scorers", "perLeague", "updatedAt"}
    extra = set(d.keys()) - old
    good = extra == {"assists", "cards", "selectedSeason", "allSeasons"} \
        and len(d.get("scorers") or []) == 400 \
        and len(d.get("perLeague") or []) == 20 \
        and d.get("selectedSeason") == "2026/2027" \
        and len(d.get("allSeasons") or []) == 12
    report("A1 current race parity", good,
           f"extra={sorted(extra)} sc={len(d.get('scorers') or [])} "
           f"pl={len(d.get('perLeague') or [])} sel={d.get('selectedSeason')}")
except Exception as e:
    report("A1 current race parity", False, repr(e))

# A2: the historical race the new selector will render — Kane pin + honest
# card absence (the 132 rule) + the assists rows that feed «پاس گل» tab
try:
    q = urllib.parse.quote("2023/2024", safe="")
    d = get(f"{BASE}/api/topscorers?season={q}")
    s0 = (d.get("scorers") or [{}])[0]
    a = d.get("assists") or []
    good = d.get("selectedSeason") == "2023/2024" \
        and s0.get("playerId") == 194165 and s0.get("name") == "Harry Kane" \
        and s0.get("nameFa") == "هری کین" and s0.get("team") == "بایرن‌مونیخ" \
        and s0.get("goals") == 36 \
        and len(d.get("scorers") or []) >= 10 \
        and len(a) >= 5 and (a[0] or {}).get("playerId") == 980381 \
        and "cards" not in d \
        and len(d.get("allSeasons") or []) == 12
    report("A2 hist race Kane pin", good,
           f"sel={d.get('selectedSeason')} s0={s0.get('name')}/{s0.get('goals')}g "
           f"ass={len(a)} cardsAbsent={'cards' not in d}")
except Exception as e:
    report("A2 hist race Kane pin", False, repr(e))

# A3: honest empty — offered-but-dataless season serves 200 with its OWN
# marker and scorers=0 (the UI shows the season-aware empty state)
try:
    q = urllib.parse.quote("2013/2014", safe="")
    d = get(f"{BASE}/api/topscorers?season={q}")
    good = d.get("ok") is True and d.get("selectedSeason") == "2013/2014" \
        and (d.get("scorers") or []) == []
    report("A3 2013/2014 honest empty", good,
           f"sel={d.get('selectedSeason')} scorers={len(d.get('scorers') or [])}")
except Exception as e:
    report("A3 2013/2014 honest empty", False, repr(e))

# A4: invalid shape → 400 (the cycle-55 guard, byte-for-byte)
try:
    try:
        get(BASE + "/api/topscorers?season=2023")
        report("A4 invalid season 400", False, "no error raised")
    except Exception as e:
        good = isinstance(e, urllib.error.HTTPError) and e.code == 400
        report("A4 invalid season 400", good, repr(e.__class__.__name__))
except Exception as e:
    report("A4 invalid season 400", False, repr(e))

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

# B1: /players plain — the selector renders with the payload's 12 options,
# the «بیست» copy survives (gate-synced 158/181), the stars grid is warm
open_page "/players"
FEAT=$(snap 'sel:!!document.querySelector("select#season-select"),opts:document.querySelectorAll("select#season-select option").length,copy20:document.body.innerText.includes("ستاره\u200Cهای بیست لیگ و جام برتر"),players:document.querySelectorAll("a[href^=\"/player/\"]").length')
B1=0
echo "$FEAT" | rg -q 'sel:true' || B1=1
echo "$FEAT" | rg -q 'opts:(1[0-9]|[2-9][0-9])' || B1=1
echo "$FEAT" | rg -q 'copy20:true' || B1=1
echo "$FEAT" | rg -q 'players:([1-9][0-9]{2,})' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 /players selector" "$FEAT"

# B2: REAL season switch via the select — native setter + change event →
# the historical payload renders (Kane anchor; he is in NO current surface)
# and the subtitle carries the honest season label
$B eval "(function(){const s=document.querySelector('select#season-select');if(!s)return 'no-select';const opt=[...s.options].find(o=>o.value==='2023/2024');if(!opt)return 'no-option';const d=Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype,'value');d.set.call(s,'2023/2024');s.dispatchEvent(new Event('change',{bubbles:true}));s.dispatchEvent(new Event('input',{bubbles:true}));return 'switched'})()" >/dev/null 2>&1
$B wait --fn "!!document.querySelector('a[href=\"/player/194165\"]')" >/dev/null 2>&1
sleep 2
FEAT=$(snap 'kane:!!document.querySelector("a[href=\"/player/194165\"]"),sub:document.body.innerText.includes("ستاره\u200Cهای فصل"),selval:(document.querySelector("select#season-select")||{}).value||""')
URL=$($B eval 'decodeURIComponent(location.search)' 2>/dev/null | tr -d '"\\')
B2=0
echo "$FEAT" | rg -q 'kane:true' || B2=1
echo "$FEAT" | rg -q 'sub:true' || B2=1
echo "$FEAT" | rg -q 'selval:2023/2024' || B2=1
echo "$URL" | grep -q "season=2023/2024" || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 switch→2023/2024" "$FEAT | url=$URL"

# B3: the switched grid click-through — Kane card → /player/194165
CLICKED=$($B eval '(function(){const links=[...document.querySelectorAll("a[href=\"/player/194165\"]")];const hit=links.find(l=>(l.innerText||"").includes("کین"));if(hit){hit.click();return "clicked"}return "no-row"})()' 2>/dev/null | tr -d '"\\')
$B wait --fn "location.pathname.startsWith('/player/194165')" >/dev/null 2>&1
sleep 2
H1=$($B eval 'JSON.stringify((document.querySelector("h1")||{}).innerText||"")' 2>/dev/null | tr -d '"\\')
URL3=$($B eval 'location.pathname' 2>/dev/null | tr -d '"\\')
B3=0
[ "$CLICKED" = "clicked" ] || B3=1
case "$URL3" in /player/194165*) : ;; *) B3=1 ;; esac
echo "$H1" | grep -q "کین" || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 click Kane" "clicked=$CLICKED url=$URL3 h1=$H1"

# B4: deep-link seeding — /players?season=2023/2024 opens the historical
# stars directly (ONE fetch, the cycle-99 pattern)
open_page "/players?season=2023%2F2024"
FEAT=$(snap 'kane:!!document.querySelector("a[href=\"/player/194165\"]"),selval:(document.querySelector("select#season-select")||{}).value||"",sub:document.body.innerText.includes("ستاره\u200Cهای فصل")')
B4=0
echo "$FEAT" | rg -q 'kane:true' || B4=1
echo "$FEAT" | rg -q 'selval:2023/2024' || B4=1
echo "$FEAT" | rg -q 'sub:true' || B4=1
[ "$B4" -eq 0 ] || BAD=$((BAD+1))
gate "B4 deep-link 2023/2024" "$FEAT"

# B5: honest empty — an offered-but-dataless season shows the season-aware
# empty copy, the selector stays, the page stays clean (no fake error)
open_page "/players?season=2013%2F2014"
FEAT=$(snap 'empty:document.body.innerText.includes("ستاره\u200Cای برای فصل"),sel:!!document.querySelector("select#season-select"),err:document.body.innerText.includes("داده\u200Cای برای نمایش نیست")')
B5=0
echo "$FEAT" | rg -q 'empty:true' || B5=1
echo "$FEAT" | rg -q 'sel:true' || B5=1
echo "$FEAT" | rg -q 'err:false' || B5=1
[ "$B5" -eq 0 ] || BAD=$((BAD+1))
gate "B5 honest empty 2013/2014" "$FEAT"

# B6: mode round-trip regression — teams mode untouched (the 134 contract),
# back to stars keeps the selector; URL returns clean on a plain load
open_page "/players"
$B eval '(function(){const b=document.querySelector("[data-testid=\"mode-teams\"]");if(b)b.click();return b?"ok":"no-tab"})()' >/dev/null 2>&1
$B wait --fn '!!document.querySelector("[data-testid=\"team-grid\"]")' >/dev/null 2>&1
sleep 1.5
$B eval '(function(){const b=document.querySelector("[data-testid=\"mode-stars\"]");if(b)b.click();return b?"ok":"no-tab"})()' >/dev/null 2>&1
$B wait --fn 'document.querySelectorAll("a[href^=\"/player/\"]").length > 50' >/dev/null 2>&1
sleep 1.5
FEAT=$(snap 'grid:!!document.querySelector("a[href^=\"/player/\"]"),sel:!!document.querySelector("select#season-select"),url:(location.pathname+location.search)')
URL6=$($B eval 'location.pathname+location.search' 2>/dev/null | tr -d '"\\')
B6=0
echo "$FEAT" | rg -q 'sel:true' || B6=1
[ "$URL6" = "/players" ] || B6=1
[ "$B6" -eq 0 ] || BAD=$((BAD+1))
gate "B6 mode round-trip" "$FEAT | url=$URL6"

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK (cycle-182: the season selector joins the players hub — the LAST /api/topscorers consumer stuck on the current season closes the cycle-55/99/132/180 sister arc: deep-link ?season= seeding with ONE fetch and the strict guard, honesty snap on the payload's selectedSeason marker, URL replaceState sync incl. the stars-mode syncUrl branch, options from the payload's own allSeasons with the cycle-99 append invariant, the season-aware honest empty state; the historical race really renders (Kane 36g anchor, click-through to /player/194165) and teams mode (squads) is untouched; ZERO route changes — /api/topscorers byte-untouched)"
else
  echo "DOM_PROOF FLAGGED (BAD=$BAD)"; exit 1
fi
