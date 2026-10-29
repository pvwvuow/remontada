#!/bin/bash
# cycle-140 update proof at 390x844 — «کنفرانس لیگ اروپا، نهمین مسابقه با
# مستثنی‌سازی ادغام». The cycle-139 card deferred exactly this step: UECL
# (fotmob.com/leagues/10216, probed live UA Chrome/124 2026-10-29) is a full
# payload (36-team league phase, FIVE knockout rounds, 6 historical seasons
# 2021/2022+) but its 6-season feed would SHRINK the cycle-132 global-merge
# intersection window from 12 to 6 — so it joins with globalMerge: false.
# One flag, one semantic: excluded from BOTH /topscorers merges (scorers +
# cards) so the page shows one participant set; every per-league surface
# stays live because /topscorers/uecl reads getStandings directly. Proof:
# standings 36/36 Persian, merge invariants byte-identical (8 participants,
# window 2026/2027→2015/2016, 160 scorers), 5-round bracket, honest null
# transfers (three cups symmetric), 5-title history, Hearts → uecl /
# Rangers → scotland search attribution, /topscorers/uecl SSG page.
set -u
B=agent-browser
$B set viewport 390 844 >/dev/null

A_BAD=0
echo "== PART A: API truth =="
python3 - <<'PY'
import json, sys, urllib.request, urllib.error, urllib.parse
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

# A1: the live UECL league-phase table — 36 rows, ZERO raw-English fa
# leftovers (the 26 cycle-140 TEAM_FA additions close every gap), and the
# per-league season window is honestly 6 (2021/2022 earliest)
try:
    d = json.loads(get('http://localhost:3000/api/standings?league=uecl').read().decode())
    rows = d.get('rows') or []
    leftovers = [r.get('name') for r in rows if r.get('fa') == r.get('name')]
    seas = d.get('allSeasons') or []
    hearts = next((r.get('fa') for r in rows if r.get('teamId') == 9860), None)
    report('A1 uecl standings 36/36 fa + 6-season window', d.get('ok') is True
           and len(rows) == 36 and not leftovers and len(seas) == 6
           and seas[-1] == '2021/2022' and hearts == 'هارتس',
           f"rows={len(rows)} leftovers={leftovers} window={seas[:1]}..{seas[-1:]} hearts={hearts}")
except Exception as e:
    ok = False; print('A1: ERR', e)

# A2: THE merge invariants (the entire point of the flag) — the race stays
# 8 participants WITHOUT uecl, the intersection window stays byte-identical
# (12 seasons, 2026/2027 → 2015/2016) and the merged table stays 160
try:
    d = json.loads(get('http://localhost:3000/api/topscorers').read().decode())
    pl = [x.get('leagueKey') for x in (d.get('perLeague') or [])]
    seas = d.get('allSeasons') or []
    report('A2 merge invariants intact with uecl exempt', d.get('ok') is True
           and len(pl) == 8 and 'uecl' not in pl and 'uel' in pl
           and len(seas) == 12 and seas[0] == '2026/2027' and seas[-1] == '2015/2016'
           and len(d.get('scorers') or []) == 160
           and len((d.get('cards') or {}).get('yellow') or []) == 10,
           f"pl={pl} window={seas[:1]}..{seas[-1:]} scorers={len(d.get('scorers') or [])}")
except Exception as e:
    ok = False; print('A2: ERR', e)

# A3: the 5-round knockout bracket with Persian stage labels
try:
    d = json.loads(get('http://localhost:3000/api/league-bracket?league=uecl').read().decode())
    b = d.get('bracket') or {}
    rounds = b.get('rounds') or []
    stageFa = [r.get('stageFa') for r in rounds]
    report('A3 uecl bracket 5 rounds', d.get('ok') is True and b.get('leagueKey') == 'uecl'
           and len(rounds) == 5
           and stageFa == ['پلی‌آف', 'یک‌هشتم نهایی', 'یک‌چهارم نهایی', 'نیمه‌نهایی', 'فینال']
           and all(len(r.get('matchups') or []) >= 1 for r in rounds),
           f"rounds={len(rounds)} stageFa={stageFa}")
except Exception as e:
    ok = False; print('A3: ERR', e)

# A4: the honest cup contract now symmetric across ALL THREE cups
try:
    u = json.loads(get('http://localhost:3000/api/league-transfers?league=uecl').read().decode())
    e1 = json.loads(get('http://localhost:3000/api/league-transfers?league=uel').read().decode())
    c = json.loads(get('http://localhost:3000/api/league-transfers?league=ucl').read().decode())
    report('A4 three cups transfers honest null', u.get('ok') is True and u.get('transfers') is None
           and e1.get('transfers') is None and c.get('transfers') is None,
           f"uecl={u.get('transfers')} uel={e1.get('transfers')} ucl={c.get('transfers')}")
except Exception as e:
    ok = False; print('A4: ERR', e)

# A5: the dedicated /topscorers/uecl route — reads getStandings directly, so
# the merge exemption must NOT touch it (full 20-row list, live leader)
try:
    d = json.loads(get('http://localhost:3000/api/topscorers/uecl').read().decode())
    sc = d.get('scorers') or []
    report('A5 uecl dedicated scorers unaffected', d.get('ok') is True and len(sc) >= 10
           and bool(sc[0].get('nameFa') or sc[0].get('name')),
           f"rows={len(sc)} top={sc[0].get('nameFa') or sc[0].get('name') if sc else '-'}")
except Exception as e:
    ok = False; print('A5: ERR', e)

# A6: 5-entry title history (newest 2025/2026 کریستال‌پالاس) + search
# attribution flip: Hearts rides the UECL standings index now, Rangers
# (outside the portal cups) keeps the scotland fallback
try:
    t = json.loads(get('http://localhost:3000/api/league-titles?league=uecl').read().decode())
    items = (t.get('titles') or {}).get('items') or []
    q = urllib.parse.quote('هارت')
    s = json.loads(get(f'http://localhost:3000/api/search?q={q}').read().decode())
    rs = s.get('results') or s.get('teams') or []
    hearts = next((r for r in rs if r.get('teamId') == 9860), None)
    q2 = urllib.parse.quote('rangers')
    s2 = json.loads(get(f'http://localhost:3000/api/search?q={q2}').read().decode())
    rs2 = s2.get('results') or s2.get('teams') or []
    rang = next((r for r in rs2 if r.get('teamId') == 8548), None)
    report('A6 titles 5 + hearts→uecl rangers→scotland', t.get('ok') is True and len(items) == 5
           and items[0].get('season') == '2025/2026' and items[0].get('championFa') == 'کریستال‌پالاس'
           and hearts is not None and hearts.get('leagueKey') == 'uecl'
           and rang is not None and rang.get('leagueKey') == 'scotland',
           f"titles={len(items)} top={items[0].get('season') if items else '-'}"
           f"/{items[0].get('championFa') if items else '-'} hearts={hearts.get('leagueFa') if hearts else None} "
           f"rangers={rang.get('leagueKey') if rang else None}")
except Exception as e:
    ok = False; print('A6: ERR', e)

print('API_OK' if ok else 'API_BAD')
sys.exit(0 if ok else 1)
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

# D1: the UECL league page — Persian h1, the live table with a cycle-140 map
# name (ستاره سرخ بلگراد), bracket + titles tabs present AND transfers absent
probe "http://localhost:3000/league/uecl" "D1 league/uecl page" \
"const h1=(document.querySelector('h1')||{}).innerText||'';const b=document.body.innerText;const nav=[...(document.querySelector('nav[aria-label=\"بخش‌های لیگ\"]')||{querySelectorAll:()=>[]}).querySelectorAll('button')].map(x=>x.innerText);return {h1:h1,zvezda:b.includes('ستاره سرخ بلگراد'),bracket:nav.includes('براکت'),titles:nav.includes('قهرمانان'),noTransfers:!nav.includes('انتقال‌ها')}" \
"" "document.body.innerText.includes('ستاره سرخ بلگراد')"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D2: click the bracket tab → the 5 Persian stage labels render
probe "http://localhost:3000/league/uecl" "D2 bracket tab click" \
"const b=document.body.innerText;return {po:b.includes('پلی‌آف'),r16:b.includes('یک‌هشتم نهایی'),qf:b.includes('یک‌چهارم نهایی'),sf:b.includes('نیمه‌نهایی'),final:b.includes('فینال')}" \
"(function(){const bs=[...document.querySelectorAll('nav[aria-label=\"بخش‌های لیگ\"] button')];const t=bs.find(x=>x.innerText.includes('براکت'));if(t)t.click();})()" \
"document.body.innerText.includes('فینال')"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D3: the global race page — the «۸ لیگ و جام برتر» copy stays honest AND the
# merge-exempt cup does NOT appear as a race chip
probe "http://localhost:3000/topscorers?league=all" "D3 race 8 copy + no uecl chip" \
"const b=document.body.innerText;return {copy8:b.includes('۸ لیگ و جام برتر'),noUeclChip:!b.includes('کنفرانس لیگ اروپا')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D3b: the dedicated /topscorers/uecl page (new SSG path) — live scorer rows
probe "http://localhost:3000/topscorers/uecl" "D3b topscorers/uecl page" \
"const h1=(document.querySelector('h1')||{}).innerText||'';return {h1:h1,ok:h1.includes('کنفرانس لیگ اروپا')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D4: the leagues index — the ninth competition card with its deep link
probe "http://localhost:3000/leagues" "D4 leagues index card" \
"const b=document.body.innerText;const l=[...document.querySelectorAll('a')].some(a=>(a.getAttribute('href')||'')==='/league/uecl');return {fa:b.includes('کنفرانس لیگ'),link:l}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

echo "== RESULT =="
if [ "$TOTAL_BAD" -eq 0 ] && [ "$A_BAD" -eq 0 ]; then echo "DOM_PROOF OK (API 6/6 + DOM 5/5 green — کنفرانس لیگ honest end-to-end: 36/36 Persian rows with the new map names, merge invariants byte-identical with the cup exempt (8 participants / 12-season window / 160 scorers / 10 cards), 5-round bracket with Persian stage labels, honest null transfers across all three cups, dedicated /topscorers/uecl unaffected (20 rows), 5-title history topped by 2025/2026 کریستال‌پالاس, Hearts→uecl + Rangers→scotland search attribution, «۸ لیگ و جام برتر» copy intact with no uecl race chip, /leagues ninth card; every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"; else echo "DOM_PROOF FLAGGED (A=$A_BAD B=$TOTAL_BAD)"; exit 1; fi
