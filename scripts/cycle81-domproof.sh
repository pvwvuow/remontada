#!/bin/bash
# Cycle-81 DOM proof: the new «همهٔ بازی‌های فصل» section (team-fixtures) on
# the three reference clubs at 390x844 — presence, default-collapsed groups
# (6+6 rows), the «نمایش همه» expand interaction, overflow / h1 / broken-img
# hygiene, console + app errors clean. Console/errors cleared before probes.
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
  $B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,h1:(document.querySelector("h1")||{}).textContent||"",vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,fx:!!document.querySelector("[data-testid=team-fixtures]"),rowsBefore:document.querySelectorAll("[data-testid=team-fixtures] a").length,toggle:(document.querySelector("[data-testid=team-fixtures] button")||{}).textContent||""})'
  # interaction: click the first «نمایش همه» toggle, count rows again
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

probe "http://localhost:3000/team/9925"
probe "http://localhost:3000/team/9826"
probe "http://localhost:3000/team/8456"
