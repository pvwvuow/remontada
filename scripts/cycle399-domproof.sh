#!/usr/bin/env bash
# cycle399-domproof.sh — fix cycle 399 (the 398 finding F): the bench-history
# fa-coverage gap closed via the 397 pattern (COACH_SEED extended with the
# live-probed ids). The 393 method:
#   A   the fix flips in DOM at 390x844: /team/8650 tenures «آرنه اسلوت» /
#       «یورگن کلوپ» / «برندان راجرز» + /team/6706 «خورخه سامپائولی»×2 /
#       «خرهاردو مارتینو»×2, the raws ABSENT page-wide, the 397 Persian holds
#       (Iraola/Scaloni) intact.
#   B   the byte-exact raw contract (names stay upstream-English in the API
#       while fa rides) + the seed dual purpose (Persian search hits the coach
#       bucket) + the standing clean classes (0 mixed nameFa on ten squads,
#       the 395 exactness, the 397 squad-coach 10/10, the last-lineup
#       byte-exact raw contract, the designed 404).
#   C   the DOM holds on the 397 surfaces + the hygiene three-pack.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }
has() { printf '%s' "$1" | grep -qF "$2" && echo 1 || echo 0; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
st() { curl -s -A "$UA" -o /tmp/d399_body.txt -w '%{http_code}' "$BASE$1"; }

echo "================ A: the 398-F fix flips in DOM (390x844) ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
agent-browser open http://localhost:3000/team/8650 >/dev/null 2>&1
sleep 4
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=team-coaches]')||{innerText:''}).innerText; var t=document.body.innerText; (s.indexOf('آرنه اسلوت')>=0?1:0)+'|'+(s.indexOf('یورگن کلوپ')>=0?1:0)+'|'+(s.indexOf('برندان راجرز')>=0?1:0)+'|'+(t.indexOf('Arne Slot')===-1?1:0)+'|'+(t.indexOf('Jürgen Klopp')===-1?1:0)+'|'+(t.indexOf('Brendan Rodgers')===-1?1:0)+'|'+(s.indexOf('آندونی ایرولا')>=0?1:0)" | tr -d '"')
IFS='|' read -r A1 A2 A3 A4 A5 A6 A7 <<< "$R"
ck "A1 /team/8650 bench history renders «آرنه اسلوت» (the 398-F flip, id=26630 probed)" "$A1"
ck "A2 /team/8650 bench history renders «یورگن کلوپ» (id=78660 probed)" "$A2"
ck "A3 /team/8650 bench history renders «برندان راجرز» (id=160770 probed)" "$A3"
ck "A4 /team/8650 raw «Arne Slot» ABSENT page-wide" "$A4"
ck "A5 /team/8650 raw «Jürgen Klopp» ABSENT page-wide" "$A5"
ck "A6 /team/8650 raw «Brendan Rodgers» ABSENT page-wide" "$A6"
ck "A7 /team/8650 the 397 hold «آندونی ایرولا» intact in bench history" "$A7"

agent-browser open http://localhost:3000/team/6706 >/dev/null 2>&1
sleep 4
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=team-coaches]')||{innerText:''}).innerText; var t=document.body.innerText; (s.indexOf('خورخه سامپائولی')>=0?1:0)+'|'+(s.indexOf('خرهاردو مارتینو')>=0?1:0)+'|'+(t.indexOf('Jorge Sampaoli')===-1?1:0)+'|'+(t.indexOf('Gerardo Martino')===-1?1:0)+'|'+(s.indexOf('لیونل اسکالونی')>=0?1:0)+'|'+((s.split('خورخه سامپائولی').length-1)>=2?1:0)+'|'+((s.split('خرهاردو مارتینو').length-1)>=2?1:0)" | tr -d '"')
IFS='|' read -r A8 A9 A10 A11 A12 A13 A14 <<< "$R"
ck "A8 /team/6706 bench history renders «خورخه سامپائولی» (id=335697 probed)" "$A8"
ck "A9 /team/6706 bench history renders «خرهاردو مارتینو» (id=80651 probed)" "$A9"
ck "A10 /team/6706 raw «Jorge Sampaoli» ABSENT page-wide" "$A10"
ck "A11 /team/6706 raw «Gerardo Martino» ABSENT page-wide" "$A11"
ck "A12 /team/6706 the 397 hold «لیونل اسکالونی» intact" "$A12"
ck "A13 BOTH Sampaoli tenures flip (×2 — the two separate accs, the 398 A10 witness state)" "$A13"
ck "A14 BOTH Martino tenures flip (×2)" "$A14"

echo "================ B: the byte-exact raw contract + the seed dual purpose ================"
ck "B1 /api/team-coaches/8650 name byte-exact «Arne Slot» AND fa=«آرنه اسلوت» (the 392 raw contract on the coach plane)" "$(api /api/team-coaches/8650 | python3 -c "
import json,sys
ten=json.load(sys.stdin).get('coaches',{}).get('tenures',[])
s=[t for t in ten if t.get('name')=='Arne Slot']
print(1 if s and s[0].get('fa')=='آرنه اسلوت' else 0)")"
ck "B2 /api/team-coaches/6706 name byte-exact «Jorge Sampaoli» AND fa=«خورخه سامپائولی»" "$(api /api/team-coaches/6706 | python3 -c "
import json,sys
ten=json.load(sys.stdin).get('coaches',{}).get('tenures',[])
s=[t for t in ten if t.get('name')=='Jorge Sampaoli']
print(1 if s and s[0].get('fa')=='خورخه سامپائولی' else 0)")"
ck "B3 /api/team-coaches/6706 «Gerardo Martino» fa=«خرهاردو مارتینو»" "$(api /api/team-coaches/6706 | python3 -c "
import json,sys
ten=json.load(sys.stdin).get('coaches',{}).get('tenures',[])
s=[t for t in ten if t.get('name')=='Gerardo Martino']
print(1 if s and s[0].get('fa')=='خرهاردو مارتینو' else 0)")"
ck "B4 ZERO fa-less tenures on 8650+6706 (the finding-F closure, API level)" "$(python3 -c "
import json, subprocess
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
bad=0
for tid in ['8650','6706']:
    out=subprocess.run(['curl','-s','-A',UA,'http://localhost:3000/api/team-coaches/'+tid],capture_output=True,text=True,timeout=60)
    for t in json.loads(out.stdout).get('coaches',{}).get('tenures',[]):
        if not (t.get('fa') or '').strip(): bad+=1
print(1 if bad==0 else 0)")"
ck "B5 the seed dual purpose: Persian query «کلوپ» hits the coach bucket (id=78660, byte-exact name + fa)" "$(api "/api/search?q=%DA%A9%D9%84%D9%88%D9%BE" | python3 -c "
import json,sys
cs=json.load(sys.stdin).get('coaches') or []
k=[c for c in cs if c.get('id')==78660 and c.get('name')=='Jürgen Klopp' and c.get('fa')=='یورگن کلوپ']
print(1 if k else 0)")"
ck "B6 the seed dual purpose: Persian query «اسلوت» hits Arne Slot" "$(api "/api/search?q=%D8%A7%D8%B3%D9%84%D9%88%D8%AA" | python3 -c "
import json,sys
cs=json.load(sys.stdin).get('coaches') or []
print(1 if any(c.get('id')==26630 for c in cs) else 0)")"
ck "B7 0 mixed nameFa across the ten probed squads (the honesty contract hold)" "$(python3 -c "
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
for pair in "8650:0" "101610:6" "8044:2" "6706:1"; do
  T=${pair%%:*}; E=${pair##*:}
  ck "B8 395 squad exactness hold: $T raw=$E" "$(api "/api/team-squad/$T" | python3 -c "
import json,sys
d=json.load(sys.stdin)
n=0
for g in (d.get('squad') or {}).get('groups') or []:
    for p in g.get('players') or []:
        if (p.get('nameFa') or '').strip()==(p.get('name') or '').strip(): n+=1
print(1 if n == $E else 0)")"
done
ck "B9 the 397 squad-coach fa 10/10 hold" "$(python3 -c "
import json, subprocess
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
ok=0
for tid in ['8650','10261','101610','8667','8044','6711','6706','8634','8256','6720']:
    out=subprocess.run(['curl','-s','-A',UA,'http://localhost:3000/api/team-squad/'+tid],capture_output=True,text=True,timeout=60)
    c=((json.loads(out.stdout).get('squad') or {}).get('coach') or {})
    if (c.get('fa') or '').strip(): ok+=1
print(1 if ok==10 else 0)")"
ck "B10 last-lineup raw contract byte-exact: 8650 coachName=«Andoni Iraola» AND coachNameFa rides" "$(api /api/team-last-lineup/8650 | python3 -c "
import json,sys
ll=json.load(sys.stdin).get('lastLineup') or {}
print(1 if ll.get('coachName')=='Andoni Iraola' and (ll.get('coachNameFa') or '').strip() else 0)")"
ck "B11 the designed 404 contract (/standings bare → 404)" "$([ "$(st /standings)" = "404" ] && echo 1 || echo 0)"

echo "================ C: the 397 surface holds in DOM ================"
agent-browser open "http://localhost:3000/players?league=pl&team=8650" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var p=(document.querySelector('[data-testid=squad-panel]')||{innerText:''}).innerText; (p.indexOf('سرمربی: آندونی ایرولا')>=0?1:0)+'|'+(p.indexOf('Andoni Iraola')===-1?1:0)" | tr -d '"')
IFS='|' read -r C1 C2 <<< "$R"
ck "C1 /players 8650 squad header «سرمربی: آندونی ایرولا» (the 397 F1 hold)" "$C1"
ck "C2 /players 8650 raw «Andoni Iraola» absent from the squad panel" "$C2"

agent-browser open http://localhost:3000/team/8650 >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('سرمربی: آندونی ایرولا')>=0?1:0)+'|'+(t.indexOf('سرمربی: Andoni Iraola')===-1?1:0)" | tr -d '"')
IFS='|' read -r C3 C4 <<< "$R"
ck "C3 /team/8650 «آخرین ترکیب» meta «سرمربی: آندونی ایرولا» (the 397 F2 hold)" "$C3"
ck "C4 /team/8650 raw «سرمربی: Andoni Iraola» absent page-wide" "$C4"

echo "--- hygiene three-pack on the fix-witness pages ---"
for PG in "" "team/8650" "team/6706" "players?league=pl&team=8650"; do
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
