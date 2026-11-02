#!/usr/bin/env bash
# cycle396-domproof.sh — bug-hunt cycle 396: the 393 method on the surfaces
# the 390-395 cycles opened. Findings are ASSERTED AT THEIR CURRENT STATE
# (the fix belongs to cycle-397=فیکس, the 393 precedent):
#
#   F1  the 394-logged item confirmed live: the /players squad-panel header
#       renders squad.coach.name RAW (players-view.tsx:765) while the SAME
#       payload carries coach.fa (cycle-259 coachFa) and the team-page chip
#       renders Persian first (team-view.tsx:597 {coach.fa || coach.name}).
#       Witnesses: 8650 «Andoni Iraola» raw on /players vs «آندونی ایرولا»
#       on /team/8650; 8634 «Hans-Dieter Flick» / «هانسی فلیک». Patrol size:
#       2 of 10 probed coaches carry a mapped fa (the 397 free win); 8 stay
#       the documented honest fallback (Scaloni/Ancelotti/Ghalenoei/de la
#       Fuente… — the coachFa coverage note for the 397 fix).
#   B   clean classes re-asserted: the honesty contract (0 mixed nameFa),
#       the 390 NT hold, the 391 venue hold, the 392 transfers hold, the
#       395 squad raw-exactness (the documented absent stay raw), the match
#       surface zero-Latin (the 384 path), the designed 404 contract.
#   C   DOM patrol at 390x844 (house agent-browser pattern, pipe-separated
#       eval + tr -d '"', the ?1:0 shaped form) on six pages + the
#       hygiene three-pack.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }
has() { printf '%s' "$1" | grep -qF "$2" && echo 1 || echo 0; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
st() { curl -s -A "$UA" -o /tmp/d396_body.txt -w '%{http_code}' "$BASE$1"; }

echo "================ A: the F1 evidence (coach name render divergence) ================"
B=$(api "/api/team-squad/8650")
ck "A1 8650 API coach.fa «آندونی ایرولا» rides (the 397 fix's data source)" "$([ "$(has "$B" '"fa":"آندونی ایرولا"')" = 1 ] && echo 1 || echo 0)"
ck "A2 8650 API coach.name byte-exact raw «Andoni Iraola»" "$([ "$(has "$B" '"name":"Andoni Iraola"')" = 1 ] && echo 1 || echo 0)"
ck "A3 8634 API coach.fa «هانسی فلیک» rides" "$([ "$(has "$(api /api/team-squad/8634)" '"fa":"هانسی فلیک"')" = 1 ] && echo 1 || echo 0)"

echo "--- DOM at 390x844: the F1 divergence ---"
agent-browser set viewport 390 844 >/dev/null 2>&1
agent-browser open "http://localhost:3000/players?league=pl&team=8650" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var p=(document.querySelector('[data-testid=squad-panel]')||{innerText:''}).innerText; (p.indexOf('سرمربی: Andoni Iraola')>=0?1:0)+'|'+(p.indexOf('سرمربی: آندونی ایرولا')===-1?1:0)+'|'+(p.indexOf('واتارو اندو')>=0?1:0)+'|'+(p.indexOf('برزیل')>=0?1:0)" | tr -d '"')
IFS='|' read -r A4 A5 A6 A7 <<< "$R"
ck "A4 /players squad header renders the RAW «سرمربی: Andoni Iraola» (F1 at its current state)" "$A4"
ck "A5 /players Persian variant «سرمربی: آندونی ایرولا» ABSENT (the finding)" "$A5"
ck "A6 /players squad names ride playerFa (the 395 hold, «واتارو اندو»)" "$A6"
ck "A7 /players nationality renders Persian (the 394 render-side hold, «برزیل»)" "$A7"

agent-browser open http://localhost:3000/team/8650 >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('آندونی ایرولا')>=0?1:0)+'|'+(t.indexOf('سرمربی: Andoni Iraola')>=0?1:0)" | tr -d '"')
IFS='|' read -r A8 A9 <<< "$R"
ck "A8 /team/8650 chip renders Persian «آندونی ایرولا» (the divergence witness)" "$A8"
ck "A9 /team/8650 «آخرین ترکیب» meta renders the RAW «سرمربی: Andoni Iraola» — F2 AT ITS CURRENT STATE (team-view:1551 LastLineupSection, the new finding)" "$A9"

echo "================ B: clean classes re-asserted ================"
ck "B1 0 mixed nameFa across the ten probed squads (the honesty contract)" "$(python3 -c "
import json, re, subprocess
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
LAT=re.compile(r'[A-Za-z]{2,}')
mixed=0
for tid in ['8650','10261','101610','8667','8044','6711','6706','8634','8256','6720']:
    out=subprocess.run(['curl','-s','-A',UA,'http://localhost:3000/api/team-squad/'+tid],capture_output=True,text=True,timeout=60)
    try: d=json.loads(out.stdout)
    except Exception: continue
    for g in (d.get('squad') or {}).get('groups') or []:
        for p in g.get('players') or []:
            n=(p.get('name') or '').strip(); nfa=(p.get('nameFa') or '').strip()
            if nfa and nfa!=n and LAT.search(nfa): mixed+=1
print(1 if mixed==0 else 0)")"
ck "B2 390 NT hold (/api/team/6711 ok:true)" "$(api /api/team/6711 | python3 -c "
import json,sys
print(1 if json.load(sys.stdin).get('ok') else 0)")"
ck "B3 391 venue hold (10261 nameFa present)" "$(api /api/team-venue/10261 | python3 -c "
import json,sys
d=json.load(sys.stdin)
v=d.get('venue') or d
print(1 if (v.get('nameFa') or '') else 0)")"
ck "B4 392 transfers hold (10261 feed ZERO raw rows)" "$(api /api/team-transfers/10261 | python3 -c "
import json,sys
items=((json.load(sys.stdin).get('transfers') or {}).get('items') or [])
bad=[i for i in items if (i.get('nameFa') or '').strip()==(i.get('name') or '').strip() and i.get('name')]
print(1 if not bad else 0)")"
for pair in "8650:0" "101610:6" "8044:2" "6706:1"; do
  T=${pair%%:*}; E=${pair##*:}
  ck "B5 395 squad exactness: $T raw=$E (documented absent stay raw)" "$(api "/api/team-squad/$T" | python3 -c "
import json,sys
d=json.load(sys.stdin)
n=0
for g in (d.get('squad') or {}).get('groups') or []:
    for p in g.get('players') or []:
        if (p.get('nameFa') or '').strip()==(p.get('name') or '').strip(): n+=1
print(1 if n == $E else 0)")"
done
ck "B6 match surface zero-Latin fa (5795503 whole payload, the 384 path)" "$(api /api/match/5795503 | python3 -c "
import json,sys
d=json.load(sys.stdin)
bad=[]
def scan(o,p=''):
    if isinstance(o,dict):
        for k,v in o.items(): scan(v,p+'.'+k)
    elif isinstance(o,list):
        for i,v in enumerate(o): scan(v,p+f'[{i}]')
    else:
        if p.endswith('.fa') and isinstance(o,str) and o and any(c.isascii() and c.isalpha() for c in o) and not any('\u0600'<=c<='\u06FF' for c in o): bad.append((p,o))
scan(d)
print(1 if not bad else 0)")"
ck "B7 the designed 404 contract (/standings bare → 404)" "$([ "$(st /standings)" = "404" ] && echo 1 || echo 0)"

echo "================ C: DOM patrol at 390x844 (six pages) ================"
agent-browser open http://localhost:3000/ >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.length>500?1:0)+'|'+(document.querySelector('header')?1:1)" | tr -d '"')
IFS='|' read -r C1 C2 <<< "$R"
ck "C1 home renders substantive Persian content" "$C1"

agent-browser open http://localhost:3000/league/pl >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('پریمیرلیگ')>=0?1:0)+'|'+(t.indexOf('برد')>=0||t.indexOf('امتیاز')>=0?1:0)" | tr -d '"')
IFS='|' read -r C3 C4 <<< "$R"
ck "C3 /league/pl Persian league anchor «پریمیرلیگ»" "$C3"
ck "C4 /league/pl standings table columns render (برد/امتیاز)" "$C4"

agent-browser open http://localhost:3000/team/101610 >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=team-squad]')||{innerText:''}).innerText; var t=document.body.innerText; (s.indexOf('ابوالفضل جلالی')>=0?1:0)+'|'+(s.indexOf('Jalali')===-1?1:0)+'|'+(s.indexOf('پیام نیازمند')>=0?1:0)+'|'+(t.indexOf('ورزشگاه آزادی')>=0?1:0)+'|'+(t.indexOf('تهران')>=0?1:0)" | tr -d '"')
IFS='|' read -r C5 C6 C6b C7 C7b <<< "$R"
ck "C5 /team/101610 squad «ابوالفضل جلالی» (the 395 hold)" "$C5"
ck "C6 /team/101610 Jalali raw absent in the squad section" "$C6"
ck "C6b /team/101610 squad «پیام نیازمند» (the 395 hold)" "$C6b"
ck "C7 /team/101610 venue «ورزشگاه آزادی» on the page (the 391 hold; the token rides the venue section — the 394 lesson: scope the WHOLE page)" "$C7"
ck "C7b /team/101610 venue city «تهران» renders Persian" "$C7b"

agent-browser open http://localhost:3000/match/5795503 >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.length>300?1:0)+'|'+(t.indexOf('پریمیرلیگ')>=0?1:0)" | tr -d '"')
IFS='|' read -r C8 C9 <<< "$R"
ck "C8 /match/5795503 renders substantive content" "$C8"
ck "C9 /match/5795503 Persian league anchor" "$C9"

echo "--- hygiene three-pack on six patrolled pages ---"
for PG in "" "league/pl" "team/8650" "team/101610" "match/5795503" "players?league=pl&team=8650"; do
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
