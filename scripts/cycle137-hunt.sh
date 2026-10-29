#!/bin/bash
# cycle-137 bug-hunt — layer 3: targeted interactive hunt on the NEWEST surface
# (the live Persian Gulf league from cycle-136), driving it the way a user does
# — real clicks and a real select change, not deep links. Viewport 390x844.
# H1 league table → team deep-link (Persepolis)   H2 transfers tab (Munir)
# H3 titles tab + honest bracket absence          H4 hub team → squad panel
# H5 global race → real season change → «۶ لیگ مشارکت‌کننده»
# H6 league chip + dedicated /topscorers/persiangulf page (first time live!)
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

# H1: the league table's team links work — click پرسپولیس → /team/101610
hunt "H1 table→team deep-link" "http://localhost:3000/league/persiangulf" \
"" \
'(function(){const a=document.querySelector("a[href=\"/team/101610\"]");if(a)a.click();return a?"clicked":"no-link"})()' \
"({onTeam:location.pathname===\"/team/101610\",h1:(document.querySelector(\"h1\")||{}).innerText||\"\"})"

# H2: transfers tab renders the real entries with Persian club names
hunt "H2 transfers tab" "http://localhost:3000/league/persiangulf" \
"" \
'(function(){const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="انتقال‌ها");if(b)b.click();return b?"clicked":"no-tab"})()' \
"({munir:(document.body.innerText||\"\").includes(\"Munir El Haddadi\"),from:(document.body.innerText||\"\").includes(\"استقلال\"),to:(document.body.innerText||\"\").includes(\"آلباسته\")})"

# H3: titles tab renders the 24-season history; the bracket tab is HONESTLY
# absent (playoff null → hidden, legend-56 contract)
hunt "H3 titles tab + bracket absence" "http://localhost:3000/league/persiangulf" \
"" \
'(function(){const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="قهرمانان");if(b)b.click();return b?"clicked":"no-tab"})()' \
"({newest:(document.body.innerText||\"\").includes(\"۲۰۲۴/۲۰۲۵\"),tractor:(document.body.innerText||\"\").includes(\"تراکتور\"),oldest:(document.body.innerText||\"\").includes(\"۲۰۰۱/۲۰۰۲\"),bracketTabAbsent:![...document.querySelectorAll(\"button\")].some(x=>(x.textContent||\"\").trim()===\"براکت\")})"

# H4: /players all-teams mode → click پرسپولیس → squad panel + URL sync
hunt "H4 hub team→squad" "http://localhost:3000/players?league=persiangulf" \
"document.querySelector(\"[data-testid=\\\"team-101610\\\"]\")" \
'(function(){const t=document.querySelector("[data-testid=\"team-101610\"]");if(t)t.click();return t?"clicked":"no-btn"})()' \
"({urlTeam:location.search.includes(\"team=101610\"),panel:!!document.querySelector(\"[data-testid=\\\"squad-panel\\\"]\"),photos:[...document.images].filter(i=>(i.src||\"\").includes(\"playerimages\")&&i.naturalWidth>0).length})"

# H5: the global race — a REAL select change to the historical season; PGPL
# participates (6 participating leagues: UCL historical still drops honestly)
hunt "H5 global historical 6 leagues" "http://localhost:3000/topscorers?league=all" \
"" \
'(function(){const s=document.querySelector("select");if(!s)return "no-select";const opt=[...s.options].find(o=>o.value==="2023/2024");if(!opt)return "no-option";const setter=Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype,"value").set;setter.call(s,"2023/2024");s.dispatchEvent(new Event("change",{bubbles:true}));return "changed"})()' \
"({urlSeason:decodeURIComponent(location.search).includes(\"season=2023/2024\"),sixLeagues:(document.body.innerText||\"\").includes(\"۶ لیگ مشارکت‌کننده\")})" 

# H6: same historical view → click the خلیج فارس chip (URL keeps BOTH) → the
# hero flips to LEAGUE LEADER → follow the dedicated page link (NEW live page)
hunt "H6 pgpl chip + dedicated page" "http://localhost:3000/topscorers?league=all&season=2023/2024" \
"(document.body.innerText||\"\").includes(\"۶ لیگ مشارکت‌کننده\")" \
'(function(){const c=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").includes("خلیج فارس"));if(c)c.click();return c?"clicked":"no-chip"})()' \
"({urlBoth:(()=>{const q=decodeURIComponent(location.search);return q.includes(\"league=persiangulf\")&&q.includes(\"season=2023/2024\")})(),leader:(document.body.innerText||\"\").includes(\"LEAGUE LEADER\"),dedicated:(document.body.innerText||\"\").includes(\"صفحه اختصاصی گلزنان\")})"

echo "== H6b: dedicated /topscorers/persiangulf (first season it is live) =="
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "http://localhost:3000/topscorers/persiangulf" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3
FEAT=$($B eval 'JSON.stringify((()=>{const h1=(document.querySelector("h1")||{}).innerText||"";const rows=document.querySelectorAll("[class*=\"row\"], [data-testid=\"scorer-row\"]").length;return {h1Aghayan:h1.includes("آقای گلان"),pgplFa:h1.includes("خلیج فارس"),rows15:rows>=15,persianRows:(document.body.innerText||"").includes("حسین‌زاده")||(document.body.innerText||"").includes("پرسپولیس")}})())' 2>/dev/null | tr -d '"\\')
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
echo "H6b dedicated page → $OUT | feat=$FEAT | console=$C appErrors=$E"
echo "$FEAT" | grep -q "h1Aghayan:true" || BAD=$((BAD+1))
echo "$FEAT" | grep -q "rows15:true" || BAD=$((BAD+1))
[ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && BAD=$((BAD+1))
[ "$C" = "0" ] && [ "$E" = "0" ] || BAD=$((BAD+1))

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "CYCLE137 HUNT OK (7/7 green — the newest surface survives real user behavior: table deep-link, transfers/titles tabs with honest bracket absence, hub squad flow with URL sync, real season-change keeping the 6-league truth, league chip URL coexistence, and the dedicated /topscorers/persiangulf page live for the first time; every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"
else
  echo "CYCLE137 HUNT FLAGGED=$BAD"; exit 1
fi
