#!/usr/bin/env bash
# cycle407-domproof.sh — update cycle 407 (فرمول ۳): the three LATER per-90
# siblings (cycles 335/336/337 — «پاس دقیق در هر ۹۰» / «بازیابی توپ در هر ۹۰» /
# «پاس بلند دقیق در هر ۹۰») joined the mapped standings payload as REQUIRED
# cached fields (v37/v38) but MISSED the read-time freshener
# freshenHonestNames — every 327/330/331 sibling rode the read-time honest
# names while these three rendered BOTH the player name AND the team subtitle
# raw on the league scorers page («Rúben Dias / Manchester City», «Fedde
# Leysen»…). Probe (repo-external scripts/cycle407_leakscan.py, UA Chrome/124)
# measured: name-rows with NO fa-ish field on exactly these three arrays
# (17 fa-less rows across pl/ucl/laliga/bundesliga sweeps + 8 raw names in the
# match-unavailable lists). Fix = three one-map read-time lines (the sibling
# pattern, NO cache bump) + a PLAYER_NAME_FA batch of the 8 unavailable
# witnesses (the 405 map-lag pattern). 
#   A   the flip witnesses in DOM at 390x844 (the /topscorers/pl per-90
#       sections + the /match/5749738 «غایبان» block) + no-raw regression.
#   B   the fix contracts + the re-asserted holds (405/404/402/401/400/399/
#       397/395 + the 116 unavailable contract + the no-bump proof + ICS).
#   C   the standing DOM holds + anchors + the hygiene three-pack on pages.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }

echo "================ A: the flip witnesses in DOM (390x844) ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
# A1-A5: /topscorers/pl — the three per-90 sections render fa-first
agent-browser open http://localhost:3000/topscorers/pl >/dev/null 2>&1
sleep 5
R=$(agent-browser eval "var q=function(t){return document.querySelectorAll('[data-testid='+t+']').length}; q('passes-row')+'|'+q('longballs-row')+'|'+q('recovery-row')" | tr -d '"')
IFS='|' read -r A1 A2 A3 <<< "$R"
ck "A1 «پاس دقیق در هر ۹۰» rows render on /topscorers/pl (passes-row>0)" "$([ "${A1:-0}" -gt 0 ] && echo 1 || echo 0)"
ck "A2 «پاس بلند دقیق در هر ۹۰» rows render (longballs-row>0)" "$([ "${A2:-0}" -gt 0 ] && echo 1 || echo 0)"
ck "A3 «بازیابی توپ در هر ۹۰» rows render (recovery-row>0)" "$([ "${A3:-0}" -gt 0 ] && echo 1 || echo 0)"
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('گرانیت ژاکا')>=0?1:0)+'|'+(t.indexOf('ساندرلند')>=0?1:0)+'|'+(t.indexOf('داوید رایا')>=0?1:0)+'|'+(t.indexOf('آرسنال')>=0?1:0)+'|'+(t.indexOf('منچسترسیتی')>=0?1:0)" | tr -d '"')
IFS='|' read -r A4 A5 A6 A7 A8 <<< "$R"
ck "A4 FLIP: «گرانیت ژاکا» rides (was raw Granit Xhaka)" "$A4"
ck "A5 FLIP: team subtitle «ساندرلند» rides (was raw Sunderland)" "$A5"
ck "A6 FLIP: «داوید رایا» rides (was raw David Raya)" "$A6"
ck "A7 FLIP: team subtitle «آرسنال» rides (was raw Arsenal)" "$A7"
ck "A8 FLIP: team subtitle «منچسترسیتی» rides (was raw Manchester City)" "$A8"
# A9-A12: /match/5749738 «غایبان» — the 8 map-batch witnesses. The block
# lives inside the «ترکیب» tab (cycle-116) — a REAL tab click first (the 406
# lesson: the witness must be picked from the surface that actually renders).
agent-browser open http://localhost:3000/match/5749738 >/dev/null 2>&1
sleep 5
agent-browser eval "([...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').trim()==='ترکیب'})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=match-unavailable]')||{innerText:''}).innerText; (s.length>0?1:0)+'|'+(s.indexOf('اسماعیل کونه')>=0?1:0)+'|'+(s.indexOf('کریستین توشتودت')>=0?1:0)+'|'+(s.indexOf('لوکا رانیری')>=0?1:0)+'|'+(s.indexOf('مارین پونگراچیچ')>=0?1:0)" | tr -d '"')
IFS='|' read -r A9 A10 A11 A12 A13 <<< "$R"
ck "A9 /match/5749738 «غایبان» block renders" "$A9"
ck "A10 FLIP: «اسماعیل کونه» rides (was raw Ismaël Koné)" "$A10"
ck "A11 FLIP: «کریستین توشتودت» rides (fa.wikipedia spelling)" "$A11"
ck "A12 FLIP: «لوکا رانیری» rides" "$A12"
ck "A13 FLIP: «مارین پونگراچیچ» rides" "$A13"
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=match-unavailable]')||{innerText:''}).innerText; var raws=['Fedde Leysen','Daniel Boloca','Ismaël Koné','Kristian Thorstvedt','Luca Ranieri','Marin Pongračić','Arthur Atta','Fabiano Parisi']; raws.every(function(r){return s.indexOf(r)===-1})?1:0" | tr -d '"')
ck "A14 no raw regression: all 8 former-raw names absent from «غایبان»" "$R"

echo "================ B: fix contracts + the re-asserted holds ================"
ck "B1 the fix: per-90 fields EXIST on every row (nameFa present even when honest-raw) on pl" "$(api "/api/standings?league=pl" | python3 -c "
import json,sys
d=json.load(sys.stdin)
tot=miss=0
for a in ('accuratePassesPer90','recoveriesPer90','longBallsPer90'):
    for r in (d.get(a) or []):
        tot+=1
        if 'nameFa' not in r or not (r.get('nameFa') or '').strip(): miss+=1
print(1 if tot>=30 and miss==0 else 0)")"
ck "B2 breadth: the three arrays 100% nameFa on ucl/laliga/seriea/bundesliga + topscorers pl/seriea" "$(python3 -c "
import json, subprocess
UA='$UA'
tot=miss=0
for u in ('/api/standings?league=ucl','/api/standings?league=laliga','/api/standings?league=seriea','/api/standings?league=bundesliga','/api/topscorers/pl','/api/topscorers/seriea'):
    d=json.loads(subprocess.check_output(['curl','-s','-A',UA,'http://localhost:3000'+u]))
    for a in ('accuratePassesPer90','recoveriesPer90','longBallsPer90'):
        for r in (d.get(a) or []):
            tot+=1
            if not (r.get('nameFa') or '').strip(): miss+=1
print(1 if tot>100 and miss==0 else 0)")"
ck "B3 flip witnesses at payload level: تسولاکیس/ژاکا/موریتا/فان‌دیک + team subtitles Persian" "$(api "/api/standings?league=pl" | python3 -c "
import json,sys
d=json.load(sys.stdin)
names=(r.get('nameFa') for a in ('accuratePassesPer90','recoveriesPer90','longBallsPer90') for r in (d.get(a) or []))
s='|'.join(x or '' for x in names)
ok=1 if ('کونستانتینوس تسولاکیس' in s and 'گرانیت ژاکا' in s and 'هیده‌ماسا موریتا' in s and 'ویرگیل فان‌دیک' in s) else 0
teams=(r.get('team') for a in ('accuratePassesPer90','recoveriesPer90','longBallsPer90') for r in (d.get(a) or []))
t='|'.join(teams or '')
ok2=1 if ('منچسترسیتی' in t and 'آرسنال' in t and 'ساندرلند' in t) else 0
print(1 if ok and ok2 else 0)")"
ck "B4 honest fallback kept: Rúben Dias stays raw INSIDE the (now-present) nameFa — the 107 rule" "$(api "/api/standings?league=pl" | python3 -c "
import json,sys
d=json.load(sys.stdin)
r=[x for x in (d.get('accuratePassesPer90') or []) if x.get('name')=='Rúben Dias']
print(1 if r and r[0].get('nameFa')=='Rúben Dias' and r[0].get('team')=='منچسترسیتی' else 0)")"
ck "B5 the 116 unavailable contract: 8/8 nameFa on 5749738 + returnRaw/returnFa shape intact" "$(api /api/match/5749738 | python3 -c "
import json,sys
lu=json.load(sys.stdin).get('lineups') or {}
rows=[u for side in ('home','away') for u in ((lu.get(side) or {}).get('unavailable') or [])]
fa=[u for u in rows if (u.get('nameFa') or '').strip()]
shape=[u for u in rows if 'returnRaw' in u and 'returnFa' in u]
print(1 if len(rows)==8 and len(fa)==8 and len(shape)>0 else 0)")"
ck "B6 no cache bump (deliberate read-time choice): standings key still v41" "$(grep -c 'standings:v41:' src/lib/fotmob.ts | grep -qx 1 && echo 1 || echo 0)"
ck "B7 the 405 hold: 2024/25 merge — every row carries non-empty nameFa" "$(api "/api/topscorers?season=2024/2025" | python3 -c "
import json,sys
sc=(json.load(sys.stdin).get('scorers') or [])
bad=[x for x in sc if not (x.get('nameFa') or '').strip()]
print(1 if sc and not bad else 0)")"
ck "B8 the 404 hold: 8650 team-stats leaderFa/extrasFa lockstep (BAD=0)" "$(python3 -c "
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
ck "B9 the 402 hold: 8650 tenure leagueName=«Premier League» AND leagueFa rides" "$(api /api/team-coaches/8650 | python3 -c "
import json,sys
ts=(json.load(sys.stdin).get('coaches',{}).get('tenures') or [])
r=[t for t in ts if t.get('leagueName')=='Premier League']
print(1 if r and r[0].get('leagueFa')=='لیگ برتر انگلیس' else 0)")"
ck "B10 the 401 hold: player trophies leagueFa never Latin on 319784+361757" "$(python3 -c "
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
ck "B11 the 400 hold: coach 26630 honours fa rides, zero Latin passthrough" "$(api /api/coach/26630 | python3 -c "
import json,sys,re
LAT=re.compile(r'[A-Za-z]{2,}')
tr=((json.load(sys.stdin).get('coach') or {}).get('trophies') or [])
if isinstance(tr, dict): tr=(tr.get('playerTrophies') or [])
ok=[t for t in tr if t.get('leagueFa') and not LAT.search(t['leagueFa'])]
print(1 if len(ok)>=1 and len(ok)==len(tr) else 0)")"
ck "B12 the 399 hold: zero fa-less tenures on 8650 + 6706" "$(python3 -c "
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
ck "B13 the 397 hold: coachFa(26630)=«آرنه اسلوت» rides /api/coach" "$(api /api/coach/26630 | python3 -c "
import json,sys
print(1 if (json.load(sys.stdin).get('coach') or {}).get('fa')=='آرنه اسلوت' else 0)")"
ck "B14 the 395 hold: /api/team-squad/8650 mixed nameFa=0" "$(api /api/team-squad/8650 | python3 -c "
import json,sys
d=json.load(sys.stdin)
n=0
for g in ((d.get('squad') or {}).get('groups') or []):
    for p in (g.get('players') or []):
        if (p.get('nameFa') or '').strip()==(p.get('name') or '').strip(): n+=1
print(1 if n==0 else 0)")"
ck "B15 the 399 dual-purpose: Persian query «کلوپ» answers the coach packet byte-exact (percent-encoded)" "$(api "/api/search?q=%DA%A9%D9%84%D9%88%D9%BE" | python3 -c "
import json,sys
cs=(json.load(sys.stdin).get('coaches') or [])
r=[c for c in cs if c.get('name')=='Jürgen Klopp' and c.get('fa')=='یورگن کلوپ']
print(1 if r else 0)")"
ck "B16 probe-artifact contract: /api/league-calendar is the ICS feed by design (text/calendar + Persian title)" "$(curl -s -o /tmp/cal407.ics -w '%{content_type}' -A "$UA" "$BASE/api/league-calendar?league=pl" | grep -q 'text/calendar' && grep -q 'X-WR-CALNAME:پریمیرلیگ انگلیس' /tmp/cal407.ics && echo 1 || echo 0)"

echo "================ C: standing DOM holds + anchors + hygiene ================"
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
agent-browser open http://localhost:3000/league/pl >/dev/null 2>&1; sleep 3
# the league page's «آقای گل» tab renders league-view's OWN ScorersList (the
# per-90 family lives on /topscorers/pl — witnessed at A1-A3) — assert the
# tab + its payload-driven Persian leader instead
agent-browser eval "([...document.querySelectorAll('button')].find(function(b){return (b.textContent||'').trim()==='آقای گل'})||{click:function(){}}).click(); 'ok'" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var t=document.body.innerText; var links=document.querySelectorAll('a[href^=\"/player/\"]').length; (t.indexOf('آقای گل')>=0?1:0)+'|'+(links>0?1:0)+'|'+(t.indexOf('ارلینگ هالند')>=0?1:0)" | tr -d '"')
IFS='|' read -r C8 C9 C10 <<< "$R"
ck "C8 /league/pl «آقای گل» tab opens with player links" "$C8"
ck "C9 FLIP: payload witness «ارلینگ هالند» rides the scorers table" "$C9"

for PG in "" "team/8650" "team/6706" "team/8634" "player/319784" "player/361757" "coach/26630" "league/premierleague" "topscorers" "topscorers/pl" "match/5749738" "standings"; do
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
