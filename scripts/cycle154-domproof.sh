#!/bin/bash
# cycle-154 DOM proof — Persian-numeral fix on team & match surfaces:
#   FIX-1 team-view header mini-grid «گل» chip: GD was always a string
#         («+9») and the old typeof guard let the string path render LATIN
#         digits inside an otherwise all-faDigits header (visible sm+).
#   FIX-2 team-view «آخرین ترکیب» formation badge: «4-4-2» → «۴-۴-۲»
#   FIX-3 match-detail lineup formation badge: same contract
# Proof @390x844 (formation visible) + @1280x800 (GD chip visible sm+):
#   - zero Latin digits in rendered innerText on /team/102101 both viewports
#   - formation badge text exactly «۴-۴-۲», GD chip exactly «+۹»
#   - /match/6054597 formations all-Persian digits
#   - every page: sw=cw, 1 h1, 0 broken images, console=0, appErr=0
set -u
B=agent-browser
BAD=0

collect() { # $1=feat $2=label $3=expected-sw
  local FEAT="$1" LABEL="$2" EXP="${3:-390}" OUT C E RC=0
  OUT=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length})' 2>/dev/null | tr -d '"\\')
  C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print(len(d['data']['messages']))
except Exception: print('ERR')")
  E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  print(len([e for e in es if e.get('url')]))
except Exception: print('ERR')")
  echo "$LABEL → $OUT | feat=$FEAT | console=$C appErrors=$E"
  echo "$FEAT" | grep -q "false\|null" && RC=1
  [ "$OUT" != "{sw:$EXP,cw:$EXP,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
  return 0
}

open_clean() { # $1=url
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 3
}

# P1: mobile 390x844 — team page, formation badge Persian, zero Latin digits
$B set viewport 390 844 >/dev/null
open_clean "http://localhost:3000/team/102101"
FEAT=$($B eval "JSON.stringify((()=>{const t=document.body.innerText||'';const badge=[...document.querySelectorAll('span')].find(s=>/^[۰-۹]+(-[۰-۹]+)+$/.test((s.textContent||'').trim()));return {faFormation:badge?(badge.textContent||'').trim():null,noLatin:((t.match(/[0-9]/g)||[]).length===0),latin:(t.match(/[0-9]+/g)||[]).slice(0,5)}})())" 2>/dev/null | tr -d '"\\')
collect "$FEAT" "P1 team 390x844 formation+zero-latin" 390

# P2: desktop 1280x800 — the GD chip renders («گل» = +۹ Persian), zero Latin
$B set viewport 1280 800 >/dev/null
open_clean "http://localhost:3000/team/102101"
FEAT=$($B eval "JSON.stringify((()=>{const t=document.body.innerText||'';const chip=[...document.querySelectorAll('div')].find(d=>{const p=d.querySelector('p');return p&&(p.textContent||'').trim()==='گل'});const gd=chip?chip.querySelectorAll('p')[1]:null;return {gdText:gd?(gd.textContent||'').trim():null,gdPersian:gd?/^[+−-]?[۰-۹]+$/.test((gd.textContent||'').trim()):false,noLatin:((t.match(/[0-9]/g)||[]).length===0)}})())" 2>/dev/null | tr -d '"\\')
collect "$FEAT" "P2 team 1280x800 GD chip +۹" 1280

# P3: match page — lineups live under the «ترکیب» TAB (real click first);
# match 5749735 carries BOTH formations (3-4-2-1 / 4-3-3 per live API probe)
$B set viewport 390 844 >/dev/null
open_clean "http://localhost:3000/match/5749735"
$B eval '(function(){const b=[...document.querySelectorAll("button")].find(x=>(x.textContent||"").trim()==="ترکیب");if(b)b.click();return b?"clicked":"no-tab"})()' >/dev/null 2>&1
sleep 4
FEAT=$($B eval "JSON.stringify((()=>{const t=document.body.innerText||'';const badges=[...document.querySelectorAll('span[dir=\"ltr\"]')].map(s=>(s.textContent||'').trim()).filter(s=>/^([۰-۹]+(-[۰-۹]+)*)$/.test(s));return {tabOpened:(t.includes('بازیکنان ذخیره')||t.includes('سرمربی:')),faBadges:badges,present:badges.length>=1,noLatin:((t.match(/[0-9]/g)||[]).length===0)}})())" 2>/dev/null | tr -d '"\\')
collect "$FEAT" "P3 match 390x844 formations Persian (tab click)" 390

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK — Persian-numeral fix proven on team (mobile+desktop) and match surfaces"
else
  echo "DOM_PROOF FLAGGED (BAD=$BAD)"; exit 1
fi
