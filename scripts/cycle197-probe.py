#!/usr/bin/env python3
# cycle-197 update live probe — bytes BEFORE the teammates block (D5).
# The gap: playerData carries `relatedLinksData` — the CURRENT club squad
# (`teammates`) and the national-team squad (`mensNationalTeam`,
# `womensNationalTeam`) as {id, name} rows — and the whole block has ZERO
# usage in src/ (grep-verified). It is universal: star and non-star payloads
# alike carry 23-35 well-formed rows per side, and every row id serves a full
# /playerData profile (no dead links — the 167 lesson). The extension rides
# the SAME cached playerData payload (zero extra upstream fetches).
# P1 = the deficit on the served API (keys absent today).
# P2 = exact upstream bytes (counts + first rows + row hygiene) on four
#      anchors: star (Raphinha), non-star (Lulli), fold-king (Fetai), pool
#      star (Gyokeres).
# P3 = row-id liveness — a teammate id answers a full playerData profile.
# P4 = honest-absence inventory (womensNationalTeam empty on all four).
# UA Chrome/124. Read-only.
import json, urllib.request

BASE = "http://localhost:3000"
UP = "https://www.fotmob.com"
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36"}

def get(u):
    return json.load(urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=30))

def rows_ok(rows):
    return [r for r in rows if isinstance(r, dict)
            and isinstance(r.get("id"), int) and r["id"] > 0
            and isinstance(r.get("name"), str) and r["name"].strip()]

ANCHORS = [(696679, "Raphinha", "star"), (1800491, "Lulli", "non-star"),
           (1516458, "Fetai", "fold-king"), (664500, "Gyokeres", "pool-star")]

print("== P1: the deficit — served /api/player lacks the block today ==")
d = get(f"{BASE}/api/player/696679")
p = d.get("player") or {}
print(f"served keys have teammates: {'teammates' in p}  nationalTeammates: {'nationalTeammates' in p}")

print("== P2: upstream bytes — counts + first rows + hygiene ==")
for pid, who, kind in ANCHORS:
    raw = get(f"{UP}/api/data/playerData?id={pid}")
    rl = raw.get("relatedLinksData") or {}
    tm = rows_ok(rl.get("teammates") or [])
    mn = rows_ok(rl.get("mensNationalTeam") or [])
    wn = rows_ok(rl.get("womensNationalTeam") or [])
    bad = len(rl.get("teammates") or []) + len(rl.get("mensNationalTeam") or []) - len(tm) - len(mn)
    print(f"{who} {pid} ({kind}): club={len(tm)} nt={len(mn)} womens={len(wn)} badRows={bad}")
    if tm:
        print(f"   club first3: {[(t['id'], t['name']) for t in tm[:3]]}")
    if mn:
        print(f"   nt   first3: {[(t['id'], t['name']) for t in mn[:3]]}")

print("== P3: row-id liveness — a teammate id serves a full profile ==")
d2 = get(f"{UP}/api/data/playerData?id=1180321")
print(f"Rensch 1180321: id={d2.get('id')} name={d2.get('name')} relatedLinks={bool(d2.get('relatedLinksData'))}")

print("== P4: honest-absence inventory (womensNationalTeam all empty) ==")
for pid, who, _ in ANCHORS:
    raw = get(f"{UP}/api/data/playerData?id={pid}")
    wn = (raw.get("relatedLinksData") or {}).get("womensNationalTeam") or []
    print(f"{who}: womensNT={len(wn)}")
