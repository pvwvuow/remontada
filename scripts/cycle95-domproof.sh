#!/bin/bash
# cycle-95 DOM proof at 390x844 — «بازیکنان کلیدی فصل» (team key players,
# overview.topPlayers): /team/8456 → section present with 3 groups (امتیاز/
# گل/پاس گل), 3 rows each, gold rank-1 chip, /player/{id} links; /team/42551
# → section absent, page intact (graceful). Every page: sw=cw=390, exactly
# 1 h1, 0 broken imgs, console clean, appErr=0.
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
$B open "http://localhost:3000/team/8456" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3.5
echo "== 1) /team/8456 =="
$B eval 'JSON.stringify((()=>{const sec=document.querySelector("[data-testid=team-top-players]");const base={sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length};if(!sec)return {...base,sec:false};const cards=[...sec.children];const links=[...sec.querySelectorAll("a")].map(a=>a.getAttribute("href"));const gold=sec.querySelectorAll(".text-amber-300").length;const txt=sec.textContent||"";return {...base,sec:true,groups:cards.length,hasHaaland:txt.includes("Haaland"),has801:txt.includes("۸.۰۱"),has9g:txt.includes("گل"),goldRanks:gold,links:links.slice(0,4)}})())' 2>/dev/null
errs

echo "== 2) /team/42551 (no data → hidden) =="
$B open "http://localhost:3000/team/42551" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3
$B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,sec:!!document.querySelector("[data-testid=team-top-players]")})' 2>/dev/null
errs

echo "== 3) /team/9925 (Celtic) =="
$B open "http://localhost:3000/team/9925" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3
$B eval 'JSON.stringify((()=>{const sec=document.querySelector("[data-testid=team-top-players]");if(!sec)return {sec:false};const txt=sec.textContent||"";return {sec:true,hasYang:txt.includes("Hyun-Jun Yang"),has792:txt.includes("۷.۹۲"),rows:sec.querySelectorAll("li").length}})())' 2>/dev/null
errs
