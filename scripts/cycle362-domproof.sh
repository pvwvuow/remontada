#!/bin/bash
# cycle-362 DOM proof at 390x844 — Iraq Stars League (fotmobId 524) joins
# the catalog as the 26th competition:
#   1) /league/iraq — h1 «لیگ ستارگان عراق», Persian 20-row table (الکرمه top)
#   2) آقای گل tab → honest empty state
#   3) season chip 2024/2025 → historical table (الشرطه champion top)
#   4) /leagues — the new card with IRQ chip
#   5) /team/1680577 — الکرمه team page renders
# Every page: sw=cw=390, console+page errors empty.
set -u
B=agent-browser

errs() {
  E=$($B errors --json 2>/dev/null | python3 -c 'import json,sys
try: print(len([e for e in json.load(sys.stdin)["data"]["errors"] if e.get("url")]))
except Exception: print("ERR")')
  C=$($B console 2>/dev/null | grep -ci error || true)
  echo "   appErr=$E consoleErr=$C"
}

nav() { # nav <url>
  $B errors --clear >/dev/null 2>&1
  $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B set viewport 390 844 >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 2.5
}

base() { # per-page invariants
  $B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,imgs:document.images.length,chars:t.length}})())' 2>/dev/null
}

$B close --all >/dev/null 2>&1
echo "== 1) /league/iraq — جدول فارسی =="
nav "http://localhost:3000/league/iraq"
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";const h1=document.querySelector("h1")?.textContent.trim();const rows=[...document.querySelectorAll("table tbody tr")].length;return {h1,rows,hasTop:t.includes("الکرمه"),hasPts:t.includes("۲۷")||t.includes("27"),chips:[...document.querySelectorAll("button")].filter(b=>/20\d\d\/20\d\d/.test(b.textContent)).length}})())' 2>/dev/null
base; errs

echo "== 2) tab آقای گل — خالی صادقانه =="
$B eval 'JSON.stringify((()=>{const tab=[...document.querySelectorAll("button")].find(b=>b.textContent.trim()==="آقای گل");if(!tab)return {tab:false};tab.click();return {tab:true}})())' 2>/dev/null
sleep 2
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {emptyHonest:t.includes("هنوز")||t.includes("ثبت نشده")||t.includes("خالی")||t.includes("در دسترس نیست")||t.includes("گلزنی"),len:t.length}})())' 2>/dev/null
base; errs

echo "== 3) چیپ فصل 2024/2025 — الشرطه قهرمان =="
nav "http://localhost:3000/league/iraq"
$B eval 'JSON.stringify((()=>{const chip=[...document.querySelectorAll("button")].find(b=>b.textContent.trim()==="2024/2025");if(!chip)return {chip:false};chip.click();return {chip:true}})())' 2>/dev/null
sleep 3
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {hasShorta:t.includes("الشرطه"),rows:[...document.querySelectorAll("table tbody tr")].length}})())' 2>/dev/null
base; errs

echo "== 4) /leagues — کارت جدید با چیپ IRQ =="
nav "http://localhost:3000/leagues"
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {hasIraq:t.includes("لیگ ستارگان عراق"),hasIRQ:t.includes("IRQ")}})())' 2>/dev/null
base; errs

echo "== 5) /team/1680577 — الکرمه =="
nav "http://localhost:3000/team/1680577"
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";const h1=document.querySelector("h1")?.textContent.trim();return {h1,hasIraqLeague:t.includes("لیگ ستارگان عراق")||t.includes("ستارگان عراق")}})())' 2>/dev/null
base; errs
