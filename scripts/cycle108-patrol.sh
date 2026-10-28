#!/bin/bash
# Cycle-108 bug-hunt DOM patrol at 390x844 — 18 routes + client-side
# interaction contracts. Re-verifies EVERY recent-cycle feature after the
# 104→107 name arc: cycle-99 season deep link, cycle-101 season-state reset,
# cycle-100/101 weather cards (+badges), cycle-97 zones, cycle-96 injury,
# cycle-95 team key players, cycle-102 matchday league render, and the NEW
# nameFa surfaces of 104-107 (team top-players, topscorers heroes/rows,
# league «آقای گل» tab, player-profile h1) with the honest-fallback contract.
# Bitmask contract (88/93/98/103): 1=overflow 2=h1!=1 4=broken imgs.
set -u
B=agent-browser

PAGES=(
  "http://localhost:3000/"
  "http://localhost:3000/news"
  "http://localhost:3000/leagues"
  "http://localhost:3000/topscorers"
  "http://localhost:3000/league/pl"
  "http://localhost:3000/league/seriea"
  "http://localhost:3000/league/ucl"
  "http://localhost:3000/league/laliga"
  "http://localhost:3000/league/bundesliga"
  "http://localhost:3000/league/ligue1"
  "http://localhost:3000/league/persiangulf"
  "http://localhost:3000/team/8456"
  "http://localhost:3000/team/9925"
  "http://localhost:3000/team/9826"
  "http://localhost:3000/player/604982"
  "http://localhost:3000/player/737066"
  "http://localhost:3000/match/5749720"
  "http://localhost:3000/match/5071464"
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
    */topscorers)
      FEAT=$($B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {globalTitle:t.includes("مصاف گلزنان"),faStar:(t.includes("امباپه")||t.includes("هالند")||t.includes("رافینیا")||t.includes("یامال")),assistTitle:t.includes("پاس گل")}})())' 2>/dev/null | tr -d '"')
      ;;
    */league/pl)
      $B eval '(()=>{const t=[...document.querySelectorAll("button")].find(b=>b.textContent.trim()==="آمار فصل");if(t)t.click();return 1})()' >/dev/null 2>&1
      sleep 1.2
      A=$($B eval 'JSON.stringify((()=>{const boards=!!document.querySelector("[data-testid=league-boards]");const lbl=[...document.querySelectorAll("*")].find(e=>e.children.length===0&&(e.textContent||"").includes("فصل "));return {boards,seasonLabel:lbl?lbl.textContent.trim():null}})())' 2>/dev/null | tr -d '"')
      $B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>x.textContent&&x.textContent.trim()==="آقای گل");if(b)b.click();return b?1:0})()' >/dev/null 2>&1
      sleep 1.5
      G=$($B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {tabFaHaaland:t.includes("ارلینگ هالند")||t.includes("الکساندر ایساک")||t.includes("ژائو پدرو"),noRawHaaland:!t.includes("Erling Haaland")}})())' 2>/dev/null | tr -d '"')
      FEAT="$A | gol=$G"
      ;;
    */league/seriea)
      FEAT=$($B eval 'JSON.stringify((()=>{const rows=document.querySelectorAll("table tbody tr").length;const t=document.body.innerText||"";return {tableRows:rows,hasInter:t.includes("اینتر"),hasMilan:t.includes("میلان")}})())' 2>/dev/null | tr -d '"')
      ;;
    */league/ucl)
      FEAT=$($B eval 'JSON.stringify({tableRows:document.querySelectorAll("table tbody tr").length,hasUCL:(document.body.innerText||"").includes("قهرمانان")})' 2>/dev/null | tr -d '"')
      ;;
    */league/persiangulf)
      FEAT=$($B eval 'JSON.stringify({hasLeagueTitle:(document.body.innerText||"").includes("خلیج فارس"),bodyLen:(document.body.innerText||"").length})' 2>/dev/null | tr -d '"')
      ;;
    */team/8456)
      FEAT=$($B eval 'JSON.stringify((()=>{const tp=document.querySelector("[data-testid=team-top-players]");const co=document.querySelector("[data-testid=team-coaches]");const t=tp?tp.textContent:"";return {topPlayers:!!tp,faHaaland:t.includes("ارلینگ هالند"),noRawHaaland:!t.includes("Erling Haaland"),coaches:!!co,coachRows:co?co.querySelectorAll("li").length:0}})())' 2>/dev/null | tr -d '"')
      ;;
    */team/9925)
      FEAT=$($B eval 'JSON.stringify({coaches:!!document.querySelector("[data-testid=team-coaches]"),rows:document.querySelectorAll("[data-testid=team-coaches] li").length})' 2>/dev/null | tr -d '"')
      ;;
    */team/9826)
      FEAT=$($B eval 'JSON.stringify({coaches:!!document.querySelector("[data-testid=team-coaches]"),rows:document.querySelectorAll("[data-testid=team-coaches] li").length})' 2>/dev/null | tr -d '"')
      ;;
    */player/604982)
      FEAT=$($B eval 'JSON.stringify((()=>{const s=document.querySelector("[data-testid=player-injury]");const h=(document.querySelector("h1")||{}).textContent||"";const out={h1HonestEn:h.includes("Loftus-Cheek")};if(!s){out.injury=false}else{const t=s.textContent||"";out.injury=true;out.hasType=t.includes("آسیب‌دیدگی ران");out.hasReturn=t.includes("اواخر نوامبر ۲۰۲۶")}return out})())' 2>/dev/null | tr -d '"')
      ;;
    */player/737066)
      FEAT=$($B eval 'JSON.stringify((()=>{const h=(document.querySelector("h1")||{}).textContent||"";return {h1Fa:h.includes("ارلینگ هالند"),h1Text:h.trim(),injuryHidden:!document.querySelector("[data-testid=player-injury]")}})())' 2>/dev/null | tr -d '"')
      ;;
    */match/5749720)
      $B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="اطلاعات");if(b)b.click();return 1})()' >/dev/null 2>&1
      sleep 1.5
      W=$($B eval 'JSON.stringify((()=>{const c=document.querySelector("[data-testid=match-weather]");if(!c)return {weather:false};const t=c.textContent||"";return {weather:true,hasTitle:t.includes("وضعیت هوا"),hasClear:t.includes("صاف"),has11:t.includes("۱۱°"),has91:t.includes("۹۱٪"),badge:t.includes("مشاهده‌شده"),noWindRow:!t.includes("باد")}})())' 2>/dev/null | tr -d '"')
      $B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="آمار");if(b)b.click();return 1})()' >/dev/null 2>&1
      sleep 1.5
      Z=$($B eval 'JSON.stringify((()=>{const c=document.querySelector("[data-testid=match-zones]");if(!c)return {zones:false};const t=c.textContent||"";return {zones:true,hasDir:t.includes("جهت حملات"),has49:t.includes("۴۹٪"),has42:t.includes("۴۲٪")}})())' 2>/dev/null | tr -d '"')
      FEAT="$W $Z"
      ;;
    */match/5071464)
      $B eval '(()=>{const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="اطلاعات");if(b)b.click();return 1})()' >/dev/null 2>&1
      sleep 1.5
      FEAT=$($B eval 'JSON.stringify((()=>{const c=document.querySelector("[data-testid=match-weather]");if(!c)return {weather:false};const t=c.textContent||"";return {weather:true,cond:t.includes("رعدوبرق")?"رعدوبرق":"other",badge:t.includes("پیش‌بینی"),hasTempDeg:t.includes("°"),hasPercent:t.includes("٪")}})())' 2>/dev/null | tr -d '"')
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

echo "== PART B: interaction contracts =="
IBAD=0
# B1) cycle-99 season deep link
$B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
$B open "http://localhost:3000/league/pl?season=2024/2025" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3
B1=$($B eval 'JSON.stringify((()=>{const txt=document.body.innerText||"";return {sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,hasHistLabel:txt.includes("فصل ۲۰۲۴/۲۰۲۵"),hasLiv84:txt.includes("لیورپول")&&txt.includes("۸۴")}})())' 2>/dev/null | tr -d '"\\')
echo "B1 deep-link → $B1"
echo "$B1" | grep -q 'hasHistLabel:true' && echo "$B1" | grep -q 'hasLiv84:true' && echo "$B1" | grep -q 'h1n:1' || { echo "   ⚠ B1 FAIL"; IBAD=$((IBAD+1)); }
# B2) cycle-101 season-state reset on client-side league switch
$B open "http://localhost:3000/leagues" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
sleep 2
$B eval 'JSON.stringify((()=>{const a=[...document.querySelectorAll("a[href=\"/league/ucl\"]")][0];if(!a)return {found:false};a.click();return {found:true}})())' >/dev/null 2>&1
$B wait --fn "document.body && (document.body.innerText||'').includes('لیگ قهرمانان اروپا')" >/dev/null 2>&1
sleep 4
B2=$($B eval 'JSON.stringify((()=>{const txt=document.body.innerText||"";const sel=document.querySelector("select");return {url:location.pathname+location.search,searchEmpty:location.search==="",hasCurrentLabel:txt.includes("فصل ۲۰۲۶/۲۰۲۷"),hasCarriedLabel:txt.includes("۲۰۲۴/۲۰۲۵"),selVal:sel?sel.value:null,sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth}})())' 2>/dev/null | tr -d '"\\')
echo "B2 league-switch reset → $B2"
echo "$B2" | grep -q 'searchEmpty:true' && echo "$B2" | grep -q 'hasCurrentLabel:true' && echo "$B2" | grep -q 'hasCarriedLabel:false' || { echo "   ⚠ B2 FAIL"; IBAD=$((IBAD+1)); }
echo "INTERACTION_BAD=$IBAD"
