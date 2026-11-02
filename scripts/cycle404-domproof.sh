#!/usr/bin/env bash
# cycle404-domproof.sh — fix cycle 404 (فرمول ۵): closes the class documented by
# the 403 bug-hunt. The team season-stats section («آمار برتر فصل», cycle-76/77)
# rendered PERSONAL names raw on three levels while its category labels were
# Persian. The 404 fix wires getTeamStats + TeamStatRowBox through the house
# maps (additive, raw byte contract untouched):
#   (الف) team-row «صدر:» extras → teamFa (TEAM_FA, honest raw fallback)
#   (ب)   player-row leader → additive leaderFa = playerFa (byte-exact keys)
#   (ج)   player-row «سپس:» extras → additive extrasFa = playerFa per entry
#   A   the 403 witnesses FLIPPED in DOM at 390x844 + no-raw-regression scoped
#       to [data-testid=team-stats].
#   B   the fix contracts (raw+fa side by side, lockstep, honest fallback) +
#       the re-asserted holds (402/401/400/399/397/395 + NT + «کلوپ»).
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

echo "================ A: the 403 witnesses FLIPPED in DOM (390x844) ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
agent-browser open http://localhost:3000/team/8650 >/dev/null 2>&1
sleep 5
R=$(agent-browser eval "var s=$stats; (s.length>0?1:0)+'|'+(s.indexOf('امتیاز فوت‌ماب')>=0?1:0)+'|'+(s.indexOf('منچسترسیتی ۷٫۲۱')>=0?1:0)+'|'+(s.indexOf('برایتون ۲٫۷')>=0?1:0)+'|'+(s.indexOf('الکساندر ایساک')>=0?1:0)+'|'+(s.indexOf('کودی گاکپو')>=0?1:0)+'|'+(s.indexOf('ویرگیل فان‌دیک')>=0?1:0)+'|'+(s.indexOf('ویکتور مونیوز ۲')>=0?1:0)+'|'+(s.indexOf('فلورین ویرتز')>=0?1:0)+'|'+((s.indexOf('Alexander Isak')===-1&&s.indexOf('Manchester City')===-1&&s.indexOf('Florian Wirtz')===-1)?1:0)" | tr -d '"')
IFS='|' read -r A1 A2 A3 A4 A5 A6 A7 A8 A9 A10 <<< "$R"
ck "A1 /team/8650 team-stats section renders" "$A1"
ck "A2 Persian category labels render («امتیاز فوت‌ماب») — class boundary now seamless" "$A2"
ck "A3 FLIP صدر: «منچسترسیتی ۷٫۲۱» (was raw Manchester City — the 403 witness (الف))" "$A3"
ck "A4 FLIP صدر: «برایتون ۲٫۷» (was raw Brighton & Hove Albion)" "$A4"
ck "A5 FLIP leader: «الکساندر ایساک» (was raw — the 403 witness (ب))" "$A5"
ck "A6 FLIP leader/extras: «کودی گاکپو»" "$A6"
ck "A7 FLIP leader: «ویرگیل فان‌دیک»" "$A7"
ck "A8 FLIP سپس: «ویکتور مونیوز ۲» (the 403 witness (ج))" "$A8"
ck "A9 FLIP سپس: «فلورین ویرتز»" "$A9"
ck "A10 no raw regression inside the section (Isak/City/Wirtz raw all absent)" "$A10"

echo "================ B: fix contracts + the re-asserted holds ================"
ck "B1 raw byte contract: leader=«Alexander Isak» kept AND leaderFa=«الکساندر ایساک» rides" "$(api /api/team-stats/8650 | python3 -c "
import json,sys
pr=((json.load(sys.stdin).get('stats') or {}).get('playerRows') or [])
r=[x for x in pr if x.get('leader')=='Alexander Isak']
print(1 if r and r[0].get('leader')=='Alexander Isak' and r[0].get('leaderFa')=='الکساندر ایساک' else 0)")"
ck "B2 lockstep «سپس»: extras raw «Víctor Muñoz ۲» AND extrasFa «ویکتور مونیوز ۲» same row" "$(api /api/team-stats/8650 | python3 -c "
import json,sys
pr=((json.load(sys.stdin).get('stats') or {}).get('playerRows') or [])
hit=0
for r in pr:
    ex=r.get('extras') or []; ef=r.get('extrasFa') or []
    if 'Víctor Muñoz ۲' in ex and 'ویکتور مونیوز ۲' in ef and len(ex)==len(ef): hit=1
print(hit)")"
ck "B3 صدر contract: extras raw «Manchester City ۷٫۲۱» kept AND extrasFa «منچسترسیتی ۷٫۲۱» rides" "$(api /api/team-stats/8650 | python3 -c "
import json,sys
tr=((json.load(sys.stdin).get('stats') or {}).get('teamRows') or [])
hit=0
for r in tr:
    ex=r.get('extras') or []; ef=r.get('extrasFa') or []
    if 'Manchester City ۷٫۲۱' in ex and 'منچسترسیتی ۷٫۲۱' in ef: hit=1
print(hit)")"
ck "B4 صدر Brighton: extras raw «Brighton & Hove Albion ۲٫۷» + extrasFa «برایتون ۲٫۷»" "$(api /api/team-stats/8650 | python3 -c "
import json,sys
tr=((json.load(sys.stdin).get('stats') or {}).get('teamRows') or [])
hit=0
for r in tr:
    ex=r.get('extras') or []; ef=r.get('extrasFa') or []
    if 'Brighton & Hove Albion ۲٫۷' in ex and 'برایتون ۲٫۷' in ef: hit=1
print(hit)")"
ck "B5 lockstep breadth: 4 teams (8650/9875/8633/9788) — every leader has leaderFa, extrasFa same length" "$(python3 -c "
import json, subprocess
UA='$UA'
bad=0; rows=0
for tid in ('8650','9875','8633','9788'):
    d=json.loads(subprocess.check_output(['curl','-s','-A',UA,'http://localhost:3000/api/team-stats/'+tid]))
    s=(d.get('stats') or {})
    for r in (s.get('playerRows') or [])+(s.get('teamRows') or []):
        rows+=1
        if r.get('leader') and not (r.get('leaderFa') or '').strip(): bad+=1
        ex=r.get('extras') or []; ef=r.get('extrasFa')
        if ex and (not ef or len(ef)!=len(ex)): bad+=1
print(1 if rows>0 and bad==0 else 0)")"
ck "B6 honest fallback: unmapped «Yan Diomande ۳» keeps raw inside extrasFa (8633 — no guessing)" "$(api /api/team-stats/8633 | python3 -c "
import json,sys
pr=((json.load(sys.stdin).get('stats') or {}).get('playerRows') or [])
hit=[e for r in pr for e in (r.get('extrasFa') or []) if e.startswith('Yan Diomande')]
print(1 if hit else 0)")"
ck "B7 the 402 hold: 8650 tenure leagueName=«Premier League» AND leagueFa rides" "$(api /api/team-coaches/8650 | python3 -c "
import json,sys
ts=(json.load(sys.stdin).get('coaches',{}).get('tenures') or [])
r=[t for t in ts if t.get('leagueName')=='Premier League']
print(1 if r and r[0].get('leagueFa')=='لیگ برتر انگلیس' else 0)")"
ck "B8 the 402 hold: 319784 career keeps name=«Série A» AND nameFa rides" "$(api /api/player/319784 | python3 -c "
import json,sys
cs=((json.load(sys.stdin).get('player') or {}).get('careerSeasons') or [])
hit=0
for r in cs:
    for t in r.get('tournaments') or []:
        if t.get('name')=='Série A' and t.get('nameFa')=='سری آ برزیل': hit=1
print(hit)")"
ck "B9 the 401 hold: player trophies leagueFa never Latin on 319784+361757" "$(python3 -c "
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
ck "B10 the 400 hold: coach 26630 honours fa rides, zero Latin passthrough (sample)" "$(api /api/coach/26630 | python3 -c "
import json,sys,re
LAT=re.compile(r'[A-Za-z]{2,}')
tr=((json.load(sys.stdin).get('coach') or {}).get('trophies') or [])
if isinstance(tr, dict): tr=(tr.get('playerTrophies') or [])
ok=[t for t in tr if t.get('leagueFa') and not LAT.search(t['leagueFa'])]
print(1 if len(ok)>=1 and len(ok)==len(tr) else 0)")"
ck "B11 the 399 hold: zero fa-less tenures on 8650 + 6706" "$(python3 -c "
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
ck "B12 the 397 hold: coachFa(26630)=«آرنه اسلوت» rides /api/coach" "$(api /api/coach/26630 | python3 -c "
import json,sys
print(1 if (json.load(sys.stdin).get('coach') or {}).get('fa')=='آرنه اسلوت' else 0)")"
ck "B13 the 395 hold: /api/team-squad/8650 mixed nameFa=0" "$(api /api/team-squad/8650 | python3 -c "
import json,sys
d=json.load(sys.stdin)
n=0
for g in ((d.get('squad') or {}).get('groups') or []):
    for p in (g.get('players') or []):
        if (p.get('nameFa') or '').strip()==(p.get('name') or '').strip(): n+=1
print(1 if n==0 else 0)")"
ck "B14 the NT contract: 361757 careerSeasons keeps name + nameFa riding (payload witness)" "$(api /api/player/361757 | python3 -c "
import json,sys
cs=((json.load(sys.stdin).get('player') or {}).get('careerSeasons') or [])
ok=cs and len(cs)>20 and cs[20].get('tournaments') and cs[20]['tournaments'][0].get('name')=='UEFA Nations League A' and cs[20]['tournaments'][0].get('nameFa')=='لیگ ملت‌های اروپا — دسته آ'
print(1 if ok else 0)")"
ck "B15 the 399 dual-purpose: Persian query «کلوپ» answers the coach packet byte-exact (percent-encoded — the canonical browser form; the recycled container's newer Node llhttp rejects raw UTF-8 request lines with 400)" "$(api "/api/search?q=%DA%A9%D9%84%D9%88%D9%BE" | python3 -c "
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
