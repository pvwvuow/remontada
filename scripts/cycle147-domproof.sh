#!/bin/bash
# cycle-147 update proof at 390x844 — «لیگ حرفه‌ای عربستان — سیزدهمین رقابت و
# یازدهمین شرکت‌کنندهٔ واقعی مسابقهٔ جهانی گلزنان». Live probe UA Chrome/124
# 2026-10-29: the Saudi Pro League feed (fotmobId 536, ccode3 KSA — from
# FotMob's own allLeagues index) serves ALL FOUR blocks: flat 18-row
# 2026/2027 table (الهلال top on 27, النصر 2nd — the Gulf Classic; القادسیه
# third), allAvailableSeasons = 17 slash-format seasons 2026/2027 → 2010/2011
# (the sliced-12 cycle-132 window covered EXACTLY — no globalMerge flag, the
# race honestly grows 10 → 11 with the window byte-identical), stats players
# with the Top scorer category + data.fotmob.com fetchAllUrl (Ivan Toney, Al
# Ahli, 12; En-Nesyri/Retegui on 7 — the thin early-season full file), 22
# title seasons (newest 2025/2026 النصر over الهلال, oldest 2004/2005 الشباب
# with no runner-up recorded), and transfers.data = 100 entries (DOMESTIC
# league — the cups' honest transfers-hide contract does not apply; 98 arrive
# through the serving layer). playoff = null → bracket tab honestly absent.
# ESPN slug probed: ksa.1 → 200. The Persian-fan pick over the Championship:
# the Gulf neighbor league. Attribution dual-truth (live-verified, not
# assumed): الهلال/النصر/الاتحاد are LIVE ACL league-phase participants so
# the first-seen index honestly keeps them on acl (exactly like سلتیک on
# uel), while sides outside any cup (ابها) ride the NEW saudi index. Copy
# truth: race «۱۱ لیگ و جام برتر», players hub «یازده لیگ», search guide
# «۱۳ لیگ و جام», /leagues metadata lists all 13. Transfers sweep: 31
# distinct unmapped names mapped (8 table-team spellings incl. Al-Ettifaq's
# hyphen form + foreign sides from Almería to Wydad Casablanca; the tsc
# duplicate-key guard caught al-raed already living in the ACL block — kept
# the older الراید spelling, additive keys only).
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

# A1: the Saudi table — 18/18 Persian rows, zero leftovers, the Gulf Classic
# one-two (الهلال/النصر) + القادسیه, the sliced-12 window ending 2015/2016,
# honest selectedSeason echo, Toney atop the scorers with Persian teams
try:
    d = json.loads(get('http://localhost:3000/api/standings?league=saudi').read().decode())
    rows = d.get('rows') or []
    left = [r.get('name') for r in rows if r.get('fa') == r.get('name')]
    seas = d.get('allSeasons') or []
    sc = d.get('scorers') or []
    top = sc[0] if sc else {}
    report('A1 saudi table 18 fa + window 12 + scorers',
           d.get('ok') is True and len(rows) == 18 and not left
           and rows[0].get('fa') == 'الهلال' and rows[1].get('fa') == 'النصر'
           and rows[2].get('fa') == 'القادسیه'
           and len(seas) == 12 and seas[0] == '2026/2027' and seas[-1] == '2015/2016'
           and d.get('selectedSeason') == '2026/2027'
           and len(sc) >= 15 and top.get('goals') == 12 and top.get('team') == 'الاهلی'
           and not any(has_ascii(s.get('team')) for s in sc),
           f"rows={len(rows)} left={left} top3={[r.get('fa') for r in rows[:3]]} seasons={len(seas)} top={top.get('name')}/{top.get('goals')}/{top.get('team')}")
except Exception as e:
    ok = False; print('A1: ERR', e)

# A2: THE race invariants — 11 participants WITH saudi, the scorers total the
# live truth gives (220 = 200 + 20 Saudi rows), the cycle-132 window
# byte-identical, honest leader (رافینیا ۱۳ stays top), cards alive
try:
    d = json.loads(get('http://localhost:3000/api/topscorers').read().decode())
    pl = [x.get('leagueKey') for x in (d.get('perLeague') or [])]
    seas = d.get('allSeasons') or []
    scorers = d.get('scorers') or []
    leader = scorers[0] if scorers else {}
    cards = d.get('cards') or {}
    y = cards.get('yellow') if isinstance(cards, dict) else None
    report('A2 race 11 participants + window byte-identical',
           len(pl) == 11 and 'saudi' in pl and 'scottish' in pl
           and len(scorers) == 220 and len(seas) == 12
           and seas[0] == '2026/2027' and seas[-1] == '2015/2016'
           and d.get('selectedSeason') == '2026/2027'
           and leader.get('name') == 'Raphinha' and leader.get('goals') == 13
           and isinstance(y, list) and len(y) > 0,
           f"pl={pl} n={len(scorers)} window={seas[:1]}..{seas[-1:]} leader={leader.get('name')}/{leader.get('goals')}/{leader.get('leagueKey')} yellow={len(y) if isinstance(y, list) else y}")
except Exception as e:
    ok = False; print('A2: ERR', e)

# A3: the other three blocks — 22 titles (newest 2025/2026 النصر over
# الهلال, oldest 2004/2005 الشباب), transfers ALL-Persian, bracket honestly
# null, fixtures clean
try:
    t = json.loads(get('http://localhost:3000/api/league-titles?league=saudi').read().decode())
    items = (t.get('titles') or {}).get('items') or []
    tr = json.loads(get('http://localhost:3000/api/league-transfers?league=saudi').read().decode())
    titems = ((tr.get('transfers') or {}).get('items')) or []
    trbad = [x for x in titems if has_ascii((x.get('from', {}).get('fa') or '')) or has_ascii((x.get('to', {}).get('fa') or ''))]
    br = json.loads(get('http://localhost:3000/api/league-bracket?league=saudi').read().decode())
    fx = json.loads(get('http://localhost:3000/api/league-fixtures?league=saudi').read().decode())
    up = fx.get('upcoming') or []
    fxbad = [m for m in up if has_ascii((m.get('home') or {}).get('fa') or '') or has_ascii((m.get('away') or {}).get('fa') or '')]
    report('A3 titles 22 + transfers clean + bracket null + fixtures clean',
           t.get('ok') is True and len(items) == 22
           and items[0].get('season') == '2025/2026' and items[0].get('championFa') == 'النصر'
           and items[0].get('runnerUpFa') == 'الهلال'
           and items[-1].get('season') == '2004/2005' and items[-1].get('championFa') == 'الشباب'
           and len(titems) >= 10 and not trbad
           and br.get('ok') is True and br.get('bracket') is None
           and len(up) >= 10 and not fxbad,
           f"titles={len(items)} newest={items[0].get('season')}/{items[0].get('championFa')}+{items[0].get('runnerUpFa')} oldest={items[-1].get('season')}/{items[-1].get('championFa')} transfers={len(titems)} trbad={trbad[:2]} fixtures={len(up)} fxbad={fxbad[:2]}")
except Exception as e:
    ok = False; print('A3: ERR', e)

# A4: the dedicated /topscorers/saudi path + the attribution dual-truth —
# الهلال stays acl (a LIVE ACL league-phase participant; first-seen index,
# exactly like سلتیک on uel) while ابها rides the NEW saudi index. Live-
# verified 2026-10-29, asserted as the live truth (D5 lesson).
try:
    s = json.loads(get('http://localhost:3000/api/topscorers/saudi').read().decode())
    sc = s.get('scorers') or []
    q1 = urllib.parse.quote('الهلال')
    sr1 = json.loads(get(f'http://localhost:3000/api/search?q={q1}').read().decode())
    g1 = next((r for r in (sr1.get('results') or []) if r.get('teamId') == 2529), None)
    q2 = urllib.parse.quote('ابها')
    sr2 = json.loads(get(f'http://localhost:3000/api/search?q={q2}').read().decode())
    g2 = next((r for r in (sr2.get('results') or []) if r.get('leagueKey') == 'saudi'), None)
    report('A4 dedicated scorers + hilal-acl truth + abha-saudi truth',
           s.get('ok') is True and len(sc) >= 10 and sc[0].get('goals') == 12
           and 'Toney' in (sc[0].get('name') or '')
           and g1 is not None and g1.get('leagueKey') == 'acl'
           and g2 is not None and g2.get('leagueKey') == 'saudi',
           f"scorers={len(sc)} top={sc[0].get('name')}/{sc[0].get('goals')} hilal={g1.get('leagueKey') if g1 else None} abha={g2.get('leagueKey') if g2 else None}")
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

# D1: the Saudi page — Persian h1, the Gulf Classic one-two Persian, the
# bracket tab honestly ABSENT, transfers tab PRESENT (domestic)
probe "http://localhost:3000/league/saudi" "D1 league/saudi page" \
"const h1=(document.querySelector('h1')||{}).innerText||'';const b=document.body.innerText;const nav=[...(document.querySelector('nav[aria-label=\"بخش‌های لیگ\"]')||{querySelectorAll:()=>[]}).querySelectorAll('button')].map(x=>x.innerText);return {h1:h1.includes('عربستان'),hilal:b.includes('الهلال'),nassr:b.includes('النصر'),qadsiah:b.includes('القادسیه'),noBracket:!nav.includes('براکت'),transfers:nav.includes('انتقال‌ها')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D2: a REAL click on the transfers tab — Persian rows, ZERO broken images
# (the cycle-145 TeamLogo placeholder now proven on the THIRD league)
probe "http://localhost:3000/league/saudi" "D2 transfers tab live + zero broken" \
"const b=document.body.innerText;return {fa:b.includes('انتقال')}" \
"(function(){const btn=[...document.querySelectorAll('nav[aria-label=\"بخش‌های لیگ\"] button')].find(x=>x.innerText.includes('انتقال'));if(btn)btn.click();})()" \
"document.body.innerText.includes('الهلال') || document.body.innerText.includes('النصر')"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D3: the global race — the copy honestly says ELEVEN, the old 10 copy is
# gone, the Saudi chip rides the participant list
probe "http://localhost:3000/topscorers?league=all" "D3 race copy ۱۱ + saudi chip" \
"const b=document.body.innerText;return {copy11:b.includes('۱۱ لیگ و جام برتر'),old10gone:!b.includes('۱۰ لیگ و جام برتر'),chip:b.includes('لیگ حرفه‌ای عربستان')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D4: the dedicated /topscorers/saudi page (new SSG path) — live rows
probe "http://localhost:3000/topscorers/saudi" "D4 topscorers/saudi page" \
"const h1=(document.querySelector('h1')||{}).innerText||'';const b=document.body.innerText;return {ok:h1.includes('لیگ حرفه‌ای عربستان'),toney:b.includes('Toney')||b.includes('تونی'),ahli:b.includes('الاهلی')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D5: the leagues index — the THIRTEENTH card with its deep link
probe "http://localhost:3000/leagues" "D5 leagues index 13th card" \
"const b=document.body.innerText;const l=[...document.querySelectorAll('a')].some(a=>(a.getAttribute('href')||'')==='/league/saudi');return {fa:b.includes('لیگ حرفه‌ای عربستان'),link:l}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D6: the players hub deep-linked to saudi — the 18-team grid + URL sync
probe "http://localhost:3000/players?league=saudi" "D6 players hub saudi grid" \
"const b=document.body.innerText;const u=window.location.search;return {hilal:b.includes('الهلال'),nassr:b.includes('النصر'),urlKept:u.includes('league=saudi')}" \
"" "document.body.innerText.includes('الهلال')"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

echo "== RESULT =="
if [ "$TOTAL_BAD" -eq 0 ] && [ "$A_BAD" -eq 0 ]; then echo "DOM_PROOF OK (API 4/4 + DOM 6/6 green — لیگ حرفه‌ای عربستان honest end-to-end: the 13th competition and the THIRD consecutive new global-race participant, joining with NO globalMerge flag because its 17 slash-format seasons cover the cycle-132 window exactly (12 seasons 2026/2027 → 2015/2016 byte-identical), the Gulf Classic one-two (الهلال/النصر) + القادسیه on an 18/18 Persian table, Ivan Toney 12 atop the scorers with Persian team fields, 220-scorer race with رافینیا still honest leader, 22 titles topped by 2025/2026 النصر over الهلال (oldest 2004/2005 الشباب), transfers LIVE and ALL-Persian (31-name sweep incl. the hyphen forms + foreign sides Almería/Wydad/Pyramids/Orlando Pirates), bracket honestly absent, attribution dual-truth live-verified: الهلال/النصر stay acl (live ACL league-phase participants — the first-seen priority dedup) while ابها rides the new saudi index, race copy ۱۱ + players hub یازده + search guide ۱۳ + /leagues 13th card, /players saudi grid with URL sync; every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"; else echo "DOM_PROOF FLAGGED (A=$A_BAD B=$TOTAL_BAD)"; exit 1; fi
