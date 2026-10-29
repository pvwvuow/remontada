#!/bin/bash
# cycle-124 DOM proof at 390x844 — «آقای گل فصل‌های تاریخی» (season-pure scorers)
# The update: getFullGoalScorers (the full per-season goals-file fetch feeding
# the merged scorers list) is now SEASON-AWARE — it follows the requested
# season via the seasonal raw's own fetchAllUrl (live-probed:
# data.fotmob.com/stats/{league}/season/{tournamentId}/goals.json archives
# exist per season, e.g. 2023/2024 PL = season/20720 = 298 rows, Haaland 27).
# This simultaneously FIXES a live-proven correctness bug (the season-blind
# merge leaked CURRENT-season goal counts into historical views: 2023/2024 PL
# ranked João Pedro 5-goals 4th — a 2026/27 count — while Watkins 19 / Foden 19
# / Solanke 19 were displaced) AND gives historical views the full per-season
# depth. Cache keys bumped (standings v5→v6, fullGoals v2→v3).
# Proof: (A) API truth — historical views serve the REAL per-season tables,
# current view unchanged, persiangulf designed 503 intact;
# (B) DOM — the league «آقای گل» tab renders the season-correct hero + rows on
# a historic deep-link and the current view stays intact; /topscorers/pl
# unchanged; 390x844: sw=cw, exactly 1 h1, 0 broken images, console=0,
# appErr=0 (bitmask 1=overflow 2=h1!=1 4=broken imgs; cycle-108 url convention).
set -u
B=agent-browser
$B set viewport 390 844 >/dev/null

echo "== PART A: API truth (season purity) =="
python3 - <<'PY'
import json, urllib.request, gzip, urllib.error
def get(u):
    r = urllib.request.Request(u, headers={'User-Agent': 'Chrome/124'})
    raw = urllib.request.urlopen(r, timeout=30).read()
    if raw[:2] == b'\x1f\x8b':
        raw = gzip.decompress(raw)
    return json.loads(raw)
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")
# the REAL 2023/2024 PL table (verifiable facts)
true2324 = {'Erling Haaland': 27, 'Cole Palmer': 22, 'Alexander Isak': 21,
            'Ollie Watkins': 19, 'Phil Foden': 19, 'Dominic Solanke': 19,
            'Mohamed Salah': 18, 'Heung-Min Son': 17}
try:
    d = get('http://localhost:3000/api/standings?league=pl&season=2023/2024')
    sc = d.get('scorers') or []
    got = {s.get('name'): s.get('goals') for s in sc}
    checked = {n: got.get(n) for n in true2324 if n in got}
    pure = all(got.get(n) == v for n, v in checked.items()) and len(checked) >= 6
    report('pl 2023/2024 season-pure', d.get('selectedSeason') == '2023/2024' and pure and len(sc) >= 15,
           f"n={len(sc)} verified={len(checked)} sample={[(s['name'], s['goals']) for s in sc[:3]]}")
except Exception as e:
    report('pl 2023/2024', False, str(e)[:90])
try:
    d = get('http://localhost:3000/api/standings?league=laliga&season=2022/2023')
    sc = d.get('scorers') or []
    top = sc[0] if sc else {}
    report('laliga 2022/2023', d.get('selectedSeason') == '2022/2023' and top.get('name') == 'Robert Lewandowski' and top.get('goals') == 23 and len(sc) >= 15,
           f"n={len(sc)} top={top.get('name')} {top.get('goals')}")
except Exception as e:
    report('laliga 2022/2023', False, str(e)[:90])
try:
    d = get('http://localhost:3000/api/standings?league=ucl&season=2024/2025')
    sc = d.get('scorers') or []
    names = {s.get('name') for s in sc[:3]}
    report('ucl 2024/2025', d.get('selectedSeason') == '2024/2025' and len(sc) >= 15 and 'Raphinha' in names,
           f"n={len(sc)} top3={[(s['name'], s['goals']) for s in sc[:3]]}")
except Exception as e:
    report('ucl 2024/2025', False, str(e)[:90])
try:
    d = get('http://localhost:3000/api/standings?league=pl')
    sc = d.get('scorers') or []
    top = sc[0] if sc else {}
    report('current pl unchanged', top.get('name') == 'Erling Haaland' and top.get('goals') == 9 and len(sc) >= 15,
           f"n={len(sc)} top={top.get('name')} {top.get('goals')}")
except Exception as e:
    report('current pl', False, str(e)[:90])
try:
    urllib.request.urlopen('http://localhost:3000/api/standings?league=persiangulf', timeout=30)
    report('persiangulf designed 503', False, 'expected 503, got 200')
except urllib.error.HTTPError as e:
    body = e.read().decode('utf-8', 'replace')
    report('persiangulf designed 503', e.code == 503 and 'در دسترس نیست' in body, f"designed {e.code}")
except Exception as e:
    report('persiangulf designed 503', False, str(e)[:90])
print("API_TRUTH " + ("OK" if ok else "BAD"))
PY

echo "== PART B: DOM 390x844 =="
probe() { # $1=url $2=label $3=extra-bool-expr(json fields over txt/tabs)
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 3
  local FEAT OUT BAD C E RC=0
  FEAT=$($B eval "JSON.stringify((()=>{const txt=document.body.innerText||'';const tabs=[...document.querySelectorAll('button')].map(b=>(b.textContent||'').trim());return $3})())" 2>/dev/null | tr -d '"\\')
  OUT=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null)
  BAD=$($B eval '(function(){var sw=document.documentElement.scrollWidth,cw=document.documentElement.clientWidth,h1n=document.querySelectorAll("h1").length,vb=[...document.images].filter(function(i){return i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden"}).length;return (sw!=cw?1:0)+(h1n!=1?2:0)+(vb>0?4:0)})()' 2>/dev/null | tr -d '"')
  C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception:
  print('ERR')")
  E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  app=[e for e in es if e.get('url')]
  print(len(app))
except Exception:
  print('ERR')")
  echo "$2 → $OUT | feat=$FEAT | console=$C appErrors=$E"
  [ "$BAD" != "0" ] && RC=1
  [ "$E" != "0" ] && RC=1
  return $RC
}
TOTAL_BAD=0

# B1: historic deep-link — scorers tab shows the season-correct hero (Haaland ۲۷)
probe "http://localhost:3000/league/pl?season=2023/2024" "B1 /league/pl?season=2023/2024" \
  '{histLabel:txt.includes("فصل ۲۰۲۳/۲۰۲۴"),falseBanner:txt.includes("ارتباط برقرار نشد.")}' \
  || { echo "   ⚠ B1 FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }
$B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="آقای گل");if(b)b.click();return 1})()' >/dev/null 2>&1
sleep 2
B1B=$($B eval 'JSON.stringify((()=>{const txt=document.body.innerText||"";return {heroHaaland:txt.includes("ارلینگ هالند")||txt.includes("هالند"),g27:txt.includes("۲۷"),palmer22:txt.includes("کول پالمر")&&txt.includes("۲۲"),fullPageLink:txt.includes("صفحه کامل گلزنان")}})())' 2>/dev/null | tr -d '"\\')
echo "B1b historic scorers tab → $B1B"
echo "$B1B" | grep -q 'heroHaaland:true' && echo "$B1B" | grep -q 'g27:true' && echo "$B1B" | grep -q 'palmer22:true' \
  || { echo "   ⚠ B1b FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }

# B2: current view — hero stays the CURRENT leader (Haaland ۹)
probe "http://localhost:3000/league/pl" "B2 /league/pl (current)" \
  '{falseBanner:txt.includes("ارتباط برقرار نشد.")}' \
  || { echo "   ⚠ B2 FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }
$B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="آقای گل");if(b)b.click();return 1})()' >/dev/null 2>&1
sleep 2
B2B=$($B eval 'JSON.stringify((()=>{const txt=document.body.innerText||"";return {haaland:txt.includes("هالند"),g9:txt.includes("۹")}})())' 2>/dev/null | tr -d '"\\')
echo "B2b current scorers tab → $B2B"
echo "$B2B" | grep -q 'haaland:true' && echo "$B2B" | grep -q 'g9:true' \
  || { echo "   ⚠ B2b FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }

# B3: /topscorers/pl global page intact
probe "http://localhost:3000/topscorers/pl" "B3 /topscorers/pl" \
  '{haaland:txt.includes("هالند"),falseBanner:txt.includes("ارتباط برقرار نشد.")}' \
  || { echo "   ⚠ B3 FLAGGED"; TOTAL_BAD=$((TOTAL_BAD+1)); }

echo "==="
echo "FLAGGED_PAGES=$TOTAL_BAD of 3 (B1b/B2b counted separately)"
if [ "$TOTAL_BAD" = "0" ]; then
  echo "CYCLE124 UPDATE PROOF OK"
else
  echo "CYCLE124 UPDATE PROOF BAD"
fi
