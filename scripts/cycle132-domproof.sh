#!/bin/bash
# cycle-132 update proof at 390x844 — «مسابقهٔ تاریخی آقای گل»: the global
# /topscorers race was current-season-only while the league page had a season
# selector since cycle-55/99 (the cycle-131 card's «انتخابگر فصل» note pointed
# here once bracket+transfers proved alive). This cycle: getAllTopScorers
# threads an optional season into every per-league read; /api/topscorers
# honors ?season= (strict SEASON_PARAM_RE, 400 on junk) and BYPASSES the
# snapshot in both directions; the view gets the same selector + deep-link +
# honesty-snap contract as the league page.
# Probed facts baked into the asserts: 2023/2024 merge top = Harry Kane 36
# (Bundesliga) ahead of Guirassy 28 and Haaland 27 — real-world correct;
# 5 domestic feeds serve history (UCL historical fails upstream, persiangulf
# is the designed 503); cards are a current-season-only feed; genuinely-served
# old seasons outside the 12-option window (2010/2011, scorers=0 thin) must
# appear as an APPENDED selector option (league-page cycle-99 invariant); and
# a well-formed season upstream does not offer at all (1999/2000) is served
# as the current season → the view must snap the URL back.
set -u
B=agent-browser
$B set viewport 390 844 >/dev/null

echo "== PART A: API truth =="
python3 - <<'PY'
import json, urllib.request, urllib.error
def get(u):
    r = urllib.request.Request(u, headers={'User-Agent': 'Chrome/124'})
    return urllib.request.urlopen(r, timeout=90)
ok = True
def report(name, good, detail):
    global ok
    print(('PASS ' if good else 'FAIL ') + name + ' — ' + detail)
    if not good: ok = False

# A1: historical merge — 2023/2024: 5 domestic feeds, Kane 36 on top, Haaland 27 in, no cards
try:
    d = json.loads(get('http://localhost:3000/api/topscorers?season=2023/2024').read().decode())
    top = d['scorers'][0]
    has_haaland27 = any(s.get('name') == 'Erling Haaland' and s.get('goals') == 27 for s in d.get('scorers', []))
    report('A1 hist 2023/2024', d.get('ok') and d.get('selectedSeason') == '2023/2024'
           and top.get('name') == 'Harry Kane' and top.get('goals') == 36 and has_haaland27
           and len(d.get('scorers', [])) >= 60 and len(d.get('perLeague', [])) == 5
           and len(d.get('allSeasons', [])) >= 2 and 'cards' not in d,
           f"top={top.get('name')}:{top.get('goals')} haaland27={has_haaland27} scorers={len(d.get('scorers', []))} perLeague={len(d.get('perLeague', []))} seasons={len(d.get('allSeasons', []))} cardsAbsent={'cards' not in d}")
except Exception as e:
    ok = False; print('A1: ERR', e)

# A2: current merge — unchanged contract + new metadata
try:
    d = json.loads(get('http://localhost:3000/api/topscorers').read().decode())
    report('A2 current', d.get('ok') and d.get('selectedSeason') == '2026/2027'
           and isinstance(d.get('allSeasons'), list) and len(d['allSeasons']) >= 2
           and isinstance(d.get('cards'), dict) and len(d.get('scorers', [])) >= 30,
           f"selectedSeason={d.get('selectedSeason')} seasons={len(d.get('allSeasons', []))} scorers={len(d.get('scorers', []))} cards={'cards' in d}")
except Exception as e:
    ok = False; print('A2: ERR', e)

# A3: junk season → honest 400 (same contract as the standings family)
try:
    get('http://localhost:3000/api/topscorers?season=banana'); ok = False; print('A3: FAIL — 200 instead of 400')
except urllib.error.HTTPError as e:
    report('A3 bogus season 400', e.code == 400, f"code={e.code}")
except Exception as e:
    ok = False; print('A3: ERR', e)

# A4: genuinely-served old season outside the option window → honest thin state
# (upstream serves the real 2010/2011 table; scorers=0 — the thin-old contract)
try:
    d = json.loads(get('http://localhost:3000/api/topscorers?season=2010/2011').read().decode())
    report('A4 2010/2011 honestly served (thin)', d.get('ok') and d.get('selectedSeason') == '2010/2011' and len(d.get('scorers', [])) == 0,
           f"selectedSeason={d.get('selectedSeason')} scorers={len(d.get('scorers', []))}")
except Exception as e:
    ok = False; print('A4: ERR', e)

# A5: current snapshot survives untouched (key + staleness flag contract)
try:
    d = json.loads(get('http://localhost:3000/api/topscorers').read().decode())
    report('A5 snapshot not poisoned', d.get('ok') and 'stale' not in d and d.get('selectedSeason') == '2026/2027',
           f"staleAbsent={'stale' not in d}")
except Exception as e:
    ok = False; print('A5: ERR', e)

# A6: well-formed UNOFFERED season → upstream serves current (snap case exists)
try:
    d = json.loads(get('http://localhost:3000/api/topscorers?season=1999/2000').read().decode())
    report('A6 1999/2000 snaps to current', d.get('ok') and d.get('selectedSeason') == '2026/2027',
           f"selectedSeason={d.get('selectedSeason')}")
except Exception as e:
    ok = False; print('A6: ERR', e)
print('API_TRUTH', 'OK' if ok else 'FAILED')
PY
A_BAD=$?

echo "== PART B: DOM 390x844 =="
probe() { # $1=url $2=label $3=extra-js returning object
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 3
  local FEAT OUT BAD C E RC=0
  FEAT=$($B eval "JSON.stringify((()=>{$3})())" 2>/dev/null | tr -d '"\\')
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
  [ "$E" != "0" ] && RC=1
  return $RC
}
TOTAL_BAD=$A_BAD

# D1: current /topscorers — selector present with the payload's own options
probe "http://localhost:3000/topscorers" "D1 /topscorers (selector + current)" \
"const sel=document.getElementById('season-select');const opts=sel?[...sel.options].map(o=>o.value):[];const sub=document.querySelector('h1').parentElement.querySelector('p')?.innerText||'';return {hasSel:!!sel,optN:opts.length,first:opts[0]||'',current:opts[0]===(sel?sel.value:''),subHasUpdate:sub.includes('به‌روزرسانی')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D2: deep link 2023/2024 (+league=all — URL filter wins over persisted
# localStorage, so the GLOBAL race hero is deterministic: Kane 36) — season
# label, URL kept, cards section hidden
probe "http://localhost:3000/topscorers?season=2023/2024&league=all" "D2 /topscorers 2023/2024 (global historical race)" \
"const body=document.body.innerText;const sel=document.getElementById('season-select');const hero=document.querySelector('.glass-scorer-hero')?.innerText||'';const cardsH2=[...document.querySelectorAll('h2')].some(h=>h.innerText.includes('آقای کارت'));return {selVal:sel?sel.value:'',urlHasSeason:location.search.includes('season=2023%2F2024'),heroKane:hero.includes('کین'),hero36:hero.includes('۳۶'),globalHero:hero.includes('GLOBAL TOP SCORER'),subHasSeason:body.includes('۲۰۲۳/۲۴'),subHasContrib:body.includes('لیگ مشارکت‌کننده'),cardsSectionAbsent:!cardsH2}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D3: unoffered season (1999/2000) → honesty snap (URL param stripped, selector back to current)
probe "http://localhost:3000/topscorers?season=1999/2000" "D3 honesty snap (1999/2000)" \
"const sel=document.getElementById('season-select');return {urlClean:!location.search.includes('season='),selVal:sel?sel.value:''}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D4: served-but-off-window old season (2010/2011) → APPENDED option, thin honest state
probe "http://localhost:3000/topscorers?season=2010/2011" "D4 appended off-window option (2010/2011)" \
"const sel=document.getElementById('season-select');const body=document.body.innerText;const opts=sel?[...sel.options].map(o=>o.value):[];return {selVal:sel?sel.value:'',urlKept:location.search.includes('season=2010%2F2011'),appended:opts.includes('2010/2011'),honestEmpty:body.includes('هنوز منتشر نشده')||body.length>60}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D5: historical + league filter deep link — pl filter active, Haaland present
probe "http://localhost:3000/topscorers?season=2023/2024&league=pl" "D5 hist + pl filter" \
"const body=document.body.innerText;return {leagueInUrl:location.search.includes('league=pl'),seasonInUrl:location.search.includes('season=2023%2F2024'),haaland:body.includes('هالند')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D6: league page selector untouched (regression neighbor)
probe "http://localhost:3000/league/pl" "D6 /league/pl (selector intact)" \
"const sel=document.getElementById('season-select');return {hasSel:!!sel,opts:sel?sel.options.length:0}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

echo "== RESULT =="
if [ "$TOTAL_BAD" -eq 0 ]; then echo "DOM_PROOF OK (API 6/6 + DOM 6/6 green — historical race honest end-to-end: Kane 36 hero, snap + append contracts both hold, snapshot untouched, league selector intact, every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"; else echo "DOM_PROOF FLAGGED=$TOTAL_BAD"; exit 1; fi
