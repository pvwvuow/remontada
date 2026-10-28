#!/bin/bash
# cycle-92 DOM proof at 390x844 — «برترین‌های رسمی فصل» (upstream season
# boards) on the league stats tab: /league/pl → [data-testid=league-boards]
# present after opening the «آمار فصل» tab, 6 team categories + kind toggle
# to بازیکنان (Top speed visible on PL), /league/seriea → boards present,
# /league/persiangulf → page intact (upstream 503-graceful, section absent).
# Every page: sw=cw=390, exactly 1 h1, 0 broken imgs, console clean, appErr=0.
set -u
B=agent-browser

$B set viewport 390 844 >/dev/null
probe() {
  $B errors --clear >/dev/null 2>&1
  $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 2
  echo "== $1 =="
  # open the «آمار فصل» tab, give the (already standings-cached) payload a beat
  $B eval '(()=>{const t=[...document.querySelectorAll("button")].find(b=>b.textContent.trim()==="آمار فصل");if(t)t.click();return t?"clicked":"no-tab"})()' >/dev/null 2>&1
  sleep 1.5
  $B eval 'JSON.stringify((()=>{const bd=document.querySelector("[data-testid=league-boards]");const base={sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length};if(!bd)return {...base,sec:false};return {...base,sec:true,title:(bd.querySelector("h3")||{}).textContent||"",hasKindToggle:bd.textContent.includes("بازیکنان"),chips:[...bd.querySelectorAll("[aria-label=\"دستهٔ آماری\"] button")].map(b=>b.textContent.trim()),podium1:((bd.querySelector(".glass-leader")||bd.querySelector("a,div"))||{}).textContent||""}})())' 2>/dev/null | tr -d '"'
  E=$($B errors --json 2>/dev/null | python3 -c 'import json,sys
try: print(len([e for e in json.load(sys.stdin)["data"]["errors"] if e.get("url")]))
except Exception: print("ERR")')
  C=$($B console 2>/dev/null | grep -ci error || true)
  echo "   appErr=$E consoleErr=$C"
}

probe "http://localhost:3000/league/pl"
probe "http://localhost:3000/league/seriea"
probe "http://localhost:3000/league/persiangulf"
