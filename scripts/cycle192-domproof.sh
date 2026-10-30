#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-192 update — «برترین‌های بازی» (the top-5 rated players per side)
#
# The 191 card flagged statSeasons as the deep candidate; the D5 probe
# (UA Chrome/124, 2026-10-30) found it ABSENT on the probed feeds —
# honestly set aside. The rescan of content.* found TWO real orphans:
#   content.table          → only a POINTER to a data.fotmob.com XML
#                            blob (tables.ext.55.fot.gz, 987 bytes gz /
#                            3137 bytes XML `<table name="Serie A"...>`)
#                            — new host + new format: honestly set aside
#                            for a later cycle (bytes recorded).
#   matchFacts.topPlayers  → THE GAP. Rides the payload we already
#     fetch (zero extra upstream calls). Pinned live:
#     5749721 (Roma–Cagliari, finished) → 5+5 rows
#       home[0]: Emanuele Lulli 1800491, rating "8.7", motm=true,  pos RM
#       away[0]: Adam Obert   1289961, rating "8.1", motm=false, pos LM
#     5765944 (finished) → 5+5 rows
#       home[0]: Luka Stojković 1358149, rating "9.2", motm=true, pos AM
#       away[0]: Anel Husic     1258242, rating "7.9", motm=false, pos CB
#     5868120 (upcoming) → EMPTY arrays → normalized null (honest absence)
#
# Change (additive-only, the exact 191 reviews pattern): /api/match/[id]
# gains an optional topPlayers {home, away} — a row needs playerId > 0
# (the 167 convention), a non-empty fullName and a non-empty
# playerRatingRounded; cap 5 per side; nameFa rides playerFa at normalize
# time (match TTL 25s — always fresh); the block is null when both sides
# end up empty. UI: a header-level TopPlayersCard right after the reviews
# card (belongs to the MATCH, not a tab — the 191 placement philosophy):
# two columns (home first = right in RTL), each row = rating pill
# (faDigits) + name linking to /player/[id] (the 172 family) + position
# label; the man-of-the-match row carries the ★ badge (the PotmCard
# star language); an empty side shows an honest «در دسترس نیست».
#
# Pinned truth on the cycle-192 build (official start pid fresh):
#   /api/match/5749721 topPlayers home n=5 away n=5 (pins above)
#   /api/match/5765944 topPlayers home n=5 away n=5 (pins above)
#   /api/match/5868120 topPlayers = null (upcoming, honest)
#   row shape: [id, motm, name, nameFa, pos, rating]
# DOM @390x844:
#   /match/5749721 → [data-testid="match-top-players"] + «برترین‌های بازی»
#     + 10 rows + the Lulli needle + the «۸.۷» rating + the ★ on the
#     Lulli row + 10 /player/ links
#   /match/5765944 → the card + the Stojković needle (width proof)
#   /match/5868120 → NO match-top-players (upcoming, honest absence)
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API proof (6 gates) =="
A_OUT=$(python3 - <<'PY'
import json, re, urllib.request
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

ROWKEYS = ["id", "motm", "name", "nameFa", "pos", "rating"]
TITLES = ["آمار کلیدی", "شوت\u200cها", "گل\u200Cهای مورد انتظار", "پاس\u200Cها", "دفاع", "دوئل\u200Cها", "انضباطی"]

def rows_ok(rows):
    return (isinstance(rows, list) and len(rows) == 5
            and all(sorted(r.keys()) == ROWKEYS for r in rows)
            and all(isinstance(r["id"], int) and r["id"] > 0 for r in rows)
            and all(isinstance(r["rating"], str) and r["rating"].strip() for r in rows)
            and all(isinstance(r["motm"], bool) for r in rows))

# A1: 5749721 — the primary pin (Roma–Cagliari)
try:
    d = get(BASE + "/api/match/5749721")
    tp = d.get("topPlayers")
    h, a = (tp or {}).get("home") or [], (tp or {}).get("away") or []
    h0 = h[0] if h else {}
    a0 = a[0] if a else {}
    good = rows_ok(h) and rows_ok(a) \
        and h0["id"] == 1800491 and h0["name"] == "Emanuele Lulli" \
        and h0["rating"] == "8.7" and h0["motm"] is True and h0["pos"] == "RM" \
        and a0["id"] == 1289961 and a0["name"] == "Adam Obert" \
        and a0["rating"] == "8.1" and a0["motm"] is False and a0["pos"] == "LM"
    report("A1 5749721 topPlayers pinned 5+5", good,
           f"h0={h0.get('name')}/{h0.get('rating')}/motm={h0.get('motm')}/{h0.get('pos')} "
           f"a0={a0.get('name')}/{a0.get('rating')}")
except Exception as e:
    report("A1 5749721 topPlayers pinned 5+5", False, repr(e))

# A2: row shape + the honest-identity contract — nameFa is always
# non-empty; nameFa != name ONLY for curated PLAYER_NAME_FA hits (the
# Persian must be Arabic-script, never garbage); the Latin name stays
# upstream. Live truth on 5749721: 4/10 mapped (Soulé/Pisilli/Molina/
# Maldini — the 104 map reaching a NEW surface), 6/10 honest Latin
# fallback (Lulli/Gollini/Obert/Nzola/Fadera/Deiola).
try:
    d = get(BASE + "/api/match/5749721")
    tp = d["topPlayers"]
    allr = tp["home"] + tp["away"]
    fa_re = re.compile(r"[\u0600-\u06FF]")
    mapped = [r for r in allr if r["nameFa"] != r["name"]]
    good = all(sorted(r.keys()) == ROWKEYS for r in allr) \
        and all(r["nameFa"].strip() for r in allr) \
        and all(fa_re.search(r["nameFa"]) for r in mapped) \
        and all(r["nameFa"] == r["name"] for r in allr if r not in mapped) \
        and len(mapped) == 4
    report("A2 row shape + honest nameFa contract", good,
           f"keys={sorted(allr[0].keys())} mapped={len(mapped)}/10 fa={[r['nameFa'] for r in mapped]}")
except Exception as e:
    report("A2 row shape + honest nameFa contract", False, repr(e))

# A3: 5765944 — the SECOND positive pin (width beyond one match)
try:
    d = get(BASE + "/api/match/5765944")
    tp = d.get("topPlayers")
    h, a = (tp or {}).get("home") or [], (tp or {}).get("away") or []
    h0, a0 = (h[0] if h else {}), (a[0] if a else {})
    good = rows_ok(h) and rows_ok(a) \
        and h0["id"] == 1358149 and h0["name"] == "Luka Stojković" \
        and h0["rating"] == "9.2" and h0["motm"] is True and h0["pos"] == "AM" \
        and a0["id"] == 1258242 and a0["name"] == "Anel Husic" \
        and a0["rating"] == "7.9" and a0["pos"] == "CB"
    report("A3 5765944 second pin 5+5", good,
           f"h0={h0.get('name')}/{h0.get('rating')} a0={a0.get('name')}/{a0.get('rating')}")
except Exception as e:
    report("A3 5765944 second pin 5+5", False, repr(e))

# A4: 5868120 — upcoming, upstream arrays EMPTY → normalized null (honest)
try:
    d = get(BASE + "/api/match/5868120")
    good = d.get("topPlayers") is None
    report("A4 upcoming honest absence", good, f"topPlayers={d.get('topPlayers')}")
except Exception as e:
    report("A4 upcoming honest absence", False, repr(e))

# A5: the 191 reviews sister surface intact on the same payload
try:
    d = get(BASE + "/api/match/5749721")
    r = d.get("reviews") or []
    r0 = r[0] if r else {}
    good = len(r) == 1 and r0.get("title", "").startswith("Roma 4-2 Cagliari: Mora inspires") \
        and r0.get("source") == "Opta"
    report("A5 191 reviews sister intact", good,
           f"n={len(r)} title={r0.get('title','')[:40]!r}")
except Exception as e:
    report("A5 191 reviews sister intact", False, repr(e))

# A6: the 190 statGroups sister surface intact on the same payload
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
  echo "$label → $OUT | console=$C appErrors=$E rc=$RC"
  [ "$RC" -eq 0 ] || BAD=$((BAD+1))
}

open_page "/"
clean_ls

# B1: /match/5749721 — the card renders: testid + label + 10 rows + the
# Lulli needle + the Persian rating «۸.۷»
open_page "/match/5749721"
sleep 1
FEAT=$(snap 'card:!!document.querySelector("[data-testid=match-top-players]"),label:document.body.innerText.includes("برترین\u200cهای بازی"),rows:document.querySelectorAll("[data-testid=match-top-players-row]").length,needle:document.body.innerText.includes("Lulli"),rating:document.body.innerText.includes("۸.۷")')
B1=0
echo "$FEAT" | rg -q 'card:true' || B1=1
echo "$FEAT" | rg -q 'label:true' || B1=1
echo "$FEAT" | rg -q 'rows:10' || B1=1
echo "$FEAT" | rg -q 'needle:true' || B1=1
echo "$FEAT" | rg -q 'rating:true' || B1=1
[ "$B1" -eq 0 ] || BAD=$((BAD+1))
gate "B1 5749721 card+label+10rows+Lulli+۸.۷" "$FEAT"
clean_ls

# B2: the MOTM star rides the Lulli row + every row links to /player/[id]
# (the 172 family linkage) + the position label renders
open_page "/match/5749721"
sleep 1
FEAT=$(snap 'star:[...document.querySelectorAll("[data-testid=match-top-players-row]")].some(r=>r.textContent.includes("Lulli")&&r.textContent.includes("★")),links:[...document.querySelector("[data-testid=match-top-players]").querySelectorAll("a")].filter(x=>(x.getAttribute("href")||"").startsWith("/player/")).length,pos:[...document.querySelectorAll("[data-testid=match-top-players-row]")].some(r=>r.textContent.includes("RM"))')
B2=0
echo "$FEAT" | rg -q 'star:true' || B2=1
echo "$FEAT" | rg -q 'links:10' || B2=1
echo "$FEAT" | rg -q 'pos:true' || B2=1
[ "$B2" -eq 0 ] || BAD=$((BAD+1))
gate "B2 motm star + 10 player links + pos" "$FEAT"
clean_ls

# B3: /match/5765944 — the second width proof in DOM (Stojković 9.2)
open_page "/match/5765944"
sleep 1
FEAT=$(snap 'card:!!document.querySelector("[data-testid=match-top-players]"),needle:document.body.innerText.includes("Stojkovi"),rating:document.body.innerText.includes("۹.۲")')
B3=0
echo "$FEAT" | rg -q 'card:true' || B3=1
echo "$FEAT" | rg -q 'needle:true' || B3=1
echo "$FEAT" | rg -q 'rating:true' || B3=1
[ "$B3" -eq 0 ] || BAD=$((BAD+1))
gate "B3 5765944 width proof (Stojković ۹.۲)" "$FEAT"
clean_ls

# B4: /match/5868120 — upcoming → the block honest-hides entirely
open_page "/match/5868120"
sleep 1
FEAT=$(snap 'noCard:!document.querySelector("[data-testid=match-top-players]")')
B4=0
echo "$FEAT" | rg -q 'noCard:true' || B4=1
[ "$B4" -eq 0 ] || BAD=$((BAD+1))
gate "B4 5868120 upcoming honest absence" "$FEAT"
clean_ls

echo "== VERDICT =="
if [ "$BAD" -eq 0 ]; then
  echo "DOM_PROOF OK — cycle-192 update proven (A 6/6 + B 4/4 @390x844)"
else
  echo "DOM_PROOF BAD=$BAD"
  exit 1
fi
