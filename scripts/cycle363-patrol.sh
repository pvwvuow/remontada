#!/bin/bash
# cycle-363 bug-hunt patrol at 390x844 — full circuit + verification of the
# newest features end-to-end (post-recovery state, HEAD=05aa321):
#   1) home
#   2) /league/iraq — cycle-362 (h1 + 20-row Persian table, الکرمه top)
#   3) /league/iraq آقای گل tab — honest empty
#   4) /league/iraq?season=2024/2025 — historical deep link (الشرطه)
#   5) /league/egypt آمار فصل — cycle-361 + cycle-360 TOTW section (11 nodes)
#   6) /league/pl آمار فصل — cycle-360 TOTW (11 nodes + round chips)
#   7) /team/1680577 (الکرمه) — cycle-362 team page
#   8) /team/101745 (الاهلی مصر) — cycle-361 team page
#   9) /match/5795501 — pre-match: cycle-359 hint + click «دیدن ترکیب» →
#      tab ترکیب + cycle-352 banner
#  10) /topscorers/iraq — honest empty page
#  11) /leagues — «لیگ ستارگان عراق» + IRQ chip
#  12) /player/696679 — cycle-355/356 contracts (expand → chips)
#  13) /coach/30889 — coach card
#  14) /topscorers — global race page
# Every page: sw=cw=390, console+page errors empty, 0 broken images.
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
echo "== 1) home =="
nav "http://localhost:3000/"
base; errs

echo "== 2) /league/iraq — cycle-362 =="
nav "http://localhost:3000/league/iraq"
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";const h1=document.querySelector("h1")?.textContent.trim();return {h1,rows:[...document.querySelectorAll("table tbody tr")].length,hasTop:t.includes("الکرمه")}})())' 2>/dev/null
base; errs

echo "== 3) /league/iraq tab آقای گل — خالی صادقانه =="
$B eval 'JSON.stringify((()=>{const tab=[...document.querySelectorAll("button")].find(b=>b.textContent.trim()==="آقای گل");if(!tab)return {tab:false};tab.click();return {tab:true}})())' 2>/dev/null
sleep 2
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {len:t.length,rows:[...document.querySelectorAll("table tbody tr")].length}})())' 2>/dev/null
base; errs

echo "== 4) /league/iraq?season=2024/2025 — تاریخی =="
nav "http://localhost:3000/league/iraq?season=2024%2F2025"
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {rows:[...document.querySelectorAll("table tbody tr")].length,hasShorta:t.includes("الشرطه")}})())' 2>/dev/null
base; errs

echo "== 5) /league/egypt آمار فصل — TOTW مصر (۳۶۰+۳۶۱) =="
nav "http://localhost:3000/league/egypt"
$B eval 'JSON.stringify((()=>{const tab=[...document.querySelectorAll("button")].find(b=>b.textContent.trim()==="آمار فصل");if(!tab)return {tab:false};tab.click();return {tab:true}})())' 2>/dev/null
sleep 3
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {hasTotw:t.includes("تیم هفته"),nodes:[...document.querySelectorAll("a[href*=/player/]")].length}})())' 2>/dev/null
base; errs

echo "== 6) /league/pl آمار فصل — TOTW لیگ =="
nav "http://localhost:3000/league/pl"
$B eval 'JSON.stringify((()=>{const tab=[...document.querySelectorAll("button")].find(b=>b.textContent.trim()==="آمار فصل");if(!tab)return {tab:false};tab.click();return {tab:true}})())' 2>/dev/null
sleep 3
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";const chips=[...document.querySelectorAll("button")].filter(b=>/هفته/.test(b.textContent)&&b.textContent.length<12).length;return {hasTotw:t.includes("تیم هفته"),roundChips:chips,playerLinks:[...document.querySelectorAll("a[href*=/player/]")].length}})())' 2>/dev/null
base; errs

echo "== 7) /team/1680577 — الکرمه =="
nav "http://localhost:3000/team/1680577"
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {h1:document.querySelector("h1")?.textContent.trim(),hasLeague:t.includes("ستارگان عراق")}})())' 2>/dev/null
base; errs

echo "== 8) /team/101745 — الاهلی مصر =="
nav "http://localhost:3000/team/101745"
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {h1:document.querySelector("h1")?.textContent.trim(),hasEgypt:t.includes("لیگ برتر مصر")}})())' 2>/dev/null
base; errs

echo "== 9) /match/5795501 — پیش‌بازی: hint ۳۵۹ + بنر ۳۵۲ =="
nav "http://localhost:3000/match/5795501"
$B eval 'JSON.stringify((()=>{const hint=document.querySelector("[data-testid=match-events-predicted-hint]");return {hint:!!hint,hintTxt:hint?.textContent.trim().slice(0,40)||null}})())' 2>/dev/null
$B eval 'JSON.stringify((()=>{const btn=[...document.querySelectorAll("button")].find(b=>b.textContent.includes("دیدن ترکیب"));if(!btn)return {clicked:false};btn.click();return {clicked:true}})())' 2>/dev/null
sleep 2.5
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";const active=[...document.querySelectorAll("#match-tabs button")].find(b=>b.getAttribute("aria-current")==="page")?.textContent.trim();return {activeTab:active,hasBanner:t.includes("ترکیب پیش‌بینی‌شده"),formation:t.includes("۴-۲-۳-۱")}})())' 2>/dev/null
base; errs

echo "== 10) /topscorers/iraq — خالی صادقانه =="
nav "http://localhost:3000/topscorers/iraq"
base; errs

echo "== 11) /leagues — عراق حاضر =="
nav "http://localhost:3000/leagues"
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {hasIraq:t.includes("لیگ ستارگان عراق"),hasIRQ:t.includes("IRQ"),hasEgypt:t.includes("لیگ برتر مصر")}})())' 2>/dev/null
base; errs

echo "== 12) /player/696679 — قرارداد ۳۵۵/۳۵۶ =="
nav "http://localhost:3000/player/696679"
$B eval 'JSON.stringify((()=>{const exp=[...document.querySelectorAll("button")].find(b=>b.textContent.trim().startsWith("نمایش همهٔ"));if(exp)exp.click();return {expanded:!!exp}})())' 2>/dev/null
sleep 1.5
$B eval 'JSON.stringify((()=>{const chips=[...document.querySelectorAll("[data-testid=player-recent-leagues] button")].map(b=>b.textContent.trim());return {chipN:chips.length,first:chips[0]||null,hasAll:chips.some(c=>c.startsWith("همهٔ"))}})())' 2>/dev/null
base; errs

echo "== 13) /coach/30889 =="
nav "http://localhost:3000/coach/30889"
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {h1:document.querySelector("h1")?.textContent.trim(),hasTrophies:t.includes("افتخارات")||t.includes("جام")}})())' 2>/dev/null
base; errs

echo "== 14) /topscorers — مسابقهٔ سراسری =="
nav "http://localhost:3000/topscorers"
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {hasTable:[...document.querySelectorAll("table tbody tr")].length>0,len:t.length}})())' 2>/dev/null
base; errs
