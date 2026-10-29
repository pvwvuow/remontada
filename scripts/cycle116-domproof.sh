#!/bin/bash
# Cycle-116 update DOM proof at 390x844 — «غایبان و آمار ترکیب» on the match
# lineups tab. The feature: the content.lineup.*Team blocks' unavailable list
# (injured / international-duty players + raw expectedReturn strings parsed to
# Persian via the cycle-96 month maps) + starter facts (میانگین سن / ارزش
# بازار ترکیب) — unconsumed since the beginning. Proof:
#   1) API truth: /api/match/5749720 lineups carry 8+5 unavailable entries
#      with typeFa «مصدومیت» + returnFa «اوایل نوامبر ۲۰۲۶»-style + starterAge
#      + totalMarketValueFa (server-formatted «۲۵۶.۷ میلیون یورو»);
#   2) DOM: the «ترکیب» tab shows the UnavailableCard (testid=match-unavailable)
#      with per-side Persian team labels + chips + Persian returns, and the
#      starter-facts line under the coach; LineupsPitch intact;
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
  d=json.load(sys.stdin); lu=d.get('lineups') or {}
  h=lu.get('home') or {}; a=lu.get('away') or {}
  uh=h.get('unavailable') or []; ua=a.get('unavailable') or []
  print(json.dumps({'hUn':len(uh),'aUn':len(ua),'hAge':h.get('starterAge'),'hMv':h.get('totalMarketValueFa'),'t1':(uh[0] or {}).get('typeFa') if uh else None,'r1':(uh[1] or {}).get('returnFa') if len(uh)>1 else None},ensure_ascii=False))
except Exception:
  print('ERR')")
echo "[api 5749720] $API"
echo "$API" | grep -q '"hUn": 8' || echo "$API" | grep -q '"hUn":8' || { FAIL=1; echo "  !! home unavailable != 8"; }
echo "$API" | grep -q '"aUn": 5' || echo "$API" | grep -q '"aUn":5' || { FAIL=1; echo "  !! away unavailable != 5"; }
echo "$API" | grep -q '"hAge": 25.1' || echo "$API" | grep -q '"hAge":25.1' || { FAIL=1; echo "  !! starterAge wrong"; }
echo "$API" | grep -q "میلیون یورو" || { FAIL=1; echo "  !! totalMarketValueFa missing"; }
echo "$API" | grep -q "مصدومیت" || { FAIL=1; echo "  !! typeFa missing"; }
echo "$API" | grep -q "اوایل نوامبر" || { FAIL=1; echo "  !! returnFa parse broken"; }

# — DOM checks —
check_page () { # $1=url $2=label
  local URL="$1" LABEL="$2"
  $B errors --clear >/dev/null 2>&1
  $B console --clear >/dev/null 2>&1
  $B open "$URL" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  # open the lineups tab (lazy content) then wait for the card
  $B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="ترکیب");if(b)b.click();return 1})()' >/dev/null 2>&1
  for i in 1 2 3 4 5 6; do
    GOT=$($B eval 'JSON.stringify(!!document.querySelector("[data-testid=match-unavailable]"))' 2>/dev/null | tr -d '"\\')
    [ "$GOT" = "true" ] && break
    sleep 2
  done
  sleep 1.5
  local BM RES CON ERR
  BM=$($B eval 'JSON.stringify((()=>{const de=document.documentElement;return {sw:window.innerWidth,cw:de.clientWidth,h1:document.querySelectorAll("h1").length,img:[...document.images].filter(i=>i.complete&&i.naturalWidth===0).length}})())' 2>/dev/null | tr -d '"\\')
  RES=$($B eval 'JSON.stringify((()=>{const c=document.querySelector("[data-testid=match-unavailable]");if(!c)return {present:false};const t=c.innerText||"";const body=document.body.innerText;return {present:true,title:t.includes("غایبان"),injury:t.includes("مصدومیت"),ret:t.includes("نوامبر"),home:t.includes("آث‌میلان"),away:t.includes("بولونیا"),age:body.includes("میانگین سن"),mv:body.includes("ارزش بازار ترکیب"),mvFa:body.includes("میلیون یورو"),coach:body.includes("سرمربی")}})())' 2>/dev/null | tr -d '"\\')
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
TXT=$($B eval 'JSON.stringify((document.querySelector("[data-testid=match-unavailable]")?.innerText||"")+"\n"+(document.body.innerText))' 2>/dev/null | tr -d '"\\')
echo "$TXT" | grep -q "غایبان" || { FAIL=1; echo "  !! card header missing"; }
echo "$TXT" | grep -q "آث‌میلان" || { FAIL=1; echo "  !! home label missing"; }
echo "$TXT" | grep -q "بولونیا" || { FAIL=1; echo "  !! away label missing"; }
echo "$TXT" | grep -q "مصدومیت" || { FAIL=1; echo "  !! injury chip missing"; }
echo "$TXT" | grep -q "اوایل نوامبر ۲۰۲۶" || { FAIL=1; echo "  !! Persian return missing"; }
echo "$TXT" | grep -q "مشارکت مشکوک" || { FAIL=1; echo "  !! doubtful parse missing"; }
echo "$TXT" | grep -q "میانگین سن" || { FAIL=1; echo "  !! starter age fact missing"; }
echo "$TXT" | grep -q "ارزش بازار ترکیب" || { FAIL=1; echo "  !! market fact missing"; }
echo "$TXT" | grep -q "۲۵۶.۷ میلیون یورو" || { FAIL=1; echo "  !! market Persian format missing"; }
echo "$TXT" | grep -q "سرمربی" || { FAIL=1; echo "  !! coach line lost (regression)"; }
NPLAY=$($B eval 'JSON.stringify(document.querySelectorAll("[data-testid=match-unavailable] a").length)' 2>/dev/null | tr -d '"\\')
echo "[unavailable player links] $NPLAY"
[ "$NPLAY" -ge 10 ] 2>/dev/null || { FAIL=1; echo "  !! player links < 10"; }

check_page "http://localhost:3000/match/5071457" "match-5071457-live"
TXT=$($B eval 'JSON.stringify((document.querySelector("[data-testid=match-unavailable]")?.innerText||"")+"\n"+(document.body.innerText))' 2>/dev/null | tr -d '"\\')
echo "$TXT" | grep -q "غایبان" || { FAIL=1; echo "  !! MLS card missing"; }
echo "$TXT" | grep -q "میانگین سن" || { FAIL=1; echo "  !! MLS starter facts missing"; }

echo "=== result ==="
[ "$FAIL" = "0" ] && echo "CYCLE116 DOMPROOF OK" || echo "CYCLE116 DOMPROOF FAIL"
exit $FAIL
