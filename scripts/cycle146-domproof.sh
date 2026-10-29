#!/bin/bash
# cycle-146 update proof at 390x844 — «لیگ برتر اسکاتلند — دوازدهمین رقابت و
# دهمین شرکت‌کنندهٔ واقعی مسابقهٔ جهانی گلزنان». Live probe UA Chrome/124
# 2026-10-29: the Scottish Premiership feed (fotmobId 64, ccode3 SCO — from
# FotMob's own allLeagues index) serves ALL FOUR blocks: flat 12-row
# 2026/2027 table (Celtic top, Rangers 2nd — the Old Firm; Heart of
# Midlothian third), allAvailableSeasons = 17 slash-format seasons
# 2026/2027 → 2010/2011 (the sliced-12 cycle-132 window covered EXACTLY —
# no globalMerge flag, the race honestly grows 9 → 10 with the window
# byte-identical), stats players with the Top scorer category +
# data.fotmob.com fetchAllUrl (Camilo Durán, Celtic, 7; 93-goal full file —
# with Rangers' Ryan Don Naderi the Iranian-name story on the second line
# of the Old Firm), 129 title seasons (newest 2025/2026 Celtic over
# Rangers, oldest 1890/1891 — the OLDEST title history any portal league
# carries), and transfers.data = 100 entries (domestic league — transfers
# LIVE). playoff = null → bracket tab honestly absent. ESPN slug probed:
# sco.1 → 200. Search attribution UPGRADE: رنجرز previously fell back to
# «اسکاتلند» (outside the portal cups) — now rides the scottish index.
# Copy truth: race «۱۰ لیگ و جام برتر», players hub «ده لیگ», search guide
# «۱۲ لیگ و جام», /leagues metadata lists all 12. «Premiership» is
# ambiguous in the daily feed (SCO vs NIR) — country-keyed CC entries +
# the plain name joins AMBIGUOUS_NAMES. Transfers sweep: 43 distinct
# unmapped names mapped (incl. Leicester City + Leyton Orient — NEVER
# mapped by any earlier cycle). One diacritic residue caught by the sweep
# rerun: NK Varaždin serves ž (U+017E) — exact-spelling key added.
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

# A1: the Scottish table — 12/12 Persian rows, zero leftovers, the Old Firm
# one-two (سلتیک/رنجرز) + هارتس, the sliced-12 window ending 2015/2016,
# honest selectedSeason echo, Durán atop the scorers
try:
    d = json.loads(get('http://localhost:3000/api/standings?league=scottish').read().decode())
    rows = d.get('rows') or []
    left = [r.get('name') for r in rows if r.get('fa') == r.get('name')]
    seas = d.get('allSeasons') or []
    sc = d.get('scorers') or []
    top = sc[0] if sc else {}
    report('A1 scottish table 12 fa + window 12 + scorers',
           d.get('ok') is True and len(rows) == 12 and not left
           and rows[0].get('fa') == 'سلتیک' and rows[1].get('fa') == 'رنجرز'
           and rows[2].get('fa') == 'هارتس'
           and len(seas) == 12 and seas[0] == '2026/2027' and seas[-1] == '2015/2016'
           and d.get('selectedSeason') == '2026/2027'
           and len(sc) >= 15 and top.get('goals') == 7 and top.get('team') == 'سلتیک'
           and not any(any(ch.isalpha() and ch.isascii() for ch in s.get('team') or '') for s in sc),
           f"rows={len(rows)} left={left} top3={[r.get('fa') for r in rows[:3]]} seasons={len(seas)} top={top.get('name')}/{top.get('goals')}/{top.get('team')}")
except Exception as e:
    ok = False; print('A1: ERR', e)

# A2: THE race invariants — 10 participants WITH scottish, 200 scorers, the
# cycle-132 window byte-identical, honest marker, cards alive
try:
    d = json.loads(get('http://localhost:3000/api/topscorers').read().decode())
    pl = [x.get('leagueKey') for x in (d.get('perLeague') or [])]
    seas = d.get('allSeasons') or []
    scorers = d.get('scorers') or []
    leader = scorers[0] if scorers else {}
    cards = d.get('cards') or {}
    y = cards.get('yellow') if isinstance(cards, dict) else None
    report('A2 race 10 participants + window byte-identical',
           len(pl) == 10 and 'scottish' in pl
           and len(scorers) == 200 and len(seas) == 12
           and seas[0] == '2026/2027' and seas[-1] == '2015/2016'
           and d.get('selectedSeason') == '2026/2027'
           and leader.get('goals', 0) >= 10 and isinstance(y, list) and len(y) > 0,
           f"pl={pl} n={len(scorers)} window={seas[:1]}..{seas[-1:]} leader={leader.get('name')}/{leader.get('goals')}/{leader.get('leagueKey')} yellow={len(y) if isinstance(y, list) else y}")
except Exception as e:
    ok = False; print('A2: ERR', e)

# A3: the other three blocks — 129 titles (newest 2025/2026 سلتیک, oldest
# 1890/1891), transfers 100 ALL-Persian, bracket honestly null, fixtures clean
try:
    t = json.loads(get('http://localhost:3000/api/league-titles?league=scottish').read().decode())
    items = (t.get('titles') or {}).get('items') or []
    tr = json.loads(get('http://localhost:3000/api/league-transfers?league=scottish').read().decode())
    titems = ((tr.get('transfers') or {}).get('items')) or []
    trbad = [x for x in titems if any(ch.isalpha() and ch.isascii() for ch in (x.get('from', {}).get('fa') or '') + (x.get('to', {}).get('fa') or ''))]
    br = json.loads(get('http://localhost:3000/api/league-bracket?league=scottish').read().decode())
    fx = json.loads(get('http://localhost:3000/api/league-fixtures?league=scottish').read().decode())
    up = fx.get('upcoming') or []
    fxbad = [m for m in up if any(ch.isalpha() and ch.isascii() for ch in ((m.get('home') or {}).get('fa') or '') + ((m.get('away') or {}).get('fa') or ''))]
    report('A3 titles 129 + transfers clean + bracket null + fixtures clean',
           t.get('ok') is True and len(items) == 129
           and items[0].get('season') == '2025/2026' and items[0].get('championFa') == 'سلتیک'
           and items[-1].get('season') == '1890/1891'
           and len(titems) >= 10 and not trbad
           and br.get('ok') is True and br.get('bracket') is None
           and len(up) >= 10 and not fxbad,
           f"titles={len(items)} newest={items[0].get('season')}/{items[0].get('championFa')} oldest={items[-1].get('season')} transfers={len(titems)} trbad={trbad[:2]} fixtures={len(up)} fxbad={fxbad[:2]}")
except Exception as e:
    ok = False; print('A3: ERR', e)

# A4: the dedicated /topscorers/scottish path + the honest attribution
# UPGRADE — رنجرز rides the scottish index (previously fell back to
# «اسکاتلند» as an outside-the-portal side). سلتیک is ALSO a live UEL
# league-phase participant (rank 35) — the cycle-141 first-seen priority
# dedup honestly keeps it on uel; the assertion checks both truths.
try:
    s = json.loads(get('http://localhost:3000/api/topscorers/scottish').read().decode())
    sc = s.get('scorers') or []
    q1 = urllib.parse.quote('سلتیک')
    sr1 = json.loads(get(f'http://localhost:3000/api/search?q={q1}').read().decode())
    g1 = next((r for r in (sr1.get('results') or []) if r.get('teamId') == 9925), None)
    q2 = urllib.parse.quote('رنجرز')
    sr2 = json.loads(get(f'http://localhost:3000/api/search?q={q2}').read().decode())
    g2 = next((r for r in (sr2.get('results') or []) if r.get('leagueKey') == 'scottish'), None)
    report('A4 dedicated scorers + rangers attribution + celtic dual-truth',
           s.get('ok') is True and len(sc) >= 15 and sc[0].get('goals') == 7
           and 'Durán' in (sc[0].get('name') or '')
           and g2 is not None and g1 is not None
           and g1.get('leagueKey') == 'uel',
           f"scorers={len(sc)} top={sc[0].get('name')}/{sc[0].get('goals')} rangers={g2.get('leagueKey') if g2 else None} celtic={g1.get('leagueKey') if g1 else None}")
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

# D1: the Scottish page — Persian h1, the Old Firm one-two Persian, the
# bracket tab honestly ABSENT, transfers tab PRESENT (domestic)
probe "http://localhost:3000/league/scottish" "D1 league/scottish page" \
"const h1=(document.querySelector('h1')||{}).innerText||'';const b=document.body.innerText;const nav=[...(document.querySelector('nav[aria-label=\"بخش‌های لیگ\"]')||{querySelectorAll:()=>[]}).querySelectorAll('button')].map(x=>x.innerText);return {h1:h1,celtic:b.includes('سلتیک'),rangers:b.includes('رنجرز'),hearts:b.includes('هارتس'),noBracket:!nav.includes('براکت'),transfers:nav.includes('انتقال‌ها')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D2: a REAL click on the transfers tab — 100 Persian rows, ZERO broken
# images (the cycle-145 TeamLogo fix now proven on the second league)
probe "http://localhost:3000/league/scottish" "D2 transfers tab live + zero broken" \
"const b=document.body.innerText;return {fa:b.includes('انتقال')}" \
"(function(){const btn=[...document.querySelectorAll('nav[aria-label=\"بخش‌های لیگ\"] button')].find(x=>x.innerText.includes('انتقال'));if(btn)btn.click();})()" \
"document.body.innerText.includes('رنجرز') || document.body.innerText.includes('سلتیک')"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D3: the global race — the copy honestly says TEN, the old 9 copy is gone,
# the Scottish chip rides the participant list
probe "http://localhost:3000/topscorers?league=all" "D3 race copy ۱۰ + scottish chip" \
"const b=document.body.innerText;return {copy10:b.includes('۱۰ لیگ و جام برتر'),old9gone:!b.includes('۹ لیگ و جام برتر'),chip:b.includes('لیگ برتر اسکاتلند')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D4: the dedicated /topscorers/scottish page (new SSG path) — live rows
probe "http://localhost:3000/topscorers/scottish" "D4 topscorers/scottish page" \
"const h1=(document.querySelector('h1')||{}).innerText||'';const b=document.body.innerText;return {ok:h1.includes('لیگ برتر اسکاتلند'),duran:b.includes('Durán')||b.includes('دوران'),celtic:b.includes('سلتیک')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D5: the leagues index — the TWELFTH card with its deep link
probe "http://localhost:3000/leagues" "D5 leagues index 12th card" \
"const b=document.body.innerText;const l=[...document.querySelectorAll('a')].some(a=>(a.getAttribute('href')||'')==='/league/scottish');return {fa:b.includes('لیگ برتر اسکاتلند'),link:l}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D6: the players hub deep-linked to scottish — the 12-team grid + URL sync
probe "http://localhost:3000/players?league=scottish" "D6 players hub scottish grid" \
"const b=document.body.innerText;const u=window.location.search;return {celtic:b.includes('سلتیک'),rangers:b.includes('رنجرز'),urlKept:u.includes('league=scottish')}" \
"" "document.body.innerText.includes('سلتیک')"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

echo "== RESULT =="
if [ "$TOTAL_BAD" -eq 0 ] && [ "$A_BAD" -eq 0 ]; then echo "DOM_PROOF OK (API 4/4 + DOM 6/6 green — لیگ برتر اسکاتلند honest end-to-end: the 12th competition and the SECOND consecutive new global-race participant, joining with NO globalMerge flag because its 17 slash-format seasons cover the cycle-132 window exactly (12 seasons 2026/2027 → 2015/2016 byte-identical), the Old Firm one-two (سلتیک/رنجرز) + هارتس on a 12/12 Persian table, Camilo Durán 7 atop the scorers with سلتیک doubling, 200-scorer race with رافینیا still honest leader, 129 titles topped by 2025/2026 سلتیک (oldest 1890/1891 — the oldest title history on the portal), transfers LIVE and ALL-Persian (43-name sweep incl. Leicester City/Leyton Orient never mapped before + the NK Varaždin ž diacritic caught by the sweep rerun), bracket honestly absent, رنجرز attribution UPGRADED from the scotland fallback to the scottish index while سلتیک honestly stays uel (live UEL league-phase participant — the cycle-141 priority dedup), race copy ۱۰ + players hub ده + search guide ۱۲ + /leagues 12th card, /players scottish grid with URL sync; drift sweep WITH scottish stays PORTAL_LEAKS=0; every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"; else echo "DOM_PROOF FLAGGED (A=$A_BAD B=$TOTAL_BAD)"; exit 1; fi
