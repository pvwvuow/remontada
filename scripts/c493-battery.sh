#!/usr/bin/env bash
# cycle-493 bug-hunt complementary battery (the c481-hunt lessons, the c488 form):
# 1) the Persian 404 page, 2) the batch-38 FIN witness team page found LIVE in
# the ±7 feed (the c488 /team/7815 Colo-Colo form), 3) a real match page with
# a clean console + zero page errors. Findings ONLY — zero src changes.
BASE="${BASE:-http://localhost:3000}"
AB="agent-browser"
PASS=0; FAIL=0
ck() { if [ "$2" = "1" ]; then PASS=$((PASS+1)); echo "PASS $1"; else FAIL=$((FAIL+1)); echo "FAIL $1 :: $3"; fi; }

$AB set viewport 390 844 >/dev/null 2>&1

echo "== 1. the Persian 404 page =="
$AB errors --clear >/dev/null 2>&1; $AB console --clear >/dev/null 2>&1
$AB open "$BASE/not-a-real-page-xyz" >/dev/null 2>&1; sleep 2
H1404=$($AB eval "document.querySelector('h1')?.textContent||''" 2>/dev/null)
BODY404=$($AB eval "document.body?.innerText||''" 2>/dev/null)
echo "   h1=$H1404"
echo "$H1404" | grep -q "۴۰۴" && OK1a=1 || OK1a=0
echo "$BODY404" | grep -q "توپ از خط بیرون رفت" && OK1b=1 || OK1b=0
ck "404 h1 «۴۰۴»" "$OK1a" "$H1404"
ck "404 Persian message alive" "$OK1b" "missing توپ از خط بیرون رفت"

echo "== 2. the batch-38 FIN witness team page (found LIVE, the B43 fa-field form) =="
WID=""; WNAME=""; WMATCH=""
for o in -7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7; do
  FEED=$(curl -s --max-time 30 "$BASE/api/matches?offset=$o" 2>/dev/null)
  HIT=$(echo "$FEED" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
except Exception:
    print(''); raise SystemExit
W=['هلسینکی','اینتر تورکو','گنیستان','وی\u200cپی\u200cاس']
for g in (d.get('groups') or []):
    for m in (g.get('matches') or []):
        for t in (m.get('home') or {}),(m.get('away') or {}):
            fa=(t.get('fa') or '')
            if fa in W:
                print(str(t.get('id'))+'|'+fa+'|'+str(m.get('id')))
                raise SystemExit
print('')
" 2>/dev/null)
  if [ -n "$HIT" ]; then WID=$(echo "$HIT" | cut -d'|' -f1); WNAME=$(echo "$HIT" | cut -d'|' -f2); WMATCH=$(echo "$HIT" | cut -d'|' -f3); break; fi
done
echo "   witness: id=$WID name=$WNAME match=$WMATCH"
if [ -n "$WID" ]; then
  $AB errors --clear >/dev/null 2>&1; $AB console --clear >/dev/null 2>&1
  $AB open "$BASE/team/$WID" >/dev/null 2>&1; sleep 3
  H1T=$($AB eval "document.querySelector('h1')?.textContent||''" 2>/dev/null)
  SWT=$($AB eval "document.documentElement.scrollWidth" 2>/dev/null | tr -d '"')
  CET=$($AB console --json 2>/dev/null | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    ms=(d.get('data') or {}).get('messages') or []
    print(sum(1 for m in ms if isinstance(m,dict) and m.get('type') in ('error','assert')))
except Exception: print('NA')")
  echo "   /team/$WID h1=$H1T sw=$SWT console=$CET"
  case "$H1T" in *$WNAME*) OK2a=1;; *) OK2a=0;; esac
  ck "witness team h1 Persian ($WNAME → $H1T)" "$OK2a" "$H1T"
  ck "witness team sw=390" "$([ "$SWT" = "390" ] && echo 1 || echo 0)" "sw=$SWT"
  ck "witness team console 0" "$([ "$CET" = "0" ] && echo 1 || echo 0)" "console=$CET"
  $AB errors --clear >/dev/null 2>&1; $AB console --clear >/dev/null 2>&1
  $AB open "$BASE/match/$WMATCH" >/dev/null 2>&1; sleep 3
  H1M=$($AB eval "document.querySelector('h1')?.textContent||''" 2>/dev/null)
  PEM=$($AB errors --json 2>/dev/null | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    e=(d.get('data') or {}).get('errors') or []
    print(len(e) if isinstance(e,list) else 0)
except Exception: print('NA')")
  CEM=$($AB console --json 2>/dev/null | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    ms=(d.get('data') or {}).get('messages') or []
    print(sum(1 for m in ms if isinstance(m,dict) and m.get('type') in ('error','assert')))
except Exception: print('NA')")
  echo "   /match/$WMATCH h1=$H1M pageErr=$PEM console=$CEM"
  ck "witness match page errors 0" "$([ "$PEM" = "0" ] && echo 1 || echo 0)" "pageErr=$PEM"
  ck "witness match console 0" "$([ "$CEM" = "0" ] && echo 1 || echo 0)" "console=$CEM"
  ck "witness match h1 present" "$([ -n "$H1M" ] && echo 1 || echo 0)" "h1 empty"
else
  ck "batch-38 witness found in live ±7 feed" "0" "none of the four FIN witnesses in the ±7 window (the feed rotates — report, not a bug)"
fi

echo "== result =="
echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" = "0" ]
