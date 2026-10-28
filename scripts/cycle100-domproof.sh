#!/bin/bash
# cycle-100 DOM proof at 390x844 — «وضعیت هوا» (weather on the match info
# tab): /match/5749720 (Milan–Bologna, finished, apiUsed=current) → click
# «اطلاعات» tab → match-weather card present with «صاف» + ۱۱° + رطوبت ۹۱٪ +
# پوشش ابر ۵٪ + badge «مشاهده‌شده»; /match/6275369 (Everton–Newcastle,
# upcoming, apiUsed=forecast) → card present with badge «پیش‌بینی» + its own
# probed values; /match/5749726 (Parma–Udinese) → «صاف» + ۱۲°. Every page:
# sw=cw=390, exactly 1 h1, 0 broken imgs, console clean, appErr=0.
set -u
B=agent-browser

$B set viewport 390 844 >/dev/null
errs() {
  E=$($B errors --json 2>/dev/null | python3 -c 'import json,sys
try: print(len([e for e in json.load(sys.stdin)["data"]["errors"] if e.get("url")]))
except Exception: print("ERR")')
  C=$($B console 2>/dev/null | grep -ci error || true)
  echo "   appErr=$E consoleErr=$C"
}

$B errors --clear >/dev/null 2>&1
$B console --clear >/dev/null 2>&1
$B open "http://localhost:3000/match/5749720" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3.5
echo "== 1) /match/5749720 open (events default) =="
$B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null
errs

echo "== 2) 5749720 click «اطلاعات» tab → weather card (current) =="
$B eval 'JSON.stringify((()=>{const btn=[...document.querySelectorAll("button")].find(b=>(b.textContent||"").trim()==="اطلاعات");if(!btn)return {found:false};btn.click();return {found:true}})())' 2>/dev/null
sleep 1.5
$B eval 'JSON.stringify((()=>{const card=document.querySelector("[data-testid=match-weather]");const base={sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth};if(!card)return {...base,card:false};const txt=card.textContent||"";return {...base,card:true,hasTitle:txt.includes("وضعیت هوا"),hasClear:txt.includes("صاف"),hasTemp:txt.includes("۱۱°"),hasHum:txt.includes("۹۱٪"),hasCloud:txt.includes("۵٪"),badgeSeen:txt.includes("مشاهده‌شده"),noWindRow:!txt.includes("باد"),rows:(card.querySelectorAll("li")).length}})())' 2>/dev/null
errs

echo "== 3) /match/6275369 upcoming → weather card (forecast badge) =="
$B open "http://localhost:3000/match/6275369" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3
$B eval 'JSON.stringify((()=>{const btn=[...document.querySelectorAll("button")].find(b=>(b.textContent||"").trim()==="اطلاعات");if(btn)btn.click();return {clicked:!!btn}})())' 2>/dev/null
sleep 1.5
$B eval 'JSON.stringify((()=>{const card=document.querySelector("[data-testid=match-weather]");const base={sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length};if(!card)return {...base,card:false};const txt=card.textContent||"";return {...base,card:true,badgeForecast:txt.includes("پیش‌بینی"),hasCloudy:txt.includes("ابری"),hasCloudCover:txt.includes("۶۴٪"),hasPrecipChance:txt.includes("۷٪")}})())' 2>/dev/null
errs

echo "== 4) /match/5749726 second current match → values =="
$B open "http://localhost:3000/match/5749726" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3
$B eval 'JSON.stringify((()=>{const btn=[...document.querySelectorAll("button")].find(b=>(b.textContent||"").trim()==="اطلاعات");if(btn)btn.click();return {clicked:!!btn}})())' 2>/dev/null
sleep 1.5
$B eval 'JSON.stringify((()=>{const card=document.querySelector("[data-testid=match-weather]");const base={sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length};if(!card)return {...base,card:false};const txt=card.textContent||"";return {...base,card:true,hasClear:txt.includes("صاف"),hasTemp:txt.includes("۱۲°"),hasHum:txt.includes("۸۹٪"),badgeSeen:txt.includes("مشاهده‌شده")}})())' 2>/dev/null
errs
