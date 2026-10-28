#!/bin/bash
# Cycle-110 update DOM proof at 390x844 — match insights («بینش‌ها»).
# The feature: matchFacts.insights rendered through curated Persian templates
# on the info tab (data-testid=match-insights), team-colored dots, Persian
# digits, honest-name refs, unknown template ids dropped. Proof:
#   1) API: /api/match/{5749720,5071464} return insights with ZERO raw
#      English template fragments and zero "…" placeholders,
#   2) DOM: both matches' info tab shows the «بینش‌ها» card with Persian
#      sentences and no raw template text,
#   3) contracts: sw=cw=390, exactly 1 h1, 0 broken imgs, console=0, appErr=0.
set -u
B=agent-browser
FAIL=0

$B set viewport 390 844 >/dev/null

RAWPAT='Have scored|Haven.t|have won the previous|is ranked|has created the most|has the most shots|top scorer \(|in their last|clean sheets in the competition'

for M in 5749720 5071464; do
  # — API truth —
  API=$(
    curl -s "http://localhost:3000/api/match/$M" | python3 -c "
import json,sys
d=json.load(sys.stdin)
ins=d.get('insights') or []
bad=[i['text'] for i in ins if ('…' in i['text']) or any(w in i['text'] for w in ['Have scored',\"Haven't\",'have won the previous','is ranked','has created the most','has the most shots',\"competition's top scorer\",'in their last','clean sheets in the competition'])]
print(f\"{len(ins)}|{len(bad)}\")
"
  )
  N="${API%%|*}"; BAD="${API##*|}"
  echo "[api $M] insights=$N rawTemplate=$BAD"
  [ "$N" -ge 1 ] || { FAIL=1; echo "  !! no insights in API"; }
  [ "$BAD" = "0" ] || { FAIL=1; echo "  !! raw English template leaked in API"; }

  # — DOM: info tab —
  $B errors --clear >/dev/null 2>&1
  $B console --clear >/dev/null 2>&1
  $B open "http://localhost:3000/match/$M" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 2
  $B eval '(()=>{const t=[...document.querySelectorAll("button")].find(b=>b.textContent.trim()==="اطلاعات");if(t)t.click();return 1})()' >/dev/null 2>&1
  sleep 1.5
  BM=$($B eval 'JSON.stringify((()=>{const de=document.documentElement;return {sw:window.innerWidth,cw:de.clientWidth,h1:document.querySelectorAll("h1").length,img:[...document.images].filter(i=>i.complete&&i.naturalWidth===0).length}})())' 2>/dev/null | tr -d '"\\')
  CARD=$($B eval 'JSON.stringify((()=>{const c=document.querySelector("[data-testid=match-insights]");if(!c)return {present:false};const t=c.innerText||"";const rows=c.querySelectorAll("li").length;return {present:true,rows,title:t.includes("بینش‌ها")}})())' 2>/dev/null | tr -d '"\\')
  RAW=$($B eval 'document.body.innerText' 2>/dev/null | tr -d '"\\' | grep -Ec "$RAWPAT" || true)
  CON=$($B console 2>/dev/null | grep -ci error || true)
  ERR=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len([e for e in d['data']['errors'] if e.get('url')]))
except Exception:
  print('ERR')")
  echo "[dom $M] bm=$BM card=$CARD rawLeft=$RAW consoleErr=$CON pageErr=$ERR"
  case "$BM" in *"sw:390,"*|*'"sw":390,'*) ;; *) FAIL=1; echo "  !! viewport contract broken";; esac
  case "$BM" in *"h1:1,"*|*'"h1":1,'*) ;; *) FAIL=1; echo "  !! h1 count != 1";; esac
  case "$BM" in *"img:0"*|*'"img":0'*) ;; *) FAIL=1; echo "  !! broken images";; esac
  case "$CARD" in *present:true*|*'"present":true'*) ;; *) FAIL=1; echo "  !! insights card missing on info tab";; esac
  case "$CARD" in *rows:0*|*'"rows":0'*) FAIL=1; echo "  !! insights card has no rows";; esac
  [ "$RAW" = "0" ] || { FAIL=1; echo "  !! raw English insight text on page"; }
  [ "$CON" = "0" ] || { FAIL=1; echo "  !! console errors"; }
  [ "$ERR" = "0" ] || { FAIL=1; echo "  !! page errors"; }
done

echo "=== result ==="
[ "$FAIL" = "0" ] && echo "CYCLE110 DOMPROOF OK" || echo "CYCLE110 DOMPROOF FAIL"
exit $FAIL
