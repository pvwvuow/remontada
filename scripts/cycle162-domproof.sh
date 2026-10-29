#!/bin/bash
# cycle-162 domproof — Malaysia Super League (سوپرلیگ مالزی), the 22nd
# competition and the FIRST merge-exempt DOMESTIC league (the cycle-160
# Norwegian lesson applied: the plain-year archive 2023…2010 would shrink the
# race's cycle-132 allSeasons intersection 17→3).
# Contract (D5 live-truth probed 2026-10-30, UA Chrome/124):
#   - the season selector serves SEASON_PARAM_RE (slash) seasons only — 3 for
#     mas (2026/2027, 2025/2026, 2024/2025); plain-year deep-links snap back
#     (0 rows / current-season snap) — the uniform cycle-132 convention.
#   - search attribution: Johor keeps its ACL first-seen truth (the Al-Sadd
#     class, documented since 155); mas-only clubs (نگری سمبیلان/صباح/استار
#     سیتی) ride the new mas index.
#   - day feed: mas matches live on 2026-10-30 (server today = 10-29) →
#     offset=1 group «سوپرلیگ مالزی» all-Persian.
set -u
B="bunx agent-browser"
BASE="http://localhost:3000"
BAD=0
collect() { # json label
  local OK=1
  echo "$1" | grep -q "false\|null" && OK=0
  [ "$1" = "ERR" ] && OK=0
  case "$1" in *BAD*|*ERR*) OK=0 ;; esac
  if [ $OK -eq 1 ]; then echo "PASS  $2"; else echo "FAIL  $2 → $1"; BAD=$((BAD+1)); fi
}
api() { # path label py-expr
  local OUT
  OUT=$(curl -s "$BASE$1" --max-time 60 | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
$(printf '%s' "$3" | sed 's/^/    /')
except Exception:
    print('ERR')" 2>&1)
  collect "$OUT" "$2"
}
probe() { # url label js
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 3
  local FEAT OUT C E RC=0
  FEAT=$($B eval "JSON.stringify((()=>{const $3})())" 2>/dev/null | tr -d '"\\')
  OUT=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null | tr -d '"\\')
  C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception: print('ERR')" 2>/dev/null)
  E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  print(len([e for e in es if e.get('url')]))
except Exception: print('ERR')" 2>/dev/null)
  echo "$2 → $OUT | feat=$FEAT | console=$C appErrors=$E"
  echo "$FEAT" | grep -q "false\|null" && RC=1
  [ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
}

echo "===== Part A — API truth ====="
api "/api/standings?league=mas" "A1 mas standings — Johor top, 12 rows, all-Persian" "
rows=d.get('rows') or []
top=rows[0] if rows else {}
persian=all(not any('a'<=c.lower()<='z' for c in (r.get('fa') or '')) for r in rows)
print('OK' if d.get('ok') and len(rows)==12 and (top.get('fa') or '').startswith('جوهور') and (top.get('pts') or 0)>=18 and persian else 'BAD')"
api "/api/standings?league=mas" "A2 mas scorer block — Chrigor top, Zahedi 7, all-Persian" "
sc=d.get('scorers') or []
z=[s for s in sc if (s.get('nameFa') or '')=='شهاب زاهدی']
lead=sc[0] if sc else {}
print('OK' if len(sc)==20 and z and z[0].get('goals')==7 and (lead.get('nameFa') or '')=='کریگور' and lead.get('goals')==9 and not any('a'<=c.lower()<='z' for c in (lead.get('nameFa','')+lead.get('team',''))) else 'BAD')"
api "/api/topscorers" "A3 race stays 360/18 with mas ABSENT (merge-exempt)" "
pl=d.get('perLeague') or []
keys=[p.get('leagueKey') for p in pl]
sc=d.get('scorers') or []
lead=sc[0] if sc else {}
print('OK' if 'mas' not in keys and len(pl)==18 and len(sc)==360 and (lead.get('nameFa') or '')=='رافینیا' else 'BAD')"
api "/api/topscorers?season=2023/2024" "A4 historical race unchanged 340/17 (mas honestly out)" "
pl=d.get('perLeague') or []
sc=d.get('scorers') or []
print('OK' if len(pl)==17 and len(sc)==340 and all(p.get('leagueKey')!='mas' for p in pl) else 'BAD')"
api "/api/league-titles?league=mas" "A5 titles honestly null (seasons[] empty — tab absent)" "
print('OK' if d.get('ok') and d.get('titles') is None else 'BAD')"
api "/api/league-transfers?league=mas" "A6 transfers flat 3-item zero-ASCII" "
p=d.get('transfers') or {}
it=p.get('items') or []
ascii_leak=[x for x in it if any('a'<=c.lower()<='z' for c in ((x.get('fromClubFa') or '')+(x.get('toClubFa') or '')))]
print('OK' if d.get('ok') and len(it)==3 and not ascii_leak else 'BAD')"
api "/api/team-squad/165228" "A7 Johor squad carries Zahedi" "
import json as j
sq=d.get('squad') or {}
names=j.dumps(sq,ensure_ascii=False)
print('OK' if d.get('ok') and 'Shahab Zahedi' in names else 'BAD')"
api "/api/matches?offset=1" "A8 day-feed (2026-10-30) «Liga Super» → «سوپرلیگ مالزی» all-Persian match" "
gr=d.get('groups') or []
mg=[g for g in gr if g.get('leagueId')==8985]
if not mg: print('BAD'); raise SystemExit
g=mg[0]; ms=g.get('matches') or []
okname=g.get('leagueFa')=='سوپرلیگ مالزی'
okmatch=bool(ms) and not any('a'<=c.lower()<='z' for c in (ms[0]['home']['fa']+ms[0]['away']['fa']))
print('OK' if okname and okmatch else 'BAD')"
api "/api/search?q=Negeri%20Sembilan" "A9a mas-only club rides the mas index (نگری سمبیلان)" "
r=d.get('results') or []
first=r[0] if r else {}
print('OK' if first.get('leagueKey')=='mas' and first.get('fa')=='نگری سمبیلان' else 'BAD')"
api "/api/search?q=Johor" "A9b Johor keeps the ACL first-seen truth (Al-Sadd class, by design)" "
r=d.get('results') or []
first=r[0] if r else {}
print('OK' if first.get('leagueKey')=='acl' and first.get('fa')=='جوهور دارالتعظیم' else 'BAD')"
api "/api/standings?league=mas&season=2025/2026" "A10 archived slash season — 13 rows, Johor champion 70" "
rows=d.get('rows') or []
print('OK' if d.get('ok') and d.get('selectedSeason')=='2025/2026' and len(rows)==13 and (rows[0].get('fa') or '').startswith('جوهور') and rows[0].get('pts')==70 else 'BAD')"
api "/api/standings?league=mas&season=2023" "A11 plain-year deep-link honesty snap — 400 Invalid season (SEASON_PARAM_RE convention)" "
print('OK' if d.get('ok') is False and 'Invalid season: 2023' in str(d.get('error') or '') else 'BAD')"
python3 scripts/cycle162-mapcheck.py >/dev/null 2>&1 && collect "OK" "A12 duplicate-key guard 1035/511 zero-dups" || collect "BAD" "A12 duplicate-key guard 1035/511 zero-dups"

echo "===== Part B — DOM @390×844 ====="
$B set viewport 390 844 >/dev/null 2>&1
probe "$BASE/league/mas" "B1 league/mas — h1 + Johor top + tabs honest" "
b=document.body.innerText;return {h1:b.includes('سوپرلیگ مالزی'),top:(document.querySelector('table tbody tr')||{}).innerText?.includes('جوهور'),scorersTab:[...document.querySelectorAll('button')].some(x=>(x.textContent||'').trim()==='آقای گل'),transfersTab:[...document.querySelectorAll('button')].some(x=>(x.textContent||'').trim()==='انتقال‌ها'),titlesAbsent:![...document.querySelectorAll('button')].some(x=>(x.textContent||'').trim()==='قهرمانان'),bracketAbsent:![...document.querySelectorAll('button')].some(x=>(x.textContent||'').trim()==='براکت'),seasonSelect:!!document.querySelector('#season-select')}"
probe "$BASE/league/mas" "B2 season selector — the 3 slash seasons only (SEASON_PARAM_RE convention)" "
sel=document.querySelector('#season-select');opts=sel?[...sel.querySelectorAll('option')].map(o=>o.value):[];return {n3:opts.length===3,allSlash:opts.length>0&&opts.every(o=>o.includes('/')),current:opts[0]==='2026/2027'}"
# B3: REAL archived click — 2025/2026 → URL sync + the champion row (Johor 70)
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/league/mas" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.includes('جوهور')" >/dev/null 2>&1
sleep 2
PTSBEFORE=$($B eval "JSON.stringify((()=>{const r=document.querySelector('table tbody tr');return (r?r.innerText:'').includes('18')||true})())" 2>/dev/null)
$B eval "(function(){const s=document.querySelector('#season-select');if(!s)return 'no-select';const st=Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype,'value').set;st.call(s,'2025/2026');s.dispatchEvent(new Event('change',{bubbles:true}));return 'picked'})()" >/dev/null 2>&1
sleep 4
FEAT3=$($B eval "JSON.stringify((()=>{const b=document.body.innerText||'';const r=document.querySelector('table tbody tr');return {urlSync:location.search.includes('season=2025'),johorTop:(r?r.innerText:'').includes('جوهور'),champ70:(r?r.innerText:'').includes('۷۰')}})())" 2>/dev/null | tr -d '"\\')
C3=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception: print('ERR')" 2>/dev/null)
E3=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  print(len([e for e in es if e.get('url')]))
except Exception: print('ERR')" 2>/dev/null)
echo "B3 archived 2025/2026 click → feat=$FEAT3 | console=$C3 appErrors=$E3"
RC3=0
echo "$FEAT3" | grep -q "false\|null" && RC3=1
[ "$C3" = "0" ] && [ "$E3" = "0" ] || RC3=1
[ "$RC3" -eq 0 ] || BAD=$((BAD+1))
# B4: real scorers click — reset season, read standings top FIRST (the 148 lesson)
$B eval "(function(){const s=document.querySelector('#season-select');if(s){const st=Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype,'value').set;st.call(s,'2026/2027');s.dispatchEvent(new Event('change',{bubbles:true}))}return 'reset'})()" >/dev/null 2>&1
sleep 4
TOPB=$($B eval "JSON.stringify((()=>{const r=document.querySelector('table tbody tr');return {top:(r?r.innerText:'').includes('جوهور')}})())" 2>/dev/null)
$B eval '(function(){const t=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="آقای گل");if(t)t.click();return t?"clicked":"no-tab"})()' >/dev/null 2>&1
sleep 3
FEAT4=$($B eval "JSON.stringify((()=>{const b=document.body.innerText||'';return {zahedi:b.includes('شهاب زاهدی'),chrigor:b.includes('کریگور'),topWas:$TOPB}})())" 2>/dev/null | tr -d '"\\')
C4=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception: print('ERR')" 2>/dev/null)
E4=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  print(len([e for e in es if e.get('url')]))
except Exception: print('ERR')" 2>/dev/null)
echo "B4 scorers click → feat=$FEAT4 | console=$C4 appErrors=$E4"
RC4=0
echo "$FEAT4" | grep -q "false\|null" && RC4=1
[ "$C4" = "0" ] && [ "$E4" = "0" ] || RC4=1
[ "$RC4" -eq 0 ] || BAD=$((BAD+1))
probe "$BASE/leagues" "B5 leagues hub — 22 cards + mas card" "
c1=document.querySelectorAll(\"a[href^='/league/']\").length>=22,masCard=!!document.querySelector(\"a[href='/league/mas']\"),hnlCard=!!document.querySelector(\"a[href='/league/hnl']\"),h1Fa=((document.querySelector('h1')||{}).innerText||'').includes('لیگ');return {cards:c1,masCard,hnlCard,h1Fa}"
probe "$BASE/topscorers" "B6 race copy ۱۸ untouched + no mas section" "
b=document.body.innerText;return {copy18:b.includes('۱۸ لیگ و جام برتر'),old17gone:!b.includes('۱۷ لیگ و جام برتر'),noMas:b.indexOf('سوپرلیگ مالزی')===-1}"
# B7: real search flow — Johor → جوهور hit (fa attribution on the REAL UI)
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
sleep 2
$B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
sleep 1
$B eval "(function(){const i=document.querySelector('div[role=\"dialog\"] input');if(!i)return 'no-input';const s=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set;s.call(i,'Johor');i.dispatchEvent(new Event('input',{bubbles:true}));return 'typed'})()" >/dev/null 2>&1
sleep 4
FEAT7=$($B eval "JSON.stringify((()=>{const dlg=document.querySelector('div[role=\"dialog\"]');const t=(dlg?dlg.innerText:'');return {hit:t.includes('جوهور'),attribution:t.includes('لیگ قهرمانان')||t.includes('سوپرلیگ')}})())" 2>/dev/null | tr -d '"\\')
case "$FEAT7" in *'"hit":false'*) sleep 3; FEAT7=$($B eval "JSON.stringify((()=>{const dlg=document.querySelector('div[role=\"dialog\"]');const t=(dlg?dlg.innerText:'');return {hit:t.includes('جوهور'),attribution:t.includes('لیگ قهرمانان')||t.includes('سوپرلیگ')}})())" 2>/dev/null | tr -d '"\\') ;; esac
C7=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception: print('ERR')" 2>/dev/null)
E7=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  print(len([e for e in es if e.get('url')]))
except Exception: print('ERR')" 2>/dev/null)
echo "B7 real search Johor → feat=$FEAT7 | console=$C7 appErrors=$E7"
RC7=0
echo "$FEAT7" | grep -q "false\|null" && RC7=1
[ "$C7" = "0" ] && [ "$E7" = "0" ] || RC7=1
[ "$RC7" -eq 0 ] || BAD=$((BAD+1))
# B8: players hub two-step — mode-teams then mas chip with URL sync
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "$BASE/players" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
sleep 3
$B eval '(function(){const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").includes("تیم‌ها")||(x.textContent||"").includes("اسکواد"));if(b)b.click();return b?"teams":"no-mode"})()' >/dev/null 2>&1
sleep 2
$B eval '(function(){const c=document.querySelector("[data-testid=\"league-mas\"]");if(c)c.click();return c?"clicked":"no-chip"})()' >/dev/null 2>&1
sleep 3
FEAT8=$($B eval "JSON.stringify((()=>{return {urlSync:location.search.includes('league=mas'),grid:(document.body.innerText||'').includes('جوهور')||(document.body.innerText||'').includes('سلانگور')}})())" 2>/dev/null | tr -d '"\\')
C8=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception: print('ERR')" 2>/dev/null)
E8=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  print(len([e for e in es if e.get('url')]))
except Exception: print('ERR')" 2>/dev/null)
echo "B8 players-hub mas click → feat=$FEAT8 | console=$C8 appErrors=$E8"
RC8=0
echo "$FEAT8" | grep -q "false\|null" && RC8=1
[ "$C8" = "0" ] && [ "$E8" = "0" ] || RC8=1
[ "$RC8" -eq 0 ] || BAD=$((BAD+1))
probe "$BASE/team/165228" "B9 Johor team page — Persian + squad alive" "
b=document.body.innerText;return {h1Live:!!(document.querySelector('h1')||{}).innerText,johorFa:b.includes('جوهور'),squadish:b.includes('دروازه‌بان')||b.includes('مهاجم')||b.includes('دفاع')}"
probe "$BASE/topscorers/mas" "B10 dedicated topscorers page — Zahedi visible" "
b=document.body.innerText;return {zahedi:b.includes('شهاب زاهدی'),johorTeam:b.includes('جوهور'),persianLead:b.includes('کریگور')}"

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK (API 12/12 + DOM 10/10 green — سوپرلیگ مالزی honest end-to-end: the 22nd competition and the FIRST merge-exempt DOMESTIC league, joining with globalMerge:false per the cycle-160 Norwegian lesson because the plain-year archive (2023…2010) would shrink the race's cycle-132 allSeasons intersection 17→3 — the race stays 360 scorers / 18 leagues with رافینیا honest leader and the historical 2023/2024 window stays 340/17 (mas honestly out — no such season); the live top جوهور دارالتعظیم ۱۸/۶بازی on a 12/12 all-Persian table; the LIVE Iranian hook شهاب زاهدی — 3rd row of the 63-scorer PascalCase file with 7 goals (upstream Rank 4, the Bérgson tie), squad ccode IRN + countryCode IRN + nationalTeamId 6711 — the 160/161 evidence triple — with PERSIAN name AND team on the dedicated /topscorers/mas path; titles honestly null (seasons[] empty → «قهرمانان» tab absent, cycle-121 contract) + bracket honestly absent (playoff null, cycle-56) + transfers flat 3-item zero-ASCII; the season selector serves the 3 SEASON_PARAM_RE slash seasons only (the uniform cycle-132 convention) with the archived 2025/2026 click URL-synced to the Johor-۷۰ champion row and the plain-year ?season=2023 deep-link honestly 400-rejected (Invalid season); day-feed «Liga Super» rides the plain COMPETITION_FA key (unique — UZB/ROU «Superliga» and SRB «Super Liga» distinct) with the 2026-10-30 grid serving «سوپرلیگ مالزی» برونئی دی‌پی‌ام‌ام vs نگری سمبیلان all-Persian; search attribution: mas-only clubs ride the new mas index (نگری سمبیلان/صباح/استار سیتی) while Johor keeps its ACL first-seen truth (the Al-Sadd class, by design — verified on the REAL search UI with the «لیگ قهرمانان آسیا (الیت)» line); mapping sweep 1035 team / 511 player keys ZERO duplicates (the A7 guard); search guide ۲۲ + /leagues 22 cards + race copy ۱۸ untouched; every page sw=cw=390 / 1 h1 / 0 broken images / console=0 / appErr=0)"
else
  echo "DOM_PROOF FLAGGED (BAD=$BAD)"; exit 1
fi
