#!/usr/bin/env bash
# ------------------------------------------------------------------
# cycle-197 update — the player profile gains squad navigation
# («هم‌تیمی‌ها» — club squad + national-team squad-mates)
#
# The probed gap (scripts/cycle197-probe.py, 2026-10-30, UA Chrome/124):
# EVERY playerData payload carries `relatedLinksData` — the current club
# squad (`teammates`) and the national-team squads (`mensNationalTeam`
# + `womensNationalTeam`) as flat {id, name} rows — 23-30 club / 27-35 NT
# rows per player, ZERO malformed rows, self never in his own lists, zero
# duplicate ids, zero upstream-Persian names, and ZERO usage in src/ before
# this cycle (grep-verified): the profile had no squad-navigation surface.
# Fix: additive-only, ZERO extra upstream fetch — buildRelatedLinks folds
# the guarded rows (id>0 the 167 lesson, seen-set dedupe, self-exclusion)
# into the normalized PlayerData (player:v7 → v8 bump, the 196 lesson), and
# the profile renders two chip groups whose every chip is a real /player
# link (the 172 family). nameFa rides the 104 map — mapped rows render
# Persian («ژائو پدرو»), unmapped rows stay honest Latin (the 92/107
# contract). Honest absence: empty groups omit, an empty block hides the
# card.
#
# Gate pins are STRUCTURAL (counts banded, hygiene invariants, self-
# exclusion) plus two club-side id pins stable mid-season (Balde 1254166 +
# Cancelo 361757 ride Raphinha's Barcelona squad; Raya 562727 rides
# Gyokeres' Arsenal squad) — the 193 lesson forbids pinning live values,
# so no squad ORDER or NT call-up bytes are pinned.
# ------------------------------------------------------------------
set -u
BASE="http://localhost:3000"
BAD=0

echo "== PART A: API proof (8 gates) =="
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

def rows_ok(rows):
    return (isinstance(rows, list) and all(
        isinstance(t, dict) and set(t.keys()) == {"id", "name", "nameFa"}
        and isinstance(t["id"], int) and t["id"] > 0
        and isinstance(t["name"], str) and t["name"].strip()
        and isinstance(t["nameFa"], str) and t["nameFa"].strip()
        for t in rows))

def hygiene(rows, self_id):
    ids = [t["id"] for t in rows]
    return len(ids) == len(set(ids)) and self_id not in ids

p = (get(f"{BASE}/api/player/696679").get("player") or {})
tm, nt = p.get("teammates") or [], p.get("nationalTeammates") or []

# A1 — Raphinha club squad: banded count + full hygiene + row shape
report("A1-raphinha-club", rows_ok(tm) and hygiene(tm, 696679) and 15 <= len(tm) <= 45,
       f"n={len(tm)}")
# A2 — Raphinha NT squad: banded count + hygiene + stable club-side Barça pins
balde = any(t["id"] == 1254166 for t in tm)
cancelo = any(t["id"] == 361757 for t in tm)
report("A2-raphinha-nt", rows_ok(nt) and hygiene(nt, 696679) and 15 <= len(nt) <= 45 and balde and cancelo,
       f"n={len(nt)} balde={balde} cancelo={cancelo}")
# A3 — the 104 map reaches the rows: at least one mapped (nameFa != name) row
mapped = [t for t in tm + nt if t["nameFa"] != t["name"]]
report("A3-map-hits", len(mapped) >= 1, f"mapped={len(mapped)} e.g.={mapped[0]['name']}→{mapped[0]['nameFa']}" if mapped else "none")
# A4 — Gyokeres: block on a second star + stable Arsenal pin (Raya)
g = (get(f"{BASE}/api/player/664500").get("player") or {})
gtm = g.get("teammates") or []
raya = any(t["id"] == 562727 for t in gtm)
report("A4-gyokeres", rows_ok(gtm) and hygiene(gtm, 664500) and len(gtm) >= 15 and raya,
       f"n={len(gtm)} raya={raya}")
# A5 — non-star universality: Lulli (outside the 400-star search pool) serves both lists
l = (get(f"{BASE}/api/player/1800491").get("player") or {})
lt, ln = l.get("teammates") or [], l.get("nationalTeammates") or []
report("A5-lulli-universal", rows_ok(lt) and rows_ok(ln) and len(lt) >= 15 and len(ln) >= 15,
       f"club={len(lt)} nt={len(ln)}")
# A6 — fold-king cross-tie: Fetai's profile serves the block too
f = (get(f"{BASE}/api/player/1516458").get("player") or {})
ft = f.get("teammates") or []
report("A6-fetai", rows_ok(ft) and len(ft) >= 15, f"club={len(ft)}")
# A7 — row-id liveness on the SERVED app: a teammate id answers a full profile (no dead links — 167)
r = get(f"{BASE}/api/player/1180321")
rp = r.get("player") or {}
report("A7-row-liveness", r.get("ok") is True and rp.get("id") == "1180321" and rows_ok(rp.get("teammates") or []),
       f"ok={r.get('ok')} h1name={rp.get('nameFa')}")
# A8 — additive contract: the pre-197 profile keys all still serve
keys = ["id", "name", "nameFa", "positionFa", "team", "info", "season", "recent", "recentTeams",
        "pitch", "career", "trophies", "deepStats", "traits", "market", "injury", "fetchedAt"]
missing = [k for k in keys if k not in p]
report("A8-additive-contract", not missing, f"missing={missing or 'none'}")
print("API_OK" if ok else "API_BAD")
PY
)
echo "$A_OUT"
echo "$A_OUT" | grep -q "API_BAD" && BAD=$((BAD+1))

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
# scroll the teammates card into view (profile pages are long)
show_card() {
  $B eval "(function(){var c=document.querySelector('[data-testid=player-teammates]');if(!c)return 'nocard';c.scrollIntoView({block:\"center\"});return 'ok';})()" >/dev/null 2>&1
  sleep 0.8
}
# click a chip by its title attr (the raw upstream name), report where we landed
click_chip() {
  $B eval "(function(){var a=[...document.querySelectorAll('[data-testid=player-teammate-chip]')].find(function(x){return x.getAttribute('title')==='$1';});if(!a)return 'nochip';a.click();return 'clicked';})()" 2>/dev/null
  $B wait --load networkidle >/dev/null 2>&1
  sleep 1.5
}

clean_ls

# B1 — Raphinha: the card renders with BOTH groups, club labeled with the team fa
open_page "/player/696679"
show_card
CARD=$($B eval "JSON.stringify({card:!!document.querySelector('[data-testid=player-teammates]'),club:document.querySelectorAll('[data-testid=player-teammates-club] [data-testid=player-teammate-chip]').length,nat:document.querySelectorAll('[data-testid=player-teammates-national] [data-testid=player-teammate-chip]').length,clubLbl:(document.querySelector('[data-testid=player-teammates-club] p')||{}).innerText||'',natLbl:(document.querySelector('[data-testid=player-teammates-national] p')||{}).innerText||''})" 2>/dev/null | tr -d '"\\')
echo "B1 card state: $CARD"
echo "$CARD" | grep -q "card:true" || BAD=$((BAD+1))
echo "$CARD" | grep -E "club:[0-9]{2,}" || BAD=$((BAD+1))
echo "$CARD" | grep -q "باشگاه" || BAD=$((BAD+1))
echo "$CARD" | grep -q "تیم ملی" || BAD=$((BAD+1))
gate "B1-raphinha-card" "card+groups+labels"

# B2 — the 172-family full loop: click the stable Barça chip (Balde) → real profile h1
click_chip "Alejandro Balde"
URL=$($B eval "location.pathname" 2>/dev/null | tr -d '"')
echo "B2 landed: $URL"
[ "$URL" = "/player/1254166" ] || BAD=$((BAD+1))
gate "B2-chip-loop-balde" "click→/player/1254166 h1"

# B3 — non-star recursion: Lulli's card → click stable Roma chip (Rensch) → Rensch's OWN card
open_page "/player/1800491"
show_card
N1=$($B eval "JSON.stringify({club:document.querySelectorAll('[data-testid=player-teammates-club] [data-testid=player-teammate-chip]').length})" 2>/dev/null | tr -d '"\\')
echo "B3 lulli chips: $N1"
echo "$N1" | grep -E "club:[0-9]{2,}" || BAD=$((BAD+1))
click_chip "Devyne Rensch"
URL2=$($B eval "location.pathname" 2>/dev/null | tr -d '"')
RENSCH=$($B eval "JSON.stringify({h1:document.querySelector('h1').innerText.trim(),own:!!document.querySelector('[data-testid=player-teammates]')})" 2>/dev/null | tr -d '"\\')
echo "B3 landed: $URL2 $RENSCH"
[ "$URL2" = "/player/1180321" ] || BAD=$((BAD+1))
echo "$RENSCH" | grep -q "own:true" || BAD=$((BAD+1))
gate "B3-lulli-recursion" "Lulli→Rensch→own card"

clean_ls
echo "== verdict =="
if [ "$BAD" -eq 0 ]; then echo "DOMPROOF OK (A 8/8 + B 3/3)"; else echo "DOMPROOF BAD=$BAD"; exit 1; fi
