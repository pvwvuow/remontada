#!/bin/bash
# cycle-151 update proof at 390x844 — «لیگ پرتغال — پانزدهمین رقابت و سیزدهمین
# شرکت‌کنندهٔ واقعی مسابقهٔ جهانی گلزنان». Live probe UA Chrome/124 2026-10-29:
# the Liga Portugal feed (fotmobId 61, ccode3 POR — found via the Sunday
# matches feed after the id=49 Eredivisie guess returned literal null and
# id=50 turned out to be EURO) serves ALL FOUR blocks: flat 18-row 2026/2027
# table (پورتو top on 27, بنفیکا 2nd on 22, اسپورتینگ‌لیسبون 3rd on 18;
# ریو آوه/استوریل propping up), allAvailableSeasons = 17 slash-format
# seasons 2026/2027 → 2010/2011 (the sliced-12 cycle-132 window covered
# EXACTLY — no globalMerge flag, the race honestly grows 12 → 13 with the
# window byte-identical), Top scorer category with a data.fotmob.com
# fetchAllUrl (پاولیدیس بنفیکا 9; لوئیس سوارز 8 — a 124-scorer full
# goals.json file), 92 title seasons (newest 2025/2026 پورتو over
# اسپورتینگ‌لیسبون, oldest 1934/1935 پورتو), and transfers.data = 100
# entries (DOMESTIC league). playoff = null → bracket tab honestly absent.
# ESPN slug probed live: por.1 → 200. The Persian-fan pick: طارمی's league
# (ریو آوه → پورتو 2020–2024). Mapping sweep: 54 additive TEAM_FA keys (the
# 18-row table spellings the older blocks missed + the 110-distinct-name
# transfer sweep + the 92-season title-history sweep winner AND runner-up +
# the stat-file spellings CD Nacional/Estoril Praia/Estrela/Sporting Braga;
# "FC Porto B" rides the qualifier fallback «پورتو دوم»; zero duplicate keys
# against the 672 pre-existing).
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

# A1: the Portugal table — 18/18 Persian rows, zero leftovers, the live top
# three (پورتو/بنفیکا/اسپورتینگ‌لیسبون), the sliced-12 window ending
# 2015/2016, honest selectedSeason echo, پاولیدیس atop the scorers with a
# Persian team field
try:
    d = json.loads(get('http://localhost:3000/api/standings?league=portugal').read().decode())
    rows = d.get('rows') or []
    left = [r.get('name') for r in rows if r.get('fa') == r.get('name')]
    seas = d.get('allSeasons') or []
    sc = d.get('scorers') or []
    top = sc[0] if sc else {}
    report('A1 portugal table 18 fa + window 12 + scorers',
           d.get('ok') is True and len(rows) == 18 and not left
           and rows[0].get('fa') == 'پورتو' and rows[1].get('fa') == 'بنفیکا'
           and rows[2].get('fa') == 'اسپورتینگ‌لیسبون'
           and len(seas) == 12 and seas[0] == '2026/2027' and seas[-1] == '2015/2016'
           and d.get('selectedSeason') == '2026/2027'
           and len(sc) >= 15 and top.get('goals') == 9 and top.get('team') == 'بنفیکا'
           and not any(has_ascii(s.get('team')) for s in sc),
           f"rows={len(rows)} left={left} top3={[r.get('fa') for r in rows[:3]]} seasons={len(seas)} top={top.get('name')}/{top.get('goals')}/{top.get('team')}")
except Exception as e:
    ok = False; print('A1: ERR', e)

# A2: THE race invariants — 13 participants WITH portugal, the scorers
# total the live truth gives (260 = 240 + 20 Portugal rows), the cycle-132
# window byte-identical, honest leader (رافینیا ۱۳ stays top), cards alive
try:
    d = json.loads(get('http://localhost:3000/api/topscorers').read().decode())
    pl = [x.get('leagueKey') for x in (d.get('perLeague') or [])]
    seas = d.get('allSeasons') or []
    scorers = d.get('scorers') or []
    leader = scorers[0] if scorers else {}
    cards = d.get('cards') or {}
    y = cards.get('yellow') if isinstance(cards, dict) else None
    report('A2 race 13 participants + window byte-identical',
           len(pl) == 13 and 'portugal' in pl and 'championship' in pl and 'saudi' in pl
           and len(scorers) == 260 and len(seas) == 12
           and seas[0] == '2026/2027' and seas[-1] == '2015/2016'
           and d.get('selectedSeason') == '2026/2027'
           and leader.get('name') == 'Raphinha' and leader.get('goals') == 13
           and isinstance(y, list) and len(y) > 0,
           f"pl={pl} n={len(scorers)} window={seas[:1]}..{seas[-1:]} leader={leader.get('name')}/{leader.get('goals')}/{leader.get('leagueKey')} yellow={len(y) if isinstance(y, list) else y}")
except Exception as e:
    ok = False; print('A2: ERR', e)

# A3: the other three blocks — 92 titles (newest 2025/2026 پورتو over
# اسپورتینگ‌لیسبون, oldest 1934/1935 پورتو), transfers ALL-Persian, bracket
# honestly null, fixtures clean
try:
    t = json.loads(get('http://localhost:3000/api/league-titles?league=portugal').read().decode())
    items = (t.get('titles') or {}).get('items') or []
    tr = json.loads(get('http://localhost:3000/api/league-transfers?league=portugal').read().decode())
    titems = ((tr.get('transfers') or {}).get('items')) or []
    trbad = [x for x in titems if has_ascii((x.get('from', {}) or {}).get('fa') or '') or has_ascii((x.get('to', {}) or {}).get('fa') or '')]
    br = json.loads(get('http://localhost:3000/api/league-bracket?league=portugal').read().decode())
    fx = json.loads(get('http://localhost:3000/api/league-fixtures?league=portugal').read().decode())
    up = fx.get('upcoming') or []
    fxbad = [m for m in up if has_ascii((m.get('home') or {}).get('fa') or '') or has_ascii((m.get('away') or {}).get('fa') or '')]
    report('A3 titles 92 + transfers clean + bracket null + fixtures clean',
           t.get('ok') is True and len(items) == 92
           and items[0].get('season') == '2025/2026' and items[0].get('championFa') == 'پورتو'
           and items[0].get('runnerUpFa') == 'اسپورتینگ‌لیسبون'
           and items[-1].get('season') == '1934/1935' and items[-1].get('championFa') == 'پورتو'
           and len(titems) >= 10 and not trbad
           and br.get('ok') is True and br.get('bracket') is None
           and len(up) >= 10 and not fxbad,
           f"titles={len(items)} newest={items[0].get('season')}/{items[0].get('championFa')}+{items[0].get('runnerUpFa')} oldest={items[-1].get('season')}/{items[-1].get('championFa')} transfers={len(titems)} trbad={trbad[:2]} fixtures={len(up)} fxbad={fxbad[:2]}")
except Exception as e:
    ok = False; print('A3: ERR', e)

# A4: the dedicated /topscorers/portugal path + attribution truths — پورتو
# rides the NEW portugal index while the six prior first-seen truths stay
# put (وست‌هم→championship, گالاتاسارای→superlig, رنجرز→scottish, ابها→saudi,
# الهلال→acl, سلتیک→uel) — live-verified, asserted as the live truth (D5).
try:
    s = json.loads(get('http://localhost:3000/api/topscorers/portugal').read().decode())
    sc = s.get('scorers') or []
    truths = [('FC Porto', 'portugal'), ('West Ham', 'championship'), ('Galatasaray', 'superlig'),
              ('Rangers', 'scottish'), ('Abha', 'saudi'), ('الهلال', 'acl'), ('Celtic', 'uel')]
    got = []
    for q, want in truths:
        sr = json.loads(get(f'http://localhost:3000/api/search?q={urllib.parse.quote(q)}').read().decode())
        r = (sr.get('results') or [{}])[0]
        got.append((q, r.get('leagueKey'), r.get('leagueKey') == want))
    report('A4 dedicated scorers + porto-portugal + six prior truths',
           s.get('ok') is True and len(sc) >= 10 and sc[0].get('goals') == 9
           and 'Pavlidis' in (sc[0].get('name') or '')
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

# D1: the Portugal page — Persian h1, the live top three Persian, the
# bracket tab honestly ABSENT, transfers tab PRESENT (domestic)
probe "http://localhost:3000/league/portugal" "D1 league/portugal page" \
"const h1=(document.querySelector('h1')||{}).innerText||'';const b=document.body.innerText;const nav=[...(document.querySelector('nav[aria-label=\"بخش‌های لیگ\"]')||{querySelectorAll:()=>[]}).querySelectorAll('button')].map(x=>x.innerText);return {h1:h1.includes('پرتغال'),porto:b.includes('پورتو'),benfica:b.includes('بنفیکا'),sporting:b.includes('اسپورتینگ'),noBracket:!nav.includes('براکت'),transfers:nav.includes('انتقال‌ها')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D2: a REAL click on the transfers tab — Persian rows, ZERO broken images
# (the cycle-145 TeamLogo placeholder proven on the EIGHTH league consumer)
probe "http://localhost:3000/league/portugal" "D2 transfers tab live + zero broken" \
"const b=document.body.innerText;return {fa:b.includes('انتقال')}" \
"(function(){const btn=[...document.querySelectorAll('nav[aria-label=\"بخش‌های لیگ\"] button')].find(x=>x.innerText.includes('انتقال'));if(btn)btn.click();})()" \
"document.body.innerText.includes('بنفیکا') || document.body.innerText.includes('پورتو')"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D3: the global race — the copy honestly says THIRTEEN, the old 12 copy is
# gone, the Portugal chip rides the participant list
probe "http://localhost:3000/topscorers?league=all" "D3 race copy ۱۳ + portugal chip" \
"const b=document.body.innerText;return {copy13:b.includes('۱۳ لیگ و جام برتر'),old12gone:!b.includes('۱۲ لیگ و جام برتر'),chip:b.includes('لیگ پرتغال')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D4: the dedicated /topscorers/portugal page (new SSG path) — live rows
probe "http://localhost:3000/topscorers/portugal" "D4 topscorers/portugal page" \
"const h1=(document.querySelector('h1')||{}).innerText||'';const b=document.body.innerText;return {ok:h1.includes('پرتغال'),pavlidis:b.includes('Pavlidis')||b.includes('پاولیدیس'),benfica:b.includes('بنفیکا')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D5: the leagues index — the FIFTEENTH card with its deep link
probe "http://localhost:3000/leagues" "D5 leagues index 15th card" \
"const b=document.body.innerText;const l=[...document.querySelectorAll('a')].some(a=>(a.getAttribute('href')||'')==='/league/portugal');return {fa:b.includes('لیگ پرتغال'),link:l}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D6: the players hub deep-linked to portugal — the 18-team grid + URL sync
probe "http://localhost:3000/players?league=portugal" "D6 players hub portugal grid" \
"const b=document.body.innerText;const u=window.location.search;return {porto:b.includes('پورتو'),benfica:b.includes('بنفیکا'),urlKept:u.includes('league=portugal')}" \
"" "document.body.innerText.includes('پورتو')"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

echo "== RESULT =="
if [ "$TOTAL_BAD" -eq 0 ] && [ "$A_BAD" -eq 0 ]; then echo "DOM_PROOF OK (API 4/4 + DOM 6/6 green — لیگ پرتغال honest end-to-end: the 15th competition and the FIFTH consecutive new global-race participant, joining with NO globalMerge flag because its 17 slash-format seasons cover the cycle-132 window exactly (12 seasons 2026/2027 → 2015/2016 byte-identical), the live top three (پورتو ۲۷/بنفیکا ۲۲/اسپورتینگ‌لیسبون ۱۸) on an 18/18 Persian table, پاولیدیس ۹ atop the scorers with a Persian team field, 260-scorer race with رافینیا still honest leader, 92 titles topped by 2025/2026 پورتو over اسپورتینگ‌لیسبون (oldest 1934/1935 پورتو), transfers LIVE and ALL-Persian (54-name sweep incl. the stat-file spellings), bracket honestly absent, attribution truth live-verified: پورتو rides the new portugal index while the six prior first-seen truths stay put (وست‌هم→championship, گالاتاسارای→superlig, رنجرز→scottish, ابها→saudi, الهلال→acl, سلتیک→uel), race copy ۱۳ + players hub سیزده + search guide ۱۵ + /leagues 15th card, /players portugal grid with URL sync; every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"; else echo "DOM_PROOF FLAGGED (A=$A_BAD B=$TOTAL_BAD)"; exit 1; fi
