#!/usr/bin/env python3
# cycle-194 fix live probe — bytes BEFORE the fold (D5 discipline).
# The polish: the five historical-only kings (the open half of the cycle-188
# observation — cycle-189 closed the nameFa half) join the player search pool
# as ZERO-fetch fold rows. This probe pins (P1) the defect — all five
# unsearchable today, while a current star IS searchable — (P2) the exact
# historical bytes each fold row must carry (per-league historical payloads:
# name/team/stat spelling as the site serves them), and (P3) the profile
# availability side. Read-only, UA Chrome/124.
import json, urllib.request, urllib.parse, urllib.error

BASE = "http://localhost:3000"
UA = {"User-Agent": "Mozilla/5.0 Chrome/124.0"}

def get(u):
    req = urllib.request.Request(u, headers=UA)
    return json.load(urllib.request.urlopen(req, timeout=30))

def j(x):
    return json.dumps(x, ensure_ascii=False)[:400]

KINGS = [
    ("alejo",   640089,  "laliga",   "2023/2024"),
    ("downes",  844943,  "pl",       "2024/2025"),
    ("fetai",   1516458, "hnl",      "2024/2025"),
    ("bruggen", 232299,  "belgium",  "2023/2024"),
    ("radakovic", 364855, "superlig", "2024/2025"),
]
Q_LATIN = {"alejo": "Alejo", "downes": "Downes", "fetai": "Fetai",
           "bruggen": "Van Der Bruggen", "radakovic": "Radakovic"}
Q_FA = {"alejo": "آلخو", "downes": "داونز", "fetai": "فتای",
        "bruggen": "بروخن", "radakovic": "راداکوویچ"}

print("== P1: the defect — five kings unsearchable TODAY ==")
for key, pid, lg, season in KINGS:
    for label, q in (("latin", Q_LATIN[key]), ("fa", Q_FA[key])):
        d = get(f"{BASE}/api/search?q={urllib.parse.quote(q)}")
        players = d.get("players") or []
        hit = [p.get("playerId") for p in players]
        status = "FOUND(!!)" if pid in hit else "absent"
        print(f"P1 {key}/{label} q={q!r} -> players={len(players)} hit={hit[:3]} [{status}]")
print("-- sanity: a current star IS searchable --")
for q in ("رافینیا", "Raphinha"):
    d = get(f"{BASE}/api/search?q={urllib.parse.quote(q)}")
    players = d.get("players") or []
    print(f"P1 sanity q={q!r} -> players={len(players)} ids={[p.get('playerId') for p in players][:3]}")

print("== P2: historical bytes per king (per-league payload, exact row) ==")
for key, pid, lg, season in KINGS:
    qs = urllib.parse.quote(season, safe="")
    d = get(f"{BASE}/api/topscorers/{lg}?season={qs}")
    blocks = [("scorers", d.get("scorers") or []),
              ("assists", d.get("assists") or []),
              ("yellow", (d.get("cards") or {}).get("yellow") or []),
              ("red", (d.get("cards") or {}).get("red") or [])]
    found = None
    for bname, rows in blocks:
        for row in rows:
            if row.get("playerId") == pid:
                found = (bname, row)
                break
        if found:
            break
    print(f"P2 {key} /{lg}?season={season}: lgFa={d.get('leagueFa')!r} sel={d.get('selectedSeason')!r} "
          f"scorers={len(d.get('scorers') or [])} assists={len(d.get('assists') or [])}")
    if found:
        print(f"   block={found[0]} row={j(found[1])}")
    else:
        print(f"   !! pid {pid} NOT in any block (honest drift?)")

print("== P3: profile side (id -> nested player.name/nameFa bytes for the gate) ==")
# probe-side slip fixed (the 193 lesson): the payload nests under "player"
for key, pid, lg, season in KINGS:
    d = get(f"{BASE}/api/player/{pid}")
    p = d.get("player") or {}
    print(f"P3 {key} /api/player/{pid} -> name={p.get('name')!r} nameFa={p.get('nameFa')!r} "
          f"team={(p.get('team') or {}).get('id')!r}")

print("== P4: current-season collision guard ==")
# the fold respects the seen-set: if a king somehow rides a CURRENT standings
# row too, the live row wins and stays single-listed. Today P1 says absent —
# re-assert so the fix story is airtight.
for key, pid, lg, season in KINGS:
    d = get(f"{BASE}/api/standings?league={lg}" if lg != "pl" else f"{BASE}/api/standings?league=pl")
    blob = json.dumps(d, ensure_ascii=False)
    print(f"P4 {key} {lg}: pid {pid} in current standings payload -> {str(pid) in blob}")
