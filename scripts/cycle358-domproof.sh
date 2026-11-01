#!/bin/bash
# cycle-358 bug-hunt patrol at 390x844 — full circuit + verification of the
# three newest features end-to-end:
#   1) home
#   2) /player/696679 — cycle-355 league-filter chips + cycle-356 stage badges
#      (expand archive, click لالیگا chip → filtered 28, then همهٔ مسابقه‌ها → back)
#   3) /team/8650 — cycle-357 team-history-link rows (8 linked, seasons span)
#   4) click oldest history row → /league/pl?season=2019/2020 → real 2019/20 table
#   5) /league/pl current standings
#   6) /topscorers
#   7) /match/5795501 pre-match (cycle-352 banner + lineup links)
#   8) /match/5749733 (finished/live — renders cleanly)
#   9) /coach/30889
#  10) /player/1417094 — Latin «FA Cup» chip honesty
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
  $B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,chars:t.length}})())' 2>/dev/null
}

$B close --all >/dev/null 2>&1
echo "== 1) home =="
nav "http://localhost:3000/"
base; errs

echo "== 2) player 696679 (رافینیا) — 355 chips + 356 badges =="
nav "http://localhost:3000/player/696679"
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";const exp=[...document.querySelectorAll("button")].find(b=>b.textContent.trim().startsWith("نمایش همهٔ"));if(exp){exp.click();return {expanded:true,label:exp.textContent.trim()}}return {expanded:false,hasRecent:t.includes("بازی‌های اخیر")}})())' 2>/dev/null
sleep 1.5
$B eval 'JSON.stringify((()=>{const chips=[...document.querySelectorAll("[data-testid=player-recent-leagues] button")].map(b=>b.textContent.trim());const badges=[...document.querySelectorAll("[data-testid=player-recent-stage]")].map(s=>s.textContent.trim());const tally={};badges.forEach(x=>tally[x]=(tally[x]||0)+1);return {chipN:chips.length,chips,badgeN:badges.length,tally}})())' 2>/dev/null
$B eval 'JSON.stringify((()=>{const chip=[...document.querySelectorAll("[data-testid=player-recent-leagues] button")].find(b=>b.textContent.includes("لالیگا"));if(!chip)return {clicked:false};chip.click();return {clicked:true,label:chip.textContent.trim()}})())' 2>/dev/null
sleep 1.5
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";const rows=document.querySelectorAll(".glass-list li").length;return {rows,toggle:[...document.querySelectorAll("button")].find(b=>b.textContent.trim().startsWith("نمایش همهٔ"))?.textContent.trim()||null,hasAllChip:t.includes("همهٔ مسابقه‌ها")}})())' 2>/dev/null
$B eval 'JSON.stringify((()=>{const all=[...document.querySelectorAll("[data-testid=player-recent-leagues] button")][0];if(!all)return {reset:false};all.click();return {reset:true}})())' 2>/dev/null
sleep 1.5
$B eval 'JSON.stringify((()=>{return {rowsAfterReset:document.querySelectorAll(".glass-list li").length,badgeN:document.querySelectorAll("[data-testid=player-recent-stage]").length}})())' 2>/dev/null
base; errs

echo "== 3) team 8650 — 357 history links =="
nav "http://localhost:3000/team/8650"
$B eval 'JSON.stringify((()=>{const ls=[...document.querySelectorAll("a[data-testid=team-history-link]")];const seasons=ls.map(a=>{const m=(a.getAttribute("href")||"").match(/season=([^&]+)/);return m?decodeURIComponent(m[1]):null});return {n:ls.length,seasons}})())' 2>/dev/null
base; errs

echo "== 4) click oldest history row -> /league/pl?season=2019/2020 =="
$B eval 'JSON.stringify((()=>{const ls=[...document.querySelectorAll("a[data-testid=team-history-link]")];const oldest=ls.find(a=>(a.getAttribute("href")||"").includes("season=2019%2F2020"))||ls[ls.length-1];if(!oldest)return {found:false};const href=oldest.getAttribute("href");oldest.click();return {found:true,href}})())' 2>/dev/null
sleep 5
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {url:location.pathname+location.search,hasLiv:t.includes("لیورپول"),has99:t.includes("۹۹"),hasCity:t.includes("سیتی"),hasUnited:t.includes("یونایتد")}})())' 2>/dev/null
base; errs

echo "== 5) /league/pl current =="
nav "http://localhost:3000/league/pl"
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {hasLiv:t.includes("لیورپول"),hasLegend:t.includes("کرنو")||t.includes("لیگ قهرمانان")||t.includes("سقوط"),rowN:document.querySelectorAll("tr").length}})())' 2>/dev/null
base; errs

echo "== 6) /topscorers =="
nav "http://localhost:3000/topscorers"
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {hasGoals:t.includes("گل"),hasAsis:t.includes("پاس"),hasYel:t.includes("کارت زرد")||t.includes("کارت‌های زرد")}})())' 2>/dev/null
base; errs

echo "== 7) match 5795501 pre-match =="
nav "http://localhost:3000/match/5795501"
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {has4231:t.includes("۴-۲-۳-۱"),lineupLinks:document.querySelectorAll("a[href^=\"/player/\"]").length,hasPred:t.includes("پیش‌بینی")}})())' 2>/dev/null
base; errs

echo "== 8) match 5749733 (Como–Venezia) =="
nav "http://localhost:3000/match/5749733"
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {h1:document.querySelector("h1")?.innerText.replace(/\n/g," ")||null,hasEvent:t.includes("گل")||t.includes("پایان")||t.includes("شروع"),touchAgg:t.includes("لمس")}})())' 2>/dev/null
base; errs

echo "== 9) coach 30889 =="
nav "http://localhost:3000/coach/30889"
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";return {h1:document.querySelector("h1")?.innerText.replace(/\n/g," ")||null,hasCareer:t.includes("هویت")||t.includes("دوران")||t.includes("باشگاه")}})())' 2>/dev/null
base; errs

echo "== 10) player 1417094 (لنکشیر) — Latin FA Cup honesty =="
nav "http://localhost:3000/player/1417094"
$B eval 'JSON.stringify((()=>{const t=document.body.innerText||"";const exp=[...document.querySelectorAll("button")].find(b=>b.textContent.trim().startsWith("نمایش همهٔ"));if(exp)exp.click();return {expanded:!!exp}})())' 2>/dev/null
sleep 1.5
$B eval 'JSON.stringify((()=>{const chips=[...document.querySelectorAll("[data-testid=player-recent-leagues] button")].map(b=>b.textContent.trim());return {chipN:chips.length,chips,latinFACup:chips.some(c=>c.includes("FA Cup"))}})())' 2>/dev/null
base; errs

echo "== DONE cycle-358 patrol =="
