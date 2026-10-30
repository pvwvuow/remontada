#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-187 update — attacking zones join the halves («نیمه‌به‌نیمه»)
#
# cycle-97 declared a v1 boundary in its own normalization comment:
# «TOTAL split only in v1 (firstHalf/secondHalf stay unrendered)».
# This cycle closes it — the same pattern cycle-186 applied to
# cycle-185's declared merge boundary. The per-half splits join the
# /api/match/[id] zones block as OPTIONAL keys appended AFTER the
# legacy triple {left,center,right}; the legacy shape stays
# byte-identical and pre-187 consumers are untouched.
#
# Honest per-period omission (the 176/186 contract family): a half key
# is emitted only when that half's shares sum > 0 upstream.
#
# Pinned live truth (probed 2026-10-30 ~01:5x UTC, UA Chrome/124,
# finished matches with full period coverage):
#   5749727 Sassuolo–Lazio (seriea)
#     home total {53,25,22} h1 {53,27,20} h2 {51,21,28}
#     away total {51,27,22} h1 {50,25,25} h2 {52,28,20}
#   5749721 Roma–Cagliari (seriea)
#     home total {40,22,38} h1 {39,21,40} h2 {41,22,37}
#     away total {38,40,22} h1 {37,41,22} h2 {40,39,21}
#   5868120 Villarreal (upcoming)     attackingZones ABSENT → zones null
#   5765944 Dinamo Zagreb (finished)  attackingZones ABSENT → zones null
#     (coverage is per-match — a finished match may honestly lack the
#     block; the stats tab hides it, no fake empty panel)
# DOM @390x844:
#   /match/5749727 stats tab → «جهت حملات» + «نیمهٔ اول» + «نیمهٔ دوم»
#     sub-rows (4 zone-half rows: 2 per side)
#   /match/5868120 (upcoming) → NO zones block, no fake panel
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API gates (6) =="
A_OUT=$(python3 - <<'PY'
import json, urllib.request
BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}
def get(u):
    req = urllib.request.Request(u, headers=UA)
    return json.load(urllib.request.urlopen(req, timeout=30))
ok = True
def report(name, good, detail):
    global ok
    ok = ok and bool(good)
    print(f"{name}: {detail} {'OK' if good else 'BAD'}")

def triples(t):
    return (t.get("left"), t.get("center"), t.get("right"))

# A1: Sassuolo–Lazio — the full per-half normalization, byte-pinned
d = get(BASE + "/api/match/5749727")
z = d.get("zones") or {}
h, a = z.get("home") or {}, z.get("away") or {}
good = (
    triples(h) == (53, 25, 22)
    and triples(h.get("firstHalf") or {}) == (53, 27, 20)
    and triples(h.get("secondHalf") or {}) == (51, 21, 28)
    and triples(a) == (51, 27, 22)
    and triples(a.get("firstHalf") or {}) == (50, 25, 25)
    and triples(a.get("secondHalf") or {}) == (52, 28, 20)
)
report("A1 5749727 halves pinned", good,
       f"home={triples(h)} h1={triples(h.get('firstHalf') or {})} h2={triples(h.get('secondHalf') or {})}")

# A2: Roma–Cagliari — second full sample
d = get(BASE + "/api/match/5749721")
z = d.get("zones") or {}
h, a = z.get("home") or {}, z.get("away") or {}
good = (
    triples(h) == (40, 22, 38)
    and triples(h.get("firstHalf") or {}) == (39, 21, 40)
    and triples(h.get("secondHalf") or {}) == (41, 22, 37)
    and triples(a) == (38, 40, 22)
    and triples(a.get("firstHalf") or {}) == (37, 41, 22)
    and triples(a.get("secondHalf") or {}) == (40, 39, 21)
)
report("A2 5749721 halves pinned", good,
       f"home={triples(h)} h1={triples(h.get('firstHalf') or {})} h2={triples(h.get('secondHalf') or {})}")

# A3: upcoming match — no fake zones, honest absence
d = get(BASE + "/api/match/5868120")
good = d.get("ok") is True and ("zones" not in d or d.get("zones") is None)
report("A3 upcoming 5868120 zones null", good, f"zones={d.get('zones')!r}")

# A4: finished WITHOUT coverage — honest absence, no empty panel data
d = get(BASE + "/api/match/5765944")
good = d.get("ok") is True and ("zones" not in d or d.get("zones") is None)
report("A4 no-coverage 5765944 zones null", good, f"zones={d.get('zones')!r}")

# A5: legacy key-order contract — first three keys of a side are EXACTLY
# left/center/right (byte-order preserved for pre-187 consumers); halves
# append only when present; every emitted half sums to 100 upstream
d = get(BASE + "/api/match/5749727")
z = d.get("zones") or {}
keys = list((z.get("home") or {}).keys())
half_keys = [k for k in keys if k in ("firstHalf", "secondHalf")]
sums_ok = all(
    sum(v for v in ((z.get("home") or {}).get(k) or {}).values()) == 100
    and sum(v for v in ((z.get("away") or {}).get(k) or {}).values()) == 100
    for k in half_keys
)
good = keys[:3] == ["left", "center", "right"] and half_keys == ["firstHalf", "secondHalf"] and sums_ok
report("A5 legacy key order + half sums", good, f"keys={keys} sums_ok={sums_ok}")

# A6: sibling surfaces untouched — the stats/lineups/events payload on the
# same match still carries its legacy blocks (no regression by the zones edit)
d = get(BASE + "/api/match/5749727")
sg = d.get("statGroups") or []
ev = d.get("events") or []
lu = d.get("lineups") or {}
good = d.get("ok") is True and len(sg) > 0 and len(ev) > 0 and bool(lu)
report("A6 siblings intact (stats/events/lineups)", good,
       f"statGroups={len(sg)} events={len(ev)} lineups={bool(lu)}")

print("API_ALL_OK" if ok else "API_BAD")
PY
) || BAD=$((BAD+1))
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
  sleep 2.5
}
snap() { $B eval "JSON.stringify({$1})" 2>/dev/null | tr -d '"\\'; }
# D5 test-isolation (the cycle-181/184 gate-side lesson): clear storage
# up-front and between gates so no leftover UI state leaks across mounts.
clean_ls() { $B eval "localStorage.clear()" >/dev/null 2>&1; }
gate() { # shared VGATES+console closer — $1=label $2=feat
  local label="$1" FEAT="$2" OUT C E RC=0
  OUT=$(snap 'sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth,h1n:document.querySelectorAll("h1").length,vbroken:[...document.images].filter(i=>i.complete&&i.naturalWidth===0&&getComputedStyle(i).visibility!=="hidden").length')
  C=$($B console --json 2>/dev/null | python3 -c "$CNT")
  E=$($B errors --json 2>/dev/null | python3 -c "$ECNT")
  [ "$OUT" != "{sw:390,cw:390,h1n:1,vbroken:0}" ] && RC=1
  [ "$C" = "0" ] && [ "$E" = "0" ] || RC=1
  echo "$label → $FEAT | $OUT | console=$C appErrors=$E rc=$RC"
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
}
click_stats_tab() {
  $B eval "[...document.querySelectorAll('nav[aria-label=\"بخش‌های مسابقه\"] button')].find(b => b.textContent.trim() === 'آمار')?.click()" >/dev/null 2>&1
  sleep 1.5
}

open_page "/"
clean_ls

# B1: Sassuolo–Lazio stats tab — the zones block renders WITH both half
# sub-rows for BOTH sides (4 zone-half rows); the match data arrives
# client-side, so wait for the block explicitly after clicking the tab
open_page "/match/5749727"
click_stats_tab
$B wait --fn "!!document.querySelector('[data-testid=\"match-zones\"]')" >/dev/null 2>&1
sleep 1.5
FEAT=$(snap 'zones:!!document.querySelector("[data-testid=\"match-zones\"]"),zh:document.body.innerText.includes("نیمهٔ اول"),zh2:document.body.innerText.includes("نیمهٔ دوم"),halves:document.querySelectorAll("[data-testid=\"zone-half\"]").length,hdr:document.body.innerText.includes("جهت حملات")')
B1=0
echo "$FEAT" | rg -q 'zones:true' || B1=1
echo "$FEAT" | rg -q 'zh:true' || B1=1
echo "$FEAT" | rg -q 'zh2:true' || B1=1
echo "$FEAT" | rg -q 'halves:4' || B1=1
echo "$FEAT" | rg -q 'hdr:true' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 finished match halves DOM" "$FEAT"
clean_ls

# B2: upcoming match — the zones block must be ABSENT (honest omission,
# no fake empty panel) while the page itself renders cleanly
open_page "/match/5868120"
click_stats_tab
sleep 1
FEAT=$(snap 'noZones:!document.querySelector("[data-testid=\"match-zones\"]"),page:document.body.innerText.length>60')
B2=0
echo "$FEAT" | rg -q 'noZones:true' || B2=1
echo "$FEAT" | rg -q 'page:true' || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 upcoming honest omission" "$FEAT"
clean_ls

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK — cycle-187 update proven (A 6/6 + B 2/2 @390x844)"
else
  echo "DOM_PROOF BAD=$BAD"
  exit 1
fi
