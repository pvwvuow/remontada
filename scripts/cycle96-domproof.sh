#!/bin/bash
# cycle-96 DOM proof at 390x844 — «وضعیت مصدومیت» (player injury status,
# playerData.injuryInformation): /player/604982 (Loftus-Cheek) → card present
# with آسیب‌دیدگی ران + اواخر نوامبر ۲۰۲۶ + Jalali update; /player/737066
# (Haaland) → card absent, page intact; /player/895362 (Rodrygo) → پارگی
# رباط صلیبی + اواخر دسامبر ۲۰۲۶; /team/8564 → bare «مصدوم» squad chips
# (the flag this card complements). Every page: sw=cw=390, exactly 1 h1,
# 0 broken imgs, console clean, appErr=0.
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
$B open "http://localhost:3000/player/604982" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3.5
echo "== 1) /player/604982 (Loftus-Cheek, injured) =="
$B eval 'JSON.stringify((()=>{const sec=document.querySelector("[data-testid=player-injury]");const base={sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length};if(!sec)return {...base,sec:false};const txt=sec.textContent||"";const rows=[...sec.querySelectorAll("div.flex.items-center.justify-between")].length;return {...base,sec:true,hasName:txt.includes("آسیب‌دیدگی ران"),hasReturn:txt.includes("اواخر نوامبر ۲۰۲۶"),hasUpdated:txt.includes("آبان ۱۴۰۵"),hasLabel:txt.includes("نوع آسیب")&&txt.includes("بازگشت پیش‌بینی‌شده"),rows}})())' 2>/dev/null
errs

echo "== 2) /player/737066 (Haaland, healthy → hidden) =="
$B open "http://localhost:3000/player/737066" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3
$B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,sec:!!document.querySelector("[data-testid=player-injury]")})' 2>/dev/null
errs

echo "== 3) /player/895362 (Rodrygo, ACL) =="
$B open "http://localhost:3000/player/895362" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3
$B eval 'JSON.stringify((()=>{const sec=document.querySelector("[data-testid=player-injury]");if(!sec)return {sec:false};const txt=sec.textContent||"";return {sec:true,hasName:txt.includes("پارگی رباط صلیبی"),hasReturn:txt.includes("اواخر دسامبر ۲۰۲۶"),hasUpdated:txt.includes("اسفند ۱۴۰۴")}})())' 2>/dev/null
errs

echo "== 4) /team/8564 (Milan squad «مصدوم» chips — ecosystem cross-ref) =="
$B open "http://localhost:3000/team/8564" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 3
$B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,injChips:[...document.querySelectorAll("span")].filter(s=>s.textContent.trim()==="مصدوم").length})' 2>/dev/null
errs
