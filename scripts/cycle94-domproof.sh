#!/bin/bash
# cycle-94 DOM proof at 390x844 — the never-probed edge: HISTORICAL season
# through the UI season selector (cycle-55 control × cycle-90 xG × cycle-92
# boards, all on one page). Flow: /league/pl current baseline → select
# 2020/2021 → standings honest (City 86), xG first row ۶۸٫۹, stats-tab boards
# present with historical podium → select back to (فعلی) → current data
# (City 21, xG delta +۵.۶) restored. Every step: sw=cw=390, 1 h1, 0 broken
# imgs, console clean, appErr=0. Complements the API end-to-end check of the
# same pair (season=2020/2021 honest + current unpoisoned) done pre-fix.
set -u
B=agent-browser

$B set viewport 390 844 >/dev/null
snap() { # generic health snapshot
  $B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null
}
errs() {
  E=$($B errors --json 2>/dev/null | python3 -c 'import json,sys
try: print(len([e for e in json.load(sys.stdin)["data"]["errors"] if e.get("url")]))
except Exception: print("ERR")')
  C=$($B console 2>/dev/null | grep -ci error || true)
  echo "   appErr=$E consoleErr=$C"
}
pick_season() { # React-safe select change
  $B eval "(()=>{const sel=document.querySelector('#season-select');if(!sel)return 'no-select';const set=Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype,'value').set;set.call(sel,'$1');sel.dispatchEvent(new Event('change',{bubbles:true}));return 'picked:$1'})()" 2>/dev/null
}

$B errors --clear >/dev/null 2>&1
$B console --clear >/dev/null 2>&1
$B open "http://localhost:3000/league/pl" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
sleep 2
echo "== 1) current baseline =="
$B eval 'JSON.stringify({label:(document.querySelector("#season-select")||{}).value||"none",top1:(document.querySelector("[data-testid=standings-table] tbody tr, table tbody tr")||{textContent:"?"}).textContent.slice(0,60)})' 2>/dev/null
snap; errs

echo "== 2) select 2020/2021 =="
pick_season "2020/2021"
sleep 4
$B eval 'JSON.stringify((()=>{const sel=document.querySelector("#season-select");const rows=[...document.querySelectorAll("table tbody tr")];const xg=document.querySelector("[data-testid=league-xg]");const xg1=xg?xg.querySelectorAll("tbody tr")[0]:null;return {sel:sel?sel.value:"none",label:(document.body.innerText.match(/فصل ۲۰۲۰\/۲۰۲۱/)||[])[0]||"no-label",top1:(rows[0]||{textContent:"?"}).textContent.slice(0,70),has86:document.body.innerText.includes("۸۶"),xgFirst:(xg1||{textContent:"no-xg"}).textContent.slice(0,70)}})())' 2>/dev/null
snap; errs

echo "== 3) stats tab boards on historical season =="
$B eval '(()=>{const t=[...document.querySelectorAll("button")].find(b=>b.textContent.trim()==="آمار فصل");if(t)t.click();return t?"clicked":"no-tab"})()' >/dev/null 2>&1
sleep 2
$B eval 'JSON.stringify((()=>{const bd=document.querySelector("[data-testid=league-boards]");if(!bd)return {sec:false};const led=bd.querySelector(".glass-leader");return {sec:true,chips:[...bd.querySelectorAll("[aria-label=\"دستهٔ آماری\"] button")].length,podium1:(led||{}).textContent||"none"}})())' 2>/dev/null
snap; errs

echo "== 4) back to current (فعلی) =="
$B eval '(()=>{const t=[...document.querySelectorAll("button")].find(b=>b.textContent.trim()==="جدول");if(t)t.click();return t?"clicked":"no-tab"})()' >/dev/null 2>&1
sleep 1
pick_season "2026/2027"
sleep 4
$B eval 'JSON.stringify((()=>{const sel=document.querySelector("#season-select");const rows=[...document.querySelectorAll("table tbody tr")];const xg=document.querySelector("[data-testid=league-xg]");const xg1=xg?xg.querySelectorAll("tbody tr")[0]:null;return {sel:sel?sel.value:"none",label:(document.body.innerText.match(/فصل ۲۰۲۶\/۲۰۲۷/)||[])[0]||"no-label",top1:(rows[0]||{textContent:"?"}).textContent.slice(0,70),has21pts:!!document.body.innerText.match(/۲۱(?!پ)/),xgFirst:(xg1||{textContent:"no-xg"}).textContent.slice(0,70)}})())' 2>/dev/null
snap; errs
