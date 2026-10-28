#!/bin/bash
# Cycle-85 DOM proof: verdict + penalty badge on «همهٔ بازی‌های فصل» rows at
# 390x844 — the City friendly 5406269 (1-1, pens 2-4, team lost the shootout)
# must render score pill «۱ : ۱», gold «پن ۲-۴» badge and chip «پ» (not «م»),
# found after expanding the results toggle; verdict chips on visible rows stay
# consistent; sw=cw, one h1, zero visible-broken images, console + app errors
# clean before every probe (same hygiene as cycle80/81).
set -u
B=agent-browser

probe() {
  $B errors --clear >/dev/null 2>&1
  $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 1.8
  echo "== $1 =="
  $B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,fx:!!document.querySelector("[data-testid=team-fixtures]")})'
  C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print('console=', len(d['data']['messages']))
except Exception:
  print('console=READERR')")
  E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  app=[e for e in es if e.get('url')]; cli=[e for e in es if not e.get('url')]
  print('errors: app-url=', len(app), 'cli-artifact-url-null=', len(cli))
except Exception:
  print('errors: READERR')")
  echo "$C  $E"
  echo "--"
}

$B set viewport 390 844 >/dev/null

# main proof: City 8456 — expand results, inspect the shootout row 5406269
$B errors --clear >/dev/null 2>&1
$B console --clear >/dev/null 2>&1
$B open "http://localhost:3000/team/8456" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.querySelector('[data-testid=team-fixtures]')" >/dev/null 2>&1
sleep 1.8
echo "== /team/8456 shootout row (after expand) =="
$B eval '(() => { const bs=[...document.querySelectorAll("[data-testid=team-fixtures] button")]; bs.forEach(b=>b.click()); return "clicked:"+bs.length; })()' >/dev/null 2>&1
sleep 1
$B eval '(() => { const row=document.querySelector("[data-testid=team-fixtures] a[href*=\"5406269\"]"); if(!row) return JSON.stringify({found:false,rows:document.querySelectorAll("[data-testid=team-fixtures] a").length}); const spans=[...row.querySelectorAll("span")].map(s=>s.textContent||""); return JSON.stringify({found:true,text:(row.innerText||"").replace(/\n/g," | "),spans,sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth}); })()'
C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print('console=', len(d['data']['messages']))
except Exception:
  print('console=READERR')")
E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  app=[e for e in es if e.get('url')]; cli=[e for e in es if not e.get('url')]
  print('errors: app-url=', len(app), 'cli-artifact-url-null=', len(cli))
except Exception:
  print('errors: READERR')")
echo "$C  $E"
echo "--"

probe "http://localhost:3000/team/9925"
probe "http://localhost:3000/team/9826"
probe "http://localhost:3000/"
