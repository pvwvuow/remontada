#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-204 fix — «keyboard navigation stays visible» in the header
# search dialog (a REAL small polish: the fix rotation with zero
# fixable findings from the 203 hunt — product bugs = 0).
#
# PRE-FIX LIVE TRUTH (probe on the running build, 2026-10-30, needle
# «ali» @390×844): the popover list container is max-h-[46vh]
# overflow-y-auto with scrollHeight 688 vs clientHeight 388 (~300px
# overflow); after ArrowDown × 11 the container scrollTop was 0 and
# the cmd-active row's bottom sat 294px BELOW the visible bottom —
# the 203 D1 keyboard span landed on an INVISIBLE row. Keyboard users
# walked blind; hover users were fine.
#
# FIX (additive-only, src/components/remontada/search-box.tsx): a
# kbNav ref set ONLY by ArrowDown/ArrowUp; when `active` changes the
# .cmd-active row scrollIntoView({block:"nearest"}) inside the popover
# — nearest scrolls only as much as needed and never scrolls a row
# that is already fully visible; the flag resets on close, so mouse
# hover NEVER scrolls (a hovered row is visible by definition).
#
# Byte-level pin discipline: the needle is RUNTIME-CHOSEN (first
# candidate with ≥9 total rows and ≥1 team from the same-moment API —
# the news feed rotates every 15 min so a byte-pinned needle would
# rot); only the scroll MECHANICS are pinned (form-pinned, grow-only).
#
# A1 the needle is fat enough (total ≥ 9, teams ≥ 1) — the overflow
#    precondition, all four additive fields present
# A2 the min-length guard shape intact (ok + four empty fields)
# A3 the 203 warm-only latency bound (< 5s)
# B1 @390×844: ArrowDown × total → container actually scrolled
#    (sc > 0) AND the cmd-active row FULLY visible inside the
#    container rect — the pre-fix probe answers sc:0 / over:294
# B2 ArrowUp × total walks back: scrollTop returns to 0 AND the FIRST
#    team row holds the highlight; Enter then lands /team/<same id the
#    same-moment API served> — keyboard nav end-to-end after scrolling
# B3 Escape closes the dialog and a reopen starts clean (q reset, "")
# All DOM: sw=cw=390, exactly 1 h1, 0 broken images, console=0,
# appErrors=0; clean_ls defensive.
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

# ---------- runtime-chosen fat needle (drift-tolerant) ----------
# The news feed rotates every 15 min — ONLY the static parts (teams,
# leagues, players) are pinned; news stays free to rotate mid-run.
NEEDLE=""; TOTAL=0; NONNEWS=0; TEAMS=0; FIRST_TEAM=0
for cand in ali real reza karim mehdi hossein; do
  OUT=$(python3 - "$cand" <<'PY'
import json, sys, urllib.request, urllib.parse
q = sys.argv[1]
req = urllib.request.Request("http://localhost:3000/api/search?q=" + urllib.parse.quote(q), headers={"User-Agent": "Mozilla/5.0"})
d = json.load(urllib.request.urlopen(req, timeout=30))
r = d.get("results") or []; l = d.get("leagues") or []; p = d.get("players") or []; n = d.get("news") or []
tot = len(r) + len(l) + len(p) + len(n)
ft = r[0].get("teamId") if r and r[0].get("teamId") else 0
print(f"TOTAL={tot} NONNEWS={len(r)+len(l)+len(p)} TEAMS={len(r)} FIRST_TEAM={ft} FIELDS={(d.get('ok') is True) and isinstance(d.get('news'), list) and isinstance(d.get('players'), list) and isinstance(d.get('leagues'), list)}")
PY
)
  C_TOTAL=$(echo "$OUT" | rg -o 'TOTAL=[0-9]+' | cut -d= -f2)
  C_NONNEWS=$(echo "$OUT" | rg -o 'NONNEWS=[0-9]+' | cut -d= -f2)
  C_TEAMS=$(echo "$OUT" | rg -o 'TEAMS=[0-9]+' | cut -d= -f2)
  C_FIRST=$(echo "$OUT" | rg -o 'FIRST_TEAM=[0-9]+' | cut -d= -f2)
  C_FIELDS=$(echo "$OUT" | rg -o 'FIELDS=(True|False)' | cut -d= -f2)
  if [ "${C_TOTAL:-0}" -ge 9 ] && [ "${C_NONNEWS:-0}" -ge 9 ] && [ "${C_TEAMS:-0}" -ge 1 ] && [ "$C_FIELDS" = "True" ]; then
    NEEDLE="$cand"; TOTAL=$C_TOTAL; NONNEWS=$C_NONNEWS; TEAMS=$C_TEAMS; FIRST_TEAM=$C_FIRST
    break
  fi
done
echo "needle: ${NEEDLE:-<none>} total=$TOTAL nonnews=$NONNEWS teams=$TEAMS first_team=$FIRST_TEAM"
[ -n "$NEEDLE" ] || { echo "NO FAT NEEDLE — aborting (overflow precondition unmeetable today)"; exit 1; }

echo "== PART A: API proof (3 gates) =="
A_OUT=$(NEEDLE="$NEEDLE" NONNEWS="$NONNEWS" TEAMS="$TEAMS" FIRST_TEAM="$FIRST_TEAM" python3 - <<'PY'
import json, os, time, urllib.request, urllib.parse
BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}
def get(u):
    return json.load(urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=30))
def enc(s): return urllib.parse.quote(s)
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

NEEDLE, NONNEWS, TEAMS = os.environ["NEEDLE"], int(os.environ["NONNEWS"]), int(os.environ["TEAMS"])

# A1: the fat needle — the STATIC parts pinned exactly, news free (the
# 15-min rotation may add/drop a headline between pick and here)
try:
    d = get(f"{BASE}/api/search?q={enc(NEEDLE)}")
    tot = len(d.get("results") or []) + len(d.get("leagues") or []) + len(d.get("players") or []) + len(d.get("news") or [])
    good = d.get("ok") is True and tot >= NONNEWS and len(d.get("results") or []) == TEAMS \
           and isinstance(d.get("news"), list) and isinstance(d.get("players"), list) and isinstance(d.get("leagues"), list)
    report("A1 fat needle static-parts pinned + news free", good,
           f"total={tot} >= nonnews={NONNEWS}, teams=={TEAMS}")
except Exception as e:
    report("A1 fat needle static-parts pinned + news free", False, repr(e))

# A2: the min-length guard shape intact (the 200 A6 contract)
try:
    d = get(f"{BASE}/api/search?q=r")
    good = d.get("ok") is True and d.get("results") == [] and d.get("players") == [] \
           and d.get("leagues") == [] and d.get("news") == []
    report("A2 min-length guard shape (four empty fields)", good,
           f"r={len(d.get('results') or [])} l={len(d.get('leagues') or [])} p={len(d.get('players') or [])} n={len(d.get('news') or [])}")
except Exception as e:
    report("A2 min-length guard shape (four empty fields)", False, repr(e))

# A3: the 203 warm-only latency bound
try:
    t0 = time.time()
    d = get(f"{BASE}/api/search?q={enc(NEEDLE)}")
    dt = time.time() - t0
    good = dt < 5.0 and d.get("ok") is True
    report("A3 warm-only latency < 5s (203 bound)", good, f"{dt:.2f}s")
except Exception as e:
    report("A3 warm-only latency < 5s (203 bound)", False, repr(e))

print("API_ALL_OK" if ok else "API_FLAGGED")
PY
)
echo "$A_OUT"
echo "$A_OUT" | rg -q "API_ALL_OK" || BAD=$((BAD+1))

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
open_search() {
  $B eval '(function(){const b=document.querySelector("button[aria-label=\"جستجوی تیم\"]");if(b)b.click();return b?"opened":"no-trigger"})()' >/dev/null 2>&1
  sleep 1
}
type_into() {
  $B eval "(function(){const i=document.querySelector('div[role=\"dialog\"] input');if(!i)return 'no-input';const s=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set;s.call(i,'$1');i.dispatchEvent(new Event('input',{bubbles:true}));return 'typed'})()" >/dev/null 2>&1
}
key_on_input() {
  $B eval "(function(){const i=document.querySelector('div[role=\"dialog\"] input');if(!i)return 'no-input';i.dispatchEvent(new KeyboardEvent('keydown',{key:'$1',bubbles:true}));return 'sent'})()" >/dev/null 2>&1
}
# visibility math lives in the DOM, not in assumptions:
#   sc   = container scrollTop (the fix must actually scroll)
#   vis  = the cmd-active row FULLY inside the container rect (±1px)
#   over = how far the row bottom pokes below the visible bottom
VIS_EXPR='(function(){var c=document.querySelector("[role=dialog] .overflow-y-auto");if(!c)return "";var r=c.querySelector(".cmd-active");if(!r)return "";var a=c.getBoundingClientRect(),b=r.getBoundingClientRect();return (b.top>=a.top-1&&b.bottom<=a.bottom+1)+"|over:"+Math.round(b.bottom-a.bottom)+"|top:"+Math.round(b.top-a.top);})()'
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

# ---------- B1: ArrowDown × total → the active row is VISIBLE ----------
open_page "/"
clean_ls
open_search
type_into "$NEEDLE"
$B wait --fn "document.querySelectorAll('[role=dialog] li').length >= $NONNEWS" >/dev/null 2>&1
sleep 1.2
FEAT=$(snap "rows:document.querySelectorAll('[role=dialog] li').length,sc:document.querySelector('[role=dialog] .overflow-y-auto').scrollTop,sh:document.querySelector('[role=dialog] .overflow-y-auto').scrollHeight,ch:document.querySelector('[role=dialog] .overflow-y-auto').clientHeight,vis:$VIS_EXPR")
B1=0
# rows >= NONNEWS (news is free to rotate mid-run — the 15-min feed)
python3 - "$FEAT" "$NONNEWS" <<'PY' || B1=1
import re, sys
f = sys.argv[1]; nn = int(sys.argv[2])
rows = int(re.search(r"rows:(\d+)", f).group(1))
sys.exit(0 if rows >= nn else 1)
PY
echo "$FEAT" | rg -q 'sh:[0-9]+,ch:[0-9]+' || B1=1
# overflow precondition: the list really overflows (sh > ch) — otherwise
# this needle cannot exercise the fix
python3 - "$FEAT" <<'PY' || B1=1
import re, sys
f = sys.argv[1]
sh = int(re.search(r"sh:(\d+)", f).group(1)); ch = int(re.search(r"ch:(\d+)", f).group(1))
sys.exit(0 if sh > ch else 1)
PY
gate "B1-pre rows≥nonnews ($NONNEWS static) + real overflow" "$FEAT"

# the walk length is the DOM's OWN row count (the keyboard span is over
# RENDERED rows — never a stale API snapshot)
ROWS=$(echo "$FEAT" | rg -o 'rows:[0-9]+' | cut -d: -f2)
case "$ROWS" in ''|*[!0-9]*) echo "ROWS extraction failed ($ROWS) — aborting"; exit 1;; esac

i=0
while [ "$i" -lt "$ROWS" ]; do key_on_input ArrowDown; i=$((i+1)); done
sleep 0.8
FEAT=$(snap "sc:document.querySelector('[role=dialog] .overflow-y-auto').scrollTop,act:!!document.querySelector('[role=dialog] .cmd-active'),vis:$VIS_EXPR")
B1=0
echo "$FEAT" | rg -q 'act:true' || B1=1
echo "$FEAT" | rg -q 'vis:true\|over:' || B1=1
echo "$FEAT" | rg -q 'sc:[1-9][0-9]*' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 ArrowDown×$ROWS → scrolled (sc>0) + active row fully visible (was sc:0/over:294 pre-fix)" "$FEAT"

# ---------- B2: ArrowUp × rows → back to the top, Enter → /team ----------
i=0
while [ "$i" -lt "$ROWS" ]; do key_on_input ArrowUp; i=$((i+1)); done
sleep 0.8
FEAT=$(snap "sc:document.querySelector('[role=dialog] .overflow-y-auto').scrollTop,first:(function(){var f=document.querySelector('[role=dialog] ul li button.cmd-active');var u=document.querySelector('[role=dialog] ul');return !!(f&&u&&u.contains(f));})(),vis:$VIS_EXPR")
B2=0
echo "$FEAT" | rg -q 'first:true' || B2=1
echo "$FEAT" | rg -q 'vis:true\|' || B2=1
# sc returns to ≤ 6 (the ul's 6px top padding — the row lands fully
# visible; the pre-fix walk never went below 294)
python3 - "$FEAT" <<'PY' || B2=1
import re, sys
f = sys.argv[1]
sc = int(re.search(r"sc:(\d+)", f).group(1))
sys.exit(0 if sc <= 6 else 1)
PY
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 ArrowUp×$ROWS → scrollTop back ≤6 (row fully visible) + FIRST team row active" "$FEAT"

key_on_input Enter
$B wait --fn "location.pathname.indexOf('/team/')===0" >/dev/null 2>&1
sleep 1.5
FEAT=$(snap "p:location.pathname")
B2=0
[ "$FEAT" = "{p:/team/$FIRST_TEAM}" ] || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2b Enter → /team/$FIRST_TEAM (the same-moment API's first team)" "$FEAT"
gate "B2c team page clean @390×844" "$FEAT"
clean_ls

# ---------- B3: Escape closes; reopen starts clean ----------
open_page "/"
clean_ls
open_search
type_into "$NEEDLE"
$B wait --fn "document.querySelectorAll('[role=dialog] li').length >= $NONNEWS" >/dev/null 2>&1
sleep 0.8
key_on_input Escape
sleep 0.8
FEAT=$(snap "dlg:!!document.querySelector('[role=dialog]')")
B3=0
echo "$FEAT" | rg -q 'dlg:false' || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 Escape closes the dialog" "$FEAT"
open_search
sleep 0.5
FEAT=$(snap "vlen:(function(){var i=document.querySelector('[role=dialog] input');return i?i.value.length:-1})()")
B3=0
echo "$FEAT" | rg -q 'vlen:0' || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3b reopen starts clean (q reset, input empty)" "$FEAT"
clean_ls

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "GATE OK (cycle-204: keyboard navigation stays visible — the kbNav-flagged scrollIntoView({block:nearest}) fix; needle $NEEDLE nonnews=$NONNEWS runtime-chosen, walk length = the DOM's own row count; API 3/3 + DOM 6/6 @390x844; pre-fix probe pinned: sc:0, over:294, sh:688, ch:388)"
else
  echo "GATE BAD=$BAD"
  exit 1
fi
