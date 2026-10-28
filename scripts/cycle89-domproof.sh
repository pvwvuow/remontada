#!/bin/bash
# Cycle-89 DOM/SSR proof: numeric-but-out-of-range ids no longer SSR-render
# h1-less skeletons. Raw HTML (curl, no JS) must contain exactly one <h1 on
# every error edge; hydrated DOM at 390x844 must keep sw=cw, h1n=1, zero
# broken images, clean console — and the REAL pages must be untouched.
set -u
B=agent-browser

echo "== SSR raw-HTML h1 audit (curl, no JS) =="
# Static error shells render fully at SSR → exactly one <h1 required.
# Real team/match pages are client-fetch views: SSR = skeleton (no h1 by
# design, pre-existing) — they are validated in the hydrated DOM audit below.
FAIL=0
for P in "team/99999999999999999999" "match/99999999999999999999" "team/abc" "match/abc" "team/0" "player/99999999999999999999"; do
  N=$(curl -s "http://localhost:3000/$P" | grep -o '<h1' | wc -l)
  C=$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:3000/$P")
  echo "  /$P → HTTP $C, SSR <h1> = $N"
  if [ "$N" -ne 1 ]; then FAIL=$((FAIL+1)); echo "    ⚠ expected exactly 1 SSR h1"; fi
done
# real pages: SSR must still contain the client skeleton (unchanged behavior)
for P in "team/9925" "match/5749720"; do
  N=$(curl -s "http://localhost:3000/$P" | grep -o '<h1' | wc -l)
  echo "  /$P → SSR <h1> = $N (client-fetch page: skeleton by design)"
done
echo "SSR_FAILS=$FAIL"

echo "== hydrated DOM audit at 390x844 =="
$B set viewport 390 844 >/dev/null
for P in "http://localhost:3000/team/99999999999999999999" "http://localhost:3000/match/99999999999999999999" "http://localhost:3000/team/abc" "http://localhost:3000/team/9925" "http://localhost:3000/match/5749720"; do
  $B errors --clear >/dev/null 2>&1
  $B console --clear >/dev/null 2>&1
  $B open "$P" >/dev/null 2>&1
  $B wait --load networkidle >/dev/null 2>&1
  sleep 1.5
  OUT=$($B eval 'JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length,h1t:(document.querySelector("h1")||{}).textContent})' 2>/dev/null)
  E=$($B errors --json 2>/dev/null | python3 -c 'import json,sys
try: print(len([e for e in json.load(sys.stdin)["data"]["errors"] if e.get("url")]))
except Exception: print("ERR")')
  echo "  $P → $OUT appErr=$E"
done
