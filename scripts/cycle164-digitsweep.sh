#!/usr/bin/env bash
# cycle-164 fix probe: Latin-digit leak sweep over VISIBLE text nodes (DOM truth)
# on surfaces cycle-154's numeral probe did not cover. House pattern from
# cycle163-hunt.sh (collect: sw/cw/h1n/vbroken + console/errors = 0 + non-empty
# feat). A leak = a text node containing Persian chars AND Latin [0-9] (mixed
# node "Ligue 1" inside the bilingual leagues card is by design and allowed).
# D5: facts first — this is the probe that decides the fix, not a gate yet.
set -u
B=agent-browser
BASE="http://localhost:3000"
$B set viewport 390 844 >/dev/null

BAD=0

collect() { # $1=feat $2=label — same house gates as 163
  local FEAT="$1" LABEL="$2" OUT C E RC=0
  OUT=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null | tr -d '"\\')
  C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception: print('ERR')")
  E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  print(len([e for e in es if e.get('url')]))
except Exception: print('ERR')")
  echo "$LABEL → $OUT | feat=$FEAT | console=$C appErrors=$E"
  echo "$FEAT" | grep -q "nleaks:0" || RC=1   # quotes stripped by tr — grep unquoted (D5)
  [ -z "$FEAT" ] && RC=1
  echo "$FEAT" | grep -q "false\|null" && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
  return 0
}

# feat: VISIBLE text nodes with Persian chars AND Latin digits — skip
# SCRIPT/STYLE/NOSCRIPT subtrees (JSON-LD + RSC payloads are not visible text;
# the first sweep run caught only those — a hunt-side read bug, D5)
FEATJS='(()=>{const leaks=[];const skip=new Set(["SCRIPT","STYLE","NOSCRIPT"]);const w=document.createTreeWalker(document.body,NodeFilter.SHOW_TEXT,{acceptNode(n){let p=n.parentElement;while(p){if(skip.has(p.tagName))return NodeFilter.FILTER_REJECT;p=p.parentElement}return /[0-9]/.test(n.textContent||"")?NodeFilter.FILTER_ACCEPT:NodeFilter.FILTER_REJECT}});let n;while((n=w.nextNode())){const t=(n.textContent||"").trim();if(!/[\u0600-\u06FF]/.test(t))continue;if(t.includes("Ligue 1"))continue;leaks.push(t.slice(0,50))}return{nleaks:leaks.length,leaks:leaks.slice(0,4)}})()'

sweep() { # $1=label $2=url
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$2" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 3
  local FEAT
  FEAT=$($B eval "JSON.stringify(($FEATJS))" 2>/dev/null | tr -d '"\\')
  collect "$FEAT" "$1"
  return 0
}

echo "== cycle-164 digit sweep @390x844 (surfaces beyond the 154 probe) =="
sweep "S1 players hub"      "$BASE/players"
sweep "S2 player 196041"    "$BASE/player/196041"
sweep "S3 leagues hub"      "$BASE/leagues"
sweep "S4 topscorers mas"   "$BASE/topscorers/mas"
sweep "S5 topscorers swiss" "$BASE/topscorers/swiss"
sweep "S6 news"             "$BASE/news"
sweep "S7 team 165228"      "$BASE/team/165228"
sweep "S8 match 6054514"    "$BASE/match/6054514"

echo "DIGITSWEEP_BAD=$BAD"
[ "$BAD" -eq 0 ] && echo "DIGITSWEEP OK" || echo "DIGITSWEEP FOUND LEAKS (see feat above)"
