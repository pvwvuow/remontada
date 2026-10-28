#!/bin/bash
# cycle-91 DOM proof at 390x844 — «تاریخچهٔ نیمکت» (team coach history):
# /team/8456 → [data-testid=team-coaches] with 4 tenure rows, newest bench
# (Enzo Maresca) tagged «نیمکت فعلی», Guardiola tenure shows ۱۰ فصل span;
# /team/9925 → 9 tenures, first live; /team/9826 → 14 tenures; /team/42551 →
# section absent (source null) with the page intact. Every page: sw=cw=390,
# exactly 1 h1, 0 broken imgs, console clean, appErr=0.
set -u
B=agent-browser

$B set viewport 390 844 >/dev/null
probe() {
  $B errors --clear >/dev/null 2>&1
  $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 3
  echo "== $1 =="
  $B eval 'JSON.stringify((()=>{const sec=document.querySelector("[data-testid=team-coaches]");const lis=sec?[...sec.querySelectorAll("li")]:[];const first=lis[0];return {sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,sec:!!sec,rows:lis.length,firstName:first?(first.querySelector("p")||{}).textContent||"":null,firstLive:first?first.textContent.includes("نیمکت فعلی"):false,guardiolaSeasons:(sec?(Array.from(lis).find(li=>li.textContent.includes("گواردیولا")||li.textContent.includes("Guardiola"))||{}).textContent||"":null),lastSpan:first?(first.querySelector("span")||{}).textContent||"":null}})())' 2>/dev/null | tr -d '"'
  E=$($B errors --json 2>/dev/null | python3 -c 'import json,sys
try: print(len([e for e in json.load(sys.stdin)["data"]["errors"] if e.get("url")]))
except Exception: print("ERR")')
  C=$($B console 2>/dev/null | grep -ci error || true)
  echo "   appErr=$E consoleErr=$C"
}

probe "http://localhost:3000/team/8456"
probe "http://localhost:3000/team/9925"
probe "http://localhost:3000/team/9826"
probe "http://localhost:3000/team/42551"
