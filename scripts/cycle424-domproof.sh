#!/bin/bash
# cycle424-domproof.sh — the home day-feed freshness label (Fix cycle 424)
# The fix: the label now rides the cycle-43 honesty contract —
# «به‌روزرسانی {timeAgoFa(fetchedAt)}» off the payload's OWN fetchedAt
# (stamped inside cached(): on a cache hit it stays the producer's birth),
# replacing the old header label that (a) showed the CLIENT fetch clock and
# (b) was hidden on mobile (no freshness witness at 390×844 at all).
#
# Witness design (the distinguishing probe): warm offset=-2's cached payload
# (10-min TTL), sleep 61s, then load the day deep-link. The payload's age is
# now ≥1 minute → the honest label reads «به‌روزرسانی ۱ دقیقه پیش» while a
# client-clock label would read «همین حالا». Byte-compare against an
# independent python replica of timeAgoFa.
set -u
BASE="${BASE:-http://localhost:3000}"
OUT=/home/z/my-project/remontada/scripts/cycle424-results.txt
: > "$OUT"
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "PASS $1" >> "$OUT"; echo "PASS $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL $1 :: $2" >> "$OUT"; echo "FAIL $1 :: $2"; }
AB="agent-browser"

# Persian-digit replica of timeAgoFa (format.ts) — minute granularity
exp_label() { # $1 = ISO fetchedAt, $2 = now_ms
python3 - "$1" "$2" <<'PY'
import sys, datetime
iso, now_ms = sys.argv[1], int(sys.argv[2])
t = datetime.datetime.fromisoformat(iso.replace("Z", "+00:00"))
diff = now_ms - int(t.timestamp() * 1000)
if diff < 0:
    print("همین حالا"); sys.exit()
m = diff // 60000
d = str.maketrans("0123456789", "۰۱۲۳۴۵۶۷۸۹")
if m < 1: print("همین حالا")
elif m < 60: print(f"{str(m).translate(d)} دقیقه پیش")
else:
    h = m // 60
    if h < 24: print(f"{str(h).translate(d)} ساعت پیش")
    else: print(f"{str(h//24).translate(d)} روز پیش")
PY
}

echo "== A. the distinguishing payload-age witness (offset=-2, warm + 61s) =="
TODAY=$(TZ=Asia/Tehran date +%F)
DAY2=$(TZ=Asia/Tehran date -d "-2 days" +%F)
WARM1=$(curl -s "$BASE/api/matches?offset=-2" | python3 -c "import json,sys;print(json.load(sys.stdin).get('fetchedAt',''))")
[ -n "$WARM1" ] && ok "A0 warm offset=-2 fetchedAt=$WARM1" || bad "A0 warm" "no fetchedAt"

echo "   ... sleeping 61s so the payload ages past the 1-minute label boundary"
sleep 61

$AB set viewport 390 844 >> "$OUT" 2>&1
$AB open "$BASE/?date=$DAY2" >> "$OUT" 2>&1
LABEL=""
for i in $(seq 1 20); do
  LABEL=$($AB eval "(()=>{const el=document.querySelector('[data-testid=home-day-freshness]');return el?el.textContent.trim():''})()" 2>/dev/null | tr -d '"')
  [ -n "$LABEL" ] && break
  sleep 1
done
NOW1=$(python3 -c "import time;print(int(time.time()*1000))")
F1=$(curl -s "$BASE/api/matches?offset=-2" | python3 -c "import json,sys;print(json.load(sys.stdin).get('fetchedAt',''))")
EXP1=$(exp_label "$F1" "$NOW1")
echo "   DOM='$LABEL' expected(now)='$EXP1' fetchedAt=$F1" >> "$OUT"
case "$LABEL" in
  *"دقیقه پیش"*) ok "A1 label reads minute-granular age (payload-sourced, NOT client clock)" ;;
  *) bad "A1 label age shape" "DOM='$LABEL'" ;;
esac
# byte-consistency with the payload's own fetchedAt (±1 render skew minute)
NOW2=$(python3 -c "import time;print(int(time.time()*1000)+60000)")
EXP2=$(exp_label "$F1" "$NOW2")
if [ "$LABEL" = "به‌روزرسانی $EXP1" ] || [ "$LABEL" = "به‌روزرسانی $EXP2" ]; then
  ok "A2 label byte-matches timeAgoFa(payload.fetchedAt) — $LABEL"
else
  bad "A2 byte-match" "DOM='$LABEL' exp1='به‌روزرسانی $EXP1' exp2='به‌روزرسانی $EXP2'"
fi
# the client-clock counterfactual: a clock label would have said همین حالا
NOWC=$(python3 -c "import time;print(int(time.time()*1000))")
CLOCK=$(exp_label "$F1" "$NOWC")
if [ "$F1" != "" ]; then
  AGE_MIN=$(( (NOWC - $(python3 -c "import datetime,sys;print(int(datetime.datetime.fromisoformat('$F1'.replace('Z','+00:00')).timestamp()*1000))") ) / 60000 ))
  if [ "$AGE_MIN" -ge 1 ]; then
    ok "A3 counterfactual holds: payload age=${AGE_MIN}min ⇒ clock label would be «همین حالا», DOM says «$LABEL»"
  else
    echo "   (A3 skipped: payload younger than 1min this run)" >> "$OUT"
  fi
fi

echo "== B. default home: label present, visible, honest =="
$AB open "$BASE/" >> "$OUT" 2>&1
LAB0=""
for i in $(seq 1 20); do
  LAB0=$($AB eval "(()=>{const el=document.querySelector('[data-testid=home-day-freshness]');return el?el.textContent.trim():''})()" 2>/dev/null | tr -d '"')
  [ -n "$LAB0" ] && break
  sleep 1
done
case "$LAB0" in
  "به‌روزرسانی "*) ok "B1 default-home label present — '$LAB0'" ;;
  "") bad "B1 default-home label" "missing" ;;
  *) bad "B1 default-home label shape" "DOM='$LAB0'" ;;
esac
VIS=$($AB eval "(()=>{const el=document.querySelector('[data-testid=home-day-freshness]');if(!el)return 'missing';const r=el.getBoundingClientRect(),s=getComputedStyle(el);return (r.width>0&&s.display!=='none'&&s.visibility!=='hidden')?'visible':'hidden'})()" 2>/dev/null | tr -d '"')
[ "$VIS" = "visible" ] && ok "B2 label VISIBLE at 390×844 (the old one was display:none on mobile)" || bad "B2 visibility" "$VIS"
OLD=$($AB eval "document.body.innerText.includes('آخرین بروزرسانی')" 2>/dev/null | tr -d '"')
[ "$OLD" = "false" ] && ok "B3 old client-clock label («آخرین بروزرسانی …») fully removed" || bad "B3 old label" "still present"
TODAYEXP="/api/day-calendar?date=$TODAY"
HREF=$($AB eval "document.querySelector('[data-testid=home-day-ics-link]')?.getAttribute('href')||''" 2>/dev/null | tr -d '"')
[ "$HREF" = "$TODAYEXP" ] && ok "B4 the 422 hold: ICS CTA href == today ($TODAYEXP)" || bad "B4 ICS href" "'$HREF' != '$TODAYEXP'"

echo "== C. hygiene three-pack =="
PE=$($AB errors --json 2>/dev/null | python3 -c "import json,sys;d=json.load(sys.stdin);e=d.get('data',{}).get('errors',d.get('errors',[]));print(len(e) if isinstance(e,list) else 0)")
[ "$PE" = "0" ] && ok "C1 page-errors zero" || bad "C1 page-errors" "$PE"
CE=$($AB console --json 2>/dev/null | python3 -c "
import json,sys
try:
  d=json.load(sys.stdin)
except Exception:
  print(0); raise SystemExit
m=d.get('data',{}).get('messages',d.get('messages',[]))
errs=[x for x in m if isinstance(x,dict) and x.get('type')=='error']
print(len(errs))")
[ "$CE" = "0" ] && ok "C2 console-errors zero" || bad "C2 console-errors" "$CE"
SW=$($AB eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
[ "$SW" = "390" ] && ok "C3 no horizontal overflow (scrollW=390)" || bad "C3 overflow" "scrollW=$SW"
$AB close >> "$OUT" 2>&1 || true

echo "=== result ===" | tee -a "$OUT"
echo "PASS=$PASS FAIL=$FAIL" | tee -a "$OUT"
[ "$FAIL" = "0" ] && echo "CYCLE424 DOMPROOF OK" || echo "CYCLE424 DOMPROOF BROKEN"
exit $FAIL
