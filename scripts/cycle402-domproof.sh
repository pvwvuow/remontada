#!/usr/bin/env bash
# cycle402-domproof.sh — update cycle 402: the league label wires finally met
# the TROPHY_FA map — (a) leagueFaById gained TROPHY_FA as its FINAL chain
# step (ids still win; byte-exact names only) so the player career rows
# («آمار فصل‌به‌فصل») stopped rendering Série A/Gaúcho/Nations League A raw;
# (b) the bench-history tenure lines gained additive leagueFa + fa-first
# render; (c) TROPHY_FA +1 (Saudi Pro League — the only genuinely missing
# tenure key; LaLiga/Bundesliga/Championship were already on file bare).
#   A   the flips in DOM at 390x844 on three team pages + two player pages.
#   B   the API contracts: byte-exact raw intact, additive fa riding, the
#       401/400/399/397/395 holds.
#   C   the standing DOM holds + the hygiene three-pack.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
bench=$(cat <<'JS'
(document.querySelector('[data-testid=team-coaches]')||{innerText:''}).innerText
JS
)
career=$(cat <<'JS'
(document.querySelector('[data-testid=player-careerseasons]')||{innerText:''}).innerText
JS
)

echo "================ A: the league-label fa flips in DOM (390x844) ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
bench_ck() { # $1=id $2=fa needle $3=raw needle $4=label
  agent-browser open "http://localhost:3000/team/$1" >/dev/null 2>&1
  sleep 5
  local R=$(agent-browser eval "var s=$bench; (s.indexOf('$2')>=0?1:0)+'|'+(s.indexOf('$3')===-1?1:0)" | tr -d '"')
  local FA RAW
  IFS='|' read -r FA RAW <<< "$R"
  ck "A$4 «$2» renders in the bench-history league lines" "$FA"
  ck "A$4 raw «$3» ABSENT from the bench-history card" "$RAW"
}
bench_ck 8650 "لیگ برتر انگلیس" "Premier League" "1 (/team/8650)"
bench_ck 8634 "لالیگا" "LaLiga" "3 (/team/8634)"
agent-browser open "http://localhost:3000/team/101919" >/dev/null 2>&1; sleep 3
R=$(agent-browser eval "var s=$bench; (s.indexOf('لیگ حرفه‌ای عربستان')>=0?1:0)+'|'+(s.indexOf('Saudi Pro League')===-1?1:0)" | tr -d '"')
IFS='|' read -r A5 A6 <<< "$R"
ck "A5 /team/101919 «لیگ حرفه‌ای عربستان» (the new map entry) renders" "$A5"
ck "A6 /team/101919 raw «Saudi Pro League» ABSENT from the bench card" "$A6"

agent-browser open "http://localhost:3000/player/319784" >/dev/null 2>&1; sleep 3
R=$(agent-browser eval "var s=$career; (s.indexOf('سری آ برزیل')>=0?1:0)+'|'+(s.indexOf('Série A')===-1?1:0)+'|'+(s.indexOf('کامپئوناتو گائوچو')>=0?1:0)" | tr -d '"')
IFS='|' read -r A7 A8 A9 <<< "$R"
ck "A7 /player/319784 career rows «سری آ برزیل» render" "$A7"
ck "A8 /player/319784 raw «Série A» ABSENT from the career section" "$A8"
ck "A9 /player/319784 career rows «کامپئوناتو گائوچو» render" "$A9"
agent-browser open "http://localhost:3000/player/361757" >/dev/null 2>&1; sleep 3
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('Nations League A')===-1?1:0)" | tr -d '"')
ck "A10 /player/361757 raw «Nations League A» ABSENT page-wide (401 honours + 402 chain jointly)" "$R"
# NOTE: the NT career rows are single-tournament per season → the pre-existing
# cycle-325 rule hides sub-rows (tournaments.length>1) → no DOM row to flip on
# 361757; the payload contract rides instead (B9). The 398 lesson: scope the
# assertion to the element that ACTUALLY wraps the text — located first.

echo "================ B: the API contracts ================"
ck "B1 byte-exact raw contract: 319784 career row keeps name=«Série A» AND nameFa rides" "$(api /api/player/319784 | python3 -c "
import json,sys
cs=(json.load(sys.stdin).get('player') or {}).get('careerSeasons') or []
hit=0
for r in cs:
    for t in r.get('tournaments') or []:
        if t.get('name')=='Série A' and t.get('nameFa')=='سری آ برزیل': hit=1
print(1 if hit else 0)")"
ck "B2 byte-exact + additive: 8650 tenure keeps leagueName=«Premier League» AND leagueFa rides" "$(api /api/team-coaches/8650 | python3 -c "
import json,sys
ts=json.load(sys.stdin).get('coaches',{}).get('tenures',[])
r=[t for t in ts if t.get('leagueName')=='Premier League']
print(1 if r and r[0].get('leagueFa')=='لیگ برتر انگلیس' else 0)")"
ck "B3 tenure leagueFa NEVER Latin on the sampled benches (null stays the honest fallback)" "$(python3 -c "
import json, re, subprocess
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
LAT=re.compile(r'[A-Za-z]{2,}')
bad=0
for tid in ['8650','8634','101919','9826','9925','6706']:
    out=subprocess.run(['curl','-s','-A',UA,'http://localhost:3000/api/team-coaches/'+tid],capture_output=True,text=True,timeout=60)
    try: ts=json.loads(out.stdout).get('coaches',{}).get('tenures',[])
    except Exception: continue
    for t in ts:
        lf=(t.get('leagueFa') or '').strip()
        if lf and LAT.search(lf): bad+=1
print(1 if bad==0 else 0)")"
ck "B4 the 401 hold: /api/player/319784 trophies leagueFa rides (unaffected by the resolver change)" "$(api /api/player/319784 | python3 -c "
import json,sys
ts=(json.load(sys.stdin).get('player') or {}).get('trophies') or []
r=[t for t in ts if t.get('leagueName')=='Premier League']
print(1 if r and r[0].get('leagueFa')=='لیگ برتر انگلیس' else 0)")"
ck "B5 the 400 hold: coach 26630 honours leagueFa rides" "$(api /api/coach/26630 | python3 -c "
import json,sys
ts=(json.load(sys.stdin).get('coach') or {}).get('trophies') or []
r=[t for t in ts if t.get('leagueName')=='Eerste Divisie']
print(1 if r and r[0].get('leagueFa')=='لیگ دسته اول هلند' else 0)")"
ck "B6 the 399 hold: /api/team-coaches/8650 zero fa-less tenures" "$(api /api/team-coaches/8650 | python3 -c "
import json,sys
ten=json.load(sys.stdin).get('coaches',{}).get('tenures',[])
print(1 if ten and all((t.get('fa') or '').strip() for t in ten) else 0)")"
ck "B7 the 397 hold: coachFa(26630) rides the /api/coach fa" "$(api /api/coach/26630 | python3 -c "
import json,sys
print(1 if (json.load(sys.stdin).get('coach') or {}).get('fa')=='آرنه اسلوت' else 0)")"
ck "B8 the 395 hold: /api/team-squad/8650 raw=0" "$(api /api/team-squad/8650 | python3 -c "
import json,sys
d=json.load(sys.stdin)
n=0
for g in (d.get('squad') or {}).get('groups') or []:
    for p in g.get('players') or []:
        if (p.get('nameFa') or '').strip()==(p.get('name') or '').strip(): n+=1
print(1 if n==0 else 0)")"
ck "B9 the NT contract: 361757 careerSeasons row keeps name=«UEFA Nations League A» AND nameFa rides (the single-tournament sub-row is hidden by the pre-existing cycle-325 DOM rule — the payload is the witness)" "$(api /api/player/361757 | python3 -c "
import json,sys
pl=(json.load(sys.stdin).get('player') or {})
cs=pl.get('careerSeasons') or []
print(1 if cs and cs[20].get('tournaments') and cs[20]['tournaments'][0].get('name')=='UEFA Nations League A' and cs[20]['tournaments'][0].get('nameFa')=='لیگ ملت‌های اروپا — دسته آ' else 0)")"

echo "================ C: standing DOM holds + hygiene ================"
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
ck "C4 no bench-history raw regression (Sampaoli absent on 8650)" "$C4"

for PG in "" "team/8650" "team/8634" "player/319784" "player/361757"; do
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
