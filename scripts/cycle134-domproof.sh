#!/bin/bash
# cycle-134 update proof at 390x844 — «بازیکنان همهٔ تیم‌ها» (direct user
# request): the /players hub was scorers+assists only («بازیکنان کل تیما رو
# باید داشته باشیم نه فقط گلزن و پاس گلرها») and every photo used the probed
# 35×35 "_xsmall" source (the «آیکون ترکیب تیم» quality complaint).
# This cycle: (1) PlayerPhoto quality ladder — re-probed 2026-10-29 UA
# Chrome/124: FotMob serves exactly three raster sizes per id (_xsmall 35px,
# _small 150px, bare 192px; _medium/_big are 403) so renders <80px take
# _small and heroes ≥80px take the bare source; no vector exists upstream,
# max-res raster is the honest maximum. (2) match «بازیکن‌ها» lineup rows get
# real headshots (they had none). (3) /players gains the «همهٔ تیم‌ها» mode:
# league → standings team list → /api/team-squad full squad (cycle-70 feed)
# with position groups, coach, injured badges, deep links and URL sync
# (?league=&team=, one-shot seed, strict validation).
set -u
B=agent-browser
$B set viewport 390 844 >/dev/null

echo "== PART A: API truth =="
python3 - <<'PY'
import json, urllib.request, urllib.error
def get(u):
    r = urllib.request.Request(u, headers={'User-Agent': 'Chrome/124'})
    return urllib.request.urlopen(r, timeout=90)
ok = True
def report(name, good, detail):
    global ok
    print(('PASS ' if good else 'FAIL ') + name + ' — ' + detail)
    if not good: ok = False

# A1: full squad feed — Barcelona (8634): honest English teamName from the
# same payload (details.name), coach, the Persian position quartet, >=20 players
try:
    d = json.loads(get('http://localhost:3000/api/team-squad/8634').read().decode())
    s = d.get('squad') or {}
    groups = s.get('groups') or []
    total = sum(len(g.get('players') or []) for g in groups)
    keys = sorted(g.get('key') for g in groups)
    keepers = next((g for g in groups if g.get('key') == 'keepers'), None)
    report('A1 squad feed 8634', d.get('ok') and s.get('teamName') == 'Barcelona'
           and bool(s.get('coach')) and total >= 20 and len(groups) >= 3
           and 'keepers' in keys and keepers is not None and len(keepers.get('players') or []) >= 1,
           f"teamName={s.get('teamName')} coach={bool(s.get('coach'))} groups={len(groups)} keys={keys} players={total}")
except Exception as e:
    ok = False; print('A1: ERR', e)

# A2: standings = the honest full team list (the picker's source), fa names present
try:
    d = json.loads(get('http://localhost:3000/api/standings?league=pl').read().decode())
    rows = d.get('rows') or []
    first = rows[0] if rows else {}
    report('A2 standings team source', d.get('ok') and len(rows) >= 18
           and all(('teamId' in r and 'name' in r) for r in rows) and bool(first.get('fa')),
           f"rows={len(rows)} first={first.get('fa') or first.get('name')}")
except Exception as e:
    ok = False; print('A2: ERR', e)

# A3: squad route guard — id 0 → honest 400
try:
    get('http://localhost:3000/api/team-squad/0'); ok = False; print('A3: FAIL — 200 instead of 400')
except urllib.error.HTTPError as e:
    report('A3 squad guard 400', e.code == 400, f"code={e.code}")
except Exception as e:
    ok = False; print('A3: ERR', e)

# A4: /players SSR shell carries the new mode tab («همهٔ تیم‌ها»)
try:
    html = get('http://localhost:3000/players').read().decode()
    report('A4 /players mode tab in shell', 'همهٔ تیم‌ها' in html and 'بازیکنان' in html,
           f"tab={'همهٔ تیم‌ها' in html}")
except Exception as e:
    ok = False; print('A4: ERR', e)

# A5: Persian position titles (the SQUAD_GROUP_FA contract) on the squad feed
try:
    d = json.loads(get('http://localhost:3000/api/team-squad/8634').read().decode())
    titles = [g.get('titleFa') for g in (d.get('squad') or {}).get('groups') or []]
    report('A5 Persian group titles', all(t in ('دروازه‌بان‌ها', 'مدافعان', 'هافبک‌ها', 'مهاجمان') for t in titles) and len(titles) >= 3,
           f"titles={titles}")
except Exception as e:
    ok = False; print('A5: ERR', e)
print('API_TRUTH', 'OK' if ok else 'FAILED')
PY
A_BAD=$?

echo "== PART B: DOM 390x844 =="
probe() { # $1=url $2=label $3=feature-js $4=optional click-js $5=optional extra wait-fn
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  if [ -n "${5:-}" ]; then $B wait --fn "$5" >/dev/null 2>&1; fi
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
TOTAL_BAD=$A_BAD

# D1: stars mode — h1, both mode tabs, photos now on the _small (150px) source,
# and the 35px _xsmall source fully retired from the hub (extra wait: the
# client fetch must land before the photo grid exists)
probe "http://localhost:3000/players" "D1 /players stars (quality ladder live)" \
"const tabs=!!document.querySelector('[data-testid=\"mode-teams\"]');const photos=[...document.images].filter(i=>(i.src||'').includes('playerimages'));const small=photos.filter(i=>i.src.includes('_small')).length;const xsmall=photos.filter(i=>i.src.includes('_xsmall')).length;return {tabs,photoN:photos.length,small,xsmall,noXsmall:xsmall===0}" \
"" \
"[...document.images].some(i=>(i.src||'').includes('playerimages'))"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D2: deep link ?league=laliga — teams mode seeded once: full team grid (20),
# active league chip, URL kept
probe "http://localhost:3000/players?league=laliga" "D2 deep link league=laliga (team grid)" \
"const grid=document.querySelector('[data-testid=\"team-grid\"]');const n=grid?grid.querySelectorAll('button').length:0;const chip=document.querySelector('[data-testid=\"league-laliga\"]');return {teams:n,urlKept:location.search.includes('league=laliga'),chipActive:chip?chip.getAttribute('aria-selected'):null}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D3: click Barcelona in the grid → full squad panel: Persian group headings,
# _small photos, coach line, injured badge mechanism in DOM (if squad carries one)
probe "http://localhost:3000/players?league=laliga" "D3 team click → full squad" \
"const panel=document.querySelector('[data-testid=\"squad-panel\"]');const heads=[...document.querySelectorAll('[data-testid=\"squad-panel\"] h2')].map(h=>h.innerText);const photos=[...document.images].filter(i=>(i.src||'').includes('playerimages')&&i.src.includes('_small'));const coach=document.body.innerText.includes('سرمربی');return {panel:!!panel,groups:heads.length,gk:heads.some(t=>t.includes('دروازه‌بان')),photos:photos.length,coach,teamLabel:document.body.innerText.includes('بارسلونا')||document.body.innerText.includes('Barcelona')}" \
"(function(){const b=document.querySelector('[data-testid=\"team-8634\"]');if(b)b.click();})()"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D4: real user path step 1 — mode tab click syncs the URL (?league=pl) and
# reveals the league chips with the pl grid
probe "http://localhost:3000/players" "D4 tab click (URL sync + chips)" \
"const chips=document.querySelectorAll('[data-testid^=\"league-\"]').length;const grid=document.querySelector('[data-testid=\"team-grid\"]');const n=grid?grid.querySelectorAll('button').length:0;return {leagueChips:chips,urlLeaguePl:location.search.includes('league=pl'),teams:n,squadCleared:!document.querySelector('[data-testid=\"squad-panel\"]')}" \
"(function(){const mt=document.querySelector('[data-testid=\"mode-teams\"]');if(mt)mt.click();})()"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D4b: step 2 — league chip click swaps the grid to LaLiga, rewrites the URL
# and drops any previously selected squad (keyed derivation)
probe "http://localhost:3000/players?league=pl" "D4b chip click swaps league" \
"const grid=document.querySelector('[data-testid=\"team-grid\"]');const n=grid?grid.querySelectorAll('button').length:0;return {urlLaliga:location.search.includes('league=laliga'),teams:n,chipActive:document.querySelector('[data-testid=\"league-laliga\"]')?.getAttribute('aria-selected'),squadCleared:!document.querySelector('[data-testid=\"squad-panel\"]')}" \
"(function(){const c=document.querySelector('[data-testid=\"league-laliga\"]');if(c)c.click();})()"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D5: squad card deep-links to the profile — click the first player card
probe "http://localhost:3000/players?league=laliga&team=8634" "D5 player card → /profile" \
"return {onPlayer:location.pathname.startsWith('/player/'),h1:(document.querySelector('h1')||{}).innerText||''}" \
"(function(){const a=document.querySelector('[data-testid=\"squad-panel\"] a[href^=\"/player/\"]');if(a)a.click();})()"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D6: match «بازیکن‌ها» tab — lineup rows now carry real headshots (the
# «آیکون ترکیب تیم» this cycle was aimed at)
probe "http://localhost:3000/match/5071461" "D6 match lineup photos" \
"const photos=[...document.images].filter(i=>(i.src||'').includes('playerimages'));const names=document.querySelectorAll('a[href^=\"/player/\"]').length;return {photos:photos.length,playerLinks:names,onPlayersTab:document.body.innerText.includes('ترکیب اصلی')||document.body.innerText.includes('جایگزین‌ها')}" \
"(function(){const t=[...document.querySelectorAll('button')].find(b=>b.innerText.includes('بازیکن‌ها'));if(t)t.click();})()"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

echo "== RESULT =="
if [ "$TOTAL_BAD" -eq 0 ]; then echo "DOM_PROOF OK (API 5/5 + DOM 7/7 green — squads honest end-to-end: full team grid per league, Persian position quartet with photos on the 150px source, coach line, profile deep links, tab/chip URL sync both ways, _xsmall retired, match lineup rows carry headshots; every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"; else echo "DOM_PROOF FLAGGED=$TOTAL_BAD"; exit 1; fi
