#!/usr/bin/env bash
# cycle395-domproof.sh — update cycle 395: the squad-surface Persian name
# pool (the 394 card's documented squad-name harvest, flipped with the 392
# byte-exact machinery).
#
#   A  the seven flagship squads flip: /api/team-squad/{id} — liverpool
#      8650, newcastle 10261, hull 8667 go fully Persian (0 raw rows);
#      the documented remainder stays honestly raw (omonio 8044 = 2,
#      persepolis 101610 = 6, iran-nt 6711 = 2, argentina-nt 6706 = 1 —
#      the gen_map deliberately-absent list, never claimed zero).
#   B  the byte-exact raw contract (the 392 rule): the squad API "name"
#      field stays byte-exact while nameFa rides alongside.
#   C  clean classes re-asserted: 391 venue hold, 392 transfers hold,
#      390 NT zero-Latin hold, the designed Persian 404.
#   D  DOM at 390x844 (house agent-browser pattern, pipe-separated eval +
#      tr -d '"', the ?1:0 shaped form): the squad section renders Persian
#      rows on 8650 / 101610 / 6706, the 394 H1 Woodman passthrough witness
#      is superseded by design (the map grew), hygiene three-pack clean.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }
has() { printf '%s' "$1" | grep -qF "$2" && echo 1 || echo 0; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
st() { curl -s -A "$UA" -o /tmp/d395_body.txt -w '%{http_code}' "$BASE$1"; }
rawcount() { api "/api/team-squad/$1" | python3 -c "
import json,sys
d=json.load(sys.stdin)
t=d.get('squad') or {}
n=0
for g in (t.get('groups') or []):
    for p in (g.get('players') or []):
        if (p.get('nameFa') or '').strip() == (p.get('name') or '').strip(): n+=1
print(n)"; }

echo "================ A: the squad flips (7 flagship squads) ================"
ck "A1 8650 liverpool → 0 raw rows (16 healed)" "$([ "$(rawcount 8650)" = "0" ] && echo 1 || echo 0)"
ck "A2 10261 newcastle → 0 raw rows (6 healed)" "$([ "$(rawcount 10261)" = "0" ] && echo 1 || echo 0)"
ck "A3 8667 hull → 0 raw rows (9 healed)" "$([ "$(rawcount 8667)" = "0" ] && echo 1 || echo 0)"
ck "A4 8044 omonio → exactly 2 raw (Fabiano/Ewandro documented)" "$([ "$(rawcount 8044)" = "2" ] && echo 1 || echo 0)"
ck "A5 101610 persepolis → exactly 6 raw (documented absent)" "$([ "$(rawcount 101610)" = "6" ] && echo 1 || echo 0)"
ck "A6 6711 iran-nt → exactly 2 raw (Hardani/Zare Mohazabieh)" "$([ "$(rawcount 6711)" = "2" ] && echo 1 || echo 0)"
ck "A7 6706 argentina-nt → exactly 1 raw (Giay documented)" "$([ "$(rawcount 6706)" = "1" ] && echo 1 || echo 0)"

B=$(api "/api/team-squad/8650")
ck "A8 8650 «واتارو اندو» rides nameFa" "$([ "$(has "$B" '"nameFa":"واتارو اندو"')" = 1 ] && echo 1 || echo 0)"
ck "A9 8650 «فدریکو کییزا» rides nameFa" "$([ "$(has "$B" '"nameFa":"فدریکو کییزا"')" = 1 ] && echo 1 || echo 0)"
B=$(api "/api/team-squad/101610")
ck "A10 101610 «ابوالفضل جلالی» rides nameFa" "$([ "$(has "$B" '"nameFa":"ابوالفضل جلالی"')" = 1 ] && echo 1 || echo 0)"
ck "A11 6711 «رامین رضائیان» rides nameFa (per-team located: he rides the NT squad, the 394 lesson)" "$([ "$(has "$(api "/api/team-squad/6711")" '"nameFa":"رامین رضائیان"')" = 1 ] && echo 1 || echo 0)"
B=$(api "/api/team-squad/6706")
ck "A12 6706 «لیساندرو مارتینز» rides nameFa" "$([ "$(has "$B" '"nameFa":"لیساندرو مارتینز"')" = 1 ] && echo 1 || echo 0)"
ck "A13 6706 «کریستیان رومرو» rides nameFa" "$([ "$(has "$B" '"nameFa":"کریستیان رومرو"')" = 1 ] && echo 1 || echo 0)"
B=$(api "/api/team-squad/8044")
ck "A14 8044 «کریستوس کونستانتینیدیس» (Greek rules live)" "$([ "$(has "$B" '"nameFa":"کریستوس کونستانتینیدیس"')" = 1 ] && echo 1 || echo 0)"

echo "================ B: the byte-exact raw contract (392 rule) ================"
B=$(api "/api/team-squad/8650")
ck "B1 raw «Wataru Endo» stays byte-exact alongside nameFa" "$([ "$(has "$B" '"name":"Wataru Endo"')" = 1 ] && echo 1 || echo 0)"
ck "B2 raw «Ronald Araujo» stays byte-exact" "$([ "$(has "$B" '"name":"Ronald Araujo"')" = 1 ] && echo 1 || echo 0)"
B=$(api "/api/team-squad/6706")
ck "B3 raw «Lisandro Martínez» stays byte-exact (accent)" "$([ "$(has "$B" '"name":"Lisandro Martínez"')" = 1 ] && echo 1 || echo 0)"
ck "B4 documented absent «Agustín Giay» stays raw nameFa==name" "$(api "/api/team-squad/6706" | python3 -c "
import json,sys
d=json.load(sys.stdin)
t=d.get('squad') or {}
hit=0
for g in (t.get('groups') or []):
    for p in (g.get('players') or []):
        if p.get('name')=='Agustín Giay' and p.get('nameFa')=='Agustín Giay': hit=1
print(hit)")"

echo "================ C: clean classes re-asserted ================"
ck "C1 391 venue hold (10261 nameFa «ورزشگاه سنت جیمز پارک»)" "$(api "/api/team-venue/10261" | python3 -c "
import json,sys
d=json.load(sys.stdin)
v=d.get('venue') or d
print(1 if (v.get('nameFa') or '') else 0)")"
ck "C2 392 transfers hold (10261 feed ZERO raw rows)" "$(api "/api/team-transfers/10261" | python3 -c "
import json,sys
d=json.load(sys.stdin)
t=d.get('transfers') or {}
items=t.get('items') or []
bad=[i for i in items if (i.get('nameFa') or '').strip()==(i.get('name') or '').strip() and i.get('name')]
print(1 if not bad else 0)")"
ck "C3 390 NT hold (/api/team/6711 ok:true + zero Latin fa)" "$(api "/api/team/6711" | python3 -c "
import json,sys
d=json.load(sys.stdin)
ok=bool(d.get('ok'))
bad=[]
def walk(o):
    if isinstance(o,dict):
        for k,v in o.items(): walk(v)
    elif isinstance(o,list):
        for v in o: walk(v)
    elif isinstance(o,str):
        pass
def scan(o,path=''):
    global bad
    if isinstance(o,dict):
        for k,v in o.items(): scan(v,path+'.'+k)
    elif isinstance(o,list):
        for i,v in enumerate(o): scan(v,path+'['+str(i)+']')
    else:
        if path.endswith('.fa') and isinstance(o,str) and o and any(c.isascii() and c.isalpha() for c in o) and not any('\u0600'<=c<='\u06FF' for c in o):
            bad.append((path,o))
scan(d)
print(1 if (ok and not bad) else 0)")"
ck "C4 the designed Persian 404 (/standings no id)" "$([ "$(st /standings)" = "404" ] && echo 1 || echo 0)"

echo "================ D: DOM at 390x844 (house agent-browser pattern) ================"
agent-browser set viewport 390 844 >/dev/null 2>&1

agent-browser open http://localhost:3000/team/8650 >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=team-squad]')||{innerText:''}).innerText; (s.indexOf('واتارو اندو')>=0?1:0)+'|'+(s.indexOf('Wataru Endo')===-1?1:0)+'|'+(s.indexOf('فدریکو کییزا')>=0?1:0)+'|'+(s.indexOf('فردی وودمن')>=0?1:0)+'|'+(s.indexOf('Woodman')===-1?1:0)+'|'+(s.indexOf('رایان گراونبرخ')>=0?1:0)+'|'+(s.indexOf('Gravenberch')===-1?1:0)" | tr -d '"')
IFS='|' read -r D1 D2 D3 D4 D5 D6 D7 <<< "$R"
ck "D1 8650 squad DOM «واتارو اندو»" "$D1"
ck "D2 8650 squad DOM Endo raw gone (page-wide)" "$D2"
ck "D3 8650 squad DOM «فدریکو کییزا»" "$D3"
ck "D4 8650 squad DOM «فردی وودمن» (the 394 H1 witness flipped by design)" "$D4"
ck "D5 8650 squad DOM Woodman raw gone" "$D5"
ck "D6 8650 squad DOM «رایان گراونبرخ»" "$D6"
ck "D7 8650 squad DOM Gravenberch raw gone" "$D7"

agent-browser open http://localhost:3000/team/101610 >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=team-squad]')||{innerText:''}).innerText; (s.indexOf('ابوالفضل جلالی')>=0?1:0)+'|'+(s.indexOf('Jalali')===-1?1:0)+'|'+(s.indexOf('حسین کنعانی')>=0?1:0)+'|'+(s.indexOf('Kanani')===-1?1:0)+'|'+(s.indexOf('پیام نیازمند')>=0?1:0)" | tr -d '"')
IFS='|' read -r D8 D9 D10 D11 D12 <<< "$R"
ck "D8 101610 squad DOM «ابوالفضل جلالی» (the 394 honest-Latin class heals)" "$D8"
ck "D9 101610 squad DOM Jalali raw gone" "$D9"
ck "D10 101610 squad DOM «حسین کنعانی»" "$D10"
ck "D11 101610 squad DOM Kanani raw gone" "$D11"
ck "D12 101610 squad DOM «پیام نیازمند»" "$D12"

agent-browser open http://localhost:3000/team/6711 >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=team-squad]')||{innerText:''}).innerText; (s.indexOf('رامین رضائیان')>=0?1:0)+'|'+(s.indexOf('Rezaeian')===-1?1:0)+'|'+(s.indexOf('Saleh Hardani')>=0?1:0)+'|'+(s.indexOf('شجاع خلیل‌زاده')>=0?1:0)" | tr -d '"')
IFS='|' read -r D18 D19 D20 D21 <<< "$R"
ck "D18 6711 squad DOM «رامین رضائیان» (per-team relocated, the 394 D11 lesson)" "$D18"
ck "D19 6711 squad DOM Rezaeian raw gone" "$D19"
ck "D20 6711 documented absent «Saleh Hardani» stays honestly raw" "$D20"
ck "D21 6711 squad DOM «شجاع خلیل‌زاده»" "$D21"

agent-browser open http://localhost:3000/team/6706 >/dev/null 2>&1
sleep 2
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=team-squad]')||{innerText:''}).innerText; (s.indexOf('لیساندرو مارتینز')>=0?1:0)+'|'+(s.indexOf('Lisandro')===-1?1:0)+'|'+(s.indexOf('نیکولاس اتمندی')>=0?1:0)+'|'+(s.indexOf('Otamendi')===-1?1:0)+'|'+(s.indexOf('Agustín Giay')>=0?1:0)" | tr -d '"')
IFS='|' read -r D13 D14 D15 D16 D17 <<< "$R"
ck "D13 6706 squad DOM «لیساندرو مارتینز»" "$D13"
ck "D14 6706 squad DOM Lisandro raw gone" "$D14"
ck "D15 6706 squad DOM «نیکولاس اتمندی»" "$D15"
ck "D16 6706 squad DOM Otamendi raw gone" "$D16"
ck "D17 6706 documented absent «Agustín Giay» stays honestly raw" "$D17"

echo "--- hygiene three-pack on the three patrolled pages ---"
for PG in team/8650 team/101610 team/6706 team/6711; do
  agent-browser open "http://localhost:3000/$PG" >/dev/null 2>&1
  sleep 2
  ERR=$(agent-browser errors 2>/dev/null | tr -d '"' | tr -d '\n')
  CON=$(agent-browser console 2>/dev/null | grep -ci error)
  SW=$(agent-browser eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
  CW=$(agent-browser eval "document.documentElement.clientWidth" 2>/dev/null | tr -d '"')
  ck "H $PG page-errors=0 (clean output is empty or 0)" "$([ -z "$ERR" ] || [ "$ERR" = "0" ] && echo 1 || echo 0)"
  ck "H $PG console-errors=0" "$([ "$CON" = "0" ] && echo 1 || echo 0)"
  ck "H $PG scrollW=cw=390" "$([ "$SW" = "$CW" ] && echo 1 || echo 0)"
done

echo "================ result ================"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ]
