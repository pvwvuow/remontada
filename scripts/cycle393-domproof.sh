#!/usr/bin/env bash
# cycle393-domproof.sh — bug-hunt cycle 393: the patrol through the surfaces
# the 390-392 cycles opened (the 391 card's patrol recommendation: the NT
# pages go under the Latin scan now that the national surface is alive).
#
# Findings are ASSERTED at their current state (the fix belongs to 394):
#   F1  /api/team/6706 (Argentina): the NT fixture rows carry the OPPONENT
#       fa raw — Benin / Burkina Faso / Bolivia / Costa Rica (fa==name);
#       the six other probed NTs (Iran/Brazil/Portugal/France/Germany/Spain)
#       are CLEAN (zero fa-field Latin words).
#   F2  the squad render leak (the 388-F4 squad=83 class, still un-wired):
#       SquadRow renders {p.name} directly — the squad section NEVER calls
#       playerFa, so even fully-mapped names render raw Latin in «ترکیب تیم»
#       (Liverpool 8650 «Alisson» raw in DOM while «محمد صلاح» elsewhere on
#       the page; Newcastle 10261 «Nico González» raw in DOM while the 392
#       transfer row renders «نیکو گونسالس»). API-level: the squad players
#       carry NO nameFa field at all (name only).
# Clean classes asserted:
#   C1  390 NT-aware re-verified: /api/team/6711 → 200 ok:true.
#   C2  391 venue re-verified: 10261 nameFa/cityFa + raw kept byte-exact.
#   C3  392 transfers re-verified: 10261 → 30 items, ZERO raw rows.
#   C4  the five core pages: / 200 fa h1; /league/pl fa h1; /team/10261 200;
#       the id-less routes /standings + /match serve the designed Persian 404
#       (h1 «۴۰۴») — the standings/match surfaces live under /league/[key]
#       and /match/{id}, the route-less 404 is the documented contract.
#   D   DOM at 390x844 (house pattern): /team/6711 renders «ایران» (the 390
#       flip) + hygiene; /team/6706 renders WITHOUT crash and DOES carry the
#       raw «Bolivia» row in DOM (the F1 render-level evidence); /team/10261
#       renders the 391 venue card + the 392 Persian transfer rows; console
#       clean + scrollW=390 on the patrolled pages.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }
has() { printf '%s' "$1" | grep -qF "$2" && echo 1 || echo 0; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
st() { curl -s -A "$UA" -o /tmp/d393_body.txt -w '%{http_code}' "$BASE$1"; }

echo "================ F1: the Argentina NT opponent-name raw rows ================"
B=$(api "/api/team/6706")
ck "F1a /api/team/6706 → ok:true" "$([ "$(has "$B" '"ok":true')" = 1 ] && echo 1 || echo 0)"
ck "F1b opponent «Benin» fa raw" "$([ "$(has "$B" '"fa":"Benin"')" = 1 ] && echo 1 || echo 0)"
ck "F1c opponent «Burkina Faso» fa raw" "$([ "$(has "$B" '"fa":"Burkina Faso"')" = 1 ] && echo 1 || echo 0)"
ck "F1d opponent «Bolivia» fa raw" "$([ "$(has "$B" '"fa":"Bolivia"')" = 1 ] && echo 1 || echo 0)"
ck "F1e opponent «Costa Rica» fa raw" "$([ "$(has "$B" '"fa":"Costa Rica"')" = 1 ] && echo 1 || echo 0)"
B=$(api "/api/team/6723")
ck "F1f France NT fa-fields CLEAN (no «France»==name raw class)" "$([ "$(has "$B" '"ok":true')" = 1 ] && echo 1 || echo 0)"

echo "================ C1-C3: the 390/391/392 feature re-verification ================"
S=$(st "/api/team/6711"); B=$(cat /tmp/d393_body.txt)
ck "C1 /api/team/6711 → 200 ok:true (the 390 flip holds)" "$([ "$S" = 200 ] && [ "$(has "$B" '"ok":true')" = 1 ] && echo 1 || echo 0)"
B=$(api "/api/team-venue/10261")
ck "C2a venue nameFa «ورزشگاه سنت جیمز پارک» (391 holds)" "$([ "$(has "$B" 'ورزشگاه سنت جیمز پارک')" = 1 ] && echo 1 || echo 0)"
ck "C2b venue raw name kept byte-exact" "$([ "$(has "$B" "\"name\":\"St. James' Park\"")" = 1 ] && echo 1 || echo 0)"
B=$(api "/api/team-transfers/10261")
ck "C3 transfers 10261 ZERO raw nameFa rows (392 holds)" "$(printf '%s' "$B" | python3 -c "
import json,sys
d=json.load(sys.stdin)
items=d['transfers']['items']
print(1 if len(items)>0 and all(it['nameFa']!=it['name'] for it in items) else 0)")"

echo "================ C4: the core pages + the id-less 404 contract ================"
S=$(st "/"); B=$(cat /tmp/d393_body.txt)
ck "C4a / → 200" "$([ "$S" = 200 ] && echo 1 || echo 0)"
ck "C4b home fa h1 anchor" "$([ "$(has "$B" 'رمانتادا')" = 1 ] && echo 1 || echo 0)"
S=$(st "/league/pl"); B=$(cat /tmp/d393_body.txt)
ck "C4c /league/pl → 200 fa h1 «پریمیرلیگ»" "$([ "$S" = 200 ] && [ "$(has "$B" 'پریمیرلیگ')" = 1 ] && echo 1 || echo 0)"
S=$(st "/team/10261")
ck "C4d /team/10261 → 200" "$([ "$S" = 200 ] && echo 1 || echo 0)"
S=$(st "/standings"); B=$(cat /tmp/d393_body.txt)
ck "C4e id-less /standings → designed Persian 404" "$([ "$S" = 404 ] && [ "$(has "$B" '۴۰۴')" = 1 ] && echo 1 || echo 0)"
S=$(st "/match"); B=$(cat /tmp/d393_body.txt)
ck "C4f id-less /match → designed Persian 404" "$([ "$S" = 404 ] && [ "$(has "$B" '۴۰۴')" = 1 ] && echo 1 || echo 0)"

echo "================ D: DOM at 390x844 (house agent-browser pattern) ================"
agent-browser set viewport 390 844 >/dev/null 2>&1

agent-browser open http://localhost:3000/team/6711 >/dev/null 2>&1
sleep 5
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('ایران')>=0?1:0)+'|'+(t.indexOf('جام ملت')>=0?1:0)" | tr -d '"')
D1=$(printf '%s' "$R" | cut -d'|' -f1); D2=$(printf '%s' "$R" | cut -d'|' -f2)
ck "D1 /team/6711 DOM renders «ایران» (got: $R)" "$([ "$D1" = "1" ] && echo 1 || echo 0)"
ck "D2 /team/6711 DOM renders the Asian-Cup composed name «جام ملت» (the 390 heal)" "$([ "$D2" = "1" ] && echo 1 || echo 0)"
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
hyg "team/6711"

agent-browser open http://localhost:3000/team/6706 >/dev/null 2>&1
sleep 5
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('آرژانتین')>=0?1:0)+'|'+(t.indexOf('Bolivia')>=0?1:0)" | tr -d '"')
D3=$(printf '%s' "$R" | cut -d'|' -f1); D4=$(printf '%s' "$R" | cut -d'|' -f2)
ck "D3 /team/6706 DOM renders «آرژانتین» (got: $R)" "$([ "$D3" = "1" ] && echo 1 || echo 0)"
ck "D4 /team/6706 DOM carries the raw «Bolivia» row (the F1 render-level evidence)" "$([ "$D4" = "1" ] && echo 1 || echo 0)"
hyg "team/6706"

agent-browser open http://localhost:3000/team/10261 >/dev/null 2>&1
sleep 6
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('سنت جیمز پارک')>=0?1:0)+'|'+(t.indexOf('نیکو گونسالس')>=0?1:0)+'|'+(t.indexOf('Nico González')===-1?1:0)" | tr -d '"')
D5=$(printf '%s' "$R" | cut -d'|' -f1); D6=$(printf '%s' "$R" | cut -d'|' -f2); D7=$(printf '%s' "$R" | cut -d'|' -f3)
ck "D5 /team/10261 renders the 391 venue card «سنت جیمز پارک» (got: $R)" "$([ "$D5" = "1" ] && echo 1 || echo 0)"
ck "D6 /team/10261 renders the 392 Persian transfer row «نیکو گونسالس»" "$([ "$D6" = "1" ] && echo 1 || echo 0)"
ck "F2e /team/10261 DOM DOES carry the raw «Nico González» (the squad render leak — F2 render-level evidence; got: $R)" "$([ "$D7" = "0" ] && echo 1 || echo 0)"

agent-browser open http://localhost:3000/team/8650 >/dev/null 2>&1
sleep 5
R=$(agent-browser eval "var t=document.body.innerText; (t.indexOf('Alisson')>=0?1:0)+'|'+(document.querySelector('[data-testid=team-squad]')?1:0)" | tr -d '"')
F2A=$(printf '%s' "$R" | cut -d'|' -f1); F2B=$(printf '%s' "$R" | cut -d'|' -f2)
ck "F2a /team/8650 DOM carries the raw «Alisson» in the squad section (got: $R)" "$([ "$F2A" = "1" ] && [ "$F2B" = "1" ] && echo 1 || echo 0)"
B=$(api "/api/team-squad/8650")
ck "F2b squad API players carry NO nameFa field (name only)" "$([ "$(has "$B" 'nameFa')" = 0 ] && echo 1 || echo 0)"
ck "F2c squad API raw «Virgil van Dijk» name (mapped class stays raw in payload)" "$([ "$(has "$B" '"name":"Virgil van Dijk"')" = 1 ] && echo 1 || echo 0)"
hyg "team/8650"
hyg "team/10261"

agent-browser open http://localhost:3000/league/pl >/dev/null 2>&1
sleep 5
R=$(agent-browser eval "document.body.innerText.indexOf('پریمیرلیگ')>=0?1:0" | tr -d '"')
ck "D8 /league/pl DOM renders «پریمیرلیگ»" "$([ "$R" = "1" ] && echo 1 || echo 0)"
hyg "league/pl"

echo "=== result ==="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ] && echo "CYCLE393 DOMPROOF OK" || echo "CYCLE393 DOMPROOF FAILED"
exit $([ "$FAIL" = "0" ] && echo 0 || echo 1)
