#!/bin/bash
# Bug-hunt cycle-83 patrol: the three cycle-82 player depth sections
# («عملکرد فصل» / traits / «روند ارزش بازار») on a forward (737066) and a
# goalkeeper (1185782) plus TWO degradation subjects found by live probing —
# Rafiei 1543604 (no deep stats, no traits, no market → all three hidden) and
# Niazmand 872590 (deep+market present, traits null) —, the cycle-81
# team-fixtures section with its expand toggle + cycle-80 team-history on the
# reference clubs, lazy-API edges for the two newest endpoints
# (team-fixtures / team-history: valid + unknown + malformed + zero id), the
# cycle-79 header-search interactive flow and the core page sweep. 390x844,
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
  $B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,h1:(document.querySelector("h1")||{}).textContent||"",imgs:document.images.length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,deep:!!document.querySelector("[data-testid=player-deep-stats]"),deepRows:document.querySelectorAll("[data-testid=player-deep-stats] .grid > div").length,goldBars:document.querySelectorAll("[data-testid=player-deep-stats] .bg-gold\\/70").length,traits:!!document.querySelector("[data-testid=player-traits]"),traitRows:document.querySelectorAll("[data-testid=player-traits] li").length,market:!!document.querySelector("[data-testid=player-market]"),spark:!!document.querySelector("[data-testid=player-market] svg polyline"),hist:!!document.querySelector("[data-testid=team-history]"),fx:!!document.querySelector("[data-testid=team-fixtures]"),invalid:/شناسه بازیکن نامعتبر/.test(document.body.innerText)})'
  # interaction (team pages only): expand the fixtures «نمایش همه» toggle
  $B eval '(() => { const b=document.querySelector("[data-testid=team-fixtures] button"); if(!b) return "no-toggle"; const before=document.querySelectorAll("[data-testid=team-fixtures] a").length; b.click(); return new Promise(r=>setTimeout(()=>{ const after=document.querySelectorAll("[data-testid=team-fixtures] a").length; r(JSON.stringify({before,after,expanded:after>before})); },150)); })()'
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

# player depth sections: forward + goalkeeper + two degradation subjects
probe "http://localhost:3000/player/737066"
probe "http://localhost:3000/player/1185782"
probe "http://localhost:3000/player/872590"
probe "http://localhost:3000/player/1543604"
# player error paths
probe "http://localhost:3000/player/abc"
probe "http://localhost:3000/player/999999999"
# team pages: cycle-80 history + cycle-81 fixtures stack
probe "http://localhost:3000/team/9925"
probe "http://localhost:3000/team/9826"
# core sweep
probe "http://localhost:3000/"
probe "http://localhost:3000/league/pl"
probe "http://localhost:3000/topscorers"
probe "http://localhost:3000/news"
probe "http://localhost:3000/match/5749720"
probe "http://localhost:3000/league/notaleague"

# lazy endpoints: the two newest (team-fixtures, team-history) + player edges
api() {
  echo "== API $1 =="
  curl -s -m 40 -o /tmp/bh83.json -w "HTTP %{http_code} " "$1"
  python3 -c "
import json
try:
    d=json.load(open('/tmp/bh83.json'))
    ks=[k for k in d.keys() if k!='ok']
    vals={k:(len(d[k]) if isinstance(d[k],list) else ('null' if d[k] is None else type(d[k]).__name__)) for k in ks}
    print('ok:',d.get('ok'),'|',vals,'| err:',d.get('error',''))
except Exception as e:
    print('BADJSON:',e)
"
}
api "http://localhost:3000/api/team-fixtures/9925"
api "http://localhost:3000/api/team-fixtures/999999999"
api "http://localhost:3000/api/team-fixtures/abc"
api "http://localhost:3000/api/team-fixtures/0"
api "http://localhost:3000/api/team-history/9925"
api "http://localhost:3000/api/team-history/999999999"
api "http://localhost:3000/api/team-history/abc"
api "http://localhost:3000/api/player/1543604"
api "http://localhost:3000/api/player/abc"

# header-search interactive flow (cycle-79 fix regression): open panel,
# type سلتیک, expect the dropdown row, click it → /team/9925
echo "== SEARCH FLOW =="
$B errors --clear >/dev/null 2>&1
$B console --clear >/dev/null 2>&1
$B open "http://localhost:3000/" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B eval '(() => { const b=document.querySelector("[aria-label=\"جستجوی تیم\"]"); if(!b) return "no-toggle-btn"; b.click(); return "opened"; })()'
sleep 0.5
$B eval '(() => { const inp=document.querySelector("[role=dialog] input"); if(!inp) return "no-input"; const setter=Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype,"value").set; setter.call(inp,"سلتیک"); inp.dispatchEvent(new Event("input",{bubbles:true})); return "typed"; })()'
sleep 1.6
$B eval 'JSON.stringify({dialog:/سلتیک/.test((document.querySelector("[role=dialog]")||{}).innerText||""),scotland:/اسکاتلند/.test((document.querySelector("[role=dialog]")||{}).innerText||"")})'
$B eval '(() => { const rows=[...document.querySelectorAll("[role=dialog] button")].filter(b=>/سلتیک/.test(b.innerText)); if(!rows.length) return "no-result-row"; rows[0].click(); return "clicked"; })()'
sleep 2.2
$B eval 'JSON.stringify({path:location.pathname,h1:(document.querySelector("h1")||{}).textContent||""})'
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
