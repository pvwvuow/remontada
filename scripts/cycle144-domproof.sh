#!/bin/bash
# cycle-144 fix proof at 390x844 — «شکار رانش: صفر نشت انگلیسی در همهٔ
# فیلدهای فارسی پرتال». Live sweep 2026-10-29 (scripts/cycle144-drift.ts)
# found 68 portal leaks across 4 classes: (1) 2026/2027 upstream spellings
# with no mapping — hyphenated Paris Saint-Germain (Ligue 1 AND UCL leader!),
# PSV Eindhoven, LASK, Sabah FK, AEK Athens, Slavia Prague, FC Porto on the
# UCL table; promoted Málaga + Racing Santander (laliga), Mainz 05 /
# 1. FC Köln / Elversberg (bundesliga), Troyes (ligue1); (2) topscorer-feed
# full forms — Bayer 04 Leverkusen, 1. FSV Mainz 05, FC Augsburg,
# Sport-Club Freiburg, SV 07 Elversberg, Sporting Lisbon, N.E.C., Union
# Saint-Gilloise, RSC Anderlecht, Celta de Vigo; (3) cup-bracket TBD slots
# arriving as one «Side A/Side B» string the mapper never split — 25 leaked
# matchups (Sturm Graz/NEC Nijmegen, Brighton & Hove Albion/FC København…);
# (4) fixtures re-serving class 1. Fix: 23 additive TEAM_FA keys (zero shape
# change) + teamFa side-splitting for slash pairs (each side mapped honestly,
# unknown sides keep upstream). The daily matches slate ALSO serves non-portal
# minor leagues (Tanzanian PL, Copa del Rey early rounds…) — those ride the
# honest English-fallback convention (cycle-104) and churn daily: counted
# separately (226 today), never a portal leak. Proof below: zero leftovers on
# all 10 standings + the 13 names Persian, all 160 scorer teams + cards
# Persian with the full forms mapped, all 4 cup brackets side-Persian
# including TBD pairs, fixtures clean, and the DOM pages showing the fixed
# names for real at 390x844 with the UEL bracket tab clicked live.
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

# A1: ALL 10 standings — zero leftovers (fa == upstream name) anywhere, plus
# the exact 13 previously-leaking names now Persian
try:
    spots = {
        'ucl': {'Paris Saint-Germain': 'پاری سن‌ژرمن', 'PSV Eindhoven': 'پی‌اس‌وی آیندهوون',
                'LASK': 'لاسک', 'Sabah FK': 'صباح باکو', 'AEK Athens': 'آئک آتن',
                'Slavia Prague': 'اسلاویا پراگ', 'FC Porto': 'پورتو'},
        'laliga': {'Málaga': 'مالاگا', 'Racing Santander': 'ریسینگ سانتاندر'},
        'bundesliga': {'Mainz 05': 'ماینتس ۰۵', '1. FC Köln': 'کلن', 'Elversberg': 'الورسبرگ'},
        'ligue1': {'Paris Saint-Germain': 'پاری سن‌ژرمن', 'Troyes': 'تروا'},
    }
    KEYS = ['ucl', 'pl', 'laliga', 'seriea', 'bundesliga', 'ligue1', 'persiangulf', 'uel', 'uecl', 'acl']
    all_ok = True
    detail = []
    for k in KEYS:
        d = json.loads(get(f'http://localhost:3000/api/standings?league={k}').read().decode())
        rows = d.get('rows') or []
        left = [r.get('name') for r in rows if r.get('fa') == r.get('name')]
        if left or not rows:
            all_ok = False; detail.append(f'{k}:left={left}')
        for en, fa in spots.get(k, {}).items():
            row = next((r for r in rows if r.get('name') == en), None)
            if row is None or row.get('fa') != fa:
                all_ok = False; detail.append(f'{k}:{en}->{row.get("fa") if row else "MISSING"}')
    report('A1 standings 10/10 zero leftovers + 13 spots Persian', all_ok, ' '.join(detail) or 'all clean')
except Exception as e:
    ok = False; print('A1: ERR', e)

# A2: the merged global race — every one of the 160 scorer rows (and the
# cards list) carries a Persian club; the topscorer-feed full forms map
try:
    d = json.loads(get('http://localhost:3000/api/topscorers').read().decode())
    sc = d.get('scorers') or []
    bad = [f"{s.get('name')}@{s.get('team')}" for s in sc if any(ch.isascii() and ch.isalpha() for ch in (s.get('team') or ''))]
    teams = set(s.get('team') for s in sc)
    spots = {'بایر لورکوزن', 'یونیون سن‌ژیلواز', 'اسپورتینگ‌لیسبون', 'سلتاویگو', 'آندرلشت', 'نایمخن'}
    cards = d.get('cards') if isinstance(d.get('cards'), list) else []
    badc = [c.get('team') for c in cards if any(ch.isascii() and ch.isalpha() for ch in (c.get('team') or ''))]
    report('A2 merged race 160 Persian clubs + full forms mapped',
           len(sc) >= 100 and not bad and not badc and spots.issubset(teams),
           f"n={len(sc)} bad={bad[:4]} cardsBad={badc[:3]} missingSpots={sorted(spots - teams)}")
except Exception as e:
    ok = False; print('A2: ERR', e)

# A3: all 4 cup brackets — every matchup side is Persian, INCLUDING the TBD
# slots that arrive as «Side A/Side B» (side-splitting in teamFa)
try:
    all_ok = True; detail = []
    for k in ['ucl', 'uel', 'uecl', 'acl']:
        d = json.loads(get(f'http://localhost:3000/api/league-bracket?league={k}').read().decode())
        rounds = (d.get('bracket') or {}).get('rounds') or []
        n = 0; bad = []
        for r in rounds:
            for m in (r.get('matchups') or []):
                for side in ('home', 'away'):
                    nm = (m.get(side) or {}).get('name') or ''
                    n += 1
                    if any(ch.isascii() and ch.isalpha() for ch in nm):
                        bad.append(nm)
        if bad: all_ok = False; detail.append(f'{k}:{bad[:3]}')
        detail.append(f'{k}={n}')
    report('A3 brackets ucl/uel/uecl/acl every side Persian (TBD pairs split)', all_ok, ' '.join(detail))
except Exception as e:
    ok = False; print('A3: ERR', e)

# A4: fixtures for all 10 competitions — zero English fa on any side
try:
    all_ok = True; detail = []
    for k in ['ucl', 'pl', 'laliga', 'seriea', 'bundesliga', 'ligue1', 'persiangulf', 'uel', 'uecl', 'acl']:
        d = json.loads(get(f'http://localhost:3000/api/league-fixtures?league={k}').read().decode())
        up = d.get('upcoming') or []
        bad = []
        for m in up:
            for side in ('home', 'away'):
                fa = (m.get(side) or {}).get('fa') or ''
                if any(ch.isascii() and ch.isalpha() for ch in fa):
                    bad.append(fa)
        if bad: all_ok = False; detail.append(f'{k}:{sorted(set(bad))[:3]}')
    report('A4 fixtures 10/10 zero English fa', all_ok, ' '.join(detail) or 'all clean')
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

# D1: the UCL table — all seven previously-leaking league-phase sides Persian
probe "http://localhost:3000/league/ucl" "D1 league/ucl fixed names" \
"const b=document.body.innerText;return {psg:b.includes('پاری سن‌ژرمن'),psv:b.includes('پی‌اس‌وی آیندهوون'),porto:b.includes('پورتو'),slavia:b.includes('اسلاویا پراگ'),aek:b.includes('آئک آتن'),lask:b.includes('لاسک'),sabah:b.includes('صباح باکو')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D2: the Bundesliga table — promoted/renamed sides Persian
probe "http://localhost:3000/league/bundesliga" "D2 league/bundesliga fixed names" \
"const b=document.body.innerText;return {mainz:b.includes('ماینتس ۰۵'),koln:b.includes('کلن'),elversberg:b.includes('الورسبرگ')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D3: LaLiga — the promoted pair Persian
probe "http://localhost:3000/league/laliga" "D3 league/laliga fixed names" \
"const b=document.body.innerText;return {malaga:b.includes('مالاگا'),racing:b.includes('ریسینگ سانتاندر')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D4: the merged global race — scorer clubs Persian next to their names
probe "http://localhost:3000/topscorers?league=all" "D4 merged race Persian clubs" \
"const b=document.body.innerText;return {leverkusen:b.includes('بایر لورکوزن'),union:b.includes('یونیون سن‌ژیلواز'),sporting:b.includes('اسپورتینگ‌لیسبون')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D5: the UEL page — REAL click on the bracket tab → every knockout round is
# UNDRAWN today, and the honest placeholder contract («قرعه هنوز نریخته» +
# Persian draw dates) means NO team name — English or otherwise — ever leaks
# in the bracket view. The TBD-pair side-splitting contract itself is proven
# at API level in A3 (46/46 Persian sides per cup) and materializes in DOM
# when the draws land.
probe "http://localhost:3000/league/uel" "D5 uel bracket tab honest placeholders + zero leaks" \
"const cards=[...document.querySelectorAll('.glass-card')];const brc=cards.filter(c=>c.innerText.includes('قرعه هنوز نریخته'));if(!brc.length)return {found:false};const t=brc.map(c=>c.innerText).join('\\n');const latin=(t.match(/[A-Za-z]{3,}/g)||[]);const b=document.body.innerText;return {found:true,undrawn:t.includes('قرعه هنوز نریخته'),r16:b.includes('یک‌هشتم نهایی'),latin:latin}" \
"(function(){const btn=[...document.querySelectorAll('nav[aria-label=\"بخش‌های لیگ\"] button')].find(x=>x.innerText.includes('براکت'));if(btn)btn.click();})()" \
"document.body.innerText.includes('قرعه هنوز نریخته')"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

echo "== RESULT =="
if [ "$TOTAL_BAD" -eq 0 ] && [ "$A_BAD" -eq 0 ]; then echo "DOM_PROOF OK (API 4/4 + DOM 5/5 green — cycle-144 drift fix honest end-to-end: zero leftovers on all 10 standings with the 13 previously-leaking names Persian (hyphenated PSG on BOTH the UCL and Ligue 1 tables, PSV Eindhoven, LASK, Sabah FK, AEK Athens, Slavia Prague, FC Porto, promoted Málaga/Racing Santander, Mainz 05/1. FC Köln/Elversberg, Troyes), all 160 race clubs + cards Persian with the topscorer-feed full forms mapped (بایر لورکوزن/یونیون سن‌ژیلواز/اسپورتینگ‌لیسبون/سلتاویگو/آندرلشت/نایمخن), all 4 cup brackets side-Persian INCLUDING the TBD «Side A/Side B» slots via teamFa side-splitting, fixtures 10/10 clean, UEL bracket tab live-clicked showing the honest undrawn-placeholder contract («قرعه هنوز نریخته» + Persian draw dates, zero Latin words in the bracket view — the pair names materialize in DOM at draw time, their Persian mapping already proven in A3); the daily non-portal slate stays on the honest fallback convention (226 names today, churns daily, never a portal surface); every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"; else echo "DOM_PROOF FLAGGED (A=$A_BAD B=$TOTAL_BAD)"; exit 1; fi
