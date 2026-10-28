#!/bin/bash
# Cycle-109 fix DOM proof at 390x844 — honest-name map completion + read-time
# freshening. The fix: (a) the last 12 unmapped names of the live /topscorers
# pool (8 scorers + 4 assists), (b) 6 proven-raw team keys (frosinone,
# internazionale, sv werder bremen, racing de santander, le mans,
# deportivo a coruña), (c) read-time freshening (freshenHonestNames /
# freshCardNames) so the L2 (SQLite) cache can no longer serve stale raw
# names after a map addition. This proof:
#   1) global /topscorers: the rendered surfaces (top-3 scorers, top-10
#      assists, cards) show the new Persian names/teams, zero raw leftovers
#      of the mapped set,
#   2) /topscorers/seriea (THE class-fix proof): the full 20-row table is
#      Persian even though its L2 payload was cached before the map change —
#      rows/teams freshened at read time,
#   3) honest fallback intact: /player/604982 h1 stays the honest English
#      name; unmapped card rows stay honest English.
# Bitmask contract (88/93/98/103): 1=overflow 2=h1!=1 4=broken imgs.
set -u
B=agent-browser
FAIL=0

$B set viewport 390 844 >/dev/null

check_page () { # $1=url $2=label $3=eval-expr (JSON) $4=raw-grep-pattern (0 expected)
  local URL="$1" LABEL="$2" EXPR="$3" RAWPAT="$4"
  $B errors --clear >/dev/null 2>&1
  $B console --clear >/dev/null 2>&1
  $B open "$URL" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 2.5
  local BM FA RAW CON ERR
  BM=$($B eval 'JSON.stringify((()=>{const de=document.documentElement;return {sw:window.innerWidth,cw:de.clientWidth,h1:document.querySelectorAll("h1").length,img:[...document.images].filter(i=>i.complete&&i.naturalWidth===0).length}})())' 2>/dev/null | tr -d '"\\')
  FA=$($B eval "$EXPR" 2>/dev/null | tr -d '"\\')
  RAW=$($B eval 'document.body.innerText' 2>/dev/null | tr -d '"\\' | grep -Ec "$RAWPAT" || true)
  CON=$($B console 2>/dev/null | grep -ci error || true)
  # cycle-108 convention: only records WITH a url are app errors — the bare
  # empty «✗» record (url=null, a stale patrol-eval artifact) is excluded
  ERR=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len([e for e in d['data']['errors'] if e.get('url')]))
except Exception:
  print('ERR')")
  echo "[$LABEL] bm=$BM fa=$FA rawLeft=$RAW consoleErr=$CON pageErr=$ERR"
  case "$BM" in *"sw:390,"*|*'"sw":390,'*) ;; *) FAIL=1; echo "  !! viewport contract broken";; esac
  case "$BM" in *"h1:1,"*|*'"h1":1,'*) ;; *) FAIL=1; echo "  !! h1 count != 1";; esac
  case "$BM" in *"img:0"*|*'"img":0'*) ;; *) FAIL=1; echo "  !! broken images";; esac
  case "$FA" in *MISSING*) FAIL=1; echo "  !! Persian name(s) missing";; esac
  [ "$RAW" = "0" ] || { FAIL=1; echo "  !! raw English leftover of the mapped set"; }
  [ "$CON" = "0" ] || { FAIL=1; echo "  !! console errors"; }
  [ "$ERR" = "0" ] || { FAIL=1; echo "  !! page errors"; }
}

# — 1) global /topscorers: rendered surfaces all Persian (scorer top-3 team,
#      assist top-10 names+teams, cards teams) —
check_page "http://localhost:3000/topscorers" "topscorers" \
  'JSON.stringify((()=>{const t=document.body.innerText||"";const need=["مصاف گلزنان","راسینگ سانتاندر","خاوی هرناندس","آنتونیو نوسا","کریستیان کاسرس","لومان","وردربرمن","دپورتیوو لاکرونیا"];const miss=need.filter(n=>!t.includes(n));return miss.length?("MISSING:"+miss.join("|")):"GLOBAL_FA_OK"})())' \
  'Lepaul|Archer|Cissè|Adams|Noslin|Mastantuono|Kvernadze|Ekkelenkamp|Hernández|Nusa|Cásseres|Moleiro|Frosinone|Internazionale|Racing de Santander|SV Werder Bremen|Le Mans|Deportivo'

# — 2) /topscorers/seriea: THE class-fix proof — full 20-row table Persian
#      although the L2 payload predates the map (read-time freshening) —
check_page "http://localhost:3000/topscorers/seriea" "topscorers-seriea" \
  'JSON.stringify((()=>{const t=document.body.innerText||"";const need=["آلفادیو سیسه","چی آدامز","تیانی نوسلین","فرانکو ماستانتوانو","گیورگی کورنادزه","یورگن اکلنکامپ","فروزینونه","اینتر"];const miss=need.filter(n=>!t.includes(n));return miss.length?("MISSING:"+miss.join("|")):"SERIEA_FA_OK"})())' \
  'Cissè|Adams|Noslin|Mastantuono|Kvernadze|Ekkelenkamp|Frosinone|Internazionale'

# — 3) honest fallback intact: /player/604982 h1 stays the honest English name —
$B errors --clear >/dev/null 2>&1
$B console --clear >/dev/null 2>&1
$B open "http://localhost:3000/player/604982" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
sleep 2.5
H1=$($B eval 'JSON.stringify({h1:(document.querySelector("h1")||{}).textContent||""})' 2>/dev/null | tr -d '"\\')
PERR=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len([e for e in d['data']['errors'] if e.get('url')]))
except Exception:
  print('ERR')")
echo "[player-604982] h1=$H1 pageErr=$PERR"
echo "$H1" | grep -qi "loftus" || { FAIL=1; echo "  !! honest English fallback broken"; }
[ "$PERR" = "0" ] || { FAIL=1; echo "  !! page errors"; }

echo "=== result ==="
[ "$FAIL" = "0" ] && echo "CYCLE109 DOMPROOF OK" || echo "CYCLE109 DOMPROOF FAIL"
exit $FAIL
