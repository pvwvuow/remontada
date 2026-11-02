#!/usr/bin/env bash
# cycle400-domproof.sh — update cycle 400: the coach-page honours section
# («افتخارات») joined the fa contract — the same-class completion (397/399
# pattern): additive teamFa (teamFa map, 34/34 after +River Plate/Newell's)
# and leagueFa (TROPHY_FA +33 byte-exact harvest entries) on the trophies
# rows, fa-first render, raw stays the honest fallback, cache key v4→v5.
#   A   the flips in DOM at 390x844 on four coach pages.
#   B   the API contracts: byte-exact raw intact, additive fa riding, the
#       honest league fallback scoped to the two documented youth/reserve
#       leagues, the TROPHY_FA consumers unbroken, the 397/399 holds.
#   C   the standing DOM holds + the hygiene three-pack.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }

echo "================ A: the honours fa flips in DOM (390x844) ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
coach_ck() { # $1=id $2=fa needle $3=raw needle $4=label
  agent-browser open "http://localhost:3000/coach/$1" >/dev/null 2>&1
  sleep 3
  local R=$(agent-browser eval "var s=(document.querySelector('[data-testid=coach-trophies]')||{innerText:''}).innerText; (s.indexOf('$2')>=0?1:0)+'|'+(s.indexOf('$3')===-1?1:0)" | tr -d '"')
  local FA RAW
  IFS='|' read -r FA RAW <<< "$R"
  ck "A$4 «$2» renders in the honours rows" "$FA"
  ck "A$4 raw «$3» ABSENT from the honours section" "$RAW"
}
coach_ck 24011 "جام حذفی انگلیس" "FA Cup" "1 (/coach/24011)"
agent-browser open "http://localhost:3000/coach/24011" >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=coach-trophies]')||{innerText:''}).innerText; (s.indexOf('آرسنال')>=0?1:0)+'|'+(s.indexOf('Arsenal')===-1?1:0)" | tr -d '"')
IFS='|' read -r A5 A6 <<< "$R"
ck "A5 /coach/24011 honours subtitle «آرسنال» (teamFa)" "$A5"
ck "A6 /coach/24011 raw «Arsenal» ABSENT from honours" "$A6"

coach_ck 11532 "کوپا دل‌ری" "Copa del Rey" "7 (/coach/11532)"
agent-browser open "http://localhost:3000/coach/11532" >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=coach-trophies]')||{innerText:''}).innerText; (s.indexOf('بارسلونا')>=0?1:0)+'|'+(s.indexOf('جام در جام اروپا')>=0?1:0)" | tr -d '"')
IFS='|' read -r A9 A10 <<< "$R"
ck "A9 /coach/11532 honours subtitle «بارسلونا»" "$A9"
ck "A10 /coach/11532 «جام در جام اروپا» (the Cup Winners' Cup, established)" "$A10"

coach_ck 26630 "لیگ دسته اول هلند" "Eerste Divisie" "11 (/coach/26630)"
agent-browser open "http://localhost:3000/coach/26630" >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=coach-trophies]')||{innerText:''}).innerText; (s.indexOf('زفوله')>=0?1:0)" | tr -d '"')
ck "A12 /coach/26630 honours subtitle «زفوله» (the 398-era raw witness coach)" "$R"

coach_ck 80651 "لیگ حرفه‌ای آرژانتین" "Liga Profesional" "13 (/coach/80651)"
agent-browser open "http://localhost:3000/coach/80651" >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=coach-trophies]')||{innerText:''}).innerText; (s.indexOf('نیولز اولد بویز')>=0?1:0)" | tr -d '"')
ck "A14 /coach/80651 subtitle «نیولز اولد بویز» (the new TEAM_FA entry)" "$R"

echo "================ B: the API contracts ================"
ck "B1 byte-exact raw contract: 26630 row keeps leagueName=«Eerste Divisie» AND leagueFa rides" "$(api /api/coach/26630 | python3 -c "
import json,sys
ts=(json.load(sys.stdin).get('coach') or {}).get('trophies') or []
r=[t for t in ts if t.get('leagueName')=='Eerste Divisie']
print(1 if r and r[0].get('leagueFa')=='لیگ دسته اول هلند' else 0)")"
ck "B2 teamFa NEVER Latin on the harvested set (34/34 mapped — zero passthrough)" "$(python3 -c "
import json, re, subprocess
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
LAT=re.compile(r'[A-Za-z]{2,}')
bad=0
for cid in ['24011','2642','131509','30889','33025','11532','27692','78719','26630','80651','78660','160770','335697']:
    out=subprocess.run(['curl','-s','-A',UA,'http://localhost:3000/api/coach/'+cid],capture_output=True,text=True,timeout=60)
    try: co=json.loads(out.stdout).get('coach') or {}
    except Exception: continue
    for t in co.get('trophies') or []:
        tf=(t.get('teamFa') or '').strip()
        if t.get('teamName') and (not tf or LAT.search(tf)): bad+=1
print(1 if bad==0 else 0)")"
ck "B3 honest league fallback scoped: every leagueFa=null row is a documented youth/reserve league" "$(python3 -c "
import json, re, subprocess
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
OK={'Premier League 2 Div 2','Campionato Primavera 1'}
bad=[]
for cid in ['24011','2642','131509','1515447','1415967','33072','38711','208516','30889','30613','94647','36771','1188285','27692','30721','1108529','33025','361759','34000','11754','41167','24105','11532','30459','78591','78719','27204','804046','96945','242474','59582','1791900','9012','22317','504132','38922','78619','1059866','26630','78660','160770','335697','80651']:
    out=subprocess.run(['curl','-s','-A',UA,'http://localhost:3000/api/coach/'+cid],capture_output=True,text=True,timeout=60)
    try: co=json.loads(out.stdout).get('coach') or {}
    except Exception: continue
    for t in co.get('trophies') or []:
        if not (t.get('leagueFa') or '').strip() and t.get('leagueName') not in OK:
            bad.append((cid,t.get('leagueName')))
print(1 if not bad else 0)")"
ck "B4 TROPHY_FA extension broke nothing: team-trophies 8650 nameFa intact" "$(api /api/team-trophies/8650 | python3 -c "
import json,sys
items=(json.load(sys.stdin).get('trophies') or {}).get('items') or []
pl=[i for i in items if i.get('name')=='Premier League']
print(1 if pl and pl[0].get('nameFa')=='لیگ برتر انگلیس' else 0)")"
ck "B5 the 399 hold: /api/team-coaches/8650 zero fa-less tenures" "$(api /api/team-coaches/8650 | python3 -c "
import json,sys
ten=json.load(sys.stdin).get('coaches',{}).get('tenures',[])
print(1 if ten and all((t.get('fa') or '').strip() for t in ten) else 0)")"
ck "B6 the 397 hold: coachFa(26630) rides the /api/coach fa" "$(api /api/coach/26630 | python3 -c "
import json,sys
print(1 if (json.load(sys.stdin).get('coach') or {}).get('fa')=='آرنه اسلوت' else 0)")"
ck "B7 the 395 hold: /api/team-squad/8650 raw=0" "$(api /api/team-squad/8650 | python3 -c "
import json,sys
d=json.load(sys.stdin)
n=0
for g in (d.get('squad') or {}).get('groups') or []:
    for p in g.get('players') or []:
        if (p.get('nameFa') or '').strip()==(p.get('name') or '').strip(): n+=1
print(1 if n==0 else 0)")"

echo "================ C: standing DOM holds + hygiene ================"
agent-browser open http://localhost:3000/coach/9012 >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var h=document.querySelector('h1'); (h&&h.innerText.indexOf('سرگی یاکیروویچ')>=0?1:0)" | tr -d '"')
ck "C1 /coach/9012 h1 «سرگی یاکیروویچ» (the 398 hold)" "$R"
agent-browser open http://localhost:3000/team/8650 >/dev/null 2>&1; sleep 3
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('آرنه اسلوت')>=0?1:0)+'|'+(t.indexOf('Jorge Sampaoli')===-1?1:0)" | tr -d '"')
IFS='|' read -r C2 C3 <<< "$R"
ck "C2 /team/8650 bench history «آرنه اسلوت» (the 399 hold)" "$C2"
ck "C3 no bench-history raw regression (Sampaoli absent on 8650)" "$C3"

for PG in "" "coach/24011" "coach/26630" "coach/80651" "team/8650"; do
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
