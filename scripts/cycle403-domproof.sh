#!/usr/bin/env bash
# cycle403-domproof.sh — bug-hunt cycle 403 (فرمول ۴): page patrol + 390x844
# verification. Bug-hunt cycles DOCUMENT, the fix belongs to cycle-404 (فیکس).
# The documented class: the team season-stats section («آمار برتر فصل»,
# cycle-76/77) predates the 395-402 fa wave — its PERSONAL names are all raw
# upstream Latin while its CATEGORY labels are Persian:
#   (a) team-row extras («صدر:») render the league leader team name raw
#       (witness: «Manchester City ۷٫۲۱» on /team/8650) — the gap the 402 card
#       already flagged, now witnessed in full class;
#   (b) player-row leader names render raw («Alexander Isak», team-view:1007
#       renders r.leader with no fa attempt);
#   (c) player-row extras («سپس:») render raw teammate names.
# The map coverage for a 404 fix already exists in-house (TEAM_FA via teamId +
# byte-exact PLAYER_NAME_FA) — no new upstream surface needed.
#   A   the witnesses in DOM at 390x844 (current state — the bug-hunt record).
#   B   the API witnesses + the re-asserted holds (402/401/400/399/397/395).
#   C   the standing DOM holds + anchors + the hygiene three-pack on TEN pages.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
stats=$(cat <<'JS'
(document.querySelector('[data-testid=team-stats]')||{innerText:''}).innerText
JS
)

echo "================ A: the documented class — witnesses in DOM (390x844) ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
agent-browser open http://localhost:3000/team/8650 >/dev/null 2>&1
sleep 5
R=$(agent-browser eval "var s=$stats; (s.length>0?1:0)+'|'+(s.indexOf('امتیاز فوت‌ماب')>=0?1:0)+'|'+(s.indexOf('Manchester City')>=0?1:0)+'|'+(s.indexOf('Alexander Isak')>=0?1:0)+'|'+(s.indexOf('Cody Gakpo')>=0?1:0)" | tr -d '"')
IFS='|' read -r A1 A2 A3 A4 A5 <<< "$R"
ck "A1 /team/8650 team-stats section renders" "$A1"
ck "A2 Persian category labels render («امتیاز فوت‌ماب») — the class boundary holds" "$A2"
ck "A3 WITNESS raw «Manchester City» in team-stats (the صدر extras gap — fix=404)" "$A3"
ck "A4 WITNESS raw «Alexander Isak» leader name (no fa attempt — fix=404)" "$A4"
ck "A5 WITNESS raw «Cody Gakpo» (leader/extras — fix=404)" "$A5"

echo "================ B: API witnesses + the re-asserted holds ================"
ck "B1 WITNESS api: 8650 teamRows extras carry raw «Manchester City» (unmapped leader team)" "$(api /api/team-stats/8650 | python3 -c "
import json,sys
tr=((json.load(sys.stdin).get('stats') or {}).get('teamRows') or [])
hit=[r for r in tr for e in (r.get('extras') or []) if e.startswith('Manchester City')]
print(1 if hit else 0)")"
ck "B2 WITNESS api: 8650 playerRows leader=«Alexander Isak» raw, row carries no fa field" "$(api /api/team-stats/8650 | python3 -c "
import json,sys
pr=((json.load(sys.stdin).get('stats') or {}).get('playerRows') or [])
r=[x for x in pr if x.get('leader')=='Alexander Isak']
print(1 if r and 'fa' not in r[0] else 0)")"
ck "B3 the 402 hold: 8650 tenure leagueName=«Premier League» AND leagueFa rides" "$(api /api/team-coaches/8650 | python3 -c "
import json,sys
ts=(json.load(sys.stdin).get('coaches',{}).get('tenures') or [])
r=[t for t in ts if t.get('leagueName')=='Premier League']
print(1 if r and r[0].get('leagueFa')=='لیگ برتر انگلیس' else 0)")"
ck "B4 the 402 hold: 319784 career keeps name=«Série A» AND nameFa rides" "$(api /api/player/319784 | python3 -c "
import json,sys
cs=((json.load(sys.stdin).get('player') or {}).get('careerSeasons') or [])
hit=0
for r in cs:
    for t in r.get('tournaments') or []:
        if t.get('name')=='Série A' and t.get('nameFa')=='سری آ برزیل': hit=1
print(1 if hit else 0)")"
ck "B5 the 401 hold: player trophies leagueFa never Latin on 319784+361757" "$(python3 -c "
import json, re, subprocess
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
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
ck "B6 the 400 hold: coach 26630 honours fa rides, zero Latin passthrough (sample)" "$(api /api/coach/26630 | python3 -c "
import json,sys,re
LAT=re.compile(r'[A-Za-z]{2,}')
tr=((json.load(sys.stdin).get('coach') or {}).get('trophies') or [])
if isinstance(tr, dict): tr=(tr.get('playerTrophies') or [])
ok=[t for t in tr if t.get('leagueFa') and not LAT.search(t['leagueFa'])]
print(1 if len(ok)>=1 and len(ok)==len(tr) else 0)")"
ck "B7 the 399 hold: zero fa-less tenures on 8650 + 6706" "$(python3 -c "
import json, subprocess
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
bad=0; seen=0
for tid in ('8650','6706'):
    d=json.loads(subprocess.check_output(['curl','-s','-A',UA,'http://localhost:3000/api/team-coaches/'+tid]))
    ts=((d.get('coaches') or {}).get('tenures')) or []
    for t in ts:
        seen+=1
        if not (t.get('fa') or '').strip(): bad+=1
print(1 if seen>0 and bad==0 else 0)")"
ck "B8 the 397 hold: coachFa(26630)=«آرنه اسلوت» rides /api/coach" "$(api /api/coach/26630 | python3 -c "
import json,sys
print(1 if (json.load(sys.stdin).get('coach') or {}).get('fa')=='آرنه اسلوت' else 0)")"
ck "B9 the 395 hold: /api/team-squad/8650 mixed nameFa=0" "$(api /api/team-squad/8650 | python3 -c "
import json,sys
d=json.load(sys.stdin)
n=0
for g in ((d.get('squad') or {}).get('groups') or []):
    for p in (g.get('players') or []):
        if (p.get('nameFa') or '').strip()==(p.get('name') or '').strip(): n+=1
print(1 if n==0 else 0)")"
ck "B10 the NT contract: 361757 careerSeasons keeps name + nameFa riding (payload witness)" "$(api /api/player/361757 | python3 -c "
import json,sys
cs=((json.load(sys.stdin).get('player') or {}).get('careerSeasons') or [])
ok=cs and len(cs)>20 and cs[20].get('tournaments') and cs[20]['tournaments'][0].get('name')=='UEFA Nations League A' and cs[20]['tournaments'][0].get('nameFa')=='لیگ ملت‌های اروپا — دسته آ'
print(1 if ok else 0)")"
ck "B11 the 399 dual-purpose: Persian query «کلوپ» answers the coach packet byte-exact" "$(api "/api/search?q=کلوپ" | python3 -c "
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
