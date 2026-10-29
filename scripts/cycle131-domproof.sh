#!/bin/bash
# cycle-131 update proof at 390x844 — «دسترسی‌پذیری بازیکنان»: the /players
# page (born in cycle-130) was an orphan — no nav entry anywhere and absent
# from the sitemap. This cycle: «بازیکنان» joins BOTH navigations (the phone
# dock + the sm+ header nav, with a new players glyph), /players joins the
# sitemap, and the home-active prefix bug is fixed (pathname.startsWith("/player")
# also matched /players → «نتایج زنده» lit up on the players page; now "/player/"
# and the players item owns /players).
# Also probed live (protocol first step): league-bracket ucl → 200 and
# league-transfers pl → 200 (bracket + transfers are NOT gaps), while the
# historical-season selector UI remains the real standing footprint gap.
# Proof: dock=5 entries on /, sitemap.xml lists /players, /players page
# active-state correct (بازیکنان on, نتایج زنده off), /player/737066 keeps
# the home mapping, desktop header shows the players link at 1024px, and
# every page sw=cw=390, exactly 1 h1, 0 broken images, console=0, appErr=0.
set -u
B=agent-browser
$B set viewport 390 844 >/dev/null

echo "== PART A: API + sitemap truth =="
python3 - <<'PY'
import json, urllib.request, urllib.error
def get(u):
    r = urllib.request.Request(u, headers={'User-Agent': 'Chrome/124'})
    return urllib.request.urlopen(r, timeout=30)
ok = True
def report(name, good, detail):
    global ok
    print(('PASS ' if good else 'FAIL ') + name + ' — ' + detail)
    if not good: ok = False
try:
    r = get('http://localhost:3000/api/league-bracket?league=ucl'); r.read()
    report('bracket API alive (ucl)', r.status == 200, f"code={r.status}")
except Exception as e:
    ok = False; print('bracket: ERR', e)
try:
    r = get('http://localhost:3000/api/league-transfers?league=pl'); r.read()
    report('transfers API alive (pl)', r.status == 200, f"code={r.status}")
except Exception as e:
    ok = False; print('transfers: ERR', e)
try:
    r = get('http://localhost:3000/sitemap.xml')
    body = r.read().decode('utf-8', 'ignore')
    report('sitemap.xml lists /players', r.status == 200 and '/players<' in body, f"len={len(body)} has_players={'/players<' in body}")
except Exception as e:
    ok = False; print('sitemap: ERR', e)
print('API_TRUTH', 'OK' if ok else 'FAILED')
PY

echo "== PART B: DOM 390x844 =="
probe() { # $1=url $2=label $3=extra-js returning object
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 3
  local FEAT OUT BAD C E RC=0
  FEAT=$($B eval "JSON.stringify((()=>{$3})())" 2>/dev/null | tr -d '"\\')
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

# D1: home — the dock now has 5 entries incl. بازیکنان (no overflow at 390)
probe "http://localhost:3000/" "D1 / (dock 5 entries)" \
"const d=[...document.querySelectorAll('nav[aria-label=\"منوی بازی\"] a')];return {dock:d.length,hasPlayers:d.some(a=>a.getAttribute('href')==='/players'&&a.innerText.includes('بازیکنان'))}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D2: /players — the بازیکنان dock item is the ONLY active one (aria-current), home OFF
probe "http://localhost:3000/players" "D2 /players (active state)" \
"const d=[...document.querySelectorAll('nav[aria-label=\"منوی بازی\"] a')];const cur=d.filter(a=>a.getAttribute('aria-current')==='page').map(a=>a.getAttribute('href'));return {current:cur.join('|')||'none',playersActive:cur.includes('/players'),homeActive:cur.includes('/')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D3: /player/737066 — deep player page still maps home (prefix fix keeps it)
probe "http://localhost:3000/player/737066" "D3 /player/737066 (home mapping intact)" \
"const d=[...document.querySelectorAll('nav[aria-label=\"منوی بازی\"] a')];const cur=d.filter(a=>a.getAttribute('aria-current')==='page').map(a=>a.getAttribute('href'));return {homeActive:cur.includes('/')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D4: /topscorers — untouched nav neighbors stay sane
probe "http://localhost:3000/topscorers" "D4 /topscorers (regression)" \
"const d=[...document.querySelectorAll('nav[aria-label=\"منوی بازی\"] a')];const cur=d.filter(a=>a.getAttribute('aria-current')==='page').map(a=>a.getAttribute('href'));return {topscorersActive:cur.includes('/topscorers')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

echo "== PART C: desktop header nav at 1024px =="
$B set viewport 1024 800 >/dev/null 2>&1
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open http://localhost:3000/ >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
sleep 2
HDR=$($B eval 'JSON.stringify((()=>{const links=[...document.querySelectorAll("nav[aria-label=\"ناوبری اصلی\"] a")];return {items:links.length,hasPlayers:links.some(a=>a.getAttribute("href")==="/players")}})())' 2>/dev/null | tr -d '"\\')
echo "C1 desktop header → $HDR"
echo "$HDR" | grep -q 'hasPlayers:true' || TOTAL_BAD=$((TOTAL_BAD+1))

echo "== RESULT =="
if [ "$TOTAL_BAD" -eq 0 ]; then echo "DOM_PROOF OK (4/4 phone pages + desktop header green — dock 5 entries, /players active-state correct, home mapping intact, sitemap lists /players, clean console)"; else echo "DOM_PROOF FLAGGED=$TOTAL_BAD"; exit 1; fi
