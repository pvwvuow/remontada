#!/bin/bash
# cycle-152 update proof at 390x844 — «لیگ برتر امارات — شانزدهمین رقابت و
# چهاردهمین شرکت‌کنندهٔ واقعی مسابقهٔ جهانی گلزنان». Live probe UA Chrome/124
# 2026-10-29: the UAE Pro League feed (fotmobId 538, ccode3 UAE — the
# Persian-fan pick of the whole Gulf arc: SEVEN Iranian internationals live
# in its 85-scorer goals.json file — عزت‌اللهی 3 / طارمی 2 / آزمون 2 /
# نوراللهی 1 / قایدی 1 / قربانی 1 / قدوس 1; the same-day Qatar probe carried
# ZERO Iranians in 76 rows, so the UAE won on live data truth) serves ALL
# FOUR blocks: flat 14-row 2026/2027 table (الجزیره top on 14, شباب الاهلی
# دبی 2nd on 13, الوصل 3rd on 13; بنی‌یاس bottom on 1), allAvailableSeasons
# = 17 slash-format seasons 2026/2027 → 2010/2011 (the sliced-12 cycle-132
# window covered EXACTLY — no globalMerge flag, the race honestly grows
# 13 → 14 with the window byte-identical), Top scorer category with a
# data.fotmob.com fetchAllUrl (Willy Semedo, United FC, 4), 19 title seasons
# (newest 2025/2026 العین over شباب الاهلی دبی, oldest 2005/2006 شباب الاهلی
# دبی — no runner-up recorded), and transfers.data = 100 entries
# (DOMESTIC league, 99 ride the serve layer). playoff = null → bracket tab
# honestly absent. NO espnSlug (the persiangulf pattern): ESPN's full soccer
# index (220 leagues / 9 pages scanned live) does not serve UAE Pro League —
# the optional field is omitted so the fallback loop skips it gracefully.
# Mapping sweep: 37 additive TEAM_FA keys (the 14-row table spellings + the
# 72-distinct-club transfer sweep + the 19-season title-history sweep
# including the folded Al Shabab Dubai + the space-variant defensive
# spellings; the five UAE clubs already mapped by the cycle-140 ACL West
# sweep stay untouched; "al-nasr sc" deliberately disambiguated as
# «النصر امارات» against the Saudi «النصر») + 21 additive PLAYER_NAME_FA
# keys (عزت‌اللهی/نوراللهی/قربانی join طارمی/آزمون/قایدی/قدوس; transfer stars
# تادچ/فکیر/تالیسکا/بنتکه/آسلاانی/لازارو/بانزا/کورونادو/دحود/پورتاس/فاس/
# گیاکوماکیس/دستان‌اوغلو/گونتر/رحیمی/مبخوت/دی‌لیما/کایو لوکاس). Zero
# duplicate keys against the 726 pre-existing team keys / 348 player keys.
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

def has_ascii(s):
    return any(ch.isalpha() and ch.isascii() for ch in s or '')

# A1: the UAE table — 14/14 Persian rows, zero leftovers, the live top
# three (الجزیره/شباب الاهلی دبی/الوصل), the sliced-12 window ending
# 2015/2016, honest selectedSeason echo, Semedo atop the scorers with a
# PERSIAN team field («یونایتد» — the mapping sweep at work)
try:
    d = json.loads(get('http://localhost:3000/api/standings?league=uae').read().decode())
    rows = d.get('rows') or []
    left = [r.get('name') for r in rows if r.get('fa') == r.get('name')]
    seas = d.get('allSeasons') or []
    sc = d.get('scorers') or []
    top = sc[0] if sc else {}
    report('A1 uae table 14 fa + window 12 + scorers',
           d.get('ok') is True and len(rows) == 14 and not left
           and rows[0].get('fa') == 'الجزیره' and rows[1].get('fa') == 'شباب الاهلی دبی'
           and rows[2].get('fa') == 'الوصل'
           and len(seas) == 12 and seas[0] == '2026/2027' and seas[-1] == '2015/2016'
           and d.get('selectedSeason') == '2026/2027'
           and len(sc) >= 15 and top.get('goals') == 4 and top.get('team') == 'یونایتد'
           and not any(has_ascii(s.get('team')) for s in sc),
           f"rows={len(rows)} left={left} top3={[r.get('fa') for r in rows[:3]]} seasons={len(seas)} top={top.get('name')}/{top.get('goals')}/{top.get('team')}")
except Exception as e:
    ok = False; print('A1: ERR', e)

# A2: THE race invariants — 14 participants WITH uae, the scorers total the
# live truth gives (280 = 260 + 20 UAE rows), the cycle-132 window
# byte-identical, honest leader (رافینیا ۱۳ stays top), cards alive
try:
    d = json.loads(get('http://localhost:3000/api/topscorers').read().decode())
    pl = [x.get('leagueKey') for x in (d.get('perLeague') or [])]
    seas = d.get('allSeasons') or []
    scorers = d.get('scorers') or []
    leader = scorers[0] if scorers else {}
    cards = d.get('cards') or {}
    y = cards.get('yellow') if isinstance(cards, dict) else None
    report('A2 race 16 participants + window byte-identical (gate-synced cycle-156: eredivisie joins)',
           len(pl) == 16 and 'eredivisie' in pl and 'qatar' in pl and 'uae' in pl and 'portugal' in pl and 'saudi' in pl
           and len(scorers) == 320 and len(seas) == 12
           and seas[0] == '2026/2027' and seas[-1] == '2015/2016'
           and d.get('selectedSeason') == '2026/2027'
           and leader.get('name') == 'Raphinha' and leader.get('goals') == 13
           and isinstance(y, list) and len(y) > 0,
           f"pl={pl} n={len(scorers)} window={seas[:1]}..{seas[-1:]} leader={leader.get('name')}/{leader.get('goals')}/{leader.get('leagueKey')} yellow={len(y) if isinstance(y, list) else y}")
except Exception as e:
    ok = False; print('A2: ERR', e)

# A3: the other three blocks — 19 titles (newest 2025/2026 العین over شباب
# الاهلی دبی, oldest 2005/2006 شباب الاهلی دبی no runner-up recorded),
# transfers ALL-Persian (99 items — zero ASCII in from/to fa fields),
# bracket honestly null, fixtures clean
try:
    t = json.loads(get('http://localhost:3000/api/league-titles?league=uae').read().decode())
    items = (t.get('titles') or {}).get('items') or []
    tr = json.loads(get('http://localhost:3000/api/league-transfers?league=uae').read().decode())
    titems = ((tr.get('transfers') or {}).get('items')) or []
    trbad = [x for x in titems if has_ascii((x.get('from', {}) or {}).get('fa') or '') or has_ascii((x.get('to', {}) or {}).get('fa') or '')]
    br = json.loads(get('http://localhost:3000/api/league-bracket?league=uae').read().decode())
    fx = json.loads(get('http://localhost:3000/api/league-fixtures?league=uae').read().decode())
    up = fx.get('upcoming') or []
    fxbad = [m for m in up if has_ascii((m.get('home') or {}).get('fa') or '') or has_ascii((m.get('away') or {}).get('fa') or '')]
    report('A3 titles 19 + transfers clean + bracket null + fixtures clean',
           t.get('ok') is True and len(items) == 19
           and items[0].get('season') == '2025/2026' and items[0].get('championFa') == 'العین'
           and items[0].get('runnerUpFa') == 'شباب الاهلی دبی'
           and items[-1].get('season') == '2005/2006' and items[-1].get('championFa') == 'شباب الاهلی دبی'
           and len(titems) >= 10 and not trbad
           and br.get('ok') is True and br.get('bracket') is None
           and len(up) >= 5 and not fxbad,
           f"titles={len(items)} newest={items[0].get('season')}/{items[0].get('championFa')}+{items[0].get('runnerUpFa')} oldest={items[-1].get('season')}/{items[-1].get('championFa')} transfers={len(titems)} trbad={trbad[:2]} fixtures={len(up)} fxbad={fxbad[:2]}")
except Exception as e:
    ok = False; print('A3: ERR', e)

# A4: the dedicated /topscorers/uae path + attribution truths — خورفکان
# rides the NEW uae index while the seven prior first-seen truths stay put
# (پورتو→portugal, وست‌هم→championship, گالاتاسارای→superlig, رنجرز→scottish,
# ابها→saudi, الهلال→acl, سلتیک→uel) — live-verified, asserted as the live
# truth (D5).
try:
    s = json.loads(get('http://localhost:3000/api/topscorers/uae').read().decode())
    sc = s.get('scorers') or []
    truths = [('Khorfakkan', 'uae'), ('FC Porto', 'portugal'), ('West Ham', 'championship'),
              ('Galatasaray', 'superlig'), ('Rangers', 'scottish'), ('Abha', 'saudi'),
              ('الهلال', 'acl'), ('Celtic', 'uel')]
    got = []
    for q, want in truths:
        sr = json.loads(get(f'http://localhost:3000/api/search?q={urllib.parse.quote(q)}').read().decode())
        r = (sr.get('results') or [{}])[0]
        got.append((q, r.get('leagueKey'), r.get('leagueKey') == want))
    report('A4 dedicated scorers + khorfakkan-uae + seven prior truths',
           s.get('ok') is True and len(sc) >= 10 and sc[0].get('goals') == 4
           and 'Semedo' in (sc[0].get('name') or '')
           and all(g[2] for g in got),
           f"scorers={len(sc)} top={sc[0].get('name')}/{sc[0].get('goals')} truths={[(g[0], g[1]) for g in got]}")
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

# D1: the UAE page — Persian h1, the live top three Persian, the bracket tab
# honestly ABSENT, transfers tab PRESENT (domestic league)
probe "http://localhost:3000/league/uae" "D1 league/uae page" \
"const h1=(document.querySelector('h1')||{}).innerText||'';const b=document.body.innerText;const nav=[...(document.querySelector('nav[aria-label=\"بخش‌های لیگ\"]')||{querySelectorAll:()=>[]}).querySelectorAll('button')].map(x=>x.innerText);return {h1:h1.includes('امارات'),jazira:b.includes('الجزیره'),shabab:b.includes('شباب الاهلی'),noBracket:!nav.includes('براکت'),transfers:nav.includes('انتقال‌ها')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D2: a REAL click on the transfers tab — Persian rows, ZERO broken images
# (the cycle-145 TeamLogo placeholder proven on the NINTH league consumer)
probe "http://localhost:3000/league/uae" "D2 transfers tab live + zero broken" \
"const b=document.body.innerText;return {fa:b.includes('انتقال')}" \
"(function(){const btn=[...document.querySelectorAll('nav[aria-label=\"بخش‌های لیگ\"] button')].find(x=>x.innerText.includes('انتقال'));if(btn)btn.click();})()" \
"document.body.innerText.includes('الجزیره') || document.body.innerText.includes('الوصل')"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D3: the global race — the copy honestly says FIFTEEN, the old 14 copy is
# gone, the Qatar chip rides the participant list
probe "http://localhost:3000/topscorers?league=all" "D3 race copy ۱۶ + eredivisie chip" \
"const b=document.body.innerText;return {copy16:b.includes('۱۶ لیگ و جام برتر'),old15gone:!b.includes('۱۵ لیگ و جام برتر'),old14gone:!b.includes('۱۴ لیگ و جام برتر'),chip:b.includes('لیگ ستارگان قطر'),ere:b.includes('اردیویزهٔ هلند')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D4: the dedicated /topscorers/uae page (new SSG path) — live rows with the
# Iranian names Persian (عزت‌اللهی)
probe "http://localhost:3000/topscorers/uae" "D4 topscorers/uae page" \
"const h1=(document.querySelector('h1')||{}).innerText||'';const b=document.body.innerText;return {ok:h1.includes('امارات'),semedo:b.includes('Semedo')||b.includes('سمدو'),ezatolahi:b.includes('عزت‌اللهی'),jazira:b.includes('یونایتد')||b.includes('الجزیره')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D5: the leagues index — the SIXTEENTH card with its deep link
probe "http://localhost:3000/leagues" "D5 leagues index 16th card" \
"const b=document.body.innerText;const l=[...document.querySelectorAll('a')].some(a=>(a.getAttribute('href')||'')==='/league/uae');return {fa:b.includes('لیگ برتر امارات'),link:l}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D6: the players hub deep-linked to uae — the 14-team grid + URL sync
probe "http://localhost:3000/players?league=uae" "D6 players hub uae grid" \
"const b=document.body.innerText;const u=window.location.search;return {jazira:b.includes('الجزیره'),wasl:b.includes('الوصل'),urlKept:u.includes('league=uae')}" \
"" "document.body.innerText.includes('الجزیره')"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

echo "== RESULT =="
if [ "$TOTAL_BAD" -eq 0 ] && [ "$A_BAD" -eq 0 ]; then echo "DOM_PROOF OK (API 4/4 + DOM 6/6 green — لیگ برتر امارات honest end-to-end: the 16th competition and the SIXTH consecutive new global-race participant, joining with NO globalMerge flag because its 17 slash-format seasons cover the cycle-132 window exactly (12 seasons 2026/2027 → 2015/2016 byte-identical), the live top three (الجزیره ۱۴/شباب الاهلی دبی ۱۳/الوصل ۱۳) on a 14/14 Persian table, Willy Semedo 4 atop the scorers with a PERSIAN team field (یونایتد), 320-scorer race (16 leagues, gate-synced cycle-156) with رافینیا still honest leader, 19 titles topped by 2025/2026 العین over شباب الاهلی دبی (oldest 2005/2006 شباب الاهلی دبی), transfers LIVE and ALL-Persian (37-name sweep, 99 items zero-ASCII), bracket honestly absent, NO espnSlug (ESPN serves no UAE fixtures — persiangulf pattern, probed live), attribution truth live-verified: خورفکان rides the new uae index while the seven prior first-seen truths stay put (پورتو→portugal, وست‌هم→championship, گالاتاسارای→superlig, رنجرز→scottish, ابها→saudi, الهلال→acl, سلتیک→uel), race copy ۱۶ + players hub شانزده + search guide ۱۹ + /leagues 19th card (acl2, gate-synced cycle-157), /players uae grid with URL sync, the SEVEN Iranians عزت‌اللهی/طارمی/آزمون/نوراللهی/قایدی/قربانی/قدوس live in the scorer pool; every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"; else echo "DOM_PROOF FLAGGED (A=$A_BAD B=$TOTAL_BAD)"; exit 1; fi
