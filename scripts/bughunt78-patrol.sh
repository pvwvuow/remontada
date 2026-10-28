#!/bin/bash
# Bug-hunt cycle-78 patrol: full portal sweep + all five lazy team sections
# (squad 70 / transfers 71 / trophies 72 / venue 75 / stats 76-77) including
# the new topThree extras lines («سپس:»/«صدر:»), the cycle-74 a11y h1 fixes
# (team error shell + 404), a fresh dynamic error path (/topscorers/notaleague)
# and the six lazy endpoints with zero-id/malformed edges. 390x844, probing
# overflow / visible-broken images / h1 / console / errors per page.
set -u
B=agent-browser

probe() {
  $B errors --clear >/dev/null 2>&1
  $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 1.6
  echo "== $1 =="
  $B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,h1:(document.querySelector("h1")||{}).textContent||"",imgs:document.images.length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,squad:!!document.querySelector("[data-testid=team-squad]"),transfers:!!document.querySelector("[data-testid=team-transfers]"),trophies:!!document.querySelector("[data-testid=team-trophies]"),venue:!!document.querySelector("[data-testid=team-venue]"),stats:!!document.querySelector("[data-testid=team-stats]"),extras:[...document.querySelectorAll("[data-testid=team-stats] li")].filter(li=>/سپس:|صدر:/.test(li.innerText)).length})'
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

# core pages
probe "http://localhost:3000/"
probe "http://localhost:3000/leagues"
probe "http://localhost:3000/league/pl"
probe "http://localhost:3000/league/ucl"
# team pages: three clubs across the lazy stack
probe "http://localhost:3000/team/9925"
probe "http://localhost:3000/team/9826"
probe "http://localhost:3000/team/8456"
probe "http://localhost:3000/player/737066"
probe "http://localhost:3000/topscorers"
probe "http://localhost:3000/news"
probe "http://localhost:3000/match/5749720"
# error-path pages (Persian empty/error states, must not crash; 74 h1 fixes)
probe "http://localhost:3000/league/notaleague"
probe "http://localhost:3000/team/999999999"
probe "http://localhost:3000/match/999999999"
probe "http://localhost:3000/topscorers/notaleague"

# lazy team endpoints: valid / unknown team / malformed / zero-id edges
api() {
  echo "== API $1 =="
  curl -s -m 40 -o /tmp/bh78.json -w "HTTP %{http_code} " "$1"
  python3 -c "
import json
try:
    d=json.load(open('/tmp/bh78.json'))
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
api "http://localhost:3000/api/team-venue/9925"
api "http://localhost:3000/api/team-stats/9925"
api "http://localhost:3000/api/team-stats/9826"
api "http://localhost:3000/api/team-stats/999999999"
api "http://localhost:3000/api/team-venue/999999999"
api "http://localhost:3000/api/team-stats/abc"
api "http://localhost:3000/api/team-venue/abc"
api "http://localhost:3000/api/team-stats/0"
