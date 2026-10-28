#!/bin/bash
# Cycle-90 DOM proof at 390x844: the xG table on league pages —
# /league/pl: [data-testid=league-xg] present with 20 rows, Persian digits,
# gold/muted delta chips; /league/ucl: 36 rows; /league/persiangulf: section
# hidden (no xG source) with page intact; historical season degrades honestly.
set -u
B=agent-browser

$B set viewport 390 844 >/dev/null
probe() {
  $B errors --clear >/dev/null 2>&1
  $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 2
  echo "== $1 =="
  $B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,xg:!!document.querySelector("[data-testid=league-xg]"),xgRows:document.querySelectorAll("[data-testid=league-xg] tbody tr").length,xgHead:(document.querySelector("[data-testid=league-xg] h2")||{}).textContent||"",firstDelta:(document.querySelector("[data-testid=league-xg] tbody tr td:last-child span[title]")||{}).textContent||""})'
  E=$($B errors --json 2>/dev/null | python3 -c 'import json,sys
try: print(len([e for e in json.load(sys.stdin)["data"]["errors"] if e.get("url")]))
except Exception: print("ERR")')
  echo "   appErr=$E"
}

probe "http://localhost:3000/league/pl"
probe "http://localhost:3000/league/ucl"
probe "http://localhost:3000/league/persiangulf"
probe "http://localhost:3000/league/pl?season=2024/2025"
