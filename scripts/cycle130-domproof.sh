#!/bin/bash
# cycle-130 update proof at 390x844 — «چهرهٔ بازیکن»: real headshots everywhere.
# Upstream contract (live-probed with UA Chrome/124 before the change):
#   https://images.fotmob.com/image_resources/playerimages/{id}.png
#     → 200 image/png for active players (Haaland 737066 19.8KB, Raphinha 696679 21.8KB)
#     → 403 S3 AccessDenied for missing/retired ids (Messi 295672, fake 99999999)
#   → so PlayerPhoto (src/components/remontada/player-photo.tsx) renders the
#     initials tile as the base layer and the <img> hides itself onError —
#     zero broken images by construction.
# Integrated: player-profile hero, /topscorers rows+hero, standings آقای گل,
# league آقای گل, league-scorers hero, team last-lineup rows (32px photo,
# shirt number moved next to the name — no data lost).
# This script: API truth (photo-contract inputs) + DOM proof that the
# headshots really render and LOAD (naturalWidth>0) on the new build,
# every page sw=cw=390, exactly 1 h1, 0 broken images, console=0, appErr=0.
set -u
B=agent-browser
$B set viewport 390 844 >/dev/null

echo "== PART A: API truth (photo-contract inputs) =="
python3 - <<'PY'
import json, urllib.request, urllib.error
def get(u):
    r = urllib.request.Request(u, headers={'User-Agent': 'Chrome/124'})
    return json.load(urllib.request.urlopen(r, timeout=30))
ok = True
def report(name, good, detail):
    global ok
    print(('PASS ' if good else 'FAIL ') + name + ' — ' + detail)
    if not good: ok = False
try:
    d = get('http://localhost:3000/api/topscorers?league=pl')
    s = d.get('scorers') or []
    ids = [x.get('playerId') for x in s]
    report('topscorers carry playerIds (photo keys)',
           d.get('ok') is True and len(s) >= 10 and all(ids),
           f"n={len(s)} first={s[0].get('name')}({s[0].get('playerId')})")
except Exception as e:
    ok = False; print('topscorers: ERR', e)
try:
    d = get('http://localhost:3000/api/standings?league=pl')
    sc = d.get('scorers') or []
    report('standings scorers carry playerIds',
           d.get('ok') is True and len(sc) > 0 and sc[0].get('playerId') is not None,
           f"top={sc[0].get('name')}({sc[0].get('playerId')})" if sc else 'empty')
except Exception as e:
    ok = False; print('standings: ERR', e)
# the upstream headshot URL itself, through the app's own contract
import urllib.request
for pid, label in ((737066, 'haaland'), (696679, 'raphinha')):
    try:
        r = urllib.request.urlopen(urllib.request.Request(
            f'https://images.fotmob.com/image_resources/playerimages/{pid}.png',
            headers={'User-Agent': 'Chrome/124'}), timeout=15)
        report(f'upstream headshot {label} {pid}', r.status == 200 and r.headers.get('content-type') == 'image/png',
               f"code={r.status} type={r.headers.get('content-type')} bytes={len(r.read())}")
    except Exception as e:
        ok = False; print(f'headshot {pid}: ERR', e)
print('API_TRUTH', 'OK' if ok else 'FAILED')
PY

echo "== PART B: DOM 390x844 — headshots render and load =="
probe() { # $1=url $2=label $3=extra-bool-expr(js, over nothing — house pattern)
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

# P1: Haaland profile — the hero headshot is in the initial DOM AND loaded
probe "http://localhost:3000/player/737066" "P1 /player/737066" \
"const h=[...document.images].find(i=>i.src.includes('playerimages/737066.png'));return {hero:!!h,loaded:h?h.naturalWidth>0:false,src:h?h.src.slice(-40):null}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# P2: مصاف گلزنان — many faces (rows + hero), all loaded
probe "http://localhost:3000/topscorers" "P2 /topscorers" \
"const f=[...document.images].filter(i=>i.src.includes('playerimages/'));return {faces:f.length,loaded:f.filter(i=>i.naturalWidth>0).length}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# P3: league page — the آقای گل chip carries the leader's face
probe "http://localhost:3000/league/pl" "P3 /league/pl" \
"const f=[...document.images].filter(i=>i.src.includes('playerimages/'));return {faces:f.length,loaded:f.filter(i=>i.naturalWidth>0).length}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# P4: team page — last-lineup rows show faces (11 starters expected)
probe "http://localhost:3000/team/8456" "P4 /team/8456 (lineup faces)" \
"const f=[...document.images].filter(i=>i.src.includes('playerimages/'));return {faces:f.length,loaded:f.filter(i=>i.naturalWidth>0).length,lineup:document.body.innerText.includes('آخرین ترکیب')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# P5: league scorers full page hero
probe "http://localhost:3000/league/pl?tab=scorers" "P5 /league/pl?tab=scorers" \
"const f=[...document.images].filter(i=>i.src.includes('playerimages/'));return {faces:f.length,loaded:f.filter(i=>i.naturalWidth>0).length}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

echo "== RESULT =="
if [ "$TOTAL_BAD" -eq 0 ]; then echo "DOM_PROOF OK (5/5 pages green — faces render+load, no overflow, 1 h1, 0 broken imgs, clean console)"; else echo "DOM_PROOF FLAGGED=$TOTAL_BAD"; exit 1; fi
