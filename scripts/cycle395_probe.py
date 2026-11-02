#!/usr/bin/env python3
# cycle-395 probe — harvest the raw (nameFa missing or nameFa==name) player
# names across the SQUAD surfaces (/api/team-squad/{id}) of the flagship
# teams (the 390-394 domproof anchors). Byte-exact harvest only — the JSON
# output is the key source for scripts/cycle395_gen_map.py.
# NOTE: the coach name rides coachFa (cycle-259) — the coach raw at
# players-view:765 is the 394 card's logged bug-hunt item, NOT this pool.
import json, subprocess, sys
from collections import OrderedDict

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
BASE = "http://localhost:3000"

TEAMS = OrderedDict([
    ("8650",   "liverpool"),
    ("10261",  "newcastle"),
    ("101610", "persepolis"),
    ("8667",   "hull"),
    ("8044",   "omonio"),
    ("6711",   "iran-nt"),
    ("6706",   "argentina-nt"),
])

def get(path):
    r = subprocess.run(["curl", "-s", "-A", UA, BASE + path],
                       capture_output=True, text=True, timeout=60)
    try:
        return json.loads(r.stdout)
    except Exception:
        return None

raw = OrderedDict()   # raw name -> {"teams": [...]}
stats = {}

for tid, label in TEAMS.items():
    j = get(f"/api/team-squad/{tid}")
    if not j or not j.get("ok"):
        print(f"team {label}: UNAVAILABLE", flush=True)
        continue
    t = j.get("squad") or {}
    total = 0
    nraw = 0
    for g in (t.get("groups") or []):
        for p in (g.get("players") or []):
            name = (p.get("name") or "").strip()
            nfa = (p.get("nameFa") or "").strip()
            if not name:
                continue
            total += 1
            if nfa == name or not nfa:
                nraw += 1
                e = raw.setdefault(name, {"teams": []})
                if label not in e["teams"]:
                    e["teams"].append(label)
    stats[label] = {"total": total, "raw": nraw}
    print(f"team {label}: {total} players, {nraw} raw", flush=True)

out = {
    "totals": {"teams": len(stats), "players": sum(s["total"] for s in stats.values()),
               "raw": sum(s["raw"] for s in stats.values())},
    "per_team": stats,
    "raw_unique_count": len(raw),
    "raw_names": raw,
}
with open("scripts/cycle395-squads-raw.json", "w", encoding="utf-8") as f:
    json.dump(out, f, ensure_ascii=False, indent=1)
print(f"\nTOTALS {out['totals']}", flush=True)
print(f"RAW UNIQUE NAMES: {len(raw)}", flush=True)
for n in raw:
    print(n, flush=True)
