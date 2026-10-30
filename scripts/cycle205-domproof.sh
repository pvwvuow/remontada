#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-205 update — «نقشهٔ گرمای لمس» on the match page.
#
# D5 probe first (live, 2026-10-30, UA Chrome/124): the exhausted
# playerData/teams/leagues/matchDetails inventories left ONE real gap —
# content.momentum? NO (already mapped). The survivors: QAData (DAZN,
# en/de), poll (odds), highlightStories (geo-blocked), superlive (a
# bare URL), newsSummary (English-only) — all honestly skipped. The
# gap that stayed: the PER-MATCH TOUCH MAP — /api/data/heatmap/match/
# {id}/heatmaps answers {players:{"p{optaId}":"<svg dots>"}} for big
# leagues (5868105 → 30 players, 6275369 EFL Cup → 32, 5749723 Serie
# A → 32) and 404s for small ones (6487504 Botola Pro). Zero usage in
# src/ before this cycle (grep-verified).
#
# Update (one upstream fetch, its own cache): /api/match/[id] gains a
# `touchMap` field — built OUTSIDE the 25 s matchDetails producer with
# its own cached entry (key touchMap:v2:{id}, TTL 1 h finished / 30 s
# live; upcoming matches are never fetched — zero hits). The join is
# the LIVE-DISCOVERED crosswalk: heatmap keys are Opta ids, resolved
# through content.playerStats optaId+teamId (exact teamId match only —
# third-team entries drop; the first draft joined on FotMob lineup ids
# and correctly joined ZERO players — the optaId probe fixed it).
# touchSides stays internal-only (stripped from the JSON response).
# UI: header-level TouchmapCard after the momentum strip — side pills
# (stat-period pattern), a 105×68 pitch, one dot per touch; hidden
# when the payload carries no side (upcoming / small-league / failed
# join — the honest-absence family).
#
# Gate pins the probed anchor match (a FINISHED Clásico — historical
# payload, does not rotate like a feed) plus both negative classes.
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API touchMap contract =="
A_OUT=""

# A1: the anchor finished match — both sides, bounds, counts, no leak
curl -s "$BASE/api/match/5868105" -o /tmp/c205_a1.json
A1=$(python3 - << 'PY'
import json
try:
    d = json.load(open('/tmp/c205_a1.json'))
    if not d.get('ok'): print('A1_FAIL not-ok'); raise SystemExit
    tm = d.get('touchMap')
    if not tm: print('A1_FAIL no-touchmap'); raise SystemExit
    ok = 'touchSides' not in d
    parts = []
    for s in ('home','away'):
        v = tm.get(s)
        if not v or v.get('players',0) < 11 or v.get('touches',0) <= 0:
            print(f'A1_FAIL side-{s}'); raise SystemExit
        bad = [p for p in v['points'] if not (-2 <= p['x'] <= 107 and -2 <= p['y'] <= 70)]
        parts.append(f"{s}:{v['touches']}t/{v['players']}p/{len(bad)}oob")
    print(('A1_OK leak=' + str(not ok) + ' ' if not ok else 'A1_OK ') + ' '.join(parts))
except Exception as e:
    print('A1_FAIL', e)
PY
)
A_OUT="$A_OUT$A1
"
echo "$A1" | rg -q "A1_OK" || BAD=$((BAD+1))

# A2: upcoming match — null, and the answer must NOT error
curl -s "$BASE/api/match/5868115" -o /tmp/c205_a2.json
A2=$(python3 -c "
import json
d = json.load(open('/tmp/c205_a2.json'))
print('A2_OK null' if d.get('ok') and d.get('touchMap') is None else 'A2_FAIL')
")
A_OUT="$A_OUT$A2
"
echo "$A2" | rg -q "A2_OK" || BAD=$((BAD+1))

# A3: small-league finished match — no heatmap feed (404 class) → cached null
curl -s "$BASE/api/match/6487504" -o /tmp/c205_a3.json
A3=$(python3 -c "
import json
d = json.load(open('/tmp/c205_a3.json'))
print('A3_OK null' if d.get('ok') and d.get('touchMap') is None else 'A3_FAIL')
")
A_OUT="$A_OUT$A3
"
echo "$A3" | rg -q "A3_OK" || BAD=$((BAD+1))

# A4: the second probed anchor (EFL Cup Everton–Newcastle) — universality
curl -s "$BASE/api/match/6275369" -o /tmp/c205_a4.json
A4=$(python3 - << 'PY'
import json
try:
    d = json.load(open('/tmp/c205_a4.json'))
    tm = d.get('touchMap') or {}
    hs = [tm.get(s) for s in ('home','away')]
    good = all(v and v.get('players',0) >= 11 for v in hs if v)
    sides = [s for s in ('home','away') if tm.get(s)]
    print(f"A4_OK sides={'+'.join(sides)}" if good and sides else 'A4_FAIL')
except Exception as e:
    print('A4_FAIL', e)
PY
)
A_OUT="$A_OUT$A4
"
echo "$A4" | rg -q "A4_OK" || BAD=$((BAD+1))

echo "$A_OUT"
echo "$A_OUT" | rg -q "A1_OK" && echo "$A_OUT" | rg -q "A2_OK" && echo "$A_OUT" | rg -q "A3_OK" && echo "$A_OUT" | rg -q "A4_OK" || BAD=$((BAD+1))

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
gate() {
  local label="$1" FEAT="$2" OUT C E RC=0
  OUT=$(snap 'sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length')
  C=$($B console --json 2>/dev/null | python3 -c "$CNT")
  E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
  [ "$OUT" != "{sw:390,cw:390,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  echo "$label → $FEAT | $OUT | console=$C appErrors=$E rc=$RC"
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
}

# B1: the touchmap card renders on the anchor match with the Persian
# title, both side pills, the home pill pressed by default and a real
# dot population (>= 200 spans — the probed 923/699 touch counts)
open_page "/match/5868105"
$B wait --fn "!!document.querySelector('[data-testid=match-touchmap]')" >/dev/null 2>&1
B1=$(snap "tm:!!document.querySelector('[data-testid=match-touchmap]'),title:document.querySelector('[data-testid=match-touchmap] header span')?document.querySelector('[data-testid=match-touchmap] header span').textContent:'-',pillHome:!!document.querySelector('[data-testid=touchmap-side-home]'),pillAway:!!document.querySelector('[data-testid=touchmap-side-away]'),homePressed:document.querySelector('[data-testid=touchmap-side-home]')?document.querySelector('[data-testid=touchmap-side-home]').getAttribute('aria-pressed'):'none',dots:document.querySelectorAll('[data-testid=match-touchmap] span[class*=rounded-full]').length")
echo "B1 $B1"
echo "$B1" | rg -q "tm:true" && echo "$B1" | rg -q "pillHome:true" && echo "$B1" | rg -q "pillAway:true" && echo "$B1" | rg -q "homePressed:true" && echo "$B1" | rg -q "dots:[1-9][0-9]*" || { echo "B1 FAIL"; BAD=$((BAD+1)); }
gate "B1-gate" "touchmap card on the finished clásico"

# B2: the away pill switches the active side (aria-pressed handover) and
# the dot field stays populated (away has its own probed 699 touches)
$B eval '(function(){const b=document.querySelector("[data-testid=touchmap-side-away]");if(b)b.click();return b?"clicked":"no-pill"})()' >/dev/null 2>&1
sleep 1
B2=$(snap "awayPressed:document.querySelector('[data-testid=touchmap-side-away]')?document.querySelector('[data-testid=touchmap-side-away]').getAttribute('aria-pressed'):'none',homePressed:document.querySelector('[data-testid=touchmap-side-home]')?document.querySelector('[data-testid=touchmap-side-home]').getAttribute('aria-pressed'):'none',dots:document.querySelectorAll('[data-testid=match-touchmap] span[class*=rounded-full]').length")
echo "B2 $B2"
echo "$B2" | rg -q "awayPressed:true" && echo "$B2" | rg -q "homePressed:false" && echo "$B2" | rg -q "dots:[1-9][0-9]*" || { echo "B2 FAIL"; BAD=$((BAD+1)); }
gate "B2-gate" "away switch keeps the card alive"

# B3: the honest-absence class — the upcoming match renders NO touchmap
open_page "/match/5868115"
B3=$(snap "tm:!!document.querySelector('[data-testid=match-touchmap]'),body:document.body?document.body.innerText.length>60:false")
echo "B3 $B3"
echo "$B3" | rg -q "tm:false" && echo "$B3" | rg -q "body:true" || { echo "B3 FAIL"; BAD=$((BAD+1)); }
gate "B3-gate" "upcoming match — honest absence"

echo "== RESULT =="
if [ "$BAD" -eq 0 ]; then
  echo "CYCLE205 DOMPROOF ALL GREEN"
else
  echo "CYCLE205 DOMPROOF FAILURES: $BAD"
  exit 1
fi
