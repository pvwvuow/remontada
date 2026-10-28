#!/bin/bash
# Cycle-82 DOM proof: the three new player-page depth sections at 390x844 —
# «عملکرد فصل» (grouped stats + percentile bars), «مقایسهٔ آمار با هم‌پست‌ها»
# (traits bars), «روند ارزش بازار» (sparkline) — on a forward (737066) and a
# goalkeeper (1185782). Overflow / h1 / broken-img hygiene, console + app
# errors clean. Console/errors cleared before each probe.
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
  $B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,h1:(document.querySelector("h1")||{}).textContent||"",vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,deep:!!document.querySelector("[data-testid=player-deep-stats]"),deepGroups:document.querySelectorAll("[data-testid=player-deep-stats] .grid > div").length,goldBars:document.querySelectorAll("[data-testid=player-deep-stats] .bg-gold\\/70").length,traits:!!document.querySelector("[data-testid=player-traits]"),traitRows:document.querySelectorAll("[data-testid=player-traits] li").length,market:!!document.querySelector("[data-testid=player-market]"),spark:!!document.querySelector("[data-testid=player-market] svg polyline"),cur:(document.querySelector("[data-testid=player-market] p")||{}).textContent||""})'
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
$B screenshot /home/z/my-project/remontada/scripts/cycle82-player-depth.png >/dev/null 2>&1
echo "screenshot: scripts/cycle82-player-depth.png"
