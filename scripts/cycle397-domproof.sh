#!/usr/bin/env bash
# cycle397-domproof.sh — update cycle 397: the coach-name Persian surface
# (the 396 bug-hunt F1/F2 flips + the coachFa coverage, the fresh declared
# gap of the latest card). The rotation-formula note: ((397 mod 5)+1)=۳=آپدیت.
#
#   A  the F1 flip: the /players squad-panel header renders Persian-first
#      (players-view.tsx:767 squad.coach.fa || squad.coach.name — the type
#      caught up) — the raw «سرمربی: Andoni Iraola» is GONE.
#   B  the F2 flip: getTeamLastLineup serves an additive coachNameFa
#      (coachFa by the same lls.coach id — the raw coachName contract stays
#      byte-exact) and the «آخرین ترکیب» meta renders fa-first.
#   C  the coachFa coverage: the 396 patrol's eight fallback benches join
#      COACH_SEED (ids probed live) — every flagship squad coach renders
#      Persian; the chips + the /coach pages keep riding the same seed.
#   D  holds re-asserted: the 395 squad raw-exactness, the 392 transfers
#      hold, the 391 venue hold, the match zero-Latin, the designed 404.
#   H  hygiene three-pack at 390x844 (house agent-browser pattern).
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }
has() { printf '%s' "$1" | grep -qF "$2" && echo 1 || echo 0; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
st() { curl -s -A "$UA" -o /tmp/d397_body.txt -w '%{http_code}' "$BASE$1"; }

echo "================ A: the F1 flip (/players header Persian-first) ================"
B=$(api "/api/team-squad/8650")
ck "A1 8650 API coach.fa «آندونی ایرولا» rides (unchanged data source)" "$([ "$(has "$B" '"fa":"آندونی ایرولا"')" = 1 ] && echo 1 || echo 0)"
ck "A2 8650 API coach.name byte-exact raw «Andoni Iraola» stays" "$([ "$(has "$B" '"name":"Andoni Iraola"')" = 1 ] && echo 1 || echo 0)"

agent-browser set viewport 390 844 >/dev/null 2>&1
agent-browser open "http://localhost:3000/players?league=pl&team=8650" >/dev/null 2>&1
sleep 3
R=$(agent-browser eval "var p=(document.querySelector('[data-testid=squad-panel]')||{innerText:''}).innerText; (p.indexOf('سرمربی: آندونی ایرولا')>=0?1:0)+'|'+(p.indexOf('سرمربی: Andoni Iraola')===-1?1:0)+'|'+(p.indexOf('واتارو اندو')>=0?1:0)" | tr -d '"')
IFS='|' read -r A3 A4 A5 <<< "$R"
ck "A3 /players header «سرمربی: آندونی ایرولا» (the F1 flip live)" "$A3"
ck "A4 /players raw «سرمربی: Andoni Iraola» GONE" "$A4"
ck "A5 /players squad names still ride playerFa (the 395 hold)" "$A5"

echo "================ B: the F2 flip (last-lineup meta Persian-first) ================"
B=$(api "/api/team-last-lineup/8650")
ck "B1 API coachNameFa «آندونی ایرولا» rides additively" "$([ "$(has "$B" '"coachNameFa":"آندونی ایرولا"')" = 1 ] && echo 1 || echo 0)"
ck "B2 API coachName byte-exact raw «Andoni Iraola» stays" "$([ "$(has "$B" '"coachName":"Andoni Iraola"')" = 1 ] && echo 1 || echo 0)"

agent-browser open http://localhost:3000/team/8650 >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('سرمربی: آندونی ایرولا')>=0?1:0)+'|'+(t.indexOf('سرمربی: Andoni Iraola')===-1?1:0)+'|'+(t.indexOf('آندونی ایرولا')>=0?1:0)" | tr -d '"')
IFS='|' read -r B3 B4 B5 <<< "$R"
ck "B3 /team/8650 «آخرین ترکیب» meta «سرمربی: آندونی ایرولا» (the F2 flip live)" "$B3"
ck "B4 /team/8650 raw «سرمربی: Andoni Iraola» GONE page-wide" "$B4"
ck "B5 /team/8650 chip «آندونی ایرولا» (the 259 hold)" "$B5"

echo "================ C: the coachFa coverage (the 396 patrol's eight benches) ================"
for pair in "6711:امیر قلعه‌نویی" "6706:لیونل اسکالونی" "8256:کارلو آنچلوتی" "6720:لوئیس د لا فوئنته" "10261:ماتیاس یایسله" "101610:مهدی طرطار" "8667:سرگی یاکیروویچ" "8044:هنینگ برگ"; do
  T=${pair%%:*}; FA=${pair##*:}
  B=$(api "/api/team-squad/$T")
  NEED="\"fa\":\"$FA\""
  ck "C $T coach fa «$FA» rides the squad API" "$([ "$(has "$B" "$NEED")" = 1 ] && echo 1 || echo 0)"
done
agent-browser open http://localhost:3000/team/6706 >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('لیونل اسکالونی')>=0?1:0)+'|'+(t.indexOf('Lionel Scaloni')===-1?1:0)+'|'+((document.querySelector('[data-testid=team-coaches]')||{innerText:''}).innerText.indexOf('لیونل اسکالونی')>=0?1:0)" | tr -d '"')
IFS='|' read -r C9 C10 C11 <<< "$R"
ck "C9 /team/6706 DOM «لیونل اسکالونی» (chip + last-lineup via one seed)" "$C9"
ck "C10 /team/6706 raw «Lionel Scaloni» gone page-wide (incl. the bench history — the 396-F2 class completion)" "$C10"
ck "C11 /team/6706 bench-history row «لیونل اسکالونی» (the history surface rides coachFa too)" "$C11"

echo "================ D: holds re-asserted ================"
for pair in "8650:0" "101610:6" "8044:2" "6706:1"; do
  T=${pair%%:*}; E=${pair##*:}
  ck "D1 395 squad exactness: $T raw=$E" "$(api "/api/team-squad/$T" | python3 -c "
import json,sys
d=json.load(sys.stdin)
n=0
for g in (d.get('squad') or {}).get('groups') or []:
    for p in g.get('players') or []:
        if (p.get('nameFa') or '').strip()==(p.get('name') or '').strip(): n+=1
print(1 if n == $E else 0)")"
done
ck "D2 392 transfers hold (10261 feed ZERO raw rows)" "$(api /api/team-transfers/10261 | python3 -c "
import json,sys
items=((json.load(sys.stdin).get('transfers') or {}).get('items') or [])
bad=[i for i in items if (i.get('nameFa') or '').strip()==(i.get('name') or '').strip() and i.get('name')]
print(1 if not bad else 0)")"
ck "D3 391 venue hold (10261 nameFa present)" "$(api /api/team-venue/10261 | python3 -c "
import json,sys
d=json.load(sys.stdin)
v=d.get('venue') or d
print(1 if (v.get('nameFa') or '') else 0)")"
ck "D4 match surface zero-Latin fa (5795503, the 384 path)" "$(api /api/match/5795503 | python3 -c "
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
ck "D5 the designed 404 contract (/standings bare → 404)" "$([ "$(st /standings)" = "404" ] && echo 1 || echo 0)"

echo "================ H: hygiene three-pack at 390x844 ================"
for PG in "team/8650" "team/6706" "team/101610" "players?league=pl&team=8650"; do
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
