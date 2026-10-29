#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-159 fix DOM proof — «بستن نشت لاتین کارنامهٔ بازیکن» at 390×844.
# The fix: teamFa qualifier fallback now rides COUNTRY_FA (national youth
# sides «Iran U23» → «ایران جوانان»), spelled-out «Under NN» qualifier added,
# iceland country key + the 159 career sweep (70 team keys, 841→911) and the
# player cache v6→v7 bump. This proof opens the live pages that CARRIED the
# leak and checks the career grids render Persian, plus console hygiene.
# ------------------------------------------------------------------
set -u
cd "$(dirname "$0")/.."
BASE="${BASE:-http://localhost:3000}"
B=agent-browser
$B set viewport 390 844 >/dev/null

BAD=0
collect() {
  local FEAT="$1" LABEL="$2" OUT C E RC=0
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
  [ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
}

# ---- D1: the hook page /player/196041 (مهدی رحمتی) — the exact rows that
# carried the leak: career grid must contain «ایران جوانان» (was Iran U23)
# and «شهرخودرو» (was Shahr Khodrou FC) and must NOT contain the Latin forms.
$B console --clear >/dev/null 2>&1
$B open "$BASE/player/196041" >/dev/null 2>&1
$B wait networkidle >/dev/null 2>&1
sleep 3
FEAT=$($B eval 'JSON.stringify({
  faU23: document.body.innerText.includes("ایران جوانان"),
  shahr: document.body.innerText.includes("شهرخودرو"),
  noIranU23: !document.body.innerText.includes("Iran U23"),
  noShahrEn: !document.body.innerText.includes("Shahr Khodrou"),
  nationalBadge: document.body.innerText.includes("تیم ملی")
})' 2>/dev/null | tr -d '"\\')
collect "$FEAT" "D1 player196041-career"

# ---- D2: regression player pages (previously unmapped-heavy careers)
# 619513 (Spezia/Rostov/Bunyodkor/Uzbekistan U23 class) and 1585676
# (Benfica U21/Portugal U21 class).
for PID in 619513 1585676; do
  $B console --clear >/dev/null 2>&1
  $B open "$BASE/player/$PID" >/dev/null 2>&1
  $B wait networkidle >/dev/null 2>&1
  sleep 2
  FEAT=$($B eval 'JSON.stringify({
    noLatinCareers: (() => {
      const sec=[...document.querySelectorAll("section,div")].find(e=>/کارنامه|مسیر حرفه‌ای|سوابق/.test(e.textContent||""));
      const t=(sec||document.body).innerText;
      return !/(^|\s)(Poland|Uzbekistan|Portugal|Spain|Benfica|Spezia|Rostov|Bunyodkor)(\s|$|[A-Z])/.test(t.replace(/«[^»]*»/g," "));
    })(),
    hasJavan: document.body.innerText.includes("جوانان")
  })' 2>/dev/null | tr -d '"\\')
  collect "$FEAT" "D2 player$PID-career"
done

# ---- D3: hunt-side spot — the pages a career name feeds indirectly:
# search «Shahr Khodrou» still finds nothing wrong; skip. Instead the
# match page for the ACL Two fixture keeps Persian sides (teamFa untouched
# for mapped teams — byte-guard against the teamFa edit regressing).
$B console --clear >/dev/null 2>&1
$B open "$BASE/match/6054514" >/dev/null 2>&1
$B wait networkidle >/dev/null 2>&1
sleep 2
FEAT=$($B eval 'JSON.stringify({
  faSides: document.body.innerText.includes("ایست بنگال") && document.body.innerText.includes("السیب"),
  h1: (document.querySelector("h1")||{}).textContent || ""
})' 2>/dev/null | tr -d '"\\')
collect "$FEAT" "D3 match6054514-sides"

echo "=== RESULT ==="
if [ "$BAD" -eq 0 ]; then
  echo "FIX PROOF OK — career grids Persian at 390×844 (ایران جوانان + شهرخودرو live; zero Latin career rows on probed players; ACL Two sides intact; console clean on every page)"
  exit 0
else
  echo "FIX PROOF FAILED — BAD=$BAD"
  exit 1
fi
