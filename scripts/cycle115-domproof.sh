#!/bin/bash
# Cycle-115 update DOM proof at 390x844 — referee & stadium facts («داور و
# ورزشگاه») on the match info tab. The feature: the infoBox Referee.stats
# block (matches, yellow/foul per-match averages with their league-average
# comparison chips, red cards, penalties) + Stadium capacity/surface —
# unconsumed since the beginning — rendered as a lazy info-tab card
# (testid=match-referee) after the info rows. Proof:
#   1) API truth: /api/match/{5749720,5071457} carry the full refereeStats +
#      stadiumExtra matching the raw probes (Sacchi 21/3.33-vs-3.71-below,
#      San Siro 75817 grass; Villarreal 31/3.87-vs-4.16-below, Nu Stadium 26700),
#   2) DOM: the «اطلاعات» tab shows the card with Persian rows (بازی
#      داوری‌شده/میانگین کارت زرد + chip/کارت قرمز/پنالتی/میانگین خطا + ظرفیت/
#      چمن) — referee NAME stays honest English; standing cards (بینش‌ها/
#      آب‌وهوا/info rows) intact on the same tab,
#   3) contracts: sw=cw=390, exactly 1 h1, 0 broken imgs, console=0,
#      pageErr=0 (cycle-108 url convention — records without url don't count).
set -u
B=agent-browser
FAIL=0

$B set viewport 390 844 >/dev/null

# — API truth —
API=$(curl -s "http://localhost:3000/api/match/5749720" | python3 -c "
import json,sys
try:
  d=json.load(sys.stdin); i=d.get('info',{}); rs=i.get('refereeStats') or {}; se=i.get('stadiumExtra') or {}
  print(json.dumps({'n':len(rs),'m':rs.get('matches'),'y':rs.get('yellowPerMatch'),'ya':rs.get('yellowAvg'),'yv':rs.get('yellowVs'),'f':rs.get('foulsVs'),'cap':se.get('capacity'),'sf':se.get('surface')},ensure_ascii=False))
except Exception:
  print('ERR')")
echo "[api 5749720] $API"
echo "$API" | grep -q '"n": 9' || echo "$API" | grep -q '"n":9' || { FAIL=1; echo "  !! refereeStats incomplete (need 9 keys)"; }
echo "$API" | grep -q '"yv": "below"' || echo "$API" | grep -q '"yv":"below"' || { FAIL=1; echo "  !! yellowVs wrong"; }
echo "$API" | grep -q '"cap": 75817' || echo "$API" | grep -q '"cap":75817' || { FAIL=1; echo "  !! capacity wrong"; }
API2=$(curl -s "http://localhost:3000/api/match/5071457" | python3 -c "
import json,sys
try:
  d=json.load(sys.stdin); rs=(d.get('info') or {}).get('refereeStats') or {}
  print(json.dumps({'m':rs.get('matches'),'y':rs.get('yellowPerMatch'),'fv':rs.get('foulsVs')},ensure_ascii=False))
except Exception:
  print('ERR')")
echo "[api 5071457] $API2"
echo "$API2" | grep -q '"fv": "below"' || echo "$API2" | grep -q '"fv":"below"' || { FAIL=1; echo "  !! mls foulsVs wrong"; }

# — DOM checks —
check_page () { # $1=url $2=label
  local URL="$1" LABEL="$2"
  $B errors --clear >/dev/null 2>&1
  $B console --clear >/dev/null 2>&1
  $B open "$URL" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  # open the info tab (lazy content) then wait for the card
  $B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="اطلاعات");if(b)b.click();return 1})()' >/dev/null 2>&1
  for i in 1 2 3 4 5 6; do
    GOT=$($B eval 'JSON.stringify(!!document.querySelector("[data-testid=match-referee]"))' 2>/dev/null | tr -d '"\\')
    [ "$GOT" = "true" ] && break
    sleep 2
  done
  sleep 1.5
  local BM RES CON ERR
  BM=$($B eval 'JSON.stringify((()=>{const de=document.documentElement;return {sw:window.innerWidth,cw:de.clientWidth,h1:document.querySelectorAll("h1").length,img:[...document.images].filter(i=>i.complete&&i.naturalWidth===0).length}})())' 2>/dev/null | tr -d '"\\')
  RES=$($B eval 'JSON.stringify((()=>{const c=document.querySelector("[data-testid=match-referee]");if(!c)return {present:false};const t=c.innerText||"";return {present:true,title:t.includes("داور و ورزشگاه"),matches:t.includes("بازی داوری‌شده"),yellow:t.includes("میانگین کارت زرد"),red:t.includes("کارت قرمز"),pens:t.includes("پنالتی اعلام‌شده"),fouls:t.includes("میانگین خطا"),below:t.includes("پایین‌تر از میانگین لیگ"),cap:t.includes("ظرفیت ورزشگاه"),turf:t.includes("نوع چمن"),refName:(t+" "+document.body.innerText).includes(document.querySelector("[data-testid=match-referee]")?.innerText?.includes("Sacchi")?"Sacchi":"__x__")}})())' 2>/dev/null | tr -d '"\\')
  CON=$($B console 2>/dev/null | grep -ci error || true)
  ERR=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len([e for e in d['data']['errors'] if e.get('url')]))
except Exception:
  print('ERR')")
  echo "[$LABEL] bm=$BM card=$RES consoleErr=$CON pageErr=$ERR"
  case "$BM" in *"sw:390,"*|*'"sw":390,'*) ;; *) FAIL=1; echo "  !! viewport contract broken";; esac
  case "$BM" in *"h1:1,"*|*'"h1":1,'*) ;; *) FAIL=1; echo "  !! h1 count != 1";; esac
  case "$BM" in *"img:0"*|*'"img":0'*) ;; *) FAIL=1; echo "  !! broken images";; esac
  [ "$CON" = "0" ] || { FAIL=1; echo "  !! console errors"; }
  [ "$ERR" = "0" ] || { FAIL=1; echo "  !! page errors"; }
}

check_page "http://localhost:3000/match/5749720" "match-5749720"
TXT=$($B eval 'JSON.stringify((document.querySelector("[data-testid=match-referee]")?.innerText||"")+"\n"+(document.body.innerText))' 2>/dev/null | tr -d '"\\')
echo "$TXT" | grep -q "داور و ورزشگاه" || { FAIL=1; echo "  !! card title missing"; }
echo "$TXT" | grep -q "بازی داوری‌شده" || { FAIL=1; echo "  !! matches row missing"; }
echo "$TXT" | grep -q "پایین‌تر از میانگین لیگ" || { FAIL=1; echo "  !! below-league chip missing"; }
echo "$TXT" | grep -q "ظرفیت ورزشگاه" || { FAIL=1; echo "  !! capacity row missing"; }
echo "$TXT" | grep -q "۷۵,۸۱۷" || { FAIL=1; echo "  !! capacity Persian digits missing"; }
echo "$TXT" | grep -q "چمن طبیعی" || { FAIL=1; echo "  !! grass surface missing"; }
echo "$TXT" | grep -q "Sacchi" || { FAIL=1; echo "  !! referee honest English name missing"; }
echo "$TXT" | grep -q "بینش‌ها" || { FAIL=1; echo "  !! insights card lost (regression)"; }

check_page "http://localhost:3000/match/5071457" "match-5071457-live"
TXT=$($B eval 'JSON.stringify((document.querySelector("[data-testid=match-referee]")?.innerText||"")+"\n"+(document.body.innerText))' 2>/dev/null | tr -d '"\\')
echo "$TXT" | grep -q "Villarreal" || { FAIL=1; echo "  !! MLS referee honest name missing"; }
echo "$TXT" | grep -q "۲۶,۷۰۰" || { FAIL=1; echo "  !! MLS capacity Persian missing"; }

echo "=== result ==="
[ "$FAIL" = "0" ] && echo "CYCLE115 DOMPROOF OK" || echo "CYCLE115 DOMPROOF FAIL"
exit $FAIL
