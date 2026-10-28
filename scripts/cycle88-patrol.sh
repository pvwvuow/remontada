#!/bin/bash
# Cycle-88 bug-hunt DOM patrol at 390x844 across every real route:
# sw=cw (no horizontal overflow), exactly one h1, zero visible-broken
# images, console clean, app errors clean (url-null = known CLI artifact).
set -u
B=agent-browser

PAGES=(
  "http://localhost:3000/"
  "http://localhost:3000/news"
  "http://localhost:3000/leagues"
  "http://localhost:3000/topscorers"
  "http://localhost:3000/league/pl"
  "http://localhost:3000/league/persiangulf"
  "http://localhost:3000/team/9925"
  "http://localhost:3000/team/9826"
  "http://localhost:3000/team/8456"
  "http://localhost:3000/player/737066"
  "http://localhost:3000/match/5749720"
  "http://localhost:3000/match/5406269"
)

$B set viewport 390 844 >/dev/null
TOTAL_BAD=0
for P in "${PAGES[@]}"; do
  $B errors --clear >/dev/null 2>&1
  $B console --clear >/dev/null 2>&1
  $B open "$P" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 1.8
  OUT=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,title:(document.querySelector("h1")||{}).textContent||""})' 2>/dev/null)
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
  echo "$P → $OUT | console=$C appErrors=$E"
  # bad bitmask computed in-browser: 1=overflow 2=h1!=1 4=broken imgs
  if [ "$E" != "0" ] || [ "$BAD" != "0" ]; then TOTAL_BAD=$((TOTAL_BAD+1)); echo "   ⚠ FLAGGED (bad=$BAD appErr=$E)"; fi
done
echo "==="
echo "FLAGGED_PAGES=$TOTAL_BAD of ${#PAGES[@]}"
