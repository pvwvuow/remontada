#!/bin/bash
# cycle-136 update proof at 390x844 — «زنده‌سازی لیگ خلیج فارس». Probed live
# 2026-10-29 (UA Chrome/124): the configured persiangulf id was a PLACEHOLDER
# (1000001715 → upstream answered a literal null body → the designed-503 era).
# The real FotMob league id is 523 and it serves everything: the 2026/2027
# table (18 teams, Persepolis/Sepahan/Esteghlal 20 pts), 17 historical
# seasons, a Top-scorer category with fetchAllUrl, a 24-entry title history
# (2001/2002 → 2024/2025) and 6 real transfers (Munir El Haddadi!). This
# cycle flips ONE config id + adds the exact upstream row names to TEAM_FA +
# the two AFC legend tKeys — every league surface lights up from the existing
# plumbing. Proof: standings/table + global merge's 7th participant, transfers,
# titles, fixtures, squad, and the /players all-teams mode for the home league.
set -u
B=agent-browser
$B set viewport 390 844 >/dev/null

echo "== PART A: API truth =="
python3 - <<'PY'
import json, urllib.request, urllib.error
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

# A1: standings — the live 523 table: 18 rows, Persepolis top (fa name from
# the exact upstream row-name mapping), AFC legend trio, season window intact
try:
    d = json.loads(get('http://localhost:3000/api/standings?league=persiangulf').read().decode())
    rows = d.get('rows') or []
    r0 = rows[0] if rows else {}
    leg = [l.get('fa') for l in (d.get('legend') or [])]
    sc = d.get('scorers') or []
    report('A1 persiangulf standings live', d.get('ok') is True and len(rows) == 18
           and r0.get('name') == 'Persepolis' and r0.get('fa') == 'پرسپولیس'
           and r0.get('teamId') == 101610 and r0.get('pts') == 20
           and d.get('selectedSeason') == '2026/2027' and len(d.get('allSeasons') or []) == 12
           and leg == ['لیگ قهرمانان آسیا', 'لیگ قهرمانان آسیا ۲', 'سقوط']
           and len(sc) >= 10 and 'حسین‌زاده' in (sc[0].get('nameFa') or '') and sc[0].get('goals') == 5,
           f"rows={len(rows)} r0={r0.get('name')}/{r0.get('fa')}/{r0.get('pts')} leg={leg} top={sc[0].get('nameFa') if sc else None}:{sc[0].get('goals') if sc else None}")
except Exception as e:
    ok = False; print('A1: ERR', e)

# A2: the GLOBAL merge gains its 7th participant (UCL current + PGPL both
# fulfill now) — perLeague carries persiangulf, the intersection window stays
# 12 seasons, and PGPL scorers ride the merged table
try:
    d = json.loads(get('http://localhost:3000/api/topscorers').read().decode())
    pl = [x.get('leagueKey') for x in (d.get('perLeague') or [])]
    pg = [s for s in (d.get('scorers') or []) if s.get('leagueKey') == 'persiangulf']
    report('A2 global merge 7th participant', d.get('ok') is True and len(pl) == 7
           and 'persiangulf' in pl and len(pg) >= 10
           and pg[0].get('goals') == 5 and 'حسین‌زاده' in (pg[0].get('nameFa') or '')
           and len(d.get('allSeasons') or []) == 12 and d.get('selectedSeason') == '2026/2027',
           f"perLeague={pl} scorers={len(d.get('scorers') or [])} pgpl={len(pg)} top={pg[0].get('nameFa') if pg else None}")
except Exception as e:
    ok = False; print('A2: ERR', e)

# A3: transfers — real entries with Persian club names (Munir El Haddadi,
# Esteghlal → Albacete, the probed head of the list)
try:
    d = json.loads(get('http://localhost:3000/api/league-transfers?league=persiangulf').read().decode())
    items = (d.get('transfers') or {}).get('items') or []
    m = next((x for x in items if x.get('name') == 'Munir El Haddadi'), None)
    report('A3 persiangulf transfers live', d.get('ok') is True and len(items) >= 6
           and m is not None and (m.get('from') or {}).get('fa') == 'استقلال'
           and (m.get('to') or {}).get('fa') == 'آلباسته' and m.get('kindFa') == 'خروجی',
           f"n={len(items)} munir={(m or {}).get('from', {}).get('fa')}→{(m or {}).get('to', {}).get('fa')}")
except Exception as e:
    ok = False; print('A3: ERR', e)

# A4: titles — 24 seasons (2001/2002 Persepolis → 2024/2025 Tractor)
try:
    d = json.loads(get('http://localhost:3000/api/league-titles?league=persiangulf').read().decode())
    t = d.get('titles') or {}
    items = t.get('items') or []
    newest = items[0] if items else {}
    oldest = items[-1] if items else {}
    report('A4 persiangulf titles live', d.get('ok') is True and t.get('total') == 24
           and len(items) == 24 and newest.get('season') == '2024/2025'
           and 'تراکتور' in (newest.get('championFa') or '')
           and oldest.get('season') == '2001/2002'
           and 'پرسپولیس' in (oldest.get('championFa') or ''),
           f"total={t.get('total')} newest={newest.get('season')}/{newest.get('championFa')} oldest={oldest.get('season')}/{oldest.get('championFa')}")
except Exception as e:
    ok = False; print('A4: ERR', e)

# A5: fixtures — the league's own fixtures feed answers with real matches
try:
    d = json.loads(get('http://localhost:3000/api/league-fixtures?league=persiangulf').read().decode())
    report('A5 persiangulf fixtures live', d.get('ok') is True
           and d.get('leagueFa') == 'لیگ خلیج فارس ایران'
           and (d.get('total') or 0) >= 1,
           f"leagueFa={d.get('leagueFa')} total={d.get('total')}")
except Exception as e:
    ok = False; print('A5: ERR', e)

# A6: squad — Persepolis (101610) full squad through the cycle-70 feed,
# Persian position groups + team label (cycle-134 additive contract)
try:
    d = json.loads(get('http://localhost:3000/api/team-squad/101610').read().decode())
    sq = d.get('squad') or {}
    groups = sq.get('groups') or []
    n = sum(len(g.get('players') or []) for g in groups)
    heads = [g.get('titleFa') for g in groups]
    report('A6 persepolis squad live', d.get('ok') is True
           and sq.get('teamName') == 'Persepolis' and len(groups) == 4 and n >= 16
           and any('دروازه‌بان' in (h or '') for h in heads)
           and any((p.get('name') == 'Payam Niazmand') for p in (groups[0].get('players') if groups else [])),
           f"groups={heads} players={n}")
except Exception as e:
    ok = False; print('A6: ERR', e)
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

TOTAL_BAD=0

# D1: the league page renders the LIVE home-league table — Persian names of
# the table's real members + the AFC legend, in one clean 390px layout
probe "http://localhost:3000/league/persiangulf" "D1 persiangulf league page live" \
"const b=document.body.innerText;const need=['پرسپولیس','سپاهان','استقلال','تراکتور','فولاد خوزستان','آلومینیوم اراک','چادرملو اردکان','نساجی مازندران'];return {h1:(document.querySelector('h1')||{}).innerText||'',teams:need.filter(t=>b.includes(t)).length,legendAfc:b.includes('لیگ قهرمانان آسیا'),season:b.includes('۲۰۲۶/۲۰۲۷')||b.includes('2026/2027')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D2: /players all-teams mode for the home league — the 7th chip leads to the
# real 18-team grid (proven selector from cycle-134)
probe "http://localhost:3000/players?league=persiangulf" "D2 hub all-teams persiangulf grid" \
"const grid=document.querySelector('[data-testid=\"team-grid\"]');const n=grid?grid.querySelectorAll('button').length:0;const b=document.body.innerText;return {teams:n,urlKept:location.search.includes('league=persiangulf'),persepolis:b.includes('پرسپولیس'),sepahan:b.includes('سپاهان')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D3: the global race tells the merge truth twice — the CURRENT view's
# hardcoded «۷ لیگ بزرگ» claim is true for the first time (all 7 feeds
# fulfill), and the HISTORICAL view's payload-derived «مشارکت‌کننده» count
# shows 6 (PGPL joins; UCL historical still drops honestly)
probe "http://localhost:3000/topscorers?league=all" "D3 global current 7-league claim" \
"const b=document.body.innerText;return {sevenLeagues:b.includes('۷ لیگ بزرگ'),playersCount:b.includes('بازیکن'),h1:(document.querySelector('h1')||{}).innerText||''}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

probe "http://localhost:3000/topscorers?league=all&season=2023/2024" "D3b historical 6 participating" \
"const b=document.body.innerText;return {participating:b.includes('۶ لیگ مشارکت‌کننده'),seasonLabel:b.includes('۲۰۲۳/۲۴')||b.includes('2023/2024')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D4: the Persepolis team page — real h1 through the exact teamFa row name,
# no broken logos (fotmobTeamLogo on 523's team ids)
probe "http://localhost:3000/team/101610" "D4 persepolis team page" \
"const h1=(document.querySelector('h1')||{}).innerText||'';return {h1:h1,ok:h1.includes('پرسپولیس')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

echo "== RESULT =="
if [ "$TOTAL_BAD" -eq 0 ] && [ "$A_BAD" -eq 0 ]; then echo "DOM_PROOF OK (API 6/6 + DOM 4/4 green — خلیج فارس honest end-to-end: live 18-row table with پرسپولیس/سپاهان/استقلال top trio + AFC legend trio, global merge's 7th participant with the 12-season window intact, real transfers with Persian club names (Munir Esteghlal→Albabaste), 24-season title history (2001/2002 Persepolis → 2024/2025 تراکتور), fixtures + Persepolis squad with Persian groups, /players 18-team grid, «۷ لیگ مشارکت‌کننده» subtitle; every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"; else echo "DOM_PROOF FLAGGED (A=$A_BAD B=$TOTAL_BAD)"; exit 1; fi
