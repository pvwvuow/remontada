#!/bin/bash
# cycle-141 update proof at 390x844 — «لیگ قهرمانان آسیا (الیت)، دهمین مسابقه
# با پارسر جدول composite». Probed live UA Chrome/124 2026-10-29: the day-feed
# ids 943983/943984 (AFC CL Elite West/East) answer null as league pages — the
# real page id surfaced via matchDetails Tournament.parentLeagueId = 525 (the
# same crack UEL used in cycle-139). The feed is the FIRST composite table the
# portal has ever served (data.composite = true, data.tables[] = West 16 +
# East 16, data.table empty) — the cycle-141 getStandings extension flattens
# West→East preserving each region's own idx (both regional leaders stay rank
# 1) and records `groups` so the UI draws the region section rows. Seasons:
# only 4 modern slash-format entries → globalMerge: false (the UECL flag) so
# the cycle-132 race window stays byte-identical. The honesty marker for
# echo-less feeds is overview.selectedSeason (probed: a bogus 2019/2020
# request silently serves the current table and the marker says 2026/2027 —
# the cycle-99 snap contract survives on a different field). Iranian angle:
# Esteghlal + Tractor ride the live West table. Proof below: 32/32 Persian
# rows with 2 region sections, merge invariants byte-identical (8 participants
# / 12-season window / 160 scorers / 10 cards), true historical 2025/2026
# table (24 rows, Al Hilal top), bogus-season honesty marker + strict 400 on
# plain years, dedicated /topscorers/acl (Rahimi 5 goals), 44-title history
# topped by 2025/2026 Al Ahli, search attribution (الهلال → acl, استقلال →
# persiangulf by the domestic-first dedup), /leagues tenth card, /players
# acl grid, season selector change → URL + Al Hilal view.
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

# A1: the live composite table — 32 rows (West 16 + East 16) flattened with
# BOTH regional leaders at rank 1, `groups` segments recorded, every fa a
# real Persian name (zero raw-English leftovers), the q1of8finals legend,
# the honest 4-season window and the overview-derived current label
try:
    d = json.loads(get('http://localhost:3000/api/standings?league=acl').read().decode())
    rows = d.get('rows') or []
    gr = d.get('groups') or []
    leftovers = [r.get('name') for r in rows if r.get('fa') == r.get('name')]
    est = next((r for r in rows if r.get('teamId') == 101614), None)
    tra = next((r for r in rows if r.get('name') == 'Tractor'), None)
    topw = next((r for r in rows if r.get('teamId') == 102117), None)  # Al-Ain
    east0 = rows[16] if len(rows) > 16 else None
    leg = [l.get('fa') for l in (d.get('legend') or [])]
    seas = d.get('allSeasons') or []
    report('A1 acl composite 32 rows + groups + fa + legend',
           d.get('ok') is True and len(rows) == 32 and not leftovers
           and gr == [{'fa': 'منطقهٔ غرب', 'count': 16}, {'fa': 'منطقهٔ شرق', 'count': 16}]
           and rows[0].get('idx') == 1 and east0 is not None and east0.get('idx') == 1
           and est is not None and est.get('fa') == 'استقلال'
           and tra is not None and tra.get('fa') == 'تراکتور'
           and topw is not None and topw.get('fa') == 'العین'
           and 'صعود به یک‌هشتم نهایی' in leg
           and len(seas) == 4 and seas[0] == '2026/2027' and seas[-1] == '2023/2024'
           and d.get('selectedSeason') == '2026/2027',
           f"rows={len(rows)} groups={gr} leftovers={leftovers} est={est.get('fa') if est else None} "
           f"tra={tra.get('fa') if tra else None} eastIdx={east0.get('idx') if east0 else None} "
           f"legend={leg} seasons={seas} sel={d.get('selectedSeason')}")
except Exception as e:
    ok = False; print('A1: ERR', e)

# A2: THE merge invariants — acl joins with globalMerge: false, so the race
# stays 8 participants and the cycle-132 window stays byte-identical
try:
    d = json.loads(get('http://localhost:3000/api/topscorers').read().decode())
    pl = [x.get('leagueKey') for x in (d.get('perLeague') or [])]
    seas = d.get('allSeasons') or []
    report('A2 merge invariants intact with acl exempt', d.get('ok') is True
           and len(pl) == 8 and 'acl' not in pl and 'uel' in pl and 'ucl' in pl
           and len(seas) == 12 and seas[0] == '2026/2027' and seas[-1] == '2015/2016'
           and len(d.get('scorers') or []) == 160
           and len((d.get('cards') or {}).get('yellow') or []) == 10,
           f"pl={pl} window={seas[:1]}..{seas[-1:]} scorers={len(d.get('scorers') or [])}")
except Exception as e:
    ok = False; print('A2: ERR', e)

# A3: the TRUE historical 2025/2026 table — 24 rows (12 per region), Al Hilal
# tops the West, the marker echoes the REQUESTED season (overview marker)
try:
    d = json.loads(get('http://localhost:3000/api/standings?league=acl&season=2025%2F2026').read().decode())
    rows = d.get('rows') or []
    gr = d.get('groups') or []
    hilal = next((r for r in rows if r.get('fa') == 'الهلال'), None)
    report('A3 acl historical 2025/2026 real table', d.get('ok') is True
           and len(rows) == 24 and gr == [{'fa': 'منطقهٔ غرب', 'count': 12}, {'fa': 'منطقهٔ شرق', 'count': 12}]
           and hilal is not None and hilal.get('idx') == 1
           and d.get('selectedSeason') == '2025/2026',
           f"rows={len(rows)} groups={gr} hilalIdx={hilal.get('idx') if hilal else None} sel={d.get('selectedSeason')}")
except Exception as e:
    ok = False; print('A3: ERR', e)

# A4: the echo-less honesty contract — a well-formed season the cup does not
# offer (2019/2020) silently serves the CURRENT table and the marker says
# 2026/2027 (the cycle-99 snap survives on overview.selectedSeason), while a
# plain-year season ("2020") is rejected by the strict SEASON_PARAM_RE guard
try:
    d = json.loads(get('http://localhost:3000/api/standings?league=acl&season=2019%2F2020').read().decode())
    e = get('http://localhost:3000/api/standings?league=acl&season=2020')
    report('A4 bogus-season marker + plain-year 400', d.get('ok') is True
           and d.get('selectedSeason') == '2026/2027' and len(d.get('rows') or []) == 32
           and e.code == 400,
           f"bogusSel={d.get('selectedSeason')} rows={len(d.get('rows') or [])} plainYear={e.code}")
except Exception as e:
    ok = False; print('A4: ERR', e)

# A5: the dedicated /topscorers/acl route (reads getStandings directly — the
# merge exemption must NOT touch it): full list, live leader Houssine Rahimi
try:
    d = json.loads(get('http://localhost:3000/api/topscorers/acl').read().decode())
    sc = d.get('scorers') or []
    top = sc[0] if sc else {}
    report('A5 acl dedicated scorers live', d.get('ok') is True and len(sc) >= 15
           and 'Rahimi' in (top.get('name') or '') and top.get('goals', 0) >= 4
           and bool(top.get('nameFa') or top.get('name')),
           f"rows={len(sc)} top={top.get('name')} goals={top.get('goals')} fa={top.get('nameFa')}")
except Exception as e:
    ok = False; print('A5: ERR', e)

# A6: 44-title history (newest 2025/2026 Al Ahli) + search attribution:
# الهلال rides the acl index, استقلال keeps the domestic persiangulf
# attribution (the first-seen dedup)
try:
    t = json.loads(get('http://localhost:3000/api/league-titles?league=acl').read().decode())
    items = (t.get('titles') or {}).get('items') or []
    q = urllib.parse.quote('الهلال')
    s = json.loads(get(f'http://localhost:3000/api/search?q={q}').read().decode())
    rs = s.get('results') or s.get('teams') or []
    hilal = next((r for r in rs if r.get('leagueKey') == 'acl'), None)
    q2 = urllib.parse.quote('استقلال')
    s2 = json.loads(get(f'http://localhost:3000/api/search?q={q2}').read().decode())
    rs2 = s2.get('results') or s2.get('teams') or []
    est = next((r for r in rs2 if r.get('teamId') == 101614), None)
    report('A6 titles 44 + hilal→acl esteghlal→persiangulf', t.get('ok') is True
           and len(items) >= 40 and items[0].get('season') == '2025/2026'
           and items[0].get('championFa') == 'الاهلی'
           and hilal is not None and est is not None and est.get('leagueKey') == 'persiangulf',
           f"titles={len(items)} top={items[0].get('season') if items else '-'}"
           f"/{items[0].get('championFa') if items else '-'} hilal={hilal.get('leagueKey') if hilal else None} "
           f"esteghlal={est.get('leagueKey') if est else None}")
except Exception as e:
    ok = False; print('A6: ERR', e)

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

# D1: the ACL league page — Persian h1, BOTH region section rows, Iranian
# clubs in Persian, legend present; bracket AND transfers tabs honestly
# ABSENT (playoff null until the knockout draw — the cycle-56/legend-56
# contract, transfers.data null — cups), titles tab present
probe "http://localhost:3000/league/acl" "D1 league/acl composite page" \
"const h1=(document.querySelector('h1')||{}).innerText||'';const b=document.body.innerText;const nav=[...(document.querySelector('nav[aria-label=\"بخش‌های لیگ\"]')||{querySelectorAll:()=>[]}).querySelectorAll('button')].map(x=>x.innerText);const gr=[...document.querySelectorAll('[data-testid=standings-group-row]')].map(x=>x.innerText);return {h1:h1,west:gr.includes('منطقهٔ غرب'),east:gr.includes('منطقهٔ شرق'),esteghlal:b.includes('استقلال'),tractor:b.includes('تراکتور'),legend:b.includes('صعود به یک‌هشتم نهایی'),noBracket:!nav.includes('براکت'),noTransfers:!nav.includes('انتقال‌ها'),titles:nav.includes('قهرمانان')}" \
"" "[...document.querySelectorAll('[data-testid=standings-group-row]')].length>=2"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D2: a REAL change event on the season select → 2025/2026 → the true
# historical table (Al Hilal top of the West) + the URL carries the season
probe "http://localhost:3000/league/acl" "D2 season selector → 2025/2026" \
"const b=document.body.innerText;const u=decodeURIComponent(window.location.search);return {hilalTop:b.includes('الهلال'),urlSeason:u.includes('season=2025/2026'),rows12:b.includes('۱۲')}" \
"(function(){const sel=document.querySelector('#season-select');if(!sel)return;const set=Object.getOwnPropertyDescriptor(window.HTMLSelectElement.prototype,'value').set;set.call(sel,'2025/2026');sel.dispatchEvent(new Event('change',{bubbles:true}));})()" \
"document.body.innerText.includes('الهلال')"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D3: the global race page — the «۸ لیگ و جام برتر» copy stays honest AND the
# merge-exempt cup does NOT appear as a race chip
probe "http://localhost:3000/topscorers?league=all" "D3 race 8 copy + no acl chip" \
"const b=document.body.innerText;return {copy8:b.includes('۸ لیگ و جام برتر'),noAclChip:!b.includes('لیگ قهرمانان آسیا')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D4: the dedicated /topscorers/acl page (new SSG path) — live scorer rows
probe "http://localhost:3000/topscorers/acl" "D4 topscorers/acl page" \
"const h1=(document.querySelector('h1')||{}).innerText||'';const b=document.body.innerText;return {h1:h1,rahimi:b.includes('رحیمی')||b.includes('Rahimi'),ok:h1.includes('لیگ قهرمانان آسیا')}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D5: the leagues index — the tenth competition card with its deep link
probe "http://localhost:3000/leagues" "D5 leagues index card" \
"const b=document.body.innerText;const l=[...document.querySelectorAll('a')].some(a=>(a.getAttribute('href')||'')==='/league/acl');return {fa:b.includes('لیگ قهرمانان آسیا'),link:l}"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

# D6: the players hub all-teams mode deep-linked to acl — the 32-team grid
# renders Persian names from both regions with the URL kept
probe "http://localhost:3000/players?league=acl" "D6 players hub acl grid" \
"const b=document.body.innerText;const u=window.location.search;return {hilal:b.includes('الهلال'),shanghai:b.includes('شانگهای پورت'),esteghlal:b.includes('استقلال'),urlKept:u.includes('league=acl')}" \
"" "document.body.innerText.includes('الهلال')"
[ $? -eq 0 ] || TOTAL_BAD=$((TOTAL_BAD+1))

echo "== RESULT =="
if [ "$TOTAL_BAD" -eq 0 ] && [ "$A_BAD" -eq 0 ]; then echo "DOM_PROOF OK (API 6/6 + DOM 6/6 green — لیگ قهرمانان آسیا (الیت) honest end-to-end: the first COMPOSITE table flattened West 16 + East 16 with both regional leaders at rank 1 and Persian region section rows, 32/32 Persian names (استقلال/تراکتور live in the West), merge invariants byte-identical with the cup exempt (8 participants / 12-season window / 160 scorers / 10 cards), true historical 2025/2026 table (24 rows, Al Hilal top, marker echoes the request), bogus-season honesty marker 2026/2027 + plain-year 400, dedicated /topscorers/acl (Rahimi), 44-title history topped by 2025/2026 الاهلی, الهلال→acl + استقلال→persiangulf search attribution, «۸ لیگ و جام برتر» copy intact with no acl race chip, /leagues tenth card, /players acl grid; every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"; else echo "DOM_PROOF FLAGGED (A=$A_BAD B=$TOTAL_BAD)"; exit 1; fi
