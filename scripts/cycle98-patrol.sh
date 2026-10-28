#!/bin/bash
# Cycle-98 bug-hunt DOM patrol at 390x844 across every real route + presence
# proofs for the two newest features (cycle-96 player injury card, cycle-97
# match attacking-zones card) and the honest-absence contracts (healthy
# Haaland → injury card hidden; upcoming match → zones hidden + empty state).
# Same bitmask contract as cycle-88/93: 1=overflow 2=h1!=1 4=broken imgs.
set -u
B=agent-browser

PAGES=(
  "http://localhost:3000/"
  "http://localhost:3000/news"
  "http://localhost:3000/leagues"
  "http://localhost:3000/topscorers"
  "http://localhost:3000/league/pl"
  "http://localhost:3000/league/persiangulf"
  "http://localhost:3000/team/9925"
  "http://localhost:3000/team/9826"
  "http://localhost:3000/team/8456"
  "http://localhost:3000/player/604982"
  "http://localhost:3000/player/737066"
  "http://localhost:3000/match/5749720"
  "http://localhost:3000/match/5406269"
)

$B set viewport 390 844 >/dev/null
TOTAL_BAD=0
for P in "${PAGES[@]}"; do
  $B errors --clear >/dev/null 2>&1
  $B console --clear >/dev/null 2>&1
  $B open "$P" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 2.5
  FEAT=""
  case "$P" in
    */league/pl)
      $B eval '(()=>{const t=[...document.querySelectorAll("button")].find(b=>b.textContent.trim()==="آمار فصل");if(t)t.click();return 1})()' >/dev/null 2>&1
      sleep 1.2
      FEAT=$($B eval 'JSON.stringify({boards:!!document.querySelector("[data-testid=league-boards]")})' 2>/dev/null | tr -d '"')
      ;;
    */player/604982)
      FEAT=$($B eval 'JSON.stringify((()=>{const s=document.querySelector("[data-testid=player-injury]");if(!s)return {injury:false};const t=s.textContent||"";return {injury:true,hasType:t.includes("آسیب‌دیدگی ران"),hasReturn:t.includes("اواخر نوامبر ۲۰۲۶")}})())' 2>/dev/null | tr -d '"')
      ;;
    */player/737066)
      FEAT=$($B eval 'JSON.stringify({injuryHidden:!document.querySelector("[data-testid=player-injury]")})' 2>/dev/null | tr -d '"')
      ;;
    */match/5749720)
      $B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="آمار");if(b)b.click();return 1})()' >/dev/null 2>&1
      sleep 1.5
      FEAT=$($B eval 'JSON.stringify((()=>{const c=document.querySelector("[data-testid=match-zones]");if(!c)return {zones:false};const t=c.textContent||"";return {zones:true,hasTitle:t.includes("جهت حملات"),has49:t.includes("۴۹٪"),has42:t.includes("۴۲٪")}})())' 2>/dev/null | tr -d '"')
      ;;
    */match/5406269)
      $B eval 'JSON.stringify((()=>{const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="آمار");if(b)b.click();return 1})())' >/dev/null 2>&1
      sleep 1.2
      FEAT=$($B eval 'JSON.stringify({zones:!!document.querySelector("[data-testid=match-zones]")})' 2>/dev/null | tr -d '"')
      ;;
    */team/*)
      FEAT=$($B eval 'JSON.stringify({coaches:!!document.querySelector("[data-testid=team-coaches]"),coachRows:document.querySelectorAll("[data-testid=team-coaches] li").length})' 2>/dev/null | tr -d '"')
      ;;
  esac
  OUT=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null)
  BAD=$($B eval '(function(){var sw=document.documentElement.scrollWidth,cw=document.documentElement.clientWidth,h1n=document.querySelectorAll("h1").length,vb=[...document.images].filter(function(i){return i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden"}).length;return (sw!=cw?1:0)+(h1n!=1?2:0)+(vb>0?4:0)})()' 2>/dev/null | tr -d '"')
  C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception:
  print('ERR')")
  E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  app=[e for e in es if e.get('url')]
  print(len(app))
except Exception:
  print('ERR')")
  echo "$P → $OUT ${FEAT:+| feat=$FEAT} | console=$C appErrors=$E"
  if [ "$E" != "0" ] || [ "$BAD" != "0" ]; then TOTAL_BAD=$((TOTAL_BAD+1)); echo "   ⚠ FLAGGED (bad=$BAD appErr=$E)"; fi
done
echo "==="
echo "FLAGGED_PAGES=$TOTAL_BAD of ${#PAGES[@]}"
