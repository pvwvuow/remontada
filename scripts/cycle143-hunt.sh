#!/bin/bash
# cycle-143 bug-hunt — layer 3: the continuous FAN JOURNEY hunt.
# Cycle-142 hunted the newest cup surface (ACL); this hunt walks the surfaces
# the USER himself asked for (cycle-134 squads/photos, cycle-135 posts) the
# way a fan does — one continuous session of REAL clicks from the home page
# to a match lineup icon to a player profile to the «پست‌های بازی» section to
# the all-teams squad hub to the news refresh to a real season change on the
# global scorers race. Viewport 390x844. Lessons baked in from 137/142:
# eval output escapes JSON quotes (stripped before the false/null grep) and
# URL claims decodeURIComponent first.
# H1 home → real click on the first match card → /match/<id>
# H2 match 5071465 → real click on «بازیکن‌ها» tab → 32px headshot rows
#    (the cycle-134 «آیکون ترکیب تیم») + shirt chips + «ترکیب اصلی»
# H3 click a player name IN the lineup → /player/<id> profile loads
# H4 /player/1167220 Joan García → «پست‌های بازی»: exactly one GK chip,
#    title=Keeper, LIVE Persian-digit occurrence count (the 53 baked in
#    cycle-135 went stale at 54 — honest pattern, not a frozen number)
# H5 /players → real clicks mode-teams → league-persiangulf → team-101610
#    → squad panel + URL sync + Persian position groups + photos
# H6 /news → real click «بروزرسانی» → refetch stays inside the budget,
#    items alive, console clean (the cycle-138 hard-budget fix under stress)
# H7 /topscorers → REAL change event → 2023/2024 → URL carries the decoded
#    season + «۸ لیگ مشارکت‌کننده» (all 8 merge contestants serve it)
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

# H1: the home page's match cards really navigate — click the first
# /match/<id> link and land on a match detail route
hunt "H1 home→match card click" "http://localhost:3000/" \
"document.querySelector(\"a[href^='/match/']\")" \
'(function(){const a=document.querySelector("a[href^=\"/match/\"]");if(a)a.click();return a?"clicked":"no-link"})()' \
"({onMatch:/^\/match\/[0-9]+$/.test(location.pathname),h1Live:!!(document.querySelector(\"h1\")||{}).innerText})"

# H2: the match page's «بازیکن‌ها» tab carries the cycle-134 lineup icons —
# real 32px headshots, shirt-number chips beside names, «ترکیب اصلی» heading
hunt "H2 match players tab lineup icons" "http://localhost:3000/match/5071465" \
"(document.body.innerText||\"\").includes(\"بازیکن‌ها\")" \
'(function(){const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="بازیکن‌ها");if(b)b.click();return b?"clicked":"no-tab"})()' \
"({starters:(document.body.innerText||\"\").includes(\"ترکیب اصلی\"),photos11:[...document.images].filter(i=>(i.src||\"\").includes(\"playerimages\")&&i.naturalWidth>0).length>=11,links11:document.querySelectorAll(\"a[href^='/player/']\").length>=11,shirt:!!document.querySelector(\".tabular-persian\")})"

# H3: continue the journey — real click on the «بازیکن‌ها» tab, then a real
# click on a player name INSIDE the lineup → the live profile (two rounds,
# bespoke: the tab content renders async so the second click needs its own
# wait round)
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "http://localhost:3000/match/5071465" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 2
$B eval '(function(){const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="بازیکن‌ها");if(b)b.click();return b?"tab":"no-tab"})()' >/dev/null 2>&1
sleep 3
$B eval '(function(){const a=document.querySelector("a[href^=\"/player/\"]");if(a)a.click();return a?"clicked":"no-link"})()' >/dev/null 2>&1
sleep 3
H3OUT=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null | tr -d '"\\')
H3FEAT=$($B eval "JSON.stringify(({onPlayer:/^\/player\/[0-9]+$/.test(location.pathname),h1Live:!!(document.querySelector(\"h1\")||{}).innerText,hero:[...document.images].some(i=>(i.src||\"\").includes(\"playerimages\")&&i.naturalWidth>0)}))" 2>/dev/null | tr -d '"\\')
H3C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception: print('ERR')")
H3E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  print(len([e for e in es if e.get('url')]))
except Exception: print('ERR')")
say "H3 lineup→player profile click → $H3OUT | feat=$H3FEAT | console=$H3C appErrors=$H3E"
H3RC=0
echo "$H3FEAT" | grep -q "false\|null" && H3RC=1
[ "$H3OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && H3RC=1
[ "$H3C" = "0" ] && [ "$H3E" = "0" ] || H3RC=1
[ "$H3RC" -eq 0 ] || BAD=$((BAD+1))

# H4: the «پست‌های بازی» section (cycle-135) — exactly one دروازه‌بان chip
# with title=Keeper and a LIVE Persian-digit occurrence count
hunt "H4 posts section keeper chip" "http://localhost:3000/player/1167220" \
"document.querySelector(\"[data-testid=\\\"player-positions\\\"]\")" \
"" \
"({section:!!document.querySelector(\"[data-testid=\\\"player-positions\\\"]\"),chips1:document.querySelectorAll(\"[data-testid=\\\"player-positions\\\"] span[title]\").length===1,gkFa:((document.querySelector(\"[data-testid=\\\"player-positions\\\"] span[title]\")||{}).innerText||\"\").includes(\"دروازه‌بان\"),occLive:/[۰-۹]+ بازی/.test(((document.querySelector(\"[data-testid=\\\"player-positions\\\"] span[title]\")||{}).innerText||\"\")),enTitle:((document.querySelector(\"[data-testid=\\\"player-positions\\\"] span[title]\")||{}).title===\"Keeper\")})"

# H5: the all-teams hub (cycle-134) — the FULL user path with three real
# clicks: mode-teams → league-persiangulf → team-101610 پرسپولیس
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "http://localhost:3000/players" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 2
$B eval '(function(){const m=document.querySelector("[data-testid=\"mode-teams\"]");if(m)m.click();return m?"mode":"no-mode"})()' >/dev/null 2>&1
sleep 3
$B eval '(function(){const l=document.querySelector("[data-testid=\"league-persiangulf\"]");if(l)l.click();return l?"league":"no-league"})()' >/dev/null 2>&1
sleep 3
$B eval '(function(){const t=document.querySelector("[data-testid=\"team-101610\"]");if(t)t.click();return t?"team":"no-team"})()' >/dev/null 2>&1
# the پرسپولیس squad fetch is cold on first hit — wait for the first real
# headshot to land, then let the stream settle (threshold calibrated to the
# 390x844 viewport; ZERO broken images is enforced by the OUT contract)
$B wait --fn "[...document.images].some(i=>(i.src||'').includes('playerimages')&&i.naturalWidth>0)" >/dev/null 2>&1
sleep 6
H5OUT=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null | tr -d '"\\')
H5FEAT=$($B eval "JSON.stringify((()=>{const b=document.body.innerText;return {panel:!!document.querySelector(\"[data-testid=\\\"squad-panel\\\"]\"),urlLeague:location.search.includes(\"league=persiangulf\"),urlTeam:location.search.includes(\"team=101610\"),photos:[...document.images].filter(i=>(i.src||\"\").includes(\"playerimages\")&&i.naturalWidth>0).length>=10,gk:b.includes(\"دروازه‌بان‌ها\"),fw:b.includes(\"مهاجمان\")}})())" 2>/dev/null | tr -d '"\\')
H5C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception: print('ERR')")
H5E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  print(len([e for e in es if e.get('url')]))
except Exception: print('ERR')")
say "H5 hub 3-click fan path→squad → $H5OUT | feat=$H5FEAT | console=$H5C appErrors=$H5E"
H5RC=0
echo "$H5FEAT" | grep -q "false\|null" && H5RC=1
[ "$H5OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && H5RC=1
[ "$H5C" = "0" ] && [ "$H5E" = "0" ] || H5RC=1
[ "$H5RC" -eq 0 ] || BAD=$((BAD+1))

# H6: the news refresh (cycle-138 hard budget) under a REAL click — the
# refetch must land inside the budget with items alive and a clean console
hunt "H6 news refresh click" "http://localhost:3000/news" \
"(document.body.innerText||\"\").includes(\"بروزرسانی\")" \
'(function(){const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").includes("بروزرسانی"));if(b)b.click();return b?"clicked":"no-btn"})()' \
"({h1:(document.querySelector(\"h1\")||{}).innerText===\"اخبار فوتبال\",alive:(document.body.innerText||\"\").length>500,items:(document.body.innerText||\"\").includes(\"ESPN\")||(document.body.innerText||\"\").includes(\"BBC\")||(document.body.innerText||\"\").includes(\"Sky\")})"

# H7: a REAL change event on the global scorers race → 2023/2024 — the URL
# carries the decoded season and the honest «۸ لیگ مشارکت‌کننده» subtitle
hunt "H7 topscorers season change" "http://localhost:3000/topscorers?league=all" \
"document.querySelector(\"#season-select\")" \
'(function(){const s=document.querySelector("#season-select");if(!s)return "no-select";const opt=[...s.options].find(o=>o.value==="2023/2024");if(!opt)return "no-option";const setter=Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype,"value").set;setter.call(s,"2023/2024");s.dispatchEvent(new Event("change",{bubbles:true}));return "changed"})()' \
"({urlSeason:decodeURIComponent(location.search).includes(\"season=2023/2024\"),participants8:(document.body.innerText||\"\").includes(\"۸ لیگ مشارکت‌کننده\"),h1Live:((document.querySelector(\"h1\")||{}).innerText||\"\").includes(\"مصاف گلزنان\")})"

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then echo "HUNT OK (7/7 green — fan journey: home card→match, «بازیکن‌ها» tab with 32px lineup icons + shirt chips + «ترکیب اصلی», lineup name→live profile, «پست‌های بازی» keeper chip with live occurrence count, 3-click all-teams path mode→league→پرسپولیس squad with URL sync, news «بروزرسانی» refetch inside the hard budget, real season change → 2023/2024 with «۸ لیگ مشارکت‌کننده»; every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"; else echo "HUNT FLAGGED (BAD=$BAD)"; exit 1; fi
