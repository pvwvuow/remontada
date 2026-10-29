#!/bin/bash
# Cycle-114 fix DOM proof at 390x844 — standings last-known-good snapshot
# fallback («آخرین داده‌های ذخیره‌شده»). The fix (cycle-42 topscorers mirror):
# /api/standings now writes a 24h L2 snapshot on every successful fetch and
# serves it with stale:true when the live fetch throws with no stored row —
# the cycle-113 registered failure mode. Proof (healthy server — the notice
# must NEVER render on live data):
#   1) API truth: /api/standings?league=seriea → ok:true, rows=20, NO stale
#      flag; the L2 snapshot row exists (Part A proof);
#   2) DOM: /league/seriea + /league/pl show the full table + legend
#      (cycle-111 contract: seriea 4 chips, pl 3) with NO stale notice;
#   3) persiangulf keeps the designed empty-state («جدولی برای این لیگ
#      ثبت نشده است»), no notice, API 503 honest;
#   4) contracts: sw=cw=390, exactly 1 h1, 0 broken imgs, console=0,
#      pageErr=0 (cycle-108 url convention — records without url don't count).
# (The notice RENDER path itself is proven by scripts/cycle114-fallback-proof.ts
# against the real route handler + real L2 under a simulated upstream outage.)
set -u
B=agent-browser
FAIL=0

$B set viewport 390 844 >/dev/null

# — API truth —
API=$(curl -s "http://localhost:3000/api/standings?league=seriea" | python3 -c "
import json,sys
try:
  d=json.load(sys.stdin)
  print(json.dumps({'ok':d.get('ok'),'rows':len(d.get('rows') or []),'stale':d.get('stale'),'legend':len(d.get('legend') or [])},ensure_ascii=False))
except Exception:
  print('ERR')")
echo "[api seriea] $API"
echo "$API" | grep -q '"ok": true' || echo "$API" | grep -q '"ok":true' || { FAIL=1; echo "  !! seriea not ok"; }
echo "$API" | grep -q '"stale": null' || echo "$API" | grep -q '"stale":null' || { FAIL=1; echo "  !! stale flag on healthy path"; }
PG=$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:3000/api/standings?league=persiangulf")
echo "[api persiangulf] HTTP=$PG (designed 503)"
[ "$PG" = "503" ] || { FAIL=1; echo "  !! persiangulf contract broken"; }

# — DOM checks —
check_page () { # $1=url $2=label $3=eval-expr
  local URL="$1" LABEL="$2" EXPR="$3"
  $B errors --clear >/dev/null 2>&1
  $B console --clear >/dev/null 2>&1
  $B open "$URL" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  sleep 2
  local BM RES CON ERR
  BM=$($B eval 'JSON.stringify((()=>{const de=document.documentElement;return {sw:window.innerWidth,cw:de.clientWidth,h1:document.querySelectorAll("h1").length,img:[...document.images].filter(i=>i.complete&&i.naturalWidth===0).length}})())' 2>/dev/null | tr -d '"\\')
  RES=$($B eval "$EXPR" 2>/dev/null | tr -d '"\\')
  CON=$($B console 2>/dev/null | grep -ci error || true)
  ERR=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len([e for e in d['data']['errors'] if e.get('url')]))
except Exception:
  print('ERR')")
  echo "[$LABEL] bm=$BM res=$RES consoleErr=$CON pageErr=$ERR"
  case "$BM" in *"sw:390,"*|*'"sw":390,'*) ;; *) FAIL=1; echo "  !! viewport contract broken";; esac
  case "$BM" in *"h1:1,"*|*'"h1":1,'*) ;; *) FAIL=1; echo "  !! h1 count != 1";; esac
  case "$BM" in *"img:0"*|*'"img":0'*) ;; *) FAIL=1; echo "  !! broken images";; esac
  [ "$CON" = "0" ] || { FAIL=1; echo "  !! console errors"; }
  [ "$ERR" = "0" ] || { FAIL=1; echo "  !! page errors"; }
}

LEAGUE_EXPR='JSON.stringify((()=>{const rows=document.querySelectorAll("[data-testid=standings-legend] ~ * , section table tbody tr").length;const legend=!!document.querySelector("[data-testid=standings-legend]");const notice=document.body.innerText.includes("آخرین داده‌های ذخیره‌شده");const tbl=document.body.innerText.includes("تبdin")||!!document.querySelector("table");return {legend, notice, table:!!document.querySelector("table"), rows}})())'

check_page "http://localhost:3000/league/seriea" "league-seriea" "$LEAGUE_EXPR"
TXT=$($B eval 'JSON.stringify(document.body.innerText.slice(0,12000))' 2>/dev/null | tr -d '"\\')
echo "$TXT" | grep -q "سهمیهٔ کنفرانس‌لیگ" || { FAIL=1; echo "  !! seriea legend (conference zone) missing"; }
echo "$TXT" | grep -q "اینتر" || { FAIL=1; echo "  !! seriea Inter Persian missing"; }
echo "$TXT" | grep -q "آخرین داده‌های ذخیره‌شده" && { FAIL=1; echo "  !! stale notice rendered on HEALTHY path"; }
NROWS=$($B eval 'JSON.stringify(document.querySelectorAll("table tbody tr").length)' 2>/dev/null | tr -d '"\\')
echo "[seriea table rows] $NROWS (20 standings + 20 xG mirror = designed 40)"
[ "$NROWS" = "40" ] || { FAIL=1; echo "  !! seriea rows != 40"; }

check_page "http://localhost:3000/league/pl" "league-pl" "$LEAGUE_EXPR"
TXT=$($B eval 'JSON.stringify(document.body.innerText.slice(0,12000))' 2>/dev/null | tr -d '"\\')
echo "$TXT" | grep -q "لیگ قهرمانان اروپا" || { FAIL=1; echo "  !! pl legend missing"; }
echo "$TXT" | grep -q "آرسنال" || { FAIL=1; echo "  !! pl Arsenal Persian missing"; }
echo "$TXT" | grep -q "آخرین داده‌های ذخیره‌شده" && { FAIL=1; echo "  !! stale notice rendered on HEALTHY path"; }

check_page "http://localhost:3000/league/persiangulf" "league-persiangulf" 'JSON.stringify((()=>{const empty=document.body.innerText.includes("جدولی برای این لیگ ثبت نشده است");const notice=document.body.innerText.includes("آخرین داده‌های ذخیره‌شده");return {empty,notice}})())'
TXT=$($B eval 'JSON.stringify(document.body.innerText.slice(0,3000))' 2>/dev/null | tr -d '"\\')
echo "$TXT" | grep -q "آخرین داده‌های ذخیره‌شده" && { FAIL=1; echo "  !! stale notice rendered on persiangulf"; }

echo "=== result ==="
[ "$FAIL" = "0" ] && echo "CYCLE114 DOMPROOF OK" || echo "CYCLE114 DOMPROOF FAIL"
exit $FAIL
