#!/bin/bash
# Cycle-86 DOM proof at 390x844: the recent-matches island on the player page —
# full archive (68 Haaland / 70 Sinisalo) with side-filter chips (همه/club/ساختار
# ملی) + «نمایش همهٔ N بازی» toggle + per-row side chip in the همه view;
# contract-end chip carries the Jalali year («۹ تیر ۱۴۱۳»); single-team players
# (Rafiei) degrade to the plain list (no chips, no toggle). sw=cw, one h1,
# zero visible-broken images, console + app errors clean before every probe.
set -u
B=agent-browser

$B set viewport 390 844 >/dev/null

# --- Haaland 737066: chips + filter + toggle flow ---
$B errors --clear >/dev/null 2>&1
$B console --clear >/dev/null 2>&1
$B open "http://localhost:3000/player/737066" >/dev/null 2>&1
$B wait --load networkidle >/dev/null 2>&1
$B wait --fn "document.querySelector('[aria-label=بازی‌های اخیر]')" >/dev/null 2>&1
sleep 2
echo "== /player/737066 initial =="
$B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,chips:[...document.querySelectorAll("[data-testid=player-recent] button")].map(b=>b.textContent),rows:document.querySelectorAll("[data-testid=player-recent] a").length,toggle:([...document.querySelectorAll("[data-testid=player-recent] button")].map(b=>b.textContent).find(t=>/نمایش/.test(t||""))||""),contract:([...document.querySelectorAll("span")].find(s=>/پایان قرارداد/.test(s.textContent||""))||{}).textContent||""})'
C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print('console=', len(d['data']['messages']))
except Exception:
  print('console=READERR')")
E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  app=[e for e in es if e.get('url')]; cli=[e for e in es if not e.get('url')]
  print('errors: app-url=', len(app), 'cli-artifact-url-null=', len(cli))
except Exception:
  print('errors: READERR')")
echo "$C  $E  --"

echo "== click «نروژ» filter =="
$B eval '(() => { const b=[...document.querySelectorAll("[data-testid=player-recent] button")].find(x=>/نروژ/.test(x.textContent||"")); if(!b) return "no-norway-chip"; b.click(); return "clicked"; })()' >/dev/null 2>&1
sleep 0.8
$B eval 'JSON.stringify({rows:document.querySelectorAll("[data-testid=player-recent] a").length,sideChips:document.querySelectorAll("[data-testid=player-recent] a span.max-w-\\[64px\\]").length,toggle:([...document.querySelectorAll("[data-testid=player-recent] button")].map(b=>b.textContent).find(t=>/نمایش/.test(t||""))||"")})'
echo "--"

echo "== click «همه» then show-all =="
$B eval '(() => { const b=[...document.querySelectorAll("[data-testid=player-recent] button")].find(x=>/^همه/.test((x.textContent||"").trim())); if(!b) return "no-all-chip"; b.click(); return "clicked"; })()' >/dev/null 2>&1
sleep 0.8
$B eval '(() => { const t=[...document.querySelectorAll("[data-testid=player-recent] button")].find(x=>/نمایش همه/.test(x.textContent||"")); if(!t) return "no-toggle"; t.click(); return "clicked"; })()' >/dev/null 2>&1
sleep 0.8
$B eval 'JSON.stringify({rows:document.querySelectorAll("[data-testid=player-recent] a").length,sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,firstRowSide:(document.querySelector("[data-testid=player-recent] a span.max-w-\\[64px\\]")||{}).textContent||""})'
C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print('console=', len(d['data']['messages']))
except Exception:
  print('console=READERR')")
echo "$C  --"

probe() {
  $B errors --clear >/dev/null 2>&1
  $B console --clear >/dev/null 2>&1
  $B open "$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 1.8
  echo "== $1 =="
  $B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,recent:!!document.querySelector("[data-testid=player-recent]"),rows:document.querySelectorAll("[data-testid=player-recent] a").length,filterChips:document.querySelectorAll("[data-testid=player-recent] button").length})'
  C=$($B console --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); print('console=', len(d['data']['messages']))
except Exception:
  print('console=READERR')")
  E=$($B errors --json 2>/dev/null | python3 -c "import json,sys
try:
  d=json.load(sys.stdin); es=d['data']['errors']
  app=[e for e in es if e.get('url')]; cli=[e for e in es if not e.get('url')]
  print('errors: app-url=', len(app), 'cli-artifact-url-null=', len(cli))
except Exception:
  print('errors: READERR')")
  echo "$C  $E"
  echo "--"
}

probe "http://localhost:3000/player/1185782"
probe "http://localhost:3000/player/1543604"
probe "http://localhost:3000/"
