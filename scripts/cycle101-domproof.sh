#!/bin/bash
# cycle-101 DOM proof at 390x844 — season state no longer carries across a
# client-side league switch (registered cycle-99 candidate, closed with
# key={key} remount) + weather vocabulary completion end-to-end:
# 1) /league/pl?season=2024/2025 → historical view (deep link still works)
# 2) dock «لیگ‌ها» → /leagues → click «لیگ قهرمانان اروپا» → /league/ucl:
#    URL has NO ?season, season label = «فصل ۲۰۲۶/۲۰۲۷» (current), NOT the
#    carried 2024/2025
# 3) /match/5071464 (thunderstorms, forecast) → info tab → «رعدوبرق» + «۱۸°»
#    + «۵۱٪» — extended weather pipeline
# 4) /match/5749720 → cycle-100 weather card unchanged («صاف»)
# Every page: sw=cw=390, exactly 1 h1, 0 broken imgs, console clean, appErr=0.
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
$B open "http://localhost:3000/league/pl?season=2024/2025" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3.5
echo "== 1) /league/pl?season=2024/2025 deep link =="
$B eval 'JSON.stringify((()=>{const txt=document.body.innerText||"";return {sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,hasHistLabel:txt.includes("فصل ۲۰۲۴/۲۰۲۵"),hasLiv84:txt.includes("لیورپول")&&txt.includes("۸۴")}})())' 2>/dev/null
errs

echo "== 2) dock «لیگ‌ها» → /leagues → ucl (client-side) → no carry =="
$B eval 'JSON.stringify((()=>{const a=[...document.querySelectorAll("a[href=\"/leagues\"]")][0];if(!a)return {found:false};a.click();return {found:true}})())' 2>/dev/null
sleep 2
$B eval 'JSON.stringify((()=>{const a=[...document.querySelectorAll("a[href=\"/league/ucl\"]")][0];if(!a)return {found:false};a.click();return {found:true}})())' 2>/dev/null
$B wait --fn "document.body && (document.body.innerText||'').includes('لیگ قهرمانان اروپا')" >/dev/null 2>&1
sleep 4
$B eval 'JSON.stringify((()=>{const txt=document.body.innerText||"";const sel=document.querySelector("select");return {url:location.pathname+location.search,searchEmpty:location.search==="",h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,hasCurrentLabel:txt.includes("فصل ۲۰۲۶/۲۰۲۷"),hasCarriedLabel:txt.includes("۲۰۲۴/۲۰۲۵"),selVal:sel?sel.value:null}})())' 2>/dev/null
errs

echo "== 3) /match/5071464 thunderstorms → «رعدوبرق» =="
$B open "http://localhost:3000/match/5071464" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3
$B eval 'JSON.stringify((()=>{const btn=[...document.querySelectorAll("button")].find(b=>(b.textContent||"").trim()==="اطلاعات");if(!btn)return {found:false};btn.click();return {found:true}})())' 2>/dev/null
sleep 1.5
$B eval 'JSON.stringify((()=>{const card=document.querySelector("[data-testid=match-weather]");const base={sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length};if(!card)return {...base,card:false};const txt=card.textContent||"";return {...base,card:true,hasThunder:txt.includes("رعدوبرق"),hasTemp:txt.includes("۱۸°"),hasPrecip:txt.includes("۵۱٪"),badgeForecast:txt.includes("پیش‌بینی")}})())' 2>/dev/null
errs

echo "== 4) /match/5749720 cycle-100 card unchanged =="
$B open "http://localhost:3000/match/5749720" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3
$B eval 'JSON.stringify((()=>{const btn=[...document.querySelectorAll("button")].find(b=>(b.textContent||"").trim()==="اطلاعات");if(btn)btn.click();return {clicked:!!btn}})())' 2>/dev/null
sleep 1.5
$B eval 'JSON.stringify((()=>{const card=document.querySelector("[data-testid=match-weather]");const base={sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length};if(!card)return {...base,card:false};const txt=card.textContent||"";return {...base,card:true,hasClear:txt.includes("صاف"),hasTemp:txt.includes("۱۱°"),hasHum:txt.includes("۹۱٪")}})())' 2>/dev/null
errs
