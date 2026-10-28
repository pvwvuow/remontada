#!/bin/bash
# Bug-hunt cycle-58 patrol: walk portal pages at 390x844, probe overflow /
# broken images / h1 / console / errors. Evidence for worklog card.
set -u
B=agent-browser

probe() {
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 80" >/dev/null 2>&1
  sleep 1.2
  echo "== $1 =="
  $B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1:(document.querySelector("h1")||{}).textContent||"",imgs:document.images.length,broken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0).length,brokenSrc:[...document.images].filter(i=>i.complete&&i.naturalWidth===0).slice(0,3).map(i=>i.src)})'
  C=$($B console 2>&1 | grep -v "agent-browser" | head -3)
  E=$($B errors 2>&1 | grep -v "agent-browser" | head -3)
  [ -n "$C" ] && echo "CONSOLE: $C"
  [ -n "$E" ] && echo "ERRORS: $E"
  echo "--"
}

$B set viewport 390 844 >/dev/null

probe "http://localhost:3000/"
probe "http://localhost:3000/leagues"
probe "http://localhost:3000/league/pl"
probe "http://localhost:3000/league/ucl"
probe "http://localhost:3000/league/persiangulf"
probe "http://localhost:3000/team/8456"
probe "http://localhost:3000/match/5749720"
probe "http://localhost:3000/player/737066"
probe "http://localhost:3000/topscorers"
probe "http://localhost:3000/topscorers/pl"
probe "http://localhost:3000/news"
# error-path pages (should show Persian empty states, not crash)
probe "http://localhost:3000/league/notaleague"
probe "http://localhost:3000/team/999999999"
probe "http://localhost:3000/match/999999999"
