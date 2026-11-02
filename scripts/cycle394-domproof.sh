#!/usr/bin/env bash
# cycle394-domproof.sh — fix cycle 394: the flip of the 393 bug-hunt findings.
#
#   F1  the Argentina 6706 NT fixture rows served the OPPONENT fa raw
#       (Benin / Burkina Faso / Bolivia / Costa Rica — fa==name). Heal: the
#       393 card's four confident TEAM_FA country keys (teamFa checks
#       TEAM_FA before COUNTRY_FA).
#   F2  the squad render wire (the 388-F4 squad=83 class): SquadRow rendered
#       {p.name} directly and the squad API players carried NO nameFa at all,
#       so even fully-mapped names rendered raw Latin in «ترکیب تیم».
#       Heal: playerFa(p.name) in SquadRow (the one additive line) + additive
#       nameFa in getTeamSquad (the API for other consumers).
#   F2+ the same-row nationality class completed: SquadRow nationality, the
#       coach chip nationality and the /players squad-panel nationality now
#       ride teamFa (COUNTRY_FA, cycle-86+) — the 3-flagship-squad probe
#       showed only «Congo» and «Northern Ireland» were missing from the map
#       (added; 25 of 27 already rode cycle-86+).
# Honest passthrough asserted (the 96/104 contract — never faked):
#   H1  Freddie Woodman (unmapped) stays raw in the squad DOM.
#   H2  48 of the 83 distinct live squad names (3 flagship squads) stay raw —
#       documented, never claimed zero beyond the map (the 392 convention).
# Clean classes re-asserted:
#   C1  390 NT re-verified (/api/team/6711 200 ok:true + zero Latin fa).
#   C2  391 venue re-verified (10261 nameFa + raw byte-exact).
#   C3  392 transfers re-verified (10261 ZERO raw nameFa rows).
#   C4  the core pages + the designed Persian 404 contract.
#   D   DOM at 390x844 (house agent-browser pattern, pipe-separated eval +
#       tr -d '"'; hygiene three-pack on every patrolled page).
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }
has() { printf '%s' "$1" | grep -qF "$2" && echo 1 || echo 0; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
st() { curl -s -A "$UA" -o /tmp/d394_body.txt -w '%{http_code}' "$BASE$1"; }

echo "================ A: the F1 flip (Argentina 6706 NT opponents) ================"
B=$(api "/api/team/6706")
ck "A1 /api/team/6706 → ok:true" "$([ "$(has "$B" '"ok":true')" = 1 ] && echo 1 || echo 0)"
ck "A2 opponent «بنین» (the Benin flip)" "$([ "$(has "$B" '"fa":"بنین"')" = 1 ] && echo 1 || echo 0)"
ck "A3 opponent «بورکینافاسو» (the Burkina Faso flip)" "$([ "$(has "$B" '"fa":"بورکینافاسو"')" = 1 ] && echo 1 || echo 0)"
ck "A4 opponent «بولیوی» (the Bolivia flip)" "$([ "$(has "$B" '"fa":"بولیوی"')" = 1 ] && echo 1 || echo 0)"
ck "A5 opponent «کاستاریکا» (the Costa Rica flip)" "$([ "$(has "$B" '"fa":"کاستاریکا"')" = 1 ] && echo 1 || echo 0)"
ck "A6 /api/team/6706 ZERO Latin fa values (whole-payload scan)" "$(printf '%s' "$B" | python3 -c "
import json,sys
d=json.load(sys.stdin)
bad=[]
def walk(o,path=''):
    if isinstance(o,dict):
        for k,v in o.items(): walk(v,path+'.'+k)
    elif isinstance(o,list):
        for i,v in enumerate(o): walk(v,path+'['+str(i)+']')
    else:
        if path.endswith('.fa') and isinstance(o,str) and o and any(c.isascii() and c.isalpha() for c in o) and not any('\u0600'<=c<='\u06FF' for c in o):
            bad.append((path,o))
print(1 if not bad else 0)")"
ck "A7 /api/team/6711 zero Latin fa (Iran NT stays clean)" "$(api "/api/team/6711" | python3 -c "
import json,sys
d=json.load(sys.stdin)
bad=[]
def walk(o,path=''):
    if isinstance(o,dict):
        for k,v in o.items(): walk(v,path+'.'+k)
    elif isinstance(o,list):
        for i,v in enumerate(o): walk(v,path+'['+str(i)+']')
    else:
        if path.endswith('.fa') and isinstance(o,str) and o and any(c.isascii() and c.isalpha() for c in o) and not any('\u0600'<=c<='\u06FF' for c in o):
            bad.append((path,o))
print(1 if (d.get('ok') is True and not bad) else 0)")"

echo "================ B: the F2 API flip (squad nameFa, additive) ================"
B=$(api "/api/team-squad/8650")
ck "B1 squad 8650 every player carries nameFa" "$(printf '%s' "$B" | python3 -c "
import json,sys
d=json.load(sys.stdin)['squad']
ps=[p for g in d['groups'] for p in g['players']]
print(1 if len(ps)>0 and all('nameFa' in p and p['nameFa'] for p in ps) else 0)")"
ck "B2 Alisson Becker → «آلیسون بکر» (the 393 F2 witness)" "$([ "$(has "$B" '"name":"Alisson Becker","nameFa":"آلیسون بکر"')" = 1 ] && echo 1 || echo 0)"
ck "B3 raw name contract kept byte-exact" "$([ "$(has "$B" '"name":"Alisson Becker"')" = 1 ] && echo 1 || echo 0)"
ck "B4 honest passthrough: Freddie Woodman nameFa==name (unmapped)" "$(printf '%s' "$B" | python3 -c "
import json,sys
d=json.load(sys.stdin)['squad']
ps=[p for g in d['groups'] for p in g['players'] if p['name']=='Freddie Woodman']
print(1 if len(ps)==1 and ps[0]['nameFa']=='Freddie Woodman' else 0)")"
B=$(api "/api/team-squad/10261")
ck "B5 Nico González → «نیکو گونسالس» (the 393 F2e witness)" "$(printf '%s' "$B" | python3 -c "
import json,sys
d=json.load(sys.stdin)['squad']
ps=[p for g in d['groups'] for p in g['players'] if p['name']=='Nico González']
print(1 if len(ps)==1 and ps[0]['nameFa']=='نیکو گونسالس' else 0)")"
ck "B6 mapped-name count on the 3 flagship squads ≥ 30 (harvest: 35/83, the rest honest raw)" "$(for id in 8650 10261 101610; do api "/api/team-squad/$id"; echo; done | python3 -c "
import json,sys,re
src=open('src/lib/player-names-fa.ts').read()
m=re.search(r'const PLAYER_NAME_FA: Record<string, string> = \{(.*?)\n\};', src, re.S)
keys=set(re.findall(r'\"([^\"]+)\":', m.group(1)))
names=set()
for line in sys.stdin:
    line=line.strip()
    if not line: continue
    d=json.loads(line).get('squad') or {}
    for g in d.get('groups',[]):
        for p in g.get('players',[]):
            if p.get('name'): names.add(p['name'])
mapped=[n for n in names if n.strip().lower() in keys]
print(1 if len(mapped)>=30 else 0)")"

echo "================ C: the 390/391/392 holds + core pages ================"
S=$(st "/api/team/6711")
ck "C1 /api/team/6711 → 200 ok:true (390 holds)" "$([ "$S" = 200 ] && [ "$(has "$(cat /tmp/d394_body.txt)" '"ok":true')" = 1 ] && echo 1 || echo 0)"
B=$(api "/api/team-venue/10261")
ck "C2 venue 10261 nameFa + raw byte-exact (391 holds)" "$([ "$(has "$B" 'ورزشگاه سنت جیمز پارک')" = 1 ] && [ "$(has "$B" "\"name\":\"St. James' Park\"")" = 1 ] && echo 1 || echo 0)"
B=$(api "/api/team-transfers/10261")
ck "C3 transfers 10261 ZERO raw nameFa rows (392 holds)" "$(printf '%s' "$B" | python3 -c "
import json,sys
d=json.load(sys.stdin)
items=d['transfers']['items']
print(1 if len(items)>0 and all(it['nameFa']!=it['name'] for it in items) else 0)")"
S=$(st "/"); ck "C4a / → 200" "$([ "$S" = 200 ] && echo 1 || echo 0)"
S=$(st "/standings"); ck "C4b id-less /standings → designed Persian 404" "$([ "$S" = 404 ] && [ "$(has "$(cat /tmp/d394_body.txt)" '۴۰۴')" = 1 ] && echo 1 || echo 0)"

echo "================ D: DOM at 390x844 (house agent-browser pattern) ================"
agent-browser set viewport 390 844 >/dev/null 2>&1

# --- /team/8650: the squad-section flip (names + nationalities + coach) ---
agent-browser open http://localhost:3000/team/8650 >/dev/null 2>&1
sleep 6
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=team-squad]')||{innerText:''}).innerText; (s.indexOf('آلیسون بکر')>=0?1:0)+'|'+(s.indexOf('Alisson')===-1?1:0)+'|'+(s.indexOf('برزیل')>=0?1:0)+'|'+(s.indexOf('Brazil')===-1?1:0)+'|'+(s.indexOf('انگلیس')>=0?1:0)+'|'+(s.indexOf('England')===-1?1:0)+'|'+(s.indexOf('اسپانیا')>=0?1:0)+'|'+(s.indexOf('Woodman')>=0?1:0)+'|'+(s.indexOf('ایرلند شمالی')>=0?1:0)" | tr -d '"')
D1=$(printf '%s' "$R" | cut -d'|' -f1); D2=$(printf '%s' "$R" | cut -d'|' -f2); D3=$(printf '%s' "$R" | cut -d'|' -f3); D4=$(printf '%s' "$R" | cut -d'|' -f4); D5=$(printf '%s' "$R" | cut -d'|' -f5); D6=$(printf '%s' "$R" | cut -d'|' -f6); D7=$(printf '%s' "$R" | cut -d'|' -f7); D8=$(printf '%s' "$R" | cut -d'|' -f8); D18=$(printf '%s' "$R" | cut -d'|' -f9)
ck "D1 8650 squad section renders «آلیسون بکر» (got: $R)" "$([ "$D1" = "1" ] && echo 1 || echo 0)"
ck "D2 8650 squad section ZERO raw «Alisson» (the F2 flip)" "$([ "$D2" = "1" ] && echo 1 || echo 0)"
ck "D3 8650 squad section renders «برزیل» (nationality wire)" "$([ "$D3" = "1" ] && echo 1 || echo 0)"
ck "D4 8650 squad section ZERO raw «Brazil»" "$([ "$D4" = "1" ] && echo 1 || echo 0)"
ck "D5 8650 squad section renders «انگلیس»" "$([ "$D5" = "1" ] && echo 1 || echo 0)"
ck "D6 8650 squad section ZERO raw «England»" "$([ "$D6" = "1" ] && echo 1 || echo 0)"
ck "D7 8650 coach chip renders «اسپانیا» (the coach nationality wire)" "$([ "$D7" = "1" ] && echo 1 || echo 0)"
ck "D18 8650 squad section renders «ایرلند شمالی» — Conor Bradley (the added COUNTRY_FA key live)" "$([ "$D18" = "1" ] && echo 1 || echo 0)"
ck "H1 8650 honest passthrough: «Freddie Woodman» stays raw (never faked)" "$([ "$D8" = "1" ] && echo 1 || echo 0)"
hyg() { local ERR CON SW CW
  sleep 3
  ERR=$(agent-browser errors 2>/dev/null | tr -d '"' | tr -d '\n')
  CON=$(agent-browser console 2>/dev/null | grep -ci error)
  SW=$(agent-browser eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
  CW=$(agent-browser eval "document.documentElement.clientWidth" 2>/dev/null | tr -d '"')
  ck "$1 page-errors=0" "$([ -z "$ERR" ] && echo 1 || echo 0)"
  ck "$1 console-errors=0" "$([ "$CON" = "0" ] && echo 1 || echo 0)"
  ck "$1 scrollW=cw=390 (got $SW/$CW)" "$([ "$SW" = "390" ] && [ "$CW" = "390" ] && echo 1 || echo 0)"
}
hyg "team/8650"

# --- /team/10261: the F2e flip (page-wide raw gone, Persian row present) ---
agent-browser open http://localhost:3000/team/10261 >/dev/null 2>&1
sleep 6
R=$(agent-browser eval "var t=document.body.innerText; var s=(document.querySelector('[data-testid=team-squad]')||{innerText:''}).innerText; (s.indexOf('نیکو گونسالس')>=0?1:0)+'|'+(t.indexOf('Nico González')===-1?1:0)+'|'+(s.indexOf('ایرلند شمالی')>=0?1:0)" | tr -d '"')
D9=$(printf '%s' "$R" | cut -d'|' -f1); D10=$(printf '%s' "$R" | cut -d'|' -f2)
ck "D9 10261 squad section renders «نیکو گونسالس» (got: $R)" "$([ "$D9" = "1" ] && echo 1 || echo 0)"
ck "D10 10261 page-wide ZERO raw «Nico González» (the F2e flip)" "$([ "$D10" = "1" ] && echo 1 || echo 0)"
hyg "team/10261"

# --- /team/6706: the F1 DOM flip ---
agent-browser open http://localhost:3000/team/6706 >/dev/null 2>&1
sleep 5
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('بنین')>=0?1:0)+'|'+(t.indexOf('Benin')===-1?1:0)+'|'+(t.indexOf('بولیوی')>=0?1:0)+'|'+(t.indexOf('Bolivia')===-1?1:0)" | tr -d '"')
D12=$(printf '%s' "$R" | cut -d'|' -f1); D13=$(printf '%s' "$R" | cut -d'|' -f2); D14=$(printf '%s' "$R" | cut -d'|' -f3); D15=$(printf '%s' "$R" | cut -d'|' -f4)
ck "D12 6706 DOM renders «بنین» (got: $R)" "$([ "$D12" = "1" ] && echo 1 || echo 0)"
ck "D13 6706 DOM ZERO raw «Benin» (the F1 flip)" "$([ "$D13" = "1" ] && echo 1 || echo 0)"
ck "D14 6706 DOM renders «بولیوی»" "$([ "$D14" = "1" ] && echo 1 || echo 0)"
ck "D15 6706 DOM ZERO raw «Bolivia» (the 393 D4 evidence flipped)" "$([ "$D15" = "1" ] && echo 1 || echo 0)"
hyg "team/6706"

# --- /players?league=pl&team=8650: the squad-panel nationality wire ---
agent-browser open "http://localhost:3000/players?league=pl&team=8650" >/dev/null 2>&1
sleep 6
R=$(agent-browser eval "var p=(document.querySelector('[data-testid=squad-panel]')||{innerText:''}).innerText; (p.indexOf('برزیل')>=0?1:0)+'|'+(p.indexOf('Brazil')===-1?1:0)" | tr -d '"')
D16=$(printf '%s' "$R" | cut -d'|' -f1); D17=$(printf '%s' "$R" | cut -d'|' -f2)
ck "D16 /players squad panel renders «برزیل» (got: $R)" "$([ "$D16" = "1" ] && echo 1 || echo 0)"
ck "D17 /players squad panel ZERO raw «Brazil»" "$([ "$D17" = "1" ] && echo 1 || echo 0)"
hyg "players/8650"

# --- /team/101610: the second added key («Congo» → «کنگو», Thievy Bifouma) ---
agent-browser open http://localhost:3000/team/101610 >/dev/null 2>&1
sleep 5
R=$(agent-browser eval "var s=(document.querySelector('[data-testid=team-squad]')||{innerText:''}).innerText; (s.indexOf('کنگو')>=0?1:0)+'|'+(s.indexOf('Congo')===-1?1:0)" | tr -d '"')
D19=$(printf '%s' "$R" | cut -d'|' -f1); D20=$(printf '%s' "$R" | cut -d'|' -f2)
ck "D19 101610 squad section renders «کنگو» (got: $R)" "$([ "$D19" = "1" ] && echo 1 || echo 0)"
ck "D20 101610 squad section ZERO raw «Congo»" "$([ "$D20" = "1" ] && echo 1 || echo 0)"
hyg "team/101610"

echo "=== result ==="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE394 DOMPROOF OK" || echo "CYCLE394 DOMPROOF FAILED"
exit $([ "$FAIL" = "0" ] && echo 0 || echo 1)
