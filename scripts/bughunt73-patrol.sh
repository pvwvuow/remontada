#!/bin/bash
# Bug-hunt cycle-73 patrol: surfaces added since the cycle-58 sweep — the
# team page lazy sections (squad 70 / transfers 71 / trophies 72) + their
# endpoints + error paths — plus the core portal pages. 390x844, probing
# overflow / visible-broken images / h1 / console / errors.
set -u
B=agent-browser

probe() {
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 80" >/dev/null 2>&1
  sleep 1.6
  echo "== $1 =="
  $B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1:(document.querySelector("h1")||{}).textContent||"",imgs:document.images.length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,squad:!!document.querySelector("[data-testid=team-squad]"),transfers:!!document.querySelector("[data-testid=team-transfers]"),trophies:!!document.querySelector("[data-testid=team-trophies]")})'
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
probe "http://localhost:3000/team/9925"
probe "http://localhost:3000/team/8456"
probe "http://localhost:3000/player/737066"
probe "http://localhost:3000/topscorers"
probe "http://localhost:3000/news"
probe "http://localhost:3000/match/5749720"
# error-path pages (Persian empty/error states, must not crash)
probe "http://localhost:3000/league/notaleague"
probe "http://localhost:3000/team/999999999"
probe "http://localhost:3000/match/999999999"

# lazy team endpoints: valid / unknown team / malformed id
api() {
  echo "== API $1 =="
  curl -s -m 40 -o /tmp/bh73.json -w "HTTP %{http_code} " "$1"
  python3 -c "
import json
try:
    d=json.load(open('/tmp/bh73.json'))
    ks=[k for k in d.keys() if k!='ok']
    vals={k:(len(d[k]) if isinstance(d[k],list) else ('null' if d[k] is None else type(d[k]).__name__)) for k in ks}
    print('ok:',d.get('ok'),'|',vals,'| err:',d.get('error',''))
except Exception as e:
    print('BADJSON:',e)
"
}
api "http://localhost:3000/api/team-squad/9925"
api "http://localhost:3000/api/team-transfers/9925"
api "http://localhost:3000/api/team-trophies/9925"
api "http://localhost:3000/api/team-trophies/999999999"
api "http://localhost:3000/api/team-trophies/abc"
api "http://localhost:3000/api/team-transfers/abc"
