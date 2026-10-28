#!/bin/bash
# cycle-99 DOM proof at 390x844 — deep-linkable season selector on the league
# page («فصل» select reads ?season= since cycle-99; the API family has honored
# &season= since cycle-55 but the page never did):
#   1) /league/pl?season=2024/2025 → historical view directly (label
#      «فصل ۲۰۲۴/۲۰۲۵», first row Liverpool ۸۴, select value 2024/2025)
#   2) selector change 2025/2026 → URL picks the season up (replaceState,
#      location.search carries season=2025%2F2026) + label follows
#   3) /league/pl?season=1999/2000 (well-formed, NOT offered) → upstream
#      silently serves the current season (probed fallback contract) → the
#      honesty snap fires: URL param STRIPPED, label «فصل ۲۰۲۶/۲۰۲۷»,
#      select value 2026/2027
#   4) /league/pl?season=garbage (bad shape) → seed ignored, current season,
#      page healthy
#   5) /league/pl (no param) → baseline unchanged
#   6) /league/pl?season=2013/2014 (real season OUTSIDE the 12-option cap,
#      City 86) → option appended, selector consistent with the data
# Every step: sw=cw=390, exactly 1 h1, 0 broken imgs, console=0, appErr=0.
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
base() {
  $B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null
}

$B errors --clear >/dev/null 2>&1
$B console --clear >/dev/null 2>&1

echo "== 1) deep link /league/pl?season=2024/2025 → historical view directly =="
$B open "http://localhost:3000/league/pl?season=2024/2025" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 4
base
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";const sel=document.querySelector("#season-select");return {label2024:t.includes("فصل ۲۰۲۴/۲۰۲۵"),liverpool:t.includes("لیورپول"),pts84:t.includes("۸۴"),selValue:sel?sel.value:null,urlHasSeason:location.search.includes("season=2024"),row1:/لیورپول[\s\S]{0,200}?۸۴/.test(t)}})())' 2>/dev/null
errs

echo "== 2) selector change → 2025/2026 → URL + label sync =="
$B eval 'JSON.stringify((()=>{const sel=document.querySelector("#season-select");if(!sel)return{found:false};const set=Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype,"value").set;set.call(sel,"2025/2026");sel.dispatchEvent(new Event("change",{bubbles:true}));return{found:true}})())' 2>/dev/null
sleep 4
$B eval 'JSON.stringify({url:decodeURIComponent(location.search),label2025:(document.body.innerText||"").includes("فصل ۲۰۲۵/۲۰۲۶"),selValue:(document.querySelector("#season-select")||{}).value||null})' 2>/dev/null
errs

echo "== 3) bogus-but-well-formed /league/pl?season=1999/2000 → honesty snap =="
$B open "http://localhost:3000/league/pl?season=1999/2000" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 5
base
$B eval 'JSON.stringify({search:location.search,label2026:(document.body.innerText||"").includes("فصل ۲۰۲۶/۲۰۲۷"),selValue:(document.querySelector("#season-select")||{}).value||null,cityPts21:(document.body.innerText||"").includes("۲۱")})' 2>/dev/null
errs

echo "== 4) bad shape /league/pl?season=garbage → ignored, current season =="
$B open "http://localhost:3000/league/pl?season=garbage" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 4
base
$B eval 'JSON.stringify({search:location.search,label2026:(document.body.innerText||"").includes("فصل ۲۰۲۶/۲۰۲۷"),selValue:(document.querySelector("#season-select")||{}).value||null})' 2>/dev/null
errs

echo "== 5) baseline /league/pl (no param) → unchanged =="
$B open "http://localhost:3000/league/pl" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 4
base
$B eval 'JSON.stringify({search:location.search,label2026:(document.body.innerText||"").includes("فصل ۲۰۲۶/۲۰۲۷"),selValue:(document.querySelector("#season-select")||{}).value||null})' 2>/dev/null
errs

echo "== 6) real season outside cap /league/pl?season=2013/2014 → option appended =="
$B open "http://localhost:3000/league/pl?season=2013/2014" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 4
base
$B eval 'JSON.stringify((()=>{const sel=document.querySelector("#season-select");const t=document.body.innerText||"";return {search:decodeURIComponent(location.search),label2013:t.includes("فصل ۲۰۱۳/۲۰۱۴"),selValue:sel?sel.value:null,optCount:sel?sel.options.length:0,hasAppended:sel?[...sel.options].some(o=>o.value==="2013/2014"):false,city86:/منچسترسیتی[\s\S]{0,200}?۸۶/.test(t)}})())' 2>/dev/null
errs
