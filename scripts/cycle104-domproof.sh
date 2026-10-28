#!/bin/bash
# Cycle-104 fix DOM proof at 390x844 — Persian display names in
# «بازیکنان کلیدی فصل» (registered cycle-103 polish observation):
#   1) /team/8456 (City): mapped rows render Persian (ارلینگ هالند) with the
#      English name kept as the row's title tooltip; value «۸.۰۱», gold
#      rank-1 chip, /player links intact.
#   2) /team/9925 (Celtic): mapped row «کامیلو دوران» AND the unmapped
#      "Kasper Waarts Høgh" staying raw English — the honest fallback,
#      exactly the cycle-96 convention.
set -u
B=agent-browser
FAIL=0

check_page () { # $1=url  -> prints core health json, sets FAIL
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 3
}

echo "== step 1: /team/8456 mapped Persian rows =="
check_page "http://localhost:3000/team/8456"
OUT=$($B eval 'JSON.stringify((()=>{const tp=document.querySelector("[data-testid=team-top-players]");if(!tp)return {section:false};const t=tp.textContent||"";const haaland=[...tp.querySelectorAll("span[title]")].find(s=>s.getAttribute("title")==="Erling Haaland");return {section:true,faHaaland:t.includes("ارلینگ هالند"),faCherki:t.includes("ریان چرکی"),faSemenyo:t.includes("آنتوان سمنیو"),noRawHaaland:!t.includes("Erling Haaland"),titleEn:!!haaland,value801:t.includes("۸.۰۱"),link:/player\/737066/.test(tp.innerHTML),goldChip:!!tp.querySelector(".bg-amber-400\\/15")}})())' 2>/dev/null)
echo "$OUT"
echo "$OUT" | tr -d '"\\' | grep -q 'section:true,faHaaland:true,faCherki:true,faSemenyo:true,noRawHaaland:true,titleEn:true,value801:true,link:true,goldChip:true' || FAIL=$((FAIL+1))

echo "== step 2: /team/9925 mapped + honest English fallback =="
check_page "http://localhost:3000/team/9925"
OUT=$($B eval 'JSON.stringify((()=>{const tp=document.querySelector("[data-testid=team-top-players]");if(!tp)return {section:false};const t=tp.textContent||"";return {section:true,faDuran:t.includes("کامیلو دوران"),faNygren:t.includes("بنجامین نایگرن"),rawHogh:t.includes("Kasper Waarts Høgh")}})())' 2>/dev/null)
echo "$OUT"
echo "$OUT" | tr -d '"\\' | grep -q 'section:true,faDuran:true,faNygren:true,rawHogh:true' || FAIL=$((FAIL+1))

echo "== core health both pages =="
for P in "http://localhost:3000/team/8456" "http://localhost:3000/team/9925"; do
  check_page "$P"
  R=$($B eval '(function(){var sw=document.documentElement.scrollWidth,cw=document.documentElement.clientWidth,h1n=document.querySelectorAll("h1").length,vb=[...document.images].filter(function(i){return i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden"}).length;return JSON.stringify({sw:sw,cw:cw,h1n:h1n,vbroken:vb})})()' 2>/dev/null)
  C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception:
  print('ERR')")
  E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  print(len([e for e in es if e.get('url')]))
except Exception:
  print('ERR')")
  echo "$P → $R | console=$C appErrors=$E"
  echo "$R $C $E"
  echo "$R" | tr -d '"\\' | grep -q 'sw:390,cw:390,h1n:1,vbroken:0' && [ "$C" = "0" ] && [ "$E" = "0" ] || FAIL=$((FAIL+1))
done
echo "==="
echo "DOMPROOF_FAIL=$FAIL"