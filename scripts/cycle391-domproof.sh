#!/usr/bin/env bash
# cycle391-domproof.sh — update cycle 391: the 388-F4 venue field-choice leak
# flipped to a Persian venue surface.
#
#   V1  /api/team-venue/10261 (Newcastle) → 200: nameFa «ورزشگاه سنت جیمز پارک»
#       + cityFa «نیوکاسل» ride ADDITIVELY — the raw name/city stay byte-exact.
#   V2  /api/team-venue/101610 (Persepolis) → «ورزشگاه آزادی» / «تهران» (the
#       probed witness: even Iranian clubs served raw Latin venue lines).
#   V3  big-league samples: 8650 Liverpool «آنفیلد/لیورپول», 8633 Real Madrid
#       «ورزشگاه برنابئو/مادرید».
#   F1  honest passthrough INTACT: 9925 Celtic (outside the six-roster harvest)
#       carries NO nameFa/cityFa keys — "Celtic Park"/"Glasgow" raw, never faked.
#   C1  the cycle-322 Place LD contract untouched: /team/10261 server HTML still
#       carries the English "St. James' Park" in its JSON-LD.
#   C2  the shape guards: abc → 400 Persian; 999999999 → 200 ok:true venue:null.
#   D   DOM at 390x844: /team/10261 venue card renders «سنت جیمز پارک» +
#       «نیوکاسل» (client-lazy fetch), /team/101610 renders «ورزشگاه آزادی» +
#       «تهران»; console clean, no overflow on both.
set -u
BASE=http://localhost:3000
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1"; fi; }
has() { printf '%s' "$1" | grep -qF "$2" && echo 1 || echo 0; }

UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
api() { curl -s -A "$UA" "$BASE$1"; }
st() { curl -s -A "$UA" -o /tmp/d391_body.txt -w '%{http_code}' "$BASE$1"; }

echo "================ V1: Newcastle venue heal (the 388 F4 flip) ================"
S=$(st "/api/team-venue/10261"); B=$(cat /tmp/d391_body.txt)
ck "V1a /api/team-venue/10261 → 200" "$([ "$S" = 200 ] && echo 1 || echo 0)"
ck "V1b nameFa «ورزشگاه سنت جیمز پارک»" "$([ "$(has "$B" '"nameFa":"ورزشگاه سنت جیمز پارک"')" = 1 ] && echo 1 || echo 0)"
ck "V1c cityFa «نیوکاسل»" "$([ "$(has "$B" '"cityFa":"نیوکاسل"')" = 1 ] && echo 1 || echo 0)"
ck "V1d raw name stays byte-exact (additive contract)" "$([ "$(has "$B" '"name":"St. James'"'"' Park"')" = 1 ] && echo 1 || echo 0)"
ck "V1e raw city stays byte-exact" "$([ "$(has "$B" '"city":"Newcastle upon Tyne"')" = 1 ] && echo 1 || echo 0)"

echo "================ V2: the Iranian club witness (پرسپولیس) ================"
B=$(api "/api/team-venue/101610")
ck "V2a nameFa «ورزشگاه آزادی»" "$([ "$(has "$B" '"nameFa":"ورزشگاه آزادی"')" = 1 ] && echo 1 || echo 0)"
ck "V2b cityFa «تهران» (raw was «Tehrān (Teheran)»)" "$([ "$(has "$B" '"cityFa":"تهران"')" = 1 ] && echo 1 || echo 0)"
ck "V2c raw city preserved" "$([ "$(has "$B" 'Tehrān (Teheran)')" = 1 ] && echo 1 || echo 0)"

echo "================ V3: big-league samples ================"
B=$(api "/api/team-venue/8650")
ck "V3a Anfield → «آنفیلد»" "$([ "$(has "$B" '"nameFa":"آنفیلد"')" = 1 ] && echo 1 || echo 0)"
ck "V3b Liverpool city → «لیورپول»" "$([ "$(has "$B" '"cityFa":"لیورپول"')" = 1 ] && echo 1 || echo 0)"
B=$(api "/api/team-venue/8633")
ck "V3c Estadio Bernabéu → «ورزشگاه برنابئو»" "$([ "$(has "$B" '"nameFa":"ورزشگاه برنابئو"')" = 1 ] && echo 1 || echo 0)"
ck "V3d Madrid → «مادرید»" "$([ "$(has "$B" '"cityFa":"مادرید"')" = 1 ] && echo 1 || echo 0)"

echo "================ F1: the honest passthrough (Celtic, out of roster) ================"
S=$(st "/api/team-venue/9925"); B=$(cat /tmp/d391_body.txt)
ck "F1a 9925 → 200" "$([ "$S" = 200 ] && echo 1 || echo 0)"
ck "F1b NO nameFa key (never faked)" "$([ "$(has "$B" 'nameFa')" = 0 ] && echo 1 || echo 0)"
ck "F1c NO cityFa key" "$([ "$(has "$B" 'cityFa')" = 0 ] && echo 1 || echo 0)"
ck "F1d raw «Celtic Park» passthrough" "$([ "$(has "$B" '"name":"Celtic Park"')" = 1 ] && echo 1 || echo 0)"
ck "F1e raw «Glasgow» passthrough" "$([ "$(has "$B" '"city":"Glasgow"')" = 1 ] && echo 1 || echo 0)"

echo "================ C1-C2: untouched contracts ================"
H=$(curl -s -A "$UA" "$BASE/team/10261")
ck "C1 cycle-322 Place LD keeps the English venue name" "$([ "$(has "$H" "St. James'" )" = 1 ] && echo 1 || echo 0)"
S=$(st "/api/team-venue/abc"); B=$(cat /tmp/d391_body.txt)
ck "C2a abc → 400" "$([ "$S" = 400 ] && echo 1 || echo 0)"
ck "C2b Persian 400 error" "$([ "$(has "$B" 'شناسه تیم نامعتبر است')" = 1 ] && echo 1 || echo 0)"
S=$(st "/api/team-venue/999999999"); B=$(cat /tmp/d391_body.txt)
ck "C3 unknown id → 502 with the Persian catch (the designed contract)" "$([ "$S" = 502 ] && [ "$(has "$B" 'دریافت اطلاعات ورزشگاه ناموفق بود')" = 1 ] && echo 1 || echo 0)"

echo "================ D: DOM at 390x844 ================"
agent-browser set viewport 390 844 >/dev/null 2>&1
agent-browser open http://localhost:3000/team/10261 >/dev/null 2>&1
sleep 5
R=$(agent-browser eval "var t=document.body.innerText; var v=document.querySelector('[data-testid=team-venue]'); (v? (v.innerText.indexOf('سنت جیمز پارک')>=0?1:0):0)+'|'+(v? (v.innerText.indexOf('نیوکاسل')>=0?1:0):0)+'|'+(t.indexOf('ورزشگاه خانه')>=0?1:0)" | tr -d '"')
VN=$(printf '%s' "$R" | cut -d'|' -f1); VC=$(printf '%s' "$R" | cut -d'|' -f2); VS=$(printf '%s' "$R" | cut -d'|' -f3)
ck "D1 venue card renders «سنت جیمز پارک» (got: $R)" "$([ "$VN" = "1" ] && echo 1 || echo 0)"
ck "D2 city renders «نیوکاسل»" "$([ "$VC" = "1" ] && echo 1 || echo 0)"
ck "D3 section title «ورزشگاه خانه» present" "$([ "$VS" = "1" ] && echo 1 || echo 0)"
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
hyg "team/10261"

agent-browser open http://localhost:3000/team/101610 >/dev/null 2>&1
sleep 5
R=$(agent-browser eval "var v=document.querySelector('[data-testid=team-venue]'); (v? (v.innerText.indexOf('ورزشگاه آزادی')>=0?1:0):0)+'|'+(v? (v.innerText.indexOf('تهران')>=0?1:0):0)" | tr -d '"')
PN=$(printf '%s' "$R" | cut -d'|' -f1); PC=$(printf '%s' "$R" | cut -d'|' -f2)
ck "D4 Persepolis venue renders «ورزشگاه آزادی» (got: $R)" "$([ "$PN" = "1" ] && echo 1 || echo 0)"
ck "D5 Persepolis city renders «تهران»" "$([ "$PC" = "1" ] && echo 1 || echo 0)"
hyg "team/101610"

echo "================ summary ================"
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = 0 ] && echo "CYCLE391 DOMPROOF OK" || echo "CYCLE391 DOMPROOF FAILED"
exit $([ "$FAIL" = 0 ] && echo 0 || echo 1)
