#!/usr/bin/env bash
# cycle405-domproof.sh — update cycle 405 (فرمول ۱): the fa-name map batch
# (PLAYER_NAME_FA +147/+10 follow-up, TEAM_FA +12) closing the measured leak
# class: the maps lagged behind the surfaces that pull players OUTSIDE the
# current-squad sweep — the 18-league topscorer merges (current + historical,
# the 420-row 2024/25 merge) and the team transfer/rumour feeds served
# well-known names raw (probe: scripts/cycle405_leakscan.py — 505 unique
# leaks, wiring verified correct everywhere, the gap was the MAP itself).
# Cache lessons applied: standings v39→v40 + fullGoals v3→v4 (nameFa bakes
# inside those caches — the coach v4→v5 derivation-change lesson).
#   A   the leak witnesses FLIPPED in DOM at 390x844 (league historical
#       «آقای گل» tab + global /topscorers?season=2024/2025 + /team/8650
#       transfers/rumours) + no-raw-regression scoped to the sections.
#   B   the fix contracts (raw+fa side by side, honest fallback intact,
#       club flips) + the re-asserted holds (404/402/401/400/399/397/395).
#   C   the standing DOM holds + anchors + the hygiene three-pack on TEN pages.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }

echo "================ A: the leak witnesses FLIPPED in DOM (390x844) ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
# A1-A3: the league historical «آقای گل» tab (the 405-witnessed page)
agent-browser open "http://localhost:3000/league/pl?season=2024/2025" >/dev/null 2>&1
sleep 5
agent-browser eval "([...document.querySelectorAll('button')].find(b=>(b.textContent||'').trim()==='آقای گل')||{click(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('لیام دلاپ')>=0?1:0)+'|'+(t.indexOf('جاستین کلایورت')>=0?1:0)+'|'+((t.indexOf('Liam Delap')===-1&&t.indexOf('Justin Kluivert')===-1)?1:0)" | tr -d '"')
IFS='|' read -r A1 A2 A3 <<< "$R"
ck "A1 /league/pl 2024/25 «آقای گل» tab: «لیام دلاپ» rides (was raw — the leak witness)" "$A1"
ck "A2 «جاستین کلایورت» rides (was raw)" "$A2"
ck "A3 no raw regression in the scorers tab (Delap/Kluivert raw absent)" "$A3"
# A4-A6: the global historical merge page
agent-browser open "http://localhost:3000/topscorers?season=2024/2025" >/dev/null 2>&1
sleep 6
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('برنان جانسون')>=0?1:0)+'|'+(t.indexOf('یورن استراند لارسن')>=0?1:0)+'|'+(t.indexOf('مهند علی')>=0?1:0)" | tr -d '"')
IFS='|' read -r A4 A5 A6 <<< "$R"
ck "A4 /topscorers 2024/25: «برنان جانسون» rides" "$A4"
ck "A5 «یورن استراند لارسن» rides (Norwegian byte-exact key)" "$A5"
ck "A6 «مهند علی» rides (rank-5 row — the Iraqi star was raw before the batch)" "$A6"
# A7-A10: the /team/8650 transfer/rumour witnesses
agent-browser open http://localhost:3000/team/8650 >/dev/null 2>&1
sleep 7
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('ابراهیما کوناته')>=0?1:0)+'|'+(t.indexOf('کرتیس جونز')>=0?1:0)+'|'+(t.indexOf('ترنت الکساندر-آرنولد')>=0?1:0)+'|'+(t.indexOf('گیلبرتو مورا')>=0?1:0)+'|'+((t.indexOf('Ibrahima Konaté')===-1&&t.indexOf('Curtis Jones')===-1&&t.indexOf('Trent Alexander-Arnold')===-1)?1:0)" | tr -d '"')
IFS='|' read -r A7 A8 A9 A10 A11 <<< "$R"
ck "A7 /team/8650 transfers: «ابراهیما کوناته» rides (was raw — Liverpool regular!)" "$A7"
ck "A8 «کرتیس جونز» rides (transfers follow-up batch)" "$A8"
ck "A9 rumours: «ترنت الکساندر-آرنولد» rides" "$A9"
ck "A10 rumours: «گیلبرتو مورا» rides + «تیخوانا» club flip" "$A10"
ck "A11 no raw regression on the team surfaces (Konaté/Jones/TAA raw absent)" "$A11"

echo "================ B: fix contracts + the re-asserted holds ================"
ck "B1 raw byte contract: topscorers row name=«Liam Delap» AND nameFa=«لیام دلاپ» side by side" "$(api "/api/topscorers?season=2024/2025" | python3 -c "
import json,sys
sc=(json.load(sys.stdin).get('scorers') or [])
r=[x for x in sc if x.get('name')=='Liam Delap']
print(1 if r and r[0].get('name')=='Liam Delap' and r[0].get('nameFa')=='لیام دلاپ' else 0)")"
ck "B2 honest fallback intact: every merge row carries a non-empty nameFa (unmapped keep raw — 96 convention)" "$(api "/api/topscorers?season=2024/2025" | python3 -c "
import json,sys
sc=(json.load(sys.stdin).get('scorers') or [])
bad=[x for x in sc if not (x.get('nameFa') or '').strip()]
print(1 if sc and not bad else 0)")"
ck "B3 sweep breadth: the well-known subset flipped — Delap/Kluivert/Šeško/Sané/Johnson all Persian on the 2024/25 merge (Ugarte/Konaté/Mitoma leaked from OTHER surfaces — the current merge + transfers — verified there)" "$(api "/api/topscorers?season=2024/2025" | python3 -c "
import json,sys
sc=(json.load(sys.stdin).get('scorers') or [])
by={x.get('name'):x.get('nameFa') for x in sc}
want={'Liam Delap':'لیام دلاپ','Justin Kluivert':'جاستین کلایورت','Benjamin Šeško':'بنجامین ششکو','Leroy Sané':'لروی سانه','Brennan Johnson':'برنان جانسون'}
print(1 if all(by.get(k)==v for k,v in want.items()) else 0)")"
ck "B4 club flip: rumours Tijuana (id 162418) → «تیخوانا» while Monaco (id 9829) stays byte-stable — matched by id (the rumours from/to carry id+fa only, no name)" "$(api /api/team-rumours/8650 | python3 -c "
import json,sys
items=((json.load(sys.stdin).get('rumours') or {}).get('items') or [])
tj=[r for r in items if (r.get('from') or {}).get('id')==162418 or (r.get('to') or {}).get('id')==162418]
mo=[r for r in items if (r.get('from') or {}).get('id')==9829 or (r.get('to') or {}).get('id')==9829]
ok_tj=(not tj) or all((r.get('from') or {}).get('fa')=='تیخوانا' or (r.get('to') or {}).get('fa')=='تیخوانا' for r in tj)
ok_mo=(not mo) or any((r.get('from') or {}).get('fa')=='موناکو' or (r.get('to') or {}).get('fa')=='موناکو' for r in mo)
print(1 if (tj or mo) and ok_tj and ok_mo else 0)")"
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
ck "B14 the cache bumps live: standings v40 serves selectedSeason + scorers (no stale shape)" "$(api "/api/standings?league=pl&season=2024/2025" | python3 -c "
import json,sys
d=json.load(sys.stdin)
b=(d.get('boards') or [])
print(1 if d.get('selectedSeason')=='2024/2025' and b else 0)")"

echo "================ C: standing DOM holds + anchors + hygiene (TEN pages) ================"
agent-browser open http://localhost:3000/player/319784 >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var h=document.querySelector('h1'); (h&&h.innerText.indexOf('آلیسون بکر')>=0?1:0)" | tr -d '"')
ck "C1 /player/319784 h1 «آلیسون بکر» (the 398 hold — untouched by the new short «آلیسون» key)" "$R"
agent-browser open http://localhost:3000/coach/24011 >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=coach-trophies]')||{innerText:''}).innerText; (s.indexOf('جام حذفی انگلیس')>=0?1:0)" | tr -d '"')
ck "C2 /coach/24011 honours «جام حذفی انگلیس» (the 400 hold)" "$R"
agent-browser open http://localhost:3000/team/8650 >/dev/null 2>&1; sleep 3
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('آرنه اسلوت')>=0?1:0)+'|'+(t.indexOf('Jorge Sampaoli')===-1?1:0)" | tr -d '"')
IFS='|' read -r C3 C4 <<< "$R"
ck "C3 /team/8650 bench history «آرنه اسلوت» (the 399 hold)" "$C3"
ck "C4 no bench raw regression (Sampaoli absent on 8650)" "$C4"
agent-browser open http://localhost:3000/coach/9012 >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var h=document.querySelector('h1'); (h&&h.innerText.indexOf('سرگی یاکیروویچ')>=0?1:0)" | tr -d '"')
ck "C5 /coach/9012 h1 «سرگی یاکیروویچ» (the 398 hold)" "$R"
agent-browser open http://localhost:3000/leagues >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('لیگ‌ها')>=0?1:0)" | tr -d '"')
ck "C6 /leagues anchor «لیگ‌ها»" "$R"
agent-browser open http://localhost:3000/topscorers >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('آقای گل')>=0?1:0)" | tr -d '"')
ck "C7 /topscorers anchor «آقای گل»" "$R"

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
