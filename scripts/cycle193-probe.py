#!/usr/bin/env python3
# cycle-193 bug-hunt live probe — establish current truth BEFORE pinning
# (D5: look at bytes first, then pin). UA Chrome/124. Read-only.
# Patrol scope: the 189-192 surfaces (the 188 hunt covered 184-187) plus
# NEW honesty dimensions no earlier gate combined:
#   - POTM (matchFacts.playerOfTheMatch) vs topPlayers motm=true consistency
#   - direct-id player navigation for a NON-star (Lulli 1800491)
#   - stats-pill (190) + zones-half (187) co-existence on one match
#   - reviews (191) + topPlayers (192) header-card co-existence
import json, urllib.request

BASE = "http://localhost:3000"
UP = "https://www.fotmob.com/api/data/matchDetails?matchId="
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0", "Accept": "application/json"}

def get(u):
    req = urllib.request.Request(u, headers=UA)
    return json.load(urllib.request.urlopen(req, timeout=30))

print("== P1: POTM vs topPlayers motm consistency (5749721 + 5765944) ==")
for m in ("5749721", "5765944"):
    d = get(f"{BASE}/api/match/{m}")
    potm = d.get("playerOfTheMatch")
    tp = d.get("topPlayers") or {}
    motm_rows = [r for side in ("home", "away") for r in (tp.get(side) or []) if r.get("motm")]
    print(f"--- {m}")
    print("  potm:", json.dumps(potm, ensure_ascii=False)[:220] if potm else "null")
    print("  motm rows:", [(r["id"], r["name"], r["rating"]) for r in motm_rows])

print("\n== P2: direct-id player navigation — Lulli 1800491 (non-star) ==")
try:
    p = get(f"{BASE}/api/player/1800491")
    print("keys:", sorted(p.keys())[:14])
    print("name:", p.get("name"), "| nameFa:", p.get("nameFa"))
    print("positions:", str(p.get("positions"))[:120])
except Exception as e:
    print("PLAYER API ERROR:", type(e).__name__, str(e)[:200])

print("\n== P3: statPeriods + zones co-existence (5749727) ==")
d = get(f"{BASE}/api/match/5749727")
sp = d.get("statPeriods")
zn = d.get("zones")
print("statPeriods keys:", list(sp.keys()) if sp else sp)
if sp:
    fh = sp.get("firstHalf") or []
    r0 = fh[0]["rows"][0] if fh and fh[0].get("rows") else {}
    print("  firstHalf groups:", len(fh), "| fh possession:", r0.get("home"), "/", r0.get("away"))
print("zones:", "null" if not zn else {k: len(zn[k]) if isinstance(zn.get(k), list) else zn.get(k) for k in ("left", "center", "right", "firstHalf", "secondHalf") if k in zn})

print("\n== P4: header-card co-existence (5749721): reviews + topPlayers + highlights ==")
d = get(f"{BASE}/api/match/5749721")
print("reviews n:", len(d.get("reviews") or []), "| topPlayers:", bool(d.get("topPlayers")), "| highlights:", bool(d.get("highlights")))

print("\n== P5: mapped rows on the match page (189 map on the 192 surface) ==")
tp = d.get("topPlayers") or {}
for side in ("home", "away"):
    for r in (tp.get(side) or []):
        if r["nameFa"] != r["name"]:
            print(f"  {side}: {r['name']} -> {r['nameFa']} ({r['rating']})")

print("\n== P6: live DOM material — page renders (server 200 + h1 count) ==")
import urllib.error
for path in ("/match/5749721", "/match/5749727", "/player/1800491"):
    req = urllib.request.Request(BASE + path, headers=UA)
    try:
        html = urllib.request.urlopen(req, timeout=30).read().decode("utf-8", "ignore")
        print(f"page {path}: {len(html)} bytes, h1-ish:", html.count("<h1"))
    except urllib.error.HTTPError as e:
        print(f"page {path}: HTTP {e.code}")
