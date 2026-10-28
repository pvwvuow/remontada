#!/bin/bash
# cycle-97 DOM proof at 390x844 — «جهت حملات» (attacking zones on the match
# stats tab): /match/5749720 (Milan–Bologna, finished) → click «آمار» tab →
# match-zones card present with 49/21/30 (home) and 35/23/42 (away) Persian
# values + both team names; /match/6275369 (Everton–Newcastle, upcoming) →
# stats tab shows the pre-kickoff empty state, zones card absent, page
# intact. Every page: sw=cw=390, exactly 1 h1, 0 broken imgs, console clean,
# appErr=0.
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

echo "== 2) click «آمار» tab → zones card =="
$B eval 'JSON.stringify((()=>{const btn=[...document.querySelectorAll("button")].find(b=>(b.textContent||"").trim()==="آمار");if(!btn)return {found:false};btn.click();return {found:true}})())' 2>/dev/null
sleep 1.5
$B eval 'JSON.stringify((()=>{const card=document.querySelector("[data-testid=match-zones]");const base={sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth};if(!card)return {...base,card:false};const txt=card.textContent||"";return {...base,card:true,hasTitle:txt.includes("جهت حملات"),has49:txt.includes("۴۹٪"),has21:txt.includes("۲۱٪"),has30:txt.includes("۳۰٪"),has35:txt.includes("۳۵٪"),has42:txt.includes("۴۲٪"),hasMilan:txt.includes("میلان"),hasBologna:txt.includes("بولونیا")}})())' 2>/dev/null
errs

echo "== 3) /match/6275369 upcoming → zones absent, empty state =="
$B open "http://localhost:3000/match/6275369" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3
$B eval 'JSON.stringify((()=>{const btn=[...document.querySelectorAll("button")].find(b=>(b.textContent||"").trim()==="آمار");if(btn)btn.click();return {clicked:!!btn}})())' 2>/dev/null
sleep 1.5
$B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,card:!!document.querySelector("[data-testid=match-zones]"),emptyState:(document.body.innerText||"").includes("آمار پس از شروع بازی")})' 2>/dev/null
errs
