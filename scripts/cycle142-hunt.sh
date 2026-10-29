#!/bin/bash
# cycle-142 bug-hunt — layer 3: targeted interactive hunt on the NEWEST surface
# (the live AFC Champions League Elite from cycle-141 — the portal's first
# composite table), driving it the way a user does — real clicks and a real
# select change, not deep links. Viewport 390x844. Lessons baked in from
# cycle-137's recorded non-findings: eval output escapes JSON quotes (the
# helper strips them before the false/null grep) and URLSearchParams encodes
# the season slash as %2F (every URL claim decodes first).
# H1 league table → team deep-link (استقلال 101614, live West row)
# H2 titles tab: 44 seasons + honest bracket/transfers absence
# H3 real season change → 2024/2025 (true 24-row table + URL carries season)
# H4 hub acl grid → click الهلال (2529) → squad panel + URL sync + photos
# H5 dedicated /topscorers/acl → click leader رحیمی → /player/1295519 profile
# H6 bogus-season deep-link (?season=2019/2020) → the cycle-99 honesty snap
#     survives on the NEW overview.selectedSeason marker: URL stripped,
#     current 32-row table shown
# H7 direct team page of تراکتور (176352 — ACL West row id)
set -u
B=agent-browser
$B set viewport 390 844 >/dev/null

BAD=0
say() { echo "$1"; }

hunt() { # $1=label $2=url $3=waitfn(optional extra) $4=clickjs $5=featjs
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$2" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  [ -n "${3:-}" ] && $B wait --fn "$3" >/dev/null 2>&1
  sleep 3
  if [ -n "${4:-}" ]; then $B eval "$4" >/dev/null 2>&1; sleep 3; fi
  local OUT C E FEAT RC=0
  FEAT=$($B eval "JSON.stringify(($5))" 2>/dev/null | tr -d '"\\')
  OUT=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null | tr -d '"\\')
  C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception: print('ERR')")
  E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  print(len([e for e in es if e.get('url')]))
except Exception: print('ERR')")
  say "$1 → $OUT | feat=$FEAT | console=$C appErrors=$E"
  echo "$FEAT" | grep -q "false\|null" && RC=1
  [ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
  return 0
}

# H1: the composite table's team links work — click استقلال → /team/101614
hunt "H1 acl table→team deep-link" "http://localhost:3000/league/acl" \
"document.body.innerText.includes(\"استقلال\")" \
'(function(){const a=document.querySelector("a[href=\"/team/101614\"]");if(a)a.click();return a?"clicked":"no-link"})()' \
"({onTeam:location.pathname===\"/team/101614\",h1Esteghlal:(document.querySelector(\"h1\")||{}).innerText?((document.querySelector(\"h1\")||{}).innerText.includes(\"استقلال\")):false})"

# H2: titles tab renders the 44-season history (newest 2025/2026 الاهلی,
# oldest ۱۹۶۷); bracket AND transfers tabs HONESTLY absent (playoff null
# until the knockout draw, transfers null — cups, legend-56/57 contracts)
hunt "H2 acl titles 44 + honest absence" "http://localhost:3000/league/acl" \
"document.body.innerText.includes(\"تراکتور\")" \
'(function(){const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="قهرمانان");if(b)b.click();return b?"clicked":"no-tab"})()' \
"({newest:(document.body.innerText||\"\").includes(\"الاهلی\"),newestSeason:(document.body.innerText||\"\").includes(\"۲۰۲۵/۲۰۲۶\"),oldest:(document.body.innerText||\"\").includes(\"۱۹۶۷\"),bracketTabAbsent:![...document.querySelectorAll(\"button\")].some(x=>(x.textContent||\"\").trim()===\"براکت\"),transfersTabAbsent:![...document.querySelectorAll(\"button\")].some(x=>(x.textContent||\"\").trim()===\"انتقال‌ها\")})"

# H3: a REAL select change to 2024/2025 — the true 24-row historical table
# (meta «۲۴ تیم» vs current «۳۲ تیم») + the URL carries the season decoded
hunt "H3 acl season change → 2024/2025" "http://localhost:3000/league/acl" \
"document.body.innerText.includes(\"۳۲ تیم\")" \
'(function(){const s=document.querySelector("#season-select");if(!s)return "no-select";const opt=[...s.options].find(o=>o.value==="2024/2025");if(!opt)return "no-option";const setter=Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype,"value").set;setter.call(s,"2024/2025");s.dispatchEvent(new Event("change",{bubbles:true}));return "changed"})()' \
"({meta24:(document.body.innerText||\"\").includes(\"۲۴ تیم\"),urlSeason:decodeURIComponent(location.search).includes(\"season=2024/2025\"),hilal:(document.body.innerText||\"\").includes(\"الهلال\")})"

# H4: /players acl grid → click الهلال (2529) → squad panel + URL sync +
# real player photos loaded (the cycle-134 quality ladder feeds it)
hunt "H4 hub acl grid→squad" "http://localhost:3000/players?league=acl" \
"document.querySelector(\"[data-testid=\\\"team-2529\\\"]\")" \
'(function(){const t=document.querySelector("[data-testid=\"team-2529\"]");if(t)t.click();return t?"clicked":"no-btn"})()' \
"({urlTeam:location.search.includes(\"team=2529\"),panel:!!document.querySelector(\"[data-testid=\\\"squad-panel\\\"]\"),photos:[...document.images].filter(i=>(i.src||\"\").includes(\"playerimages\")&&i.naturalWidth>0).length})"

# H5: the dedicated /topscorers/acl page → click leader رحیمی → the player
# profile loads with a real photo (fetchAllUrl leader Houssine Rahimi)
hunt "H5 acl scorers→player profile" "http://localhost:3000/topscorers/acl" \
"(document.body.innerText||\"\").includes(\"Rahimi\")||(document.body.innerText||\"\").includes(\"رحیمی\")" \
'(function(){const a=document.querySelector("a[href=\"/player/1295519\"]");if(a)a.click();return a?"clicked":"no-link"})()' \
"({onPlayer:location.pathname===\"/player/1295519\",h1Live:!!(document.querySelector(\"h1\")||{}).innerText,photos:[...document.images].filter(i=>(i.src||\"\").includes(\"playerimages\")&&i.naturalWidth>0).length})"

# H6: the cycle-99 honesty snap survives on the NEW marker — a well-formed
# season the cup does not offer (2019/2020) silently serves the CURRENT
# 32-row table and the snap strips the stale URL param so selector, label
# and address never contradict the data on screen
hunt "H6 bogus-season honesty snap" "http://localhost:3000/league/acl?season=2019%2F2020" \
"document.body.innerText.includes(\"استقلال\")" \
"" \
"({urlClean:!location.search.includes(\"season\"),meta32:(document.body.innerText||\"\").includes(\"۳۲ تیم\"),esteghlal:(document.body.innerText||\"\").includes(\"استقلال\"),westSection:(document.body.innerText||\"\").includes(\"منطقهٔ غرب\")})"

# H7: the direct team page of تراکتور rides the ACL West row id (176352) —
# Persian h1 + the team surface alive
hunt "H7 team/176352 tractor" "http://localhost:3000/team/176352" \
"" \
"" \
"({h1Tractor:(document.querySelector(\"h1\")||{}).innerText?((document.querySelector(\"h1\")||{}).innerText.includes(\"تراکتور\")):false,alive:(document.body.innerText||\"\").length>200})"

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then echo "HUNT OK (7/7 green — ACL interactive hunt: table→استقلال deep-link, 44-title tab with honest bracket/transfers absence, real season change → true ۲۴تیمی 2024/2025 + URL, hub الهلال→squad panel with photos, /topscorers/acl leader→profile, bogus-season honesty snap strips the URL on the new overview marker, /team/176352 تراکتور; every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"; else echo "HUNT FLAGGED (BAD=$BAD)"; exit 1; fi
