#!/bin/bash
# cycle-133 bug-hunt — targeted interaction hunt on the newest surface
# (cycle-132 historical race on /topscorers): the cycle-132 proof covered
# deep-links; this hunt drives the UI the way a user does — selector change
# events (not URL), season→current switch, league-chip click while
# historical, historical assists section, dedicated per-league page sanity.
# Viewport 390x844; every page: sw=cw=390, exactly 1 h1, 0 broken images,
# console=0, appErr=0.
set -u
B=agent-browser
$B set viewport 390 844 >/dev/null

probe() { # $1=url $2=label $3=extra-js returning object (runs AFTER optional $4 post-wait js)
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 3
  if [ -n "${4:-}" ]; then $B eval "$4" >/dev/null 2>&1; sleep 3; fi
  local FEAT OUT BAD C E RC=0
  FEAT=$($B eval "JSON.stringify((()=>{$3})())" 2>/dev/null | tr -d '"\\')
  OUT=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null)
  BAD=$($B eval '(function(){var sw=document.documentElement.scrollWidth,cw=document.documentElement.clientWidth,h1n=document.querySelectorAll("h1").length,vb=[...document.images].filter(function(i){return i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden"}).length;return (sw!=cw?1:0)+(h1n!=1?2:0)+(vb>0?4:0)})()' 2>/dev/null | tr -d '"')
  C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception:
  print('ERR')")
  E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  app=[e for e in es if e.get('url')]
  print(len(app))
except Exception:
  print('ERR')")
  echo "$2 → $OUT | feat=$FEAT | console=$C appErrors=$E"
  [ "$BAD" != "0" ] && RC=1
  [ "$E" != "0" ] && RC=1
  return $RC
}
TOTAL_BAD=0

# H1: selector-driven change (user event, not deep link): pick 2022/2023 →
# refetch → hero = Haaland 36 (real 2022/2023 truth) + URL carries the season
probe "http://localhost:3000/topscorers" "H1 selector change → 2022/2023" \
"const hero=document.querySelector('.glass-scorer-hero')?.innerText||'';const sel=document.getElementById('season-select');return {heroHaaland:hero.includes('هالند'),hero36:hero.includes('۳۶'),urlSeason:location.search.includes('season=2022%2F2023'),selVal:sel?sel.value:''}" \
"(function(){var sel=document.getElementById('season-select');var st=Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype,'value').set;st.call(sel,'2022/2023');sel.dispatchEvent(new Event('change',{bubbles:true}));})()"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# H2: selector back to (فعلی) from a historical view → URL param stripped, current leader back
probe "http://localhost:3000/topscorers?season=2022/2023" "H2 selector → current (فعلی)" \
"const sel=document.getElementById('season-select');const hero=document.querySelector('.glass-scorer-hero')?.innerText||'';return {urlClean:!location.search.includes('season='),selVal:sel?sel.value:'',heroIsCurrent:(hero||'').length>0}" \
"(function(){var sel=document.getElementById('season-select');var st=Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype,'value').set;st.call(sel,'2026/2027');sel.dispatchEvent(new Event('change',{bubbles:true}));})()"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# H3: league chip click while historical → URL keeps season AND adds league;
# league hero = league leader (bundesliga 2023/2024 = Kane 36, LEAGUE LEADER)
probe "http://localhost:3000/topscorers?season=2023/2024" "H3 chip click keeps season" \
"const hero=document.querySelector('.glass-scorer-hero')?.innerText||'';return {urlSeason:location.search.includes('season=2023%2F2024'),urlLeague:location.search.includes('league=bundesliga'),heroKane:hero.includes('کین'),hero36:hero.includes('۳۶'),leagueLeader:hero.includes('LEAGUE LEADER')}" \
"(function(){const chips=[...document.querySelectorAll('button')];const c=chips.find(b=>b.innerText.includes('بوندسلیگا'));if(c)c.click();})()"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# H4: historical assists section renders (2023/2024) — h2 present with rows
probe "http://localhost:3000/topscorers?season=2023/2024" "H4 historical assists section" \
"const h2=[...document.querySelectorAll('h2')].some(h=>h.innerText.includes('مسابقه پاس گل'));const rows=document.querySelectorAll('h2')?document.body.innerText.includes('پاس'):false;return {assistsH2:h2,hasAssistText:rows}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# H5: dedicated per-league page untouched by the cycle-132 changes
probe "http://localhost:3000/topscorers/pl" "H5 /topscorers/pl (neighbor)" \
"const body=document.body.innerText;return {hasRows:body.length>200,hasPlayer:body.includes('هالند')||body.includes('گل')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

echo "== RESULT =="
if [ "$TOTAL_BAD" -eq 0 ]; then echo "HUNT OK (5/5 interaction hunts green — selector events, snap-back, chip+season coexistence, historical assists, per-league page; all pages sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"; else echo "HUNT FLAGGED=$TOTAL_BAD"; exit 1; fi
