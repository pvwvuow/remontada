#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-191 update — the post-match review feed («گزارش‌های بازی»)
#
# The 190 card declared the task's remaining-gaps list (انتخابگر فصل /
# براکت جام‌ها / انتقال‌ها) fully covered since 55/99/180/182, 56, 57.
# D5 live probe (UA Chrome/124, 2026-10-30) found the REAL remaining
# gap: matchFacts.postReview — Opta's post-match articles — carried by
# upstream and normalized by NO cycle before:
#   5749721 (Roma–Cagliari, finished)  → 1 entry (en)
#   5749727 (Sassuolo–Lazio, finished) → 8 entries = ONE article in 8
#     languages (ids carry "_lang" suffixes: _es, _pt-BR, _fr, _it,
#     _de, _ar, _pt — the base id repeats)
#   5765944 (finished)                 → 0 entries (honest absence)
#   5868120 (upcoming)                 → 0 entries (honest absence)
#
# Change (additive-only, the exact 125 highlights-card pattern): the
# match route gains an optional `reviews` array — entries group by the
# base id, the "en" entry wins its group, ≤3 articles, strict guards
# (title + https://www.fotmob.com/news/ shareUrl required; image
# guarded separately → "" degrades to a text row). UI: a header-level
# ReviewsCard right after the highlights card — each row links to the
# FotMob news article in a new tab; the image rides the site-wide
# onError-hide pattern (vbroken=0 invariant). Match cache TTL is 25s —
# no namespace bump needed (the 187/190 precedent).
#
# Pinned live truth (probed 2026-10-30, official start after the
# cycle-191 build):
#   /api/match/5749721  reviews n=1: title "Roma 4-2 Cagliari: Mora
#     inspires victory as hosts leave it late again", source Opta,
#     url ^https://www.fotmob.com/news/g93sxl53vrbt17cur8xphbyb5-,
#     image ^https://images.performgroup.com/, date 2026-10-27,
#     description non-empty (Stadio Olimpico)
#   /api/match/5749727  reviews n=1 (DxED from 8): title "Sassuolo
#     2-6 Lazio: Gattuso's men run riot to go top of Seri...", url
#     ^https://www.fotmob.com/news/hvmev0vtnpd51lyyud6cbhf2g-
#   row shape parity: [date, description, image, source, title, url]
# DOM @390x844:
#   /match/5749721 → [data-testid="match-reviews"] + «گزارش‌های بازی»
#     + the news link + the "Mora inspires" needle
#   /match/5749727 → exactly ONE news row (the dedupe proof) + the en
#     needle "run riot" + NO Arabic variant («ساسولو»)
#   /match/5765944 → NO match-reviews (finished, honest absence)
#   /match/5868120 → NO match-reviews (upcoming, honest absence)
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API proof (6 gates) =="
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

ROWKEYS = ["date", "description", "image", "source", "title", "url"]
TITLES = ["آمار کلیدی", "شوت\u200cها", "گل\u200Cهای مورد انتظار", "پاس\u200Cها", "دفاع", "دوئل\u200Cها", "انضباطی"]

def reviews_ok(r):
    return (isinstance(r, list) and len(r) >= 1
            and all(isinstance(x, dict) for x in r)
            and all(sorted(x.keys()) == ROWKEYS for x in r))

# A1: 5749721 — the single-en-entry pin (Roma–Cagliari)
try:
    d = get(BASE + "/api/match/5749721")
    r = d.get("reviews")
    r0 = (r or [{}])[0]
    good = reviews_ok(r) and len(r) == 1 \
        and r0["title"].startswith("Roma 4-2 Cagliari: Mora inspires") \
        and r0["url"].startswith("https://www.fotmob.com/news/g93sxl53vrbt17cur8xphbyb5-") \
        and r0["source"] == "Opta" \
        and r0["image"].startswith("https://images.performgroup.com/") \
        and r0["description"].strip() != "" \
        and (r0.get("date") or "").startswith("2026-10-27")
    report("A1 5749721 single review pinned", good,
           f"n={len(r) if r else 0} title={r0.get('title','')[:45]!r} src={r0.get('source')} date={r0.get('date')}")
except Exception as e:
    report("A1 5749721 single review pinned", False, repr(e))

# A2: 5749727 — THE DEDUPE GATE: 8 upstream language entries → 1 en row
try:
    d = get(BASE + "/api/match/5749727")
    r = d.get("reviews")
    r0 = (r or [{}])[0]
    good = reviews_ok(r) and len(r) == 1 \
        and r0["title"].startswith("Sassuolo 2-6 Lazio: Gattuso") \
        and r0["url"].startswith("https://www.fotmob.com/news/hvmev0vtnpd51lyyud6cbhf2g-") \
        and r0["source"] == "Opta"
    report("A2 5749727 deduped 8→1 (en wins)", good,
           f"n={len(r) if r else 0} title={r0.get('title','')[:45]!r}")
except Exception as e:
    report("A2 5749727 deduped 8→1 (en wins)", False, repr(e))

# A3: row shape parity on both pins
try:
    a = get(BASE + "/api/match/5749721").get("reviews") or [{}]
    b = get(BASE + "/api/match/5749727").get("reviews") or [{}]
    ka, kb = sorted(a[0].keys()), sorted(b[0].keys())
    good = ka == kb == ROWKEYS
    report("A3 row shape parity", good, f"roma={ka} sassuolo={kb}")
except Exception as e:
    report("A3 row shape parity", False, repr(e))

# A4: 5765944 — finished yet NO postReview upstream → honest absence
try:
    d = get(BASE + "/api/match/5765944")
    good = d.get("reviews") is None
    report("A4 finished-no-review honest absence", good, f"reviews={d.get('reviews')}")
except Exception as e:
    report("A4 finished-no-review honest absence", False, repr(e))

# A5: 5868120 — upcoming → honest absence
try:
    d = get(BASE + "/api/match/5868120")
    good = d.get("reviews") is None
    report("A5 upcoming honest absence", good, f"reviews={d.get('reviews')}")
except Exception as e:
    report("A5 upcoming honest absence", False, repr(e))

# A6: the 190 stat-table sister surface intact on the same payload
try:
    d = get(BASE + "/api/match/5749727")
    sg = d.get("statGroups") or []
    r0 = sg[0]["rows"][0]
    good = len(sg) == 7 and [g["title"] for g in sg] == TITLES \
        and r0.get("title") == "مالکیت توپ" and r0.get("home") == "42" and r0.get("away") == "58"
    report("A6 190 statGroups parity (42/58)", good,
           f"groups={len(sg)} r0={r0.get('home')}/{r0.get('away')}")
except Exception as e:
    report("A6 190 statGroups parity (42/58)", False, repr(e))

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
  sleep 2.5
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

open_page "/"
clean_ls

# B1: /match/5749721 — the reviews card renders: testid + label + a real
# fotmob news link + the en title needle
open_page "/match/5749721"
sleep 1
FEAT=$(snap 'card:!!document.querySelector("[data-testid=\"match-reviews\"]"),label:document.body.innerText.includes("گزارش\u200cهای بازی"),link:!!document.querySelector("[data-testid=\"match-reviews\"] a[href^=\"https://www.fotmob.com/news/\"]"),needle:document.body.innerText.includes("Mora inspires")')
B1=0
echo "$FEAT" | rg -q 'card:true' || B1=1
echo "$FEAT" | rg -q 'label:true' || B1=1
echo "$FEAT" | rg -q 'link:true' || B1=1
echo "$FEAT" | rg -q 'needle:true' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 5749721 reviews card" "$FEAT"
clean_ls

# B2: /match/5749727 — the dedupe proof in DOM: exactly ONE news row, the
# en needle, and NO Arabic variant («ساسولو») anywhere in the card
open_page "/match/5749727"
sleep 1
FEAT=$(snap 'rows:document.querySelectorAll("[data-testid=\"match-reviews\"] a[href^=\"https://www.fotmob.com/news/\"]").length,enNeedle:document.body.innerText.includes("run riot"),noAr:![...document.querySelectorAll("[data-testid=\"match-reviews\"] a span")].some(s=>s.textContent.includes("ساسولو"))')
B2=0
echo "$FEAT" | rg -q 'rows:1' || B2=1
echo "$FEAT" | rg -q 'enNeedle:true' || B2=1
echo "$FEAT" | rg -q 'noAr:true' || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 5749727 dedupe (1 row, en, no ar)" "$FEAT"
clean_ls

# B3: /match/5765944 — finished, no upstream review → the block honest-hides
open_page "/match/5765944"
sleep 1
FEAT=$(snap 'noCard:!document.querySelector("[data-testid=\"match-reviews\"]")')
B3=0
echo "$FEAT" | rg -q 'noCard:true' || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 5765944 honest absence" "$FEAT"
clean_ls

# B4: /match/5868120 — upcoming → the block honest-hides
open_page "/match/5868120"
sleep 1
FEAT=$(snap 'noCard:!document.querySelector("[data-testid=\"match-reviews\"]")')
B4=0
echo "$FEAT" | rg -q 'noCard:true' || B4=1
[ "$B4" -eq 0 ] || BAD=$((BAD+1))
gate "B4 5868120 upcoming honest absence" "$FEAT"
clean_ls

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK — cycle-191 update proven (A 6/6 + B 4/4 @390x844)"
else
  echo "DOM_PROOF BAD=$BAD"
  exit 1
fi
