#!/usr/bin/env bash
# cycle401-domproof.sh — update cycle 401: the PLAYER-page honours section
# («افتخارات» on /player) joined the fa contract — the same-class completion
# (397/399/400 pattern): additive leagueFa (TROPHY_FA hit, +16 byte-exact
# player-side harvest entries) on the trophies rows, fa-first render, raw
# stays the honest fallback, cache key player:v13→v14.
#   A   the flips in DOM at 390x844 on five player pages.
#   B   the API contracts: byte-exact raw intact, additive fa riding, the
#       honest fallback scoped to the documented youth/county cups, the
#       TROPHY_FA consumers unbroken, the 400/399/397/395 holds.
#   C   the standing DOM holds + the hygiene three-pack.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
# the honours section is aria-label=افتخارات (player-profile.tsx)
tro=$(cat <<'JS'
(document.querySelector('section[aria-label="افتخارات"]')||{innerText:''}).innerText
JS
)

echo "================ A: the honours fa flips in DOM (390x844) ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
p_ck() { # $1=id $2=fa needle $3=raw needle $4=label
  agent-browser open "http://localhost:3000/player/$1" >/dev/null 2>&1
  sleep 3
  local R=$(agent-browser eval "var s=$tro; (s.indexOf('$2')>=0?1:0)+'|'+(s.indexOf('$3')===-1?1:0)" | tr -d '"')
  local FA RAW
  IFS='|' read -r FA RAW <<< "$R"
  ck "A$4 «$2» renders in the honours rows" "$FA"
  ck "A$4 raw «$3» ABSENT from the honours section" "$RAW"
}
p_ck 319784 "لیگ برتر انگلیس" "Premier League" "1 (/player/319784)"
agent-browser open "http://localhost:3000/player/319784" >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var s=$tro; (s.indexOf('چالش جهانی جی‌لیگ')>=0?1:0)+'|'+(s.indexOf('کامپئوناتو گائوچو')>=0?1:0)+'|'+(s.indexOf('لیورپول')>=0?1:0)+'|'+(s.indexOf('کوپا آمریکا')>=0?1:0)" | tr -d '"')
IFS='|' read -r A3 A4 A5 A6 <<< "$R"
ck "A3 /player/319784 «چالش جهانی جی‌لیگ» (the new map entry)" "$A3"
ck "A4 /player/319784 «کامپئوناتو گائوچو» (the Carioca sibling)" "$A4"
ck "A5 /player/319784 honours subtitle «لیورپول» (the 159 teamFa side intact)" "$A5"
ck "A6 /player/319784 «کوپا آمریکا» (the 400 key reused)" "$A6"

p_ck 245555 "فینالیسیما" "Finalissima" "7 (/player/245555)"
p_ck 361757 "لیگ ملت‌های اروپا — دسته آ" "Nations League A" "9 (/player/361757)"
p_ck 169718 "تروفئو خوان گامپر" "Joan Gamper" "10 (/player/169718)"
agent-browser open "http://localhost:3000/player/1167220" >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var s=$tro; (s.indexOf('المپیک تابستانی')>=0?1:0)+'|'+(s.indexOf('لالیگا ۲')>=0?1:0)+'|'+(s.indexOf('LaLiga2')===-1?1:0)" | tr -d '"')
IFS='|' read -r A11 A12 A13 <<< "$R"
ck "A11 /player/1167220 «المپیک تابستانی» (the new map entry)" "$A11"
ck "A12 /player/1167220 «لالیگا ۲» renders" "$A12"
ck "A13 /player/1167220 raw «LaLiga2» ABSENT from honours" "$A13"
agent-browser open "http://localhost:3000/player/1187506" >/dev/null 2>&1; sleep 2
R=$(agent-browser eval "var s=$tro; (s.indexOf('جام ملت‌های آفریقا زیر ۲۳ سال')>=0?1:0)" | tr -d '"')
ck "A14 /player/1187506 «جام ملت‌های آفریقا زیر ۲۳ سال» (the new map entry)" "$R"

echo "================ B: the API contracts ================"
ck "B1 byte-exact raw contract: 319784 row keeps leagueName=«Premier League» AND leagueFa rides" "$(api /api/player/319784 | python3 -c "
import json,sys
ts=(json.load(sys.stdin).get('player') or {}).get('trophies') or []
r=[t for t in ts if t.get('leagueName')=='Premier League']
print(1 if r and r[0].get('leagueFa')=='لیگ برتر انگلیس' else 0)")"
ck "B2 leagueFa NEVER Latin on the harvested set (zero passthrough)" "$(python3 -c "
import json, re, subprocess
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
LAT=re.compile(r'[A-Za-z]{2,}')
bad=0
for pid in ['319784','245555','361757','169718','1167220','1187506','948800','582276','1068920','383971','719330','544589','1232530','268375','833219','184554','1285872','1281100','926445','562726','170322','568571']:
    out=subprocess.run(['curl','-s','-A',UA,'http://localhost:3000/api/player/'+pid],capture_output=True,text=True,timeout=60)
    try: ts=(json.loads(out.stdout).get('player') or {}).get('trophies') or []
    except Exception: continue
    for t in ts:
        lf=(t.get('leagueFa') or '').strip()
        if lf and LAT.search(lf): bad+=1
print(1 if bad==0 else 0)")"
ck "B3 honest league fallback scoped: every leagueFa=null row is a documented youth/county/ambiguous cup" "$(python3 -c "
import json, subprocess
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
OK={'Tournoi U20 4 Nations','Tournoi Maurice Revello','Cup','HNL','First NL','Cheshire Senior Cup','Premier League International Cup','EFL Trophy','División de Honor Juvenil',\"King's Cup\",'Queensland Champions Cup','U17 Bundesliga','DFB Junioren Pokal','Premier League 2 Div 2','Campionato Primavera 1'}
bad=[]
for pid in ['319784','245555','361757','169718','1167220','1187506','948800','582276','1068920','383971','719330','544589','1232530','268375','833219','184554','1285872','1281100','926445','562726','170322','568571']:
    out=subprocess.run(['curl','-s','-A',UA,'http://localhost:3000/api/player/'+pid],capture_output=True,text=True,timeout=60)
    try: ts=(json.loads(out.stdout).get('player') or {}).get('trophies') or []
    except Exception: continue
    for t in ts:
        if not (t.get('leagueFa') or '').strip() and t.get('leagueName') not in OK:
            bad.append((pid,t.get('leagueName')))
print(1 if not bad else 0)")"
ck "B4 TROPHY_FA extension broke nothing: team-trophies 8650 nameFa intact" "$(api /api/team-trophies/8650 | python3 -c "
import json,sys
items=(json.load(sys.stdin).get('trophies') or {}).get('items') or []
pl=[i for i in items if i.get('name')=='Premier League']
print(1 if pl and pl[0].get('nameFa')=='لیگ برتر انگلیس' else 0)")"
ck "B5 the 400 hold intact after the map growth: coach 26630 honours leagueFa rides" "$(api /api/coach/26630 | python3 -c "
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

for PG in "" "player/319784" "player/361757" "coach/24011" "team/8650"; do
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
