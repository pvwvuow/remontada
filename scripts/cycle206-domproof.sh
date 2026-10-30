#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-206 update — «جزئیات بازیکن» on the match «بازیکن‌ها» tab.
#
# D5 probe first (live, 2026-10-30, UA Chrome/124): every content.
# playerStats entry carries a `stats` ARRAY — cycle-47 consumed ONLY
# the top_stats section (rating/minutes/goals/…). The survivors:
# attack / defense / duels — probed on three matches (Clásico 5868105:
# 28 of 30 players carry all three, GKs top_stats only; EFL Cup
# 6275369 + Serie A 5749723 confirm the same section keys), a fixed
# 27-label vocabulary, `fractionWithPercentage` rows carrying value/
# total pairs (0/1 dribbles, 1/4 ground duels). Zero usage in src/
# before this cycle (grep-verified).
#
# Update additive-only, ZERO fresh upstream calls (rides the one
# already-cached matchDetails fetch): /api/match/[id] PlayerStatRow
# gains an OPTIONAL `deep` array — every stats section beyond
# top_stats, generically mapped (a future Goalkeeping section rides
# the same path), rows labelFa-mapped over the full probed vocabulary
# (honest English fallback), valueless rows dropped (Was fouled null),
# pct rows keep value/total. UI: an expandable «جزئیات» panel under
# each player row — Persian section titles, value/total pairs in
# Persian digits, the raw English label preserved in title attr.
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API deep-stats contract =="
curl -s "$BASE/api/match/5868105" -o /tmp/c206_a1.json
A_OUT=""

A1=$(python3 - << 'PY'
import json
try:
    d = json.load(open('/tmp/c206_a1.json'))
    ps = d.get('playerStats') or {}
    rows = ps.get('home', []) + ps.get('away', [])
    deep_rows = [p for p in rows if p.get('deep')]
    if len(deep_rows) < 15:
        print(f'A1_FAIL deep-rows={len(deep_rows)}'); raise SystemExit
    # Raphinha (probed: attack=10, defense=7, duels=5 — by key, any player
    # with the same shape works; pin the STRUCTURE not the byte counts)
    r = next((p for p in rows if p.get('name') == 'Raphinha'), None)
    if not r or not r.get('deep'):
        print('A1_FAIL no-raphinha-deep'); raise SystemExit
    keys = {s['key'] for s in r['deep']}
    if keys != {'attack','defense','duels'}:
        print(f'A1_FAIL keys={keys}'); raise SystemExit
    atk = next(s for s in r['deep'] if s['key']=='attack')
    if atk['titleFa'] != 'حمله' or len(atk['rows']) < 8:
        print(f"A1_FAIL atk title/rows={atk['titleFa']}/{len(atk['rows'])}"); raise SystemExit
    fa_hit = any(rw['labelFa'] == 'لمس توپ' and rw['label'] == 'Touches' for rw in atk['rows'])
    pct_row = next((rw for rw in atk['rows'] if rw['pct']), None)
    if not fa_hit or not pct_row or pct_row.get('total') is None:
        print(f'A1_FAIL fa={fa_hit} pct={pct_row}'); raise SystemExit
    # every row numeric-sound: value or total present
    bad = [rw for s in r['deep'] for rw in s['rows'] if rw['value'] is None and rw['total'] is None]
    if bad:
        print(f'A1_FAIL valueless={len(bad)}'); raise SystemExit
    gks = [p for p in rows if p.get('isGk')]
    gk_deep = [p for p in gks if p.get('deep')]
    print(f"A1_OK deep={len(deep_rows)} pct={pct_row['value']}/{pct_row['total']} gk_deep={len(gk_deep)}/{len(gks)}")
except Exception as e:
    print('A1_FAIL', e)
PY
)
A_OUT="$A_OUT$A1
"
echo "$A1" | rg -q "A1_OK" || BAD=$((BAD+1))

# A2: a second probed match (EFL Cup) — universality of the same contract
curl -s "$BASE/api/match/6275369" -o /tmp/c206_a2.json
A2=$(python3 - << 'PY'
import json
try:
    d = json.load(open('/tmp/c206_a2.json'))
    ps = d.get('playerStats') or {}
    rows = ps.get('home', []) + ps.get('away', [])
    deep_rows = [p for p in rows if p.get('deep')]
    keys = {s['key'] for p in deep_rows for s in p['deep']}
    print(f"A2_OK deep={len(deep_rows)} keys={'+'.join(sorted(keys))}" if len(deep_rows) >= 14 and 'attack' in keys and 'defense' in keys and 'duels' in keys else 'A2_FAIL')
except Exception as e:
    print('A2_FAIL', e)
PY
)
A_OUT="$A_OUT$A2
"
echo "$A2" | rg -q "A2_OK" || BAD=$((BAD+1))

echo "$A_OUT"
echo "$A_OUT" | rg -q "A1_OK" && echo "$A_OUT" | rg -q "A2_OK" || BAD=$((BAD+1))

echo "== PART B: DOM proof @390x844 (agent-browser, console must stay 0) =="
B=agent-browser
$B set viewport 390 844 >/dev/null
CNT='import json,sys
try:
  d=json.load(sys.stdin); print(len(d["data"]["messages"]))
except Exception: print("ERR")'
ECNT='import json,sys
try:
  d=json.load(sys.stdin); es=d["data"]["errors"]
  print(len([e for e in es if e.get("url")]))
except Exception: print("ERR")'

open_page() {
  $B errors --clear >/dev/null 2>&1; $B console --clear >/dev/null 2>&1
  $B open "$BASE$1" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  $B wait --fn "document.body && document.body.innerText.length > 60" >/dev/null 2>&1
  sleep 2
}
snap() { $B eval "JSON.stringify({$1})" 2>/dev/null | tr -d '"\\'; }
clean_ls() { $B eval "localStorage.clear()" >/dev/null 2>&1; }
gate() {
  local label="$1" FEAT="$2" OUT C E RC=0
  OUT=$(snap 'sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length')
  C=$($B console --json 2>/dev/null | python3 -c "$CNT")
  E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
  [ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  echo "$label → $FEAT | $OUT | console=$C appErrors=$E rc=$RC"
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
}
open_players_tab() {
  $B eval '(function(){const bs=[...document.querySelectorAll("nav[aria-label=\"بخش‌های مسابقه\"] button")];const b=bs.find(x=>x.textContent.trim()==="بازیکن‌ها");if(b)b.click();return b?"tab":"no-tab"})()' >/dev/null 2>&1
  sleep 1
}

open_page "/match/5868105"
clean_ls
open_players_tab

# B1: the first «جزئیات» toggle expands the deep panel with Persian
# section titles (حمله first by upstream order) and populated rows
$B wait --fn "!!document.querySelector('[data-testid=player-deep-toggle]')" >/dev/null 2>&1
$B eval '(function(){const b=document.querySelector("[data-testid=player-deep-toggle]");b.click();return "opened"})()' >/dev/null 2>&1
sleep 0.6
B1=$(snap "panel:!!document.querySelector('[data-testid=player-deep]'),sections:[...document.querySelectorAll('[data-testid=player-deep] > div > p')].map(x=>x.textContent).join('|'),rows:document.querySelectorAll('[data-testid=player-deep] div.flex.items-center').length,expanded:document.querySelector('[data-testid=player-deep-toggle]')?document.querySelector('[data-testid=player-deep-toggle]').getAttribute('aria-expanded'):'none'")
echo "B1 $B1"
echo "$B1" | rg -q "panel:true" && echo "$B1" | rg -q "حمله" && echo "$B1" | rg -q "rows:[1-9][0-9]*" && echo "$B1" | rg -q "expanded:true" || { echo "B1 FAIL"; BAD=$((BAD+1)); }
gate "B1-gate" "deep panel expands with Persian sections"

# B2: the toggle closes AND reopens (idempotent, aria handover both ways)
$B eval '(function(){const b=document.querySelector("[data-testid=player-deep-toggle]");b.click();return "closed"})()' >/dev/null 2>&1
sleep 0.4
B2=$(snap "panel:!!document.querySelector('[data-testid=player-deep]'),expanded:document.querySelector('[data-testid=player-deep-toggle]')?document.querySelector('[data-testid=player-deep-toggle]').getAttribute('aria-expanded'):'none'")
$B eval '(function(){const b=document.querySelector("[data-testid=player-deep-toggle]");b.click();return "reopened"})()' >/dev/null 2>&1
sleep 0.4
B2b=$(snap "panel:!!document.querySelector('[data-testid=player-deep]'),expanded:document.querySelector('[data-testid=player-deep-toggle]')?document.querySelector('[data-testid=player-deep-toggle]').getAttribute('aria-expanded'):'none',faTouch:[...document.querySelectorAll('[data-testid=player-deep] span')].some(x=>x.textContent==='لمس توپ')")
echo "B2 $B2 / reopen $B2b"
echo "$B2" | rg -q "panel:false" && echo "$B2" | rg -q "expanded:false" && echo "$B2b" | rg -q "panel:true" && echo "$B2b" | rg -q "faTouch:true" || { echo "B2 FAIL"; BAD=$((BAD+1)); }
gate "B2-gate" "toggle closes and reopens — لمس توپ Persian row visible"

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "CYCLE206 DOMPROOF ALL GREEN"
else
  echo "CYCLE206 DOMPROOF FAILURES: $BAD"
  exit 1
fi
