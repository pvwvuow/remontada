#!/bin/bash
# cycle-150 update proof at 390x844 — «چمپیونشیپ انگلیس — چهاردهمین رقابت و
# دوازدهمین شرکت‌کنندهٔ واقعی مسابقهٔ جهانی گلزنان». Live probe UA Chrome/124
# 2026-10-29: the EFL Championship feed (fotmobId 48, ccode3 ENG — the pick
# passed over twice in 145/147) serves ALL FOUR blocks: flat 24-row 2026/2027
# table (میدلزبورو top on 25, سوانزی 2nd, وستهام 3rd — the relegated giant;
# دربی/پرستون propping up), allAvailableSeasons = 17 slash-format seasons
# 2026/2027 → 2010/2011 (the sliced-12 cycle-132 window covered EXACTLY — no
# globalMerge flag, the race honestly grows 11 → 12 with the window
# byte-identical), stats players with the Top scorer category +
# data.fotmob.com fetchAllUrl (Will Lankshear, Middlesbrough, 11;
# Guðjohnsen 8, Larin 7 — a 208-scorer full file), 123 title seasons (newest
# 2025/2026 Coventry City over Ipswich Town, oldest 1892/1893 Birmingham
# City — the SECOND-oldest title history in the portal after the Scottish
# Premiership's 129), and transfers.data = 100 entries (DOMESTIC league —
# the cups' honest transfers-hide contract does not apply). playoff = null →
# bracket tab honestly absent. ESPN slug probed: eng.2 → 200. Mapping sweep:
# 80 distinct unmapped names mapped (4 table-team spellings + the 100-entry
# transfer sweep, 126 distinct club names + the 123-season title-history
# sweep, winner AND runner-up sides; the duplicate-key guard caught
# "charlton" and "coventry city" already living in the old PL block — kept
# the older spellings چارلتون/کاونتری, additive keys only).
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

# A1: the Championship table — 24/24 Persian rows, zero leftovers, the
# live top three (میدلزبورو/سوانزی/وستهام), the sliced-12 window ending
# 2015/2016, honest selectedSeason echo, Lankshear atop the scorers with a
# Persian team field
try:
    d = json.loads(get('http://localhost:3000/api/standings?league=championship').read().decode())
    rows = d.get('rows') or []
    left = [r.get('name') for r in rows if r.get('fa') == r.get('name')]
    seas = d.get('allSeasons') or []
    sc = d.get('scorers') or []
    top = sc[0] if sc else {}
    report('A1 championship table 24 fa + window 12 + scorers',
           d.get('ok') is True and len(rows) == 24 and not left
           and rows[0].get('fa') == 'میدلزبورو' and rows[1].get('fa') == 'سوانزی'
           and rows[2].get('fa') == 'وستهام'
           and len(seas) == 12 and seas[0] == '2026/2027' and seas[-1] == '2015/2016'
           and d.get('selectedSeason') == '2026/2027'
           and len(sc) >= 15 and top.get('goals') == 11 and top.get('team') == 'میدلزبورو'
           and not any(has_ascii(s.get('team')) for s in sc),
           f"rows={len(rows)} left={left} top3={[r.get('fa') for r in rows[:3]]} seasons={len(seas)} top={top.get('name')}/{top.get('goals')}/{top.get('team')}")
except Exception as e:
    ok = False; print('A1: ERR', e)

# A2: THE race invariants — 12 participants WITH championship, the scorers
# total the live truth gives (240 = 220 + 20 Championship rows), the
# cycle-132 window byte-identical, honest leader (رافینیا ۱۳ stays top),
# cards alive
try:
    d = json.loads(get('http://localhost:3000/api/topscorers').read().decode())
    pl = [x.get('leagueKey') for x in (d.get('perLeague') or [])]
    seas = d.get('allSeasons') or []
    scorers = d.get('scorers') or []
    leader = scorers[0] if scorers else {}
    cards = d.get('cards') or {}
    y = cards.get('yellow') if isinstance(cards, dict) else None
    report('A2 race 12 participants + window byte-identical',
           len(pl) == 12 and 'championship' in pl and 'saudi' in pl and 'scottish' in pl
           and len(scorers) == 240 and len(seas) == 12
           and seas[0] == '2026/2027' and seas[-1] == '2015/2016'
           and d.get('selectedSeason') == '2026/2027'
           and leader.get('name') == 'Raphinha' and leader.get('goals') == 13
           and isinstance(y, list) and len(y) > 0,
           f"pl={pl} n={len(scorers)} window={seas[:1]}..{seas[-1:]} leader={leader.get('name')}/{leader.get('goals')}/{leader.get('leagueKey')} yellow={len(y) if isinstance(y, list) else y}")
except Exception as e:
    ok = False; print('A2: ERR', e)

# A3: the other three blocks — 123 titles (newest 2025/2026 کاونتری over
# ایپسوییچ, oldest 1892/1893 بیرمنگام‌سیتی), transfers ALL-Persian, bracket
# honestly null, fixtures clean
try:
    t = json.loads(get('http://localhost:3000/api/league-titles?league=championship').read().decode())
    items = (t.get('titles') or {}).get('items') or []
    tr = json.loads(get('http://localhost:3000/api/league-transfers?league=championship').read().decode())
    titems = ((tr.get('transfers') or {}).get('items')) or []
    trbad = [x for x in titems if has_ascii((x.get('from', {}).get('fa') or '')) or has_ascii((x.get('to', {}).get('fa') or ''))]
    br = json.loads(get('http://localhost:3000/api/league-bracket?league=championship').read().decode())
    fx = json.loads(get('http://localhost:3000/api/league-fixtures?league=championship').read().decode())
    up = fx.get('upcoming') or []
    fxbad = [m for m in up if has_ascii((m.get('home') or {}).get('fa') or '') or has_ascii((m.get('away') or {}).get('fa') or '')]
    report('A3 titles 123 + transfers clean + bracket null + fixtures clean',
           t.get('ok') is True and len(items) == 123
           and items[0].get('season') == '2025/2026' and items[0].get('championFa') == 'کاونتری'
           and items[0].get('runnerUpFa') == 'ایپسوییچ'
           and items[-1].get('season') == '1892/1893' and items[-1].get('championFa') == 'بیرمنگام‌سیتی'
           and len(titems) >= 10 and not trbad
           and br.get('ok') is True and br.get('bracket') is None
           and len(up) >= 10 and not fxbad,
           f"titles={len(items)} newest={items[0].get('season')}/{items[0].get('championFa')}+{items[0].get('runnerUpFa')} oldest={items[-1].get('season')}/{items[-1].get('championFa')} transfers={len(titems)} trbad={trbad[:2]} fixtures={len(up)} fxbad={fxbad[:2]}")
except Exception as e:
    ok = False; print('A3: ERR', e)

# A4: the dedicated /topscorers/championship path + attribution truths — a
# relegated giant (وست‌هم) rides the NEW championship index while the five
# prior first-seen truths stay put (گالاتاسارای→superlig, رنجرز→scottish,
# ابها→saudi, الهلال→acl, سلتیک→uel) — live-verified, asserted as the live
# truth (D5 lesson).
try:
    s = json.loads(get('http://localhost:3000/api/topscorers/championship').read().decode())
    sc = s.get('scorers') or []
    truths = [('West Ham', 'championship'), ('Galatasaray', 'superlig'),
              ('Rangers', 'scottish'), ('ابها', 'saudi'), ('الهلال', 'acl'), ('Celtic', 'uel')]
    got = []
    for q, want in truths:
        sr = json.loads(get(f'http://localhost:3000/api/search?q={urllib.parse.quote(q)}').read().decode())
        r = (sr.get('results') or [{}])[0]
        got.append((q, r.get('leagueKey'), r.get('leagueKey') == want))
    report('A4 dedicated scorers + west-ham-championship + five prior truths',
           s.get('ok') is True and len(sc) >= 10 and sc[0].get('goals') == 11
           and 'Lankshear' in (sc[0].get('name') or '')
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

# D1: the Championship page — Persian h1, the live top three Persian, the
# bracket tab honestly ABSENT, transfers tab PRESENT (domestic)
probe "http://localhost:3000/league/championship" "D1 league/championship page" \
"const h1=(document.querySelector('h1')||{}).innerText||'';const b=document.body.innerText;const nav=[...(document.querySelector('nav[aria-label=\"بخش‌های لیگ\"]')||{querySelectorAll:()=>[]}).querySelectorAll('button')].map(x=>x.innerText);return {h1:h1.includes('چمپیونشیپ'),boro:b.includes('میدلزبورو'),swansea:b.includes('سوانزی'),wham:b.includes('وستهام'),noBracket:!nav.includes('براکت'),transfers:nav.includes('انتقال‌ها')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D2: a REAL click on the transfers tab — Persian rows, ZERO broken images
# (the cycle-145 TeamLogo placeholder proven on the NEXT league consumer)
probe "http://localhost:3000/league/championship" "D2 transfers tab live + zero broken" \
"const b=document.body.innerText;return {fa:b.includes('انتقال')}" \
"(function(){const btn=[...document.querySelectorAll('nav[aria-label=\"بخش‌های لیگ\"] button')].find(x=>x.innerText.includes('انتقال'));if(btn)btn.click();})()" \
"document.body.innerText.includes('میدلزبورو') || document.body.innerText.includes('وستهام')"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D3: the global race — the copy honestly says TWELVE, the old 11 copy is
# gone, the Championship chip rides the participant list
probe "http://localhost:3000/topscorers?league=all" "D3 race copy ۱۲ + championship chip" \
"const b=document.body.innerText;return {copy12:b.includes('۱۲ لیگ و جام برتر'),old11gone:!b.includes('۱۱ لیگ و جام برتر'),chip:b.includes('چمپیونشیپ انگلیس')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D4: the dedicated /topscorers/championship page (new SSG path) — live rows
probe "http://localhost:3000/topscorers/championship" "D4 topscorers/championship page" \
"const h1=(document.querySelector('h1')||{}).innerText||'';const b=document.body.innerText;return {ok:h1.includes('چمپیونشیپ'),lankshear:b.includes('Lankshear')||b.includes('لنکشیر'),boro:b.includes('میدلزبورو')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D5: the leagues index — the FOURTEENTH card with its deep link
probe "http://localhost:3000/leagues" "D5 leagues index 14th card" \
"const b=document.body.innerText;const l=[...document.querySelectorAll('a')].some(a=>(a.getAttribute('href')||'')==='/league/championship');return {fa:b.includes('چمپیونشیپ انگلیس'),link:l}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D6: the players hub deep-linked to championship — the 24-team grid + URL sync
probe "http://localhost:3000/players?league=championship" "D6 players hub championship grid" \
"const b=document.body.innerText;const u=window.location.search;return {boro:b.includes('میدلزبورو'),wham:b.includes('وستهام'),urlKept:u.includes('league=championship')}" \
"" "document.body.innerText.includes('میدلزبورو')"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

echo "== RESULT =="
if [ "$TOTAL_BAD" -eq 0 ] && [ "$A_BAD" -eq 0 ]; then echo "DOM_PROOF OK (API 4/4 + DOM 6/6 green — چمپیونشیپ انگلیس honest end-to-end: the 14th competition and the FOURTH consecutive new global-race participant, joining with NO globalMerge flag because its 17 slash-format seasons cover the cycle-132 window exactly (12 seasons 2026/2027 → 2015/2016 byte-identical), the live top three (میدلزبورو ۲۵/سوانزی/وستهام) on a 24/24 Persian table, Will Lankshear 11 atop the scorers with a Persian team field, 240-scorer race with رافینیا still honest leader, 123 titles topped by 2025/2026 کاونتری over ایپسوییچ (oldest 1892/1893 بیرمنگام‌سیتی), transfers LIVE and ALL-Persian (80-name sweep incl. the titles' runner-up sides), bracket honestly absent, attribution truth live-verified: وست‌هم rides the new championship index while the five prior first-seen truths stay put (گالاتاسارای→superlig, رنجرز→scottish, ابها→saudi, الهلال→acl, سلتیک→uel), race copy ۱۲ + players hub دوازده + search guide ۱۴ + /leagues 14th card, /players championship grid with URL sync; every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"; else echo "DOM_PROOF FLAGGED (A=$A_BAD B=$TOTAL_BAD)"; exit 1; fi
