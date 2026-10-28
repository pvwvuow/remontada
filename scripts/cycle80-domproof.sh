#!/bin/bash
# Cycle-80 DOM proof: the new «سوابق لیگ» section (team-history) on the three
# reference clubs at 390x844 — sw=cw, exactly one h1, zero visible-broken
# images, section present with the expected first row (most recent season,
# champion badge on leaders), console + app errors clean. Console/errors are
# cleared before every probe (same hygiene as bughunt78).
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
  $B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,h1:(document.querySelector("h1")||{}).textContent||"",vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,hist:!!document.querySelector("[data-testid=team-history]"),histRows:document.querySelectorAll("[data-testid=team-history] li").length,firstRow:(document.querySelector("[data-testid=team-history] li")||{}).innerText||"",champ:[...document.querySelectorAll("[data-testid=team-history] li")].filter(li=>/قهرمان لیگ/.test(li.innerText)).length,archive:(document.querySelector("[data-testid=team-history]")?.closest("section")?.querySelector("header span")||{}).textContent||""})'
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

probe "http://localhost:3000/team/9925"
probe "http://localhost:3000/team/9826"
probe "http://localhost:3000/team/8456"
probe "http://localhost:3000/"
