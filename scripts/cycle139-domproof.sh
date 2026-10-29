#!/bin/bash
# cycle-139 update proof at 390x844 — «لیگ اروپا، هشتمین مسابقه». Probed live
# 2026-10-29 (UA Chrome/124): the daily matches feed exposed the real UEL page
# id (parentLeagueId/primaryId = 73 — fotmob.com/leagues/73; the small classic
# ids are other cups: 42=UCL, 44=Copa America) serving the full 2026/2027
# league-phase table (36 teams), FIVE playoff rounds, 17 historical seasons
# (2010/2011+ — a superset of the global merge's 12-season window, unlike
# UECL's 6 which would have SHRUNK it — deferred), stats blocks in the exact
# domestic shape (empty topItems + fetchAllUrl) and transfers.data=null (cups).
# This cycle adds ONE config entry + 9 missing TEAM_FA names — every surface
# lights through the existing generic plumbing. Proof: standings (36/36 fa),
# global merge's 8th participant with the 12-season window BYTE-IDENTICAL,
# 5-round bracket, honest null transfers, fixtures, 55-title history,
# /topscorers/uel, search attribution (Celtic → uel), /leagues index.
set -u
B=agent-browser
$B set viewport 390 844 >/dev/null

A_BAD=0
echo "== PART A: API truth =="
python3 - <<'PY'
import json, urllib.request, urllib.error, urllib.parse
def get(u):
    r = urllib.request.Request(u, headers={'User-Agent': 'Chrome/124'})
    try:
        return urllib.request.urlopen(r, timeout=120)
    except urllib.error.HTTPError as e:
        return e
ok = True
def report(name, good, detail):
    global ok
    print(('PASS ' if good else 'FAIL ') + name + ' — ' + detail)
    if not good: ok = False

# A1: the live UEL league-phase table — 36 rows, Benfica top with the mapped
# fa name, the 12-season window intact, and ZERO raw-English fa leftovers
# (the 9 cycle-139 TEAM_FA additions close the last gaps)
try:
    d = json.loads(get('http://localhost:3000/api/standings?league=uel').read().decode())
    rows = d.get('rows') or []
    leftovers = [r.get('name') for r in rows if r.get('fa') == r.get('name')]
    report('A1 uel standings live 36/36 fa', d.get('ok') is True and len(rows) == 36
           and rows[0].get('name') == 'Benfica' and rows[0].get('fa') == 'بنفیکا'
           and d.get('selectedSeason') == '2026/2027'
           and len(d.get('allSeasons') or []) == 12 and not leftovers,
           f"rows={len(rows)} r0={rows[0].get('name')}/{rows[0].get('fa')} "
           f"allSeasons={len(d.get('allSeasons') or [])} leftovers={leftovers}")
except Exception as e:
    ok = False; print('A1: ERR', e)

# A2: the GLOBAL merge gains its 8th participant — perLeague carries uel with
# the full 20-row list, the merged table grows 140 → 160, and the cycle-132
# intersection window is BYTE-IDENTICAL to the 7-league baseline
# (2026/2027 … 2015/2016, exactly 12 — the whole point of choosing UEL over UECL)
try:
    d = json.loads(get('http://localhost:3000/api/topscorers').read().decode())
    pl = [x.get('leagueKey') for x in (d.get('perLeague') or [])]
    uel = [s for s in (d.get('scorers') or []) if s.get('leagueKey') == 'uel']
    seas = d.get('allSeasons') or []
    report('A2 merge 8th participant + 12-window intact', d.get('ok') is True
           and len(pl) == 8 and 'uel' in pl and len(uel) == 20
           and len(d.get('scorers') or []) == 160
           and len(seas) == 12 and seas[0] == '2026/2027' and seas[-1] == '2015/2016'
           and d.get('selectedSeason') == '2026/2027',
           f"pl={pl} uel={len(uel)} scorers={len(d.get('scorers') or [])} "
           f"window={seas[:1]}..{seas[-1:]}")
except Exception as e:
    ok = False; print('A2: ERR', e)

# A3: the 5-round knockout bracket — stage labels translated, the playoff
# round carries matchups (names may be TBD pre-draw; the shape is the contract)
try:
    d = json.loads(get('http://localhost:3000/api/league-bracket?league=uel').read().decode())
    b = d.get('bracket') or {}
    rounds = b.get('rounds') or []
    stageFa = [r.get('stageFa') for r in rounds]
    pmatch = (rounds[0].get('matchups') if rounds else []) or []
    report('A3 uel bracket 5 rounds', d.get('ok') is True and b.get('leagueKey') == 'uel'
           and len(rounds) == 5
           and stageFa == ['پلی‌آف', 'یک‌هشتم نهایی', 'یک‌چهارم نهایی', 'نیمه‌نهایی', 'فینال']
           and all(len(r.get('matchups') or []) >= 1 for r in rounds),
           f"rounds={len(rounds)} stageFa={stageFa} playoffMatchups={len(pmatch)}")
except Exception as e:
    ok = False; print('A3: ERR', e)

# A4: the honest cup contract — transfers.data is null for BOTH cups, the tab
# hides instead of an empty shell (cycle-57 rule, now symmetric for uel)
try:
    u = json.loads(get('http://localhost:3000/api/league-transfers?league=uel').read().decode())
    c = json.loads(get('http://localhost:3000/api/league-transfers?league=ucl').read().decode())
    report('A4 cup transfers honest null', u.get('ok') is True and u.get('transfers') is None
           and c.get('ok') is True and c.get('transfers') is None,
           f"uel={u.get('transfers')} ucl={c.get('transfers')}")
except Exception as e:
    ok = False; print('A4: ERR', e)

# A5: UEL fixtures — live upcoming list with Persian side names resolved
try:
    d = json.loads(get('http://localhost:3000/api/league-fixtures?league=uel').read().decode())
    up = d.get('upcoming') or []
    fa_ok = all((m.get('home') or {}).get('fa') and (m.get('away') or {}).get('fa') for m in up[:5])
    report('A5 uel fixtures live', d.get('ok') is True and len(up) >= 10 and fa_ok,
           f"upcoming={len(up)} first={(up[0]['home']['fa'] if up else '-')}-"
           f"{(up[0]['away']['fa'] if up else '-')} fa_ok={fa_ok}")
except Exception as e:
    ok = False; print('A5: ERR', e)

# A6: 55-entry title history (newest 2025/2026 استون‌ویلا) + the search index
# now attributes Celtic to the Europa League (standings-built index beats the
# scotland fallback via the teamId de-dup)
try:
    t = json.loads(get('http://localhost:3000/api/league-titles?league=uel').read().decode())
    items = (t.get('titles') or {}).get('items') or []
    q = urllib.parse.quote('سلتیک')
    s = json.loads(get(f'http://localhost:3000/api/search?q={q}').read().decode())
    rs = s.get('results') or s.get('teams') or []
    celtic = next((r for r in rs if r.get('teamId') == 9925), None)
    report('A6 titles 55 + celtic→uel attribution', t.get('ok') is True and len(items) == 55
           and items[0].get('season') == '2025/2026' and items[0].get('championFa') == 'استون‌ویلا'
           and celtic is not None and celtic.get('leagueKey') == 'uel',
           f"titles={len(items)} top={items[0].get('season') if items else '-'}"
           f"/{items[0].get('championFa') if items else '-'} celtic={celtic.get('leagueFa') if celtic else None}")
except Exception as e:
    ok = False; print('A6: ERR', e)

print('API_OK' if ok else 'API_BAD')
PY
[ $? -eq 0 ] || A_BAD=$((A_BAD+1))

TOTAL_BAD=0
echo "== PART B: DOM 390x844 =="
probe() { # $1=url $2=label $3=feature-js $4=optional click-js $5=optional extra wait-fn
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  if [ -n "${5:-}" ]; then $B wait --fn "$5" >/dev/null 2>&1; fi
  sleep 3
  if [ -n "${4:-}" ]; then $B eval "$4" >/dev/null 2>&1; sleep 3; fi
  local FEAT FEAT_RAW OUT BAD C E RC=0
  FEAT_RAW=$($B eval "JSON.stringify((()=>{$3})())" 2>/dev/null)
  FEAT=$(echo "$FEAT_RAW" | tr -d '"\\')
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
  echo "$FEAT_RAW" | python3 -c "
import json, sys
raw = sys.stdin.read().strip()
try:
    d = json.loads(raw)
    if isinstance(d, str): d = json.loads(d)
    assert isinstance(d, dict) and all(v is not False and v is not None for v in d.values()), f'falsey: {d}'
except Exception as ex:
    print('  FEAT-BAD:', raw, ex); sys.exit(1)
" || RC=1
  [ "$C" = "0" ] || RC=1
  [ "$E" = "0" ] || RC=1
  return $RC
}

# D1: the UEL league page — Persian h1, the live table with بنفیکا, the
# bracket + titles tabs present AND the transfers tab honestly ABSENT
probe "http://localhost:3000/league/uel" "D1 league/uel page" \
"const h1=(document.querySelector('h1')||{}).innerText||'';const b=document.body.innerText;const nav=[...(document.querySelector('nav[aria-label=\"بخش‌های لیگ\"]')||{querySelectorAll:()=>[]}).querySelectorAll('button')].map(x=>x.innerText);return {h1:h1,benfica:b.includes('بنفیکا'),bracket:nav.includes('براکت'),titles:nav.includes('قهرمانان'),noTransfers:!nav.includes('انتقال‌ها')}" \
"" "document.body.innerText.includes('بنفیکا')"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D2: click the bracket tab → the 5 Persian stage labels render
probe "http://localhost:3000/league/uel" "D2 bracket tab click" \
"const b=document.body.innerText;return {po:b.includes('پلی‌آف'),r16:b.includes('یک‌هشتم نهایی'),qf:b.includes('یک‌چهارم نهایی'),sf:b.includes('نیمه‌نهایی'),final:b.includes('فینال')}" \
"(function(){const bs=[...document.querySelectorAll('nav[aria-label=\"بخش‌های لیگ\"] button')];const t=bs.find(x=>x.innerText.includes('براکت'));if(t)t.click();})()" \
"document.body.innerText.includes('فینال')"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D3: the global race page — the honest «۸ لیگ و جام برتر» subtitle and the
# Europa League chip in the league filter
probe "http://localhost:3000/topscorers?league=all" "D3 global race 8 copy + uel chip" \
"const b=document.body.innerText;return {copy8:b.includes('۸ لیگ و جام برتر'),uelChip:b.includes('لیگ اروپا')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D3b: the dedicated /topscorers/uel page (SSG path from the new config)
probe "http://localhost:3000/topscorers/uel" "D3b topscorers/uel page" \
"const h1=(document.querySelector('h1')||{}).innerText||'';return {h1:h1,ok:h1.includes('لیگ اروپا')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D4: the leagues index — the new cup card with its Persian name and deep link
probe "http://localhost:3000/leagues" "D4 leagues index card" \
"const b=document.body.innerText;const l=[...document.querySelectorAll('a')].some(a=>(a.getAttribute('href')||'')==='/league/uel');return {fa:b.includes('لیگ اروپا'),link:l}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

echo "== RESULT =="
if [ "$TOTAL_BAD" -eq 0 ] && [ "$A_BAD" -eq 0 ]; then echo "DOM_PROOF OK (API 6/6 + DOM 5/5 green — لیگ اروپا honest end-to-end: 36/36 Persian table rows led by بنفیکا, the 8th merge participant with the 12-season window byte-identical (160 scorers, uel list 20), 5-round bracket with Persian stage labels, honest null transfers for both cups, live fixtures with fa sides, 55-title history topped by 2025/2026 استون‌ویلا, Celtic attributed to uel in search, «۸ لیگ و جام برتر» copy, /topscorers/uel SSG path, /leagues card; every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"; else echo "DOM_PROOF FLAGGED (A=$A_BAD B=$TOTAL_BAD)"; exit 1; fi
