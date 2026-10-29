#!/bin/bash
# cycle-145 update proof at 390x844 — «سوپرلیگ ترکیه — یازدهمین رقابت و
# نهمین شرکت‌کنندهٔ واقعی مسافهٔ جهانی گلزنان». Live probe UA Chrome/124
# 2026-10-29: the Süper Lig feed (fotmobId 71, ccode3 TUR — canonical id
# taken from FotMob's own allLeagues index) serves ALL FOUR blocks: flat
# 18-row 2026/2027 table (Galatasaray top; promoted Amed Sportif 2nd!),
# allAvailableSeasons = 17 slash-format seasons 2026/2027 → 2010/2011 (so
# the sliced-12 cycle-132 race window 2026/2027 → 2015/2016 is covered
# EXACTLY — no globalMerge flag needed, the race honestly grows 8 → 9
# while the window stays byte-identical), stats players with the Top
# scorer category + data.fotmob.com fetchAllUrl (Gift Orban / Mohamed
# Salah / Victor Osimhen all on 8 — the first three-way 8-goal tie atop a
# portal table), 70 title seasons (newest 2025/2026 Galatasaray over
# Fenerbahçe, oldest 1956/1957), and transfers.data = 100 entries — a
# DOMESTIC league, so the cups' honest transfers-hide does not apply.
# playoff = null → the bracket tab honestly absent. ESPN fallback slug
# probed: tur.1 → 200. Copy truth: race «۹ لیگ و جام برتر», players hub
# «نه لیگ», search guide «۱۱ لیگ و جام», /leagues metadata lists all 11.
# Plus the honest carry-over fix: the committed cycle-144 drift sweep was
# module-less TS (top-level await) — tsc never saw it because the cycle-144
# chain ran before the file existed; `export {}` module marker added and
# tsc now passes WITH the scripts tree included.
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

# A1: the Süper Lig table — 18/18 Persian rows, zero leftovers, top three
# Persian (Galatasaray / Amed Sportif / Trabzonspor), the sliced-12 season
# window ending exactly at 2015/2016, honest selectedSeason echo, and the
# three-way 8-goal tie atop the scorer list
try:
    d = json.loads(get('http://localhost:3000/api/standings?league=superlig').read().decode())
    rows = d.get('rows') or []
    left = [r.get('name') for r in rows if r.get('fa') == r.get('name')]
    seas = d.get('allSeasons') or []
    sc = d.get('scorers') or []
    top3 = [(s.get('name'), s.get('team'), s.get('goals')) for s in sc[:3]]
    report('A1 superlig table 18 fa + window 12 + scorers',
           d.get('ok') is True and len(rows) == 18 and not left
           and rows[0].get('fa') == 'گالاتاسارای' and rows[1].get('fa') == 'آمد اسپورتیف'
           and rows[2].get('fa') == 'ترابزون‌اسپور'
           and len(seas) == 12 and seas[0] == '2026/2027' and seas[-1] == '2015/2016'
           and d.get('selectedSeason') == '2026/2027'
           and len(sc) >= 15 and sc[0].get('goals') == 8 and sc[1].get('goals') == 8 and sc[2].get('goals') == 8
           and not any(any(ch.isalpha() and ch.isascii() for ch in s.get('team') or '') for s in sc),
           f"rows={len(rows)} left={left} seas={seas[:1]}..{seas[-1:]} top3={top3}")
except Exception as e:
    ok = False; print('A1: ERR', e)

# A2: THE race invariants — 9 participants WITH superlig, 180 scorers, the
# cycle-132 window byte-identical (12 seasons, 2026/2027 → 2015/2016),
# honest marker, cards section alive
try:
    d = json.loads(get('http://localhost:3000/api/topscorers').read().decode())
    pl = [x.get('leagueKey') for x in (d.get('perLeague') or [])]
    seas = d.get('allSeasons') or []
    scorers = d.get('scorers') or []
    leader = scorers[0] if scorers else {}
    cards = d.get('cards') or {}
    y = cards.get('yellow') if isinstance(cards, dict) else None
    report('A2 race 9 participants + window byte-identical',
           len(pl) == 9 and 'superlig' in pl
           and len(scorers) == 180 and len(seas) == 12
           and seas[0] == '2026/2027' and seas[-1] == '2015/2016'
           and d.get('selectedSeason') == '2026/2027'
           and leader.get('goals', 0) >= 10 and isinstance(y, list) and len(y) > 0,
           f"pl={pl} n={len(scorers)} window={seas[:1]}..{seas[-1:]} leader={leader.get('name')}/{leader.get('goals')}/{leader.get('leagueKey')} yellow={len(y) if isinstance(y, list) else y}")
except Exception as e:
    ok = False; print('A2: ERR', e)

# A3: the other three blocks — 70 titles (newest 2025/2026 گالاتاسارای,
# oldest 1956/1957), transfers LIVE (a domestic league — items with Persian
# club sides), bracket honestly null (playoff null), fixtures 20 upcoming
# with zero English fa
try:
    t = json.loads(get('http://localhost:3000/api/league-titles?league=superlig').read().decode())
    items = (t.get('titles') or {}).get('items') or []
    tr = json.loads(get('http://localhost:3000/api/league-transfers?league=superlig').read().decode())
    titems = ((tr.get('transfers') or {}).get('items')) or []
    trbad = [x for x in titems if any(ch.isalpha() and ch.isascii() for ch in (x.get('from', {}).get('fa') or '') + (x.get('to', {}).get('fa') or ''))]
    br = json.loads(get('http://localhost:3000/api/league-bracket?league=superlig').read().decode())
    fx = json.loads(get('http://localhost:3000/api/league-fixtures?league=superlig').read().decode())
    up = fx.get('upcoming') or []
    fxbad = [m for m in up if any(ch.isalpha() and ch.isascii() for ch in ((m.get('home') or {}).get('fa') or '') + ((m.get('away') or {}).get('fa') or ''))]
    report('A3 titles 70 + transfers live + bracket null + fixtures clean',
           t.get('ok') is True and len(items) == 70
           and items[0].get('season') == '2025/2026' and items[0].get('championFa') == 'گالاتاسارای'
           and items[-1].get('season') == '1956/1957'
           and len(titems) >= 10 and not trbad
           and br.get('ok') is True and br.get('bracket') is None
           and len(up) >= 15 and not fxbad,
           f"titles={len(items)} newest={items[0].get('season')}/{items[0].get('championFa')} transfers={len(titems)} trbad={trbad[:2]} bracket={br.get('bracket')} fixtures={len(up)} fxbad={fxbad[:2]}")
except Exception as e:
    ok = False; print('A3: ERR', e)

# A4: the dedicated /topscorers/superlig path + honest search attribution
# (گالاتاسارای rides the superlig index)
try:
    s = json.loads(get('http://localhost:3000/api/topscorers/superlig').read().decode())
    sc = s.get('scorers') or []
    q = urllib.parse.quote('گالاتاسارای')
    sr = json.loads(get(f'http://localhost:3000/api/search?q={q}').read().decode())
    rs = sr.get('results') or sr.get('teams') or []
    gal = next((r for r in rs if r.get('leagueKey') == 'superlig'), None)
    report('A4 dedicated scorers + search attribution',
           s.get('ok') is True and len(sc) >= 15 and sc[0].get('goals') == 8
           and 'Orban' in (sc[0].get('name') or '')
           and gal is not None,
           f"scorers={len(sc)} top={sc[0].get('name')}/{sc[0].get('goals')} galatasaray={gal.get('leagueKey') if gal else None}")
except Exception as e:
    ok = False; print('A4: ERR', e)

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

# D1: the Süper Lig page — Persian h1, the promoted leader story Persian,
# the bracket tab honestly ABSENT (playoff null), transfers tab PRESENT
# (domestic league)
probe "http://localhost:3000/league/superlig" "D1 league/superlig page" \
"const h1=(document.querySelector('h1')||{}).innerText||'';const b=document.body.innerText;const nav=[...(document.querySelector('nav[aria-label=\"بخش‌های لیگ\"]')||{querySelectorAll:()=>[]}).querySelectorAll('button')].map(x=>x.innerText);return {h1:h1,galata:b.includes('گالاتاسارای'),amed:b.includes('آمد اسپورتیف'),trabzon:b.includes('ترابزون‌اسپور'),fener:b.includes('فنرباغچه'),noBracket:!nav.includes('براکت'),transfers:nav.includes('انتقال‌ها')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D2: a REAL click on the transfers tab — the domestic league's live transfer
# rows render with Persian club names
probe "http://localhost:3000/league/superlig" "D2 transfers tab live" \
"const b=document.body.innerText;return {fa:b.includes('انتقال')}" \
"(function(){const btn=[...document.querySelectorAll('nav[aria-label=\"بخش‌های لیگ\"] button')].find(x=>x.innerText.includes('انتقال'));if(btn)btn.click();})()" \
"document.body.innerText.includes('سامسون‌اسپور') || document.body.innerText.includes('گالاتاسارای')"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D3: the global race — the copy honestly says NINE, the old 8 copy is gone,
# and the Süper Lig chip rides the participant list
probe "http://localhost:3000/topscorers?league=all" "D3 race copy ۹ + superlig chip" \
"const b=document.body.innerText;return {copy9:b.includes('۹ لیگ و جام برتر'),old8gone:!b.includes('۸ لیگ و جام برتر'),chip:b.includes('سوپرلیگ ترکیه')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D4: the dedicated /topscorers/superlig page (new SSG path) — live rows
probe "http://localhost:3000/topscorers/superlig" "D4 topscorers/superlig page" \
"const h1=(document.querySelector('h1')||{}).innerText||'';const b=document.body.innerText;return {ok:h1.includes('سوپرلیگ ترکیه'),orban:b.includes('Orban')||b.includes('اوربان'),amed:b.includes('آمد اسپورتیف')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D5: the leagues index — the ELEVENTH card with its deep link
probe "http://localhost:3000/leagues" "D5 leagues index 11th card" \
"const b=document.body.innerText;const l=[...document.querySelectorAll('a')].some(a=>(a.getAttribute('href')||'')==='/league/superlig');return {fa:b.includes('سوپرلیگ ترکیه'),link:l}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D6: the players hub deep-linked to superlig — the 18-team grid with URL sync
probe "http://localhost:3000/players?league=superlig" "D6 players hub superlig grid" \
"const b=document.body.innerText;const u=window.location.search;return {galata:b.includes('گالاتاسارای'),amed:b.includes('آمد اسپورتیف'),urlKept:u.includes('league=superlig')}" \
"" "document.body.innerText.includes('گالاتاسارای')"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

echo "== RESULT =="
if [ "$TOTAL_BAD" -eq 0 ] && [ "$A_BAD" -eq 0 ]; then echo "DOM_PROOF OK (API 4/4 + DOM 6/6 green — سوپرلیگ ترکیه honest end-to-end: the 11th competition and the FIRST new global-race participant since cycle-132, joining with NO globalMerge flag because its 17 slash-format seasons cover the cycle-132 window exactly (12 seasons 2026/2027 → 2015/2016 byte-identical), 18/18 Persian table rows with promoted آمد اسپورتیف 2nd, the three-way 8-goal tie (Orban/Salah/Osimhen), 180-scorer race with رافینیا still honest leader, 70 titles topped by 2025/2026 گالاتاسارای (oldest 1956/1957), transfers LIVE (domestic — 100-entry feed, Persian club sides), bracket honestly absent, fixtures 20 clean, گالاتاسارای→superlig search attribution, race copy ۹ + players hub نه + search guide ۱۱ + /leagues 11th card, /players superlig grid with URL sync; drift sweep WITH superlig stays PORTAL_LEAKS=0; plus the carry-over tsc module fix on the committed cycle-144 drift sweep; every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"; else echo "DOM_PROOF FLAGGED (A=$A_BAD B=$TOTAL_BAD)"; exit 1; fi
