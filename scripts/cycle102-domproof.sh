#!/bin/bash
# cycle-102 DOM proof at 390x844 — matchday-aware standings TTL is an
# infrastructure update (UI unchanged): prove both a matchday league page
# (seriea — live matchday right now) and a quiet league page (pl) render
# their standings tables intact with the payload's new additive metadata.
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

$B open "http://localhost:3000/league/seriea" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 4
echo "== 1) /league/seriea (matchday league) renders table =="
$B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,tableRows:document.querySelectorAll("table tbody tr").length,hasInter:(document.body.innerText||"").includes("اینتر")})' 2>/dev/null
errs

$B open "http://localhost:3000/league/pl" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3
echo "== 2) /league/pl (quiet league) renders table =="
$B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,tableRows:document.querySelectorAll("table tbody tr").length,hasCity:(document.body.innerText||"").includes("منچسترسیتی")})' 2>/dev/null
errs

$B open "http://localhost:3000/league/seriea?season=2024/2025" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 4
echo "== 3) historical season path unaffected =="
$B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,hasHistLabel:(document.body.innerText||"").includes("۲۰۲۴/۲۰۲۵")})' 2>/dev/null
errs
