#!/bin/bash
# Cycle-111 update DOM proof at 390x844 — standings zone legend («راهنمای
# سهمیه‌ها»). The feature: the league payload's table legend (qualification/
# relegation zones) rendered through the curated Persian tKey map as a footer
# under the standings table (testid=standings-legend) — explaining the
# per-row qualColor strips that had no explanation since the beginning.
# Proof:
#   1) API truth: /api/standings/{pl,seriea,ucl} carry legend with the right
#      Persian titles + colors; persiangulf carries none (feed has no table),
#   2) DOM: /league/pl shows the legend footer («لیگ قهرمانان اروپا»، «لیگ
#      اروپا»، «سقوط»), /league/seriea shows «سهمیهٔ کنفرانس‌لیگ»، /league/ucl
#      shows «صعود به یک‌هشتم نهایی», /league/persiangulf hides the legend,
#   3) contracts: sw=cw=390, exactly 1 h1, 0 broken imgs, console=0, appErr=0.
set -u
B=agent-browser
FAIL=0

$B set viewport 390 844 >/dev/null

# — API truth —
for LK in pl seriea ucl persiangulf; do
  API=$(curl -s "http://localhost:3000/api/standings?league=$LK" | python3 -c "
import json,sys
try:
  d=json.load(sys.stdin)
  lg=d.get('legend') or []
  print(json.dumps([x['fa'] for x in lg],ensure_ascii=False))
except Exception as e:
  print('ERR')
")
  echo "[api $LK] legend=$API"
  case "$LK" in
    pl)  echo "$API" | grep -q "لیگ قهرمانان اروپا" && echo "$API" | grep -q "سقوط" || { FAIL=1; echo "  !! pl legend wrong"; };;
    seriea) echo "$API" | grep -q "سهمیهٔ کنفرانس‌لیگ" || { FAIL=1; echo "  !! seriea legend wrong"; };;
    ucl) echo "$API" | grep -q "یک‌هشتم نهایی" || { FAIL=1; echo "  !! ucl legend wrong"; };;
    persiangulf) [ "$API" = "[]" ] || { FAIL=1; echo "  !! persiangulf should have no legend"; };;
  esac
done

# — DOM checks —
check_page () { # $1=url $2=label $3=need-persian(0 = must be ABSENT) $4=eval-expr
  local URL="$1" LABEL="$2" NEED="$3" EXPR="$4"
  $B errors --clear >/dev/null 2>&1
  $B console --clear >/dev/null 2>&1
  $B open "$URL" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 2.5
  local BM RES CON ERR
  BM=$($B eval 'JSON.stringify((()=>{const de=document.documentElement;return {sw:window.innerWidth,cw:de.clientWidth,h1:document.querySelectorAll("h1").length,img:[...document.images].filter(i=>i.complete&&i.naturalWidth===0).length}})())' 2>/dev/null | tr -d '"\\')
  RES=$($B eval "$EXPR" 2>/dev/null | tr -d '"\\')
  CON=$($B console 2>/dev/null | grep -ci error || true)
  ERR=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len([e for e in d['data']['errors'] if e.get('url')]))
except Exception:
  print('ERR')")
  echo "[$LABEL] bm=$BM legend=$RES consoleErr=$CON pageErr=$ERR"
  case "$BM" in *"sw:390,"*|*'"sw":390,'*) ;; *) FAIL=1; echo "  !! viewport contract broken";; esac
  case "$BM" in *"h1:1,"*|*'"h1":1,'*) ;; *) FAIL=1; echo "  !! h1 count != 1";; esac
  case "$BM" in *"img:0"*|*'"img":0'*) ;; *) FAIL=1; echo "  !! broken images";; esac
  [ "$CON" = "0" ] || { FAIL=1; echo "  !! console errors"; }
  [ "$ERR" = "0" ] || { FAIL=1; echo "  !! page errors"; }
}

LEGEND_EXPR='JSON.stringify((()=>{const c=document.querySelector("[data-testid=standings-legend]");if(!c)return {present:false};const t=c.innerText||"";return {present:true,chips:c.querySelectorAll("span span").length,text:t.slice(0,120)}})())'
NOLEGEND_EXPR='JSON.stringify({present:!!document.querySelector("[data-testid=standings-legend]")})'

check_page "http://localhost:3000/league/pl" "league-pl" 1 "$LEGEND_EXPR"
$B eval 'document.querySelector("[data-testid=standings-legend]")?.innerText||""' 2>/dev/null | tr -d '"\\' | grep -q "لیگ قهرمانان اروپا" || { FAIL=1; echo "  !! pl legend text missing"; }
$B eval 'document.querySelector("[data-testid=standings-legend]")?.innerText||""' 2>/dev/null | tr -d '"\\' | grep -q "سقوط" || { FAIL=1; echo "  !! pl relegation missing"; }

check_page "http://localhost:3000/league/seriea" "league-seriea" 1 "$LEGEND_EXPR"
$B eval 'document.querySelector("[data-testid=standings-legend]")?.innerText||""' 2>/dev/null | tr -d '"\\' | grep -q "سهمیهٔ کنفرانس‌لیگ" || { FAIL=1; echo "  !! seriea conference missing"; }

check_page "http://localhost:3000/league/ucl" "league-ucl" 1 "$LEGEND_EXPR"
$B eval 'document.querySelector("[data-testid=standings-legend]")?.innerText||""' 2>/dev/null | tr -d '"\\' | grep -q "یک‌هشتم نهایی" || { FAIL=1; echo "  !! ucl 1/8 finals missing"; }

check_page "http://localhost:3000/league/persiangulf" "league-persiangulf" 0 "$NOLEGEND_EXPR"

echo "=== result ==="
[ "$FAIL" = "0" ] && echo "CYCLE111 DOMPROOF OK" || echo "CYCLE111 DOMPROOF FAIL"
exit $FAIL
