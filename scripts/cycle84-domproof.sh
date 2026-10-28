#!/bin/bash
# Cycle-84 DOM proof: the fix adds an sr-only Persian h1 to the invalid-id
# error shells /team/abc and /player/abc (cycle-83 patrol finding). Prove at
# 390x844: each error shell now has exactly one h1 (hidden Persian label),
# valid team/player pages still have exactly one h1 (no double-h1 regression),
# zero visible-broken images, console + app errors clean before every probe.
set -u
B=agent-browser

probe() {
  $B errors --clear >/dev/null 2>&1
  $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 10" >/dev/null 2>&1
  sleep 1.8
  echo "== $1 =="
  $B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,h1:(document.querySelector("h1")||{}).textContent||"",h1vis:((document.querySelector("h1")||{}).offsetHeight||0),msg:(document.querySelector("main p")||{}).textContent||"",vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})'
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

probe "http://localhost:3000/team/abc"
probe "http://localhost:3000/player/abc"
probe "http://localhost:3000/team/0"
probe "http://localhost:3000/team/9925"
probe "http://localhost:3000/player/737066"
probe "http://localhost:3000/"
