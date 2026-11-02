#!/usr/bin/env bash
# cycle406-domproof.sh — update cycle 406 (فرمول ۲): the team-kind league
# boards («برترین‌های رسمی فصل», cycle-92) built their rows WITHOUT nameFa —
# the league stats tab rendered RAW club names («Aston Villa», «Paris
# Saint-Germain») while the player-kind rows rode playerFa since cycle-107.
# The 398/402 patrols never opened the «آمار فصل» tab, so the class stayed
# unwitnessed until this cycle's sweep. Fix = one wiring line (the 404/402
# pattern): the team branch now rides teamFa (additive nameFa, honest raw
# fallback) + the standings cache bump v40→v41 (nameFa bakes inside).
#   A   the flip witnesses in DOM at 390x844 (stats tab via a real tab click
#       on /league/ucl + /league/pl) + no-raw-regression scoped to the boards.
#   B   the fix contracts + the re-asserted holds (405/404/402/401/400/399/
#       397/395).
#   C   the standing DOM holds + anchors + the hygiene three-pack on TEN pages.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }

echo "================ A: the flip witnesses in DOM (390x844) ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
# A1-A3: /league/ucl «آمار فصل» tab (the 406-witnessed surface)
agent-browser open http://localhost:3000/league/ucl >/dev/null 2>&1
sleep 5
agent-browser eval "([...document.querySelectorAll('button')].find(b=>(b.textContent||'').trim()==='آمار فصل')||{click(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=league-boards]')||{innerText:''}).innerText; (s.length>0?1:0)+'|'+(s.indexOf('استون‌ویلا')>=0?1:0)+'|'+(s.indexOf('پاری سن‌ژرمن')>=0?1:0)+'|'+((s.indexOf('Aston Villa')===-1&&s.indexOf('Paris Saint-Germain')===-1&&s.indexOf('Liverpool')===-1)?1:0)" | tr -d '"')
IFS='|' read -r A1 A2 A3 A4 <<< "$R"
ck "A1 /league/ucl boards section renders after the «آمار فصل» tab click" "$A1"
ck "A2 FLIP: «استون‌ویلا» rides (was raw Aston Villa — the 406 witness)" "$A2"
ck "A3 FLIP: «پاری سن‌ژرمن» rides" "$A3"
ck "A4 no raw regression inside the boards (Villa/PSG/Liverpool raw absent)" "$A4"
# A5-A6: /league/pl boards
agent-browser open http://localhost:3000/league/pl >/dev/null 2>&1
sleep 5
agent-browser eval "([...document.querySelectorAll('button')].find(b=>(b.textContent||'').trim()==='آمار فصل')||{click(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=league-boards]')||{innerText:''}).innerText; (s.indexOf('منچسترسیتی')>=0?1:0)+'|'+(s.indexOf('آرسنال')>=0?1:0)+'|'+(s.indexOf('برایتون')>=0?1:0)" | tr -d '"')
IFS='|' read -r A5 A6 A7 <<< "$R"
ck "A5 /league/pl boards: «منچسترسیتی» rides (top of «امتیاز فوت‌ماب تیم»)" "$A5"
ck "A6 «آرسنال» rides" "$A6"
ck "A7 «برایتون» rides" "$A7"

echo "================ B: fix contracts + the re-asserted holds ================"
ck "B1 raw byte contract: UCL board row name=«Aston Villa» AND nameFa=«استون‌ویلا» side by side" "$(api "/api/standings?league=ucl" | python3 -c "
import json,sys
bs=(json.load(sys.stdin).get('boards') or [])
hit=[r for b in bs if b.get('kind')=='team' for r in (b.get('rows') or []) if r.get('name')=='Aston Villa']
print(1 if hit and hit[0].get('name')=='Aston Villa' and hit[0].get('nameFa')=='استون‌ویلا' else 0)")"
ck "B2 sweep breadth: every team-board row Persian on ucl/pl/laliga/bundesliga (366 rows)" "$(python3 -c "
import json, subprocess, re
UA='$UA'
tot=bad=0
for lg in ('ucl','pl','laliga','bundesliga'):
    d=json.loads(subprocess.check_output(['curl','-s','-A',UA,'http://localhost:3000/api/standings?league='+lg]))
    for b in (d.get('boards') or []):
        if b.get('kind')!='team': continue
        for r in (b.get('rows') or []):
            tot+=1
            nf=(r.get('nameFa') or '').strip()
            if not nf or re.search(r'[A-Za-z]{2,}', nf): bad+=1
print(1 if tot>300 and bad==0 else 0)")"
ck "B3 player-kind boards unchanged: rows keep nameFa (playerFa) riding" "$(api "/api/standings?league=ucl" | python3 -c "
import json,sys
bs=[b for b in (json.load(sys.stdin).get('boards') or []) if b.get('kind')=='player']
rows=[r for b in bs for r in (b.get('rows') or [])]
ok=[r for r in rows if (r.get('nameFa') or '').strip()]
print(1 if rows and len(ok)==len(rows) else 0)")"
ck "B4 the 405 hold: 2024/25 merge — every row carries non-empty nameFa (honest raw for unmapped)" "$(api "/api/topscorers?season=2024/2025" | python3 -c "
import json,sys
sc=(json.load(sys.stdin).get('scorers') or [])
bad=[x for x in sc if not (x.get('nameFa') or '').strip()]
print(1 if sc and not bad else 0)")"
ck "B5 the 404 hold: 8650 team-stats leaderFa/extrasFa lockstep (BAD=0)" "$(python3 -c "
import json, subprocess
UA='$UA'
bad=0; rows=0
d=json.loads(subprocess.check_output(['curl','-s','-A',UA,'http://localhost:3000/api/team-stats/8650']))
s=(d.get('stats') or {})
for r in (s.get('playerRows') or [])+(s.get('teamRows') or []):
    rows+=1
    if r.get('leader') and not (r.get('leaderFa') or '').strip(): bad+=1
    ex=r.get('extras') or []; ef=r.get('extrasFa')
    if ex and (not ef or len(ef)!=len(ex)): bad+=1
print(1 if rows>0 and bad==0 else 0)")"
ck "B6 the 402 hold: 8650 tenure leagueName=«Premier League» AND leagueFa rides" "$(api /api/team-coaches/8650 | python3 -c "
import json,sys
ts=(json.load(sys.stdin).get('coaches',{}).get('tenures') or [])
r=[t for t in ts if t.get('leagueName')=='Premier League']
print(1 if r and r[0].get('leagueFa')=='لیگ برتر انگلیس' else 0)")"
ck "B7 the 401 hold: player trophies leagueFa never Latin on 319784+361757" "$(python3 -c "
import json, re, subprocess
UA='$UA'
LAT=re.compile(r'[A-Za-z]{2,}')
bad=0; seen=0
for pid in ('319784','361757'):
    d=json.loads(subprocess.check_output(['curl','-s','-A',UA,'http://localhost:3000/api/player/'+pid]))
    tr=((d.get('player') or {}).get('trophies') or [])
    if isinstance(tr, dict): tr=(tr.get('playerTrophies') or [])
    for t in tr:
        lf=t.get('leagueFa')
        if lf is not None:
            seen+=1
            if LAT.search(lf): bad+=1
print(1 if seen>0 and bad==0 else 0)")"
ck "B8 the 400 hold: coach 26630 honours fa rides, zero Latin passthrough (sample)" "$(api /api/coach/26630 | python3 -c "
import json,sys,re
LAT=re.compile(r'[A-Za-z]{2,}')
tr=((json.load(sys.stdin).get('coach') or {}).get('trophies') or [])
if isinstance(tr, dict): tr=(tr.get('playerTrophies') or [])
ok=[t for t in tr if t.get('leagueFa') and not LAT.search(t['leagueFa'])]
print(1 if len(ok)>=1 and len(ok)==len(tr) else 0)")"
ck "B9 the 399 hold: zero fa-less tenures on 8650 + 6706" "$(python3 -c "
import json, subprocess
UA='$UA'
bad=0; seen=0
for tid in ('8650','6706'):
    d=json.loads(subprocess.check_output(['curl','-s','-A',UA,'http://localhost:3000/api/team-coaches/'+tid]))
    ts=((d.get('coaches') or {}).get('tenures')) or []
    for t in ts:
        seen+=1
        if not (t.get('fa') or '').strip(): bad+=1
print(1 if seen>0 and bad==0 else 0)")"
ck "B10 the 397 hold: coachFa(26630)=«آرنه اسلوت» rides /api/coach" "$(api /api/coach/26630 | python3 -c "
import json,sys
print(1 if (json.load(sys.stdin).get('coach') or {}).get('fa')=='آرنه اسلوت' else 0)")"
ck "B11 the 395 hold: /api/team-squad/8650 mixed nameFa=0" "$(api /api/team-squad/8650 | python3 -c "
import json,sys
d=json.load(sys.stdin)
n=0
for g in ((d.get('squad') or {}).get('groups') or []):
    for p in (g.get('players') or []):
        if (p.get('nameFa') or '').strip()==(p.get('name') or '').strip(): n+=1
print(1 if n==0 else 0)")"
ck "B12 the NT contract: 361757 careerSeasons keeps name + nameFa riding (payload witness)" "$(api /api/player/361757 | python3 -c "
import json,sys
cs=((json.load(sys.stdin).get('player') or {}).get('careerSeasons') or [])
ok=cs and len(cs)>20 and cs[20].get('tournaments') and cs[20]['tournaments'][0].get('name')=='UEFA Nations League A' and cs[20]['tournaments'][0].get('nameFa')=='لیگ ملت‌های اروپا — دسته آ'
print(1 if ok else 0)")"
ck "B13 the 399 dual-purpose: Persian query «کلوپ» answers the coach packet byte-exact (percent-encoded)" "$(api "/api/search?q=%DA%A9%D9%84%D9%88%D9%BE" | python3 -c "
import json,sys
cs=(json.load(sys.stdin).get('coaches') or [])
r=[c for c in cs if c.get('name')=='Jürgen Klopp' and c.get('fa')=='یورگن کلوپ']
print(1 if r else 0)")"

echo "================ C: standing DOM holds + anchors + hygiene (TEN pages) ================"
agent-browser open http://localhost:3000/player/319784 >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var h=document.querySelector('h1'); (h&&h.innerText.indexOf('آلیسون بکر')>=0?1:0)" | tr -d '"')
ck "C1 /player/319784 h1 «آلیسون بکر» (the 398 hold)" "$R"
agent-browser open http://localhost:3000/coach/24011 >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=coach-trophies]')||{innerText:''}).innerText; (s.indexOf('جام حذفی انگلیس')>=0?1:0)" | tr -d '"')
ck "C2 /coach/24011 honours «جام حذفی انگلیس» (the 400 hold)" "$R"
agent-browser open http://localhost:3000/team/8650 >/dev/null 2>&1; sleep 3
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('آرنه اسلوت')>=0?1:0)+'|'+(t.indexOf('Jorge Sampaoli')===-1?1:0)+'|'+(t.indexOf('ابراهیما کوناته')>=0?1:0)" | tr -d '"')
IFS='|' read -r C3 C4 C5 <<< "$R"
ck "C3 /team/8650 bench history «آرنه اسلوت» (the 399 hold)" "$C3"
ck "C4 no bench raw regression (Sampaoli absent on 8650)" "$C4"
ck "C5 the 405 hold in DOM: transfers «ابراهیما کوناته» still rides" "$C5"
agent-browser open http://localhost:3000/coach/9012 >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var h=document.querySelector('h1'); (h&&h.innerText.indexOf('سرگی یاکیروویچ')>=0?1:0)" | tr -d '"')
ck "C6 /coach/9012 h1 «سرگی یاکیروویچ» (the 398 hold)" "$R"
agent-browser open http://localhost:3000/leagues >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('لیگ‌ها')>=0?1:0)" | tr -d '"')
ck "C7 /leagues anchor «لیگ‌ها»" "$R"
agent-browser open http://localhost:3000/topscorers >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('آقای گل')>=0?1:0)" | tr -d '"')
ck "C8 /topscorers anchor «آقای گل»" "$R"

for PG in "" "team/8650" "team/6706" "team/8634" "player/319784" "player/361757" "coach/26630" "league/premierleague" "topscorers" "standings"; do
  agent-browser open "http://localhost:3000/$PG" >/dev/null 2>&1
  sleep 2
  ERR=$(agent-browser errors 2>/dev/null | tr -d '"' | tr -d '\n')
  CON=$(agent-browser console 2>/dev/null | grep -ci error)
  SW=$(agent-browser eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
  CW=$(agent-browser eval "document.documentElement.clientWidth" 2>/dev/null | tr -d '"')
  ck "H /$PG page-errors clean (empty or 0)" "$([ -z "$ERR" ] || [ "$ERR" = "0" ] && echo 1 || echo 0)"
  ck "H /$PG console-errors=0" "$([ "$CON" = "0" ] && echo 1 || echo 0)"
  ck "H /$PG scrollW=cw=390" "$([ "$SW" = "$CW" ] && echo 1 || echo 0)"
done

echo "================ result ================"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ]
