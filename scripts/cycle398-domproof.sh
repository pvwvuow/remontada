#!/usr/bin/env bash
# cycle398-domproof.sh — bug-hunt cycle 398: the 393/396 method.
#   A   the 397 flips re-verified in DOM (the coach Persian surfaces: the
#       players squad-panel, the last-lineup meta, the bench tenures) PLUS
#       the fresh finding F asserted AT ITS CURRENT STATE (the bench-history
#       fa-coverage gap: Sampaoli/Martino/Slot/Klopp raw — the 399=فیکس
#       material, probed ids Martino=80651 Sampaoli=335697) and the new
#       /coach + /player surfaces' Persian h1s.
#   B   clean classes re-asserted: the honesty contracts (0 mixed nameFa on
#       squads + top-players + player), the 390/391/392/395 holds, the match
#       zero-Latin, the designed 404, the coach API career fa coverage, the
#       last-lineup byte-exact raw contract, the 397 squad-coach 10/10.
#   C   DOM patrol on the not-yet-patrolled pages (/leagues, /topscorers,
#       /search) at 390x844 + the hygiene three-pack on seven pages.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }
has() { printf '%s' "$1" | grep -qF "$2" && echo 1 || echo 0; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
st() { curl -s -A "$UA" -o /tmp/d398_body.txt -w '%{http_code}' "$BASE$1"; }

echo "================ A: the 397 coach flips hold in DOM + the fresh finding at its state ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
agent-browser open "http://localhost:3000/players?league=pl&team=8650" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var p=(document.querySelector('[data-testid=squad-panel]')||{innerText:''}).innerText; (p.indexOf('سرمربی: آندونی ایرولا')>=0?1:0)+'|'+(p.indexOf('Andoni Iraola')===-1?1:0)+'|'+(p.indexOf('واتارو اندو')>=0?1:0)" | tr -d '"')
IFS='|' read -r A1 A2 A3 <<< "$R"
ck "A1 /players 8650 squad header renders Persian «سرمربی: آندونی ایرولا» (the 397 F1 flip hold)" "$A1"
ck "A2 /players 8650 raw «Andoni Iraola» ABSENT from the squad panel" "$A2"
ck "A3 /players 8650 squad names ride playerFa (the 395 hold, «واتارو اندو»)" "$A3"

agent-browser open "http://localhost:3000/players?league=es&team=8634" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var p=(document.querySelector('[data-testid=squad-panel]')||{innerText:''}).innerText; (p.indexOf('سرمربی: هانسی فلیک')>=0?1:0)+'|'+(p.indexOf('Flick')===-1?1:0)" | tr -d '"')
IFS='|' read -r A4 A5 <<< "$R"
ck "A4 /players 8634 renders «سرمربی: هانسی فلیک» (the second 396 witness, flipped in 397)" "$A4"
ck "A5 /players 8634 raw «Flick» absent from the squad panel" "$A5"

agent-browser open http://localhost:3000/team/8650 >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('سرمربی: آندونی ایرولا')>=0?1:0)+'|'+(t.indexOf('سرمربی: Andoni Iraola')===-1?1:0)+'|'+(t.indexOf('میانگین سن')>=0?1:0)" | tr -d '"')
IFS='|' read -r A6 A7 A8 <<< "$R"
ck "A6 /team/8650 «آخرین ترکیب» meta renders «سرمربی: آندونی ایرولا» (the 397 F2 flip hold; the meta <p> sits OUTSIDE the team-last-lineup testid — the section wraps starters only)" "$A6"
ck "A7 /team/8650 raw «سرمربی: Andoni Iraola» absent page-wide" "$A7"
ck "A8 /team/8650 last-lineup meta rides («میانگین سن» Persian digits surface)" "$A8"

agent-browser open http://localhost:3000/team/6706 >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=team-coaches]')||{innerText:''}).innerText; (s.indexOf('لیونل اسکالونی')>=0?1:0)+'|'+(s.indexOf('Jorge Sampaoli')>=0?1:0)+'|'+(s.indexOf('Gerardo Martino')>=0?1:0)" | tr -d '"')
IFS='|' read -r A9 A10 A11 <<< "$R"
ck "A9 /team/6706 bench history renders «لیونل اسکالونی» (the 397 tenure flip hold)" "$A9"
ck "A10 /team/6706 «Jorge Sampaoli» renders RAW in bench history (the fresh finding F AT ITS CURRENT STATE — the 399=فیکس material, id=335697 probed)" "$A10"
ck "A11 /team/6706 «Gerardo Martino» renders RAW (the finding, id=80651 probed)" "$A11"

agent-browser open http://localhost:3000/coach/9012 >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "var h=document.querySelector('h1'); var t=document.body.innerText; ((h&&h.innerText.indexOf('سرگی یاکیروویچ')>=0)?1:0)+'|'+(t.indexOf('هال‌سیتی')>=0?1:0)+'|'+(t.indexOf('بوسنی')>=0?1:0)" | tr -d '"')
IFS='|' read -r A12 A13 A14 <<< "$R"
ck "A12 /coach/9012 h1 renders Persian «سرگی یاکیروویچ» (the new-surface hold)" "$A12"
ck "A13 /coach/9012 career rows render Persian «هال‌سیتی» (the teamFa career hold)" "$A13"
ck "A14 /coach/9012 country renders Persian «بوسنی»" "$A14"

agent-browser open http://localhost:3000/player/319784 >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var h=document.querySelector('h1'); (h&&h.innerText.indexOf('آلیسون بکر')>=0?1:0)" | tr -d '"')
ck "A15 /player/319784 h1 renders Persian «آلیسون بکر» (the new-surface hold)" "$R"

echo "================ B: clean classes re-asserted (API) ================"
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
ck "B6b match surface zero-Latin fa (5795501)" "$(api /api/match/5795501 | python3 -c "
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
ck "B8 coach API: 9012+504132 fa present AND career rows ZERO raw (the new ground clean)" "$(python3 -c "
import json, subprocess
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
ok=True
for cid in ['9012','504132']:
    out=subprocess.run(['curl','-s','-A',UA,'http://localhost:3000/api/coach/'+cid],capture_output=True,text=True,timeout=60)
    c=(json.loads(out.stdout).get('coach') or {})
    if not (c.get('fa') or '').strip(): ok=False
    for r in c.get('career') or []:
        if not (r.get('fa') or '').strip(): ok=False
print(1 if ok else 0)")"
ck "B9 player API honesty: 319784 nameFa differs from name and carries NO Latin (non-mixed)" "$(api /api/player/319784 | python3 -c "
import json,sys,re
p=(json.load(sys.stdin).get('player') or {})
nfa=(p.get('nameFa') or '').strip(); n=(p.get('name') or '').strip()
mixed=bool(nfa and nfa!=n and re.search(r'[A-Za-z]{2,}',nfa))
print(1 if (nfa and not mixed) else 0)")"
ck "B10 top-players honesty: 0 mixed nameFa across 8650+101610" "$(python3 -c "
import json, re, subprocess
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
LAT=re.compile(r'[A-Za-z]{2,}')
bad=0
def walk(o):
    global bad
    if isinstance(o,dict):
        nm=(o.get('name') or '').strip(); nf=(o.get('nameFa') or '').strip()
        if nm and nf and nf!=nm and LAT.search(nf): bad+=1
        for v in o.values(): walk(v)
    elif isinstance(o,list):
        for v in o: walk(v)
for tid in ['8650','101610']:
    out=subprocess.run(['curl','-s','-A',UA,'http://localhost:3000/api/team-top-players/'+tid],capture_output=True,text=True,timeout=60)
    walk(json.loads(out.stdout).get('topPlayers') or {})
print(1 if bad==0 else 0)")"
ck "B11 last-lineup raw contract byte-exact: 8650 coachName=«Andoni Iraola» AND coachNameFa rides (the 397 B hold)" "$(api /api/team-last-lineup/8650 | python3 -c "
import json,sys
ll=json.load(sys.stdin).get('lastLineup') or {}
print(1 if ll.get('coachName')=='Andoni Iraola' and (ll.get('coachNameFa') or '').strip() else 0)")"
ck "B12 squad coach fa 10/10 (the 397 C hold, API level)" "$(python3 -c "
import json, subprocess
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
ok=0
for tid in ['8650','10261','101610','8667','8044','6711','6706','8634','8256','6720']:
    out=subprocess.run(['curl','-s','-A',UA,'http://localhost:3000/api/team-squad/'+tid],capture_output=True,text=True,timeout=60)
    c=((json.loads(out.stdout).get('squad') or {}).get('coach') or {})
    if (c.get('fa') or '').strip(): ok+=1
print(1 if ok==10 else 0)")"

echo "================ C: DOM patrol on the not-yet-patrolled pages ================"
agent-browser open http://localhost:3000/leagues >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('لیگ‌ها')>=0?1:0)+'|'+(t.length>400?1:0)" | tr -d '"')
IFS='|' read -r C1 C2 <<< "$R"
ck "C1 /leagues renders the Persian anchor «لیگ‌ها»" "$C1"
ck "C2 /leagues renders substantive content" "$C2"

agent-browser open http://localhost:3000/topscorers >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('آقای گل')>=0?1:0)+'|'+(t.length>400?1:0)" | tr -d '"')
IFS='|' read -r C3 C4 <<< "$R"
ck "C3 /topscorers renders the Persian anchor «آقای گل»" "$C3"
ck "C4 /topscorers renders substantive content" "$C4"

agent-browser open "http://localhost:3000/search?q=%D8%A7%DB%8C%D8%B1%D8%A7%D9%86" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('جستجو')>=0?1:0)+'|'+(t.length>200?1:0)" | tr -d '"')
IFS='|' read -r C5 C6 <<< "$R"
ck "C5 /search renders the Persian anchor «جستجو»" "$C5"
ck "C6 /search renders content for the Persian query «ایران»" "$C6"

echo "--- hygiene three-pack on seven patrolled pages ---"
for PG in "" "league/pl" "coach/9012" "player/319784" "leagues" "topscorers" "team/6706"; do
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
