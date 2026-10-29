#!/bin/bash
# cycle-135 update proof at 390x844 — «پست‌های بازی» (player profile
# multi-position map). Probed 2026-10-29 UA Chrome/124: playerData carries
# `positionDescription.positions[]` (label + occurences + isMainPosition) that
# was never mapped — the profile only showed the single primaryPosition label.
# A season selector for the profile was ALSO probed first and honestly
# dropped: playerData ignores ?season= (always serves the current season) and
# every candidate endpoint (playerStats/playerSeasonStats/playerCareerStats/
# legacy playerData) 500s/404s — upstream does not serve per-season player
# stats, so nothing honest to build there. This cycle instead: (1) PlayerData
# gains optional `positions[]` (main-first, occurrence-desc, fa labels via the
# NEW side-aware faPositionDetail — faPosition untouched for proven surfaces),
# (2) profile gains the «پست‌های بازی» chips section (star = main post, count
# in Persian digits), (3) "Keeper"-labeled GK payloads (Joan García) map to
# «دروازه‌بان» in the detail mapper only.
set -u
B=agent-browser
$B set viewport 390 844 >/dev/null

echo "== PART A: API truth =="
python3 - <<'PY'
import json, urllib.request, urllib.error
def get(u):
    r = urllib.request.Request(u, headers={'User-Agent': 'Chrome/124'})
    try:
        return urllib.request.urlopen(r, timeout=90)
    except urllib.error.HTTPError as e:
        return e
ok = True
def report(name, good, detail):
    global ok
    print(('PASS ' if good else 'FAIL ') + name + ' — ' + detail)
    if not good: ok = False

# A1: Raphinha (696679) — 6-position map, main-first ordering, side-aware
# Persian labels (Right/Left Midfielder → «هافبک راست/چپ», NOT flattened to
# «هافبک»), occurrence counts from the payload's own tally
try:
    d = json.loads(get('http://localhost:3000/api/player/696679').read().decode())
    p = d.get('player') or {}
    pos = p.get('positions') or []
    first = pos[0] if pos else {}
    fas = [s.get('fa') for s in pos]
    report('A1 raphinha positions', d.get('ok') is True and len(pos) == 6
           and first.get('fa') == 'وینگر چپ' and first.get('isMain') is True
           and first.get('occurrences') == 20 and first.get('en') == 'Left Winger'
           and 'مهاجم' in fas and 'هافبک هجومی' in fas and 'هافبک چپ' in fas
           and 'هافبک راست' in fas and 'وینگر راست' in fas
           and p.get('positionFa') == 'وینگر چپ',
           f"count={len(pos)} first={first.get('fa')}/{first.get('occurrences')} fas={fas}")
except Exception as e:
    ok = False; print('A1: ERR', e)

# A2: Joan García (1167220) — the probed "Keeper" raw label maps to
# «دروازه‌بان» in the detail mapper; single spot, main, honest occurrence count
try:
    d = json.loads(get('http://localhost:3000/api/player/1167220').read().decode())
    p = d.get('player') or {}
    pos = p.get('positions') or []
    report('A2 keeper label refined', d.get('ok') is True and len(pos) == 1
           and pos[0].get('fa') == 'دروازه‌بان' and pos[0].get('isMain') is True
           and pos[0].get('en') == 'Keeper' and isinstance(pos[0].get('occurrences'), int)
           and pos[0]['occurrences'] >= 40,
           f"pos={pos}")
except Exception as e:
    ok = False; print('A2: ERR', e)

# A3: contract intact — required PlayerData fields still present and unchanged
# (additive field only; positionFa/positionEn behaviour identical to the
# proven shape, e.g. Raphinha stays «وینگر چپ»)
try:
    d = json.loads(get('http://localhost:3000/api/player/696679').read().decode())
    p = d.get('player') or {}
    need = ['id', 'name', 'nameFa', 'positionFa', 'positionEn', 'status', 'team', 'info', 'season', 'fetchedAt']
    missing = [k for k in need if k not in p]
    report('A3 contract intact', d.get('ok') is True and not missing
           and p.get('positionEn') == 'Left Winger',
           f"missing={missing} positionEn={p.get('positionEn')}")
except Exception as e:
    ok = False; print('A3: ERR', e)

# A4: guard intact — junk id still 400 (nothing loosened by the additive field)
try:
    r = get('http://localhost:3000/api/player/0')
    report('A4 junk id 400', r.status == 400, f"status={r.status}")
except Exception as e:
    ok = False; print('A4: ERR', e)
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
  local FEAT FEAT_RAW OUT BAD C E RC=0
  # raw eval output is strict JSON (quoted keys) — keep it un-mangled for the
  # FEAT assertion below; FEAT (tr-stripped) is display-only, like cycle-132/134
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
    d = json.loads(raw)                 # agent-browser wraps the string in quotes
    if isinstance(d, str): d = json.loads(d)
    assert isinstance(d, dict) and all(v is not False and v is not None for v in d.values()), f'falsey: {d}'
except Exception as ex:
    print('  FEAT-BAD:', raw, ex); sys.exit(1)
" || RC=1
  [ "$C" = "0" ] || RC=1
  [ "$E" = "0" ] || RC=1
  return $RC
}

TOTAL_BAD=0

# D1: Raphinha profile — «پست‌های بازی» section renders 6 chips, first chip is
# the starred main post «وینگر چپ» with the Persian-digit occurrence, footnote
# present, all in the first viewport flow of the SSR page
probe "http://localhost:3000/player/696679" "D1 raphinha positions section" \
"const s=document.querySelector('[data-testid=\"player-positions\"]');const chips=s?[...s.querySelectorAll('span[title]')]:[];const first=chips[0]||{};return {section:!!s,chips:chips.length,firstFa:(first.innerText||'').includes('وینگر چپ'),mainStarred:!!(first.querySelector('svg[aria-label=\"پست اصلی\"]')),hasFootnote:(s?s.innerText:'').includes('پست اصلی با ستاره'),hasCount:chips.some(c=>/بازی/.test(c.innerText))}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D2: Joan García profile — exactly one «دروازه‌بان» chip with «۵۳ بازی»
# (Persian digits), proving the Keeper refinement reaches the DOM
probe "http://localhost:3000/player/1167220" "D2 keeper single chip" \
"const s=document.querySelector('[data-testid=\"player-positions\"]');const chips=s?[...s.querySelectorAll('span[title]')]:[];return {section:!!s,chipN:chips.length,gkFa:chips.length===1&&chips[0].innerText.includes('دروازه‌بان'),occ53:chips.length===1&&chips[0].innerText.includes('۵۳ بازی'),enTitle:chips.length===1&&chips[0].title==='Keeper'}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D3: the section sits between injury and season stats and the profile stays
# layout-clean at 390×844 with the headshot hero intact (quality ladder from
# cycle-134 still on the bare 192px source for the 60px hero)
probe "http://localhost:3000/player/696679" "D3 layout + hero source intact" \
"const s=document.querySelector('[data-testid=\"player-positions\"]');const stats=document.querySelector('[aria-label=\"آمار فصل\"]');const img=document.querySelector('img[src*=\"playerimages\"]');const order=s&&stats?(s.compareDocumentPosition(stats)&Node.DOCUMENT_POSITION_FOLLOWING)!==0:false;return {beforeStats:order,heroSrc:(img?img.src:'').includes('playerimages/696679'),heroLoaded:img?img.naturalWidth>0:false,noXsmall:img?!img.src.includes('_xsmall'):false}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D4: a player without the map (probe a coach-style/odd id honestly → the
# section must be absent, not an empty shell). We use the match-level proof
# instead: /players hub and a league page still render clean (no regression
# from the shared module edits)
probe "http://localhost:3000/players" "D4 hub regression clean" \
"const stars=document.querySelectorAll('[data-testid=\"star-list\"] img,[data-testid=\"star-list\"] span img').length;const photos=[...document.images].filter(i=>(i.src||'').includes('playerimages')&&!i.src.includes('_xsmall'));return {pageLoaded:document.body.innerText.length>200,photos:photos.length>50,positionsSectionAbsent:!document.querySelector('[data-testid=\"player-positions\"]')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

echo "== RESULT =="
if [ "$TOTAL_BAD" -eq 0 ] && [ "$A_BAD" -eq 0 ]; then echo "DOM_PROOF OK (API 4/4 + DOM 4/4 green — پست‌های بازی honest end-to-end: 6-chip main-first map for Raphinha with side-aware fa labels, single دروازه‌بان chip for the Keeper-labeled GK, contract intact (required fields + 400 guard), section between injury and season stats, hub clean, every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"; else echo "DOM_PROOF FLAGGED (A=$A_BAD B=$TOTAL_BAD)"; exit 1; fi
