#!/bin/bash
# Cycle-87 DOM proof at 390x844: the SSR pitch section on the player page —
# Haaland (outfield): «نقشهٔ شوت‌ها» with 30 shot dots (9 gold goal dots =
# circle[stroke]) + 248 heat dots + summary «۹ گل از ۳۰ شوت · xG مجموع ۶.۱»;
# Sinisalo (GK): auto keeper view «شوت‌های رو‌به‌رو» with faced shots; Rafiei
# (no pitch data): section absent, page intact. sw=cw, one h1, zero
# visible-broken images, console + app errors clean before every probe.
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
  $B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,pitch:!!document.querySelector("[data-testid=player-pitch]"),header:(document.querySelector("[data-testid=player-pitch] header")||{}).textContent||"",shots:[...document.querySelectorAll("[data-testid=player-pitch] svg circle")].length,goalDots:document.querySelectorAll("[data-testid=player-pitch] svg circle[stroke]").length,heat:!!document.querySelector("[data-testid=player-pitch] svg circle[opacity]")})'
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
probe "http://localhost:3000/player/737066"
probe "http://localhost:3000/player/1185782"
probe "http://localhost:3000/player/1543604"
probe "http://localhost:3000/"
