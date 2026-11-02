#!/usr/bin/env python3
# cycle-392 probe — collect raw (nameFa==name) player names across the
# transfers surfaces (league-transfers for the five covered domestic
# leagues + team-transfers for flagship teams). Byte-exact harvest only.
import json, subprocess, sys
from collections import OrderedDict

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
BASE = "http://localhost:3000"

def get(path):
    r = subprocess.run(["curl", "-s", "-A", UA, BASE + path],
                       capture_output=True, text=True, timeout=60)
    try:
        return json.loads(r.stdout)
    except Exception:
        return None

raw = OrderedDict()   # raw name -> {"teams": [...], "kinds": [...]}
totals = {"league_items": 0, "team_items": 0}

# 1) league-transfers for every LEAGUES key with a feed
for key in ["pl", "laliga", "seriea", "bundesliga", "ligue1", "persiangulf", "ucl"]:
    j = get(f"/api/league-transfers?league={key}")
    if not j or not j.get("ok"):
        print(f"league {key}: unavailable", flush=True)
        continue
    t = j.get("transfers") or {}
    items = t.get("items") or []
    if not items:
        print(f"league {key}: no feed (null)", flush=True)
        continue
    n = 0
    for it in items:
        name = (it.get("name") or "").strip()
        nfa = (it.get("nameFa") or "").strip()
        totals["league_items"] += 1
        if name and nfa == name:
            e = raw.setdefault(name, {"teams": [], "kinds": []})
            e["teams"].append(key)
            e["kinds"].append(it.get("kind", ""))
    print(f"league {key}: {len(items)} items", flush=True)

# 2) team-transfers for flagship clubs
TEAMS = {"10261": "newcastle", "8667": "hull", "8044": "omonio"}
for tid, label in TEAMS.items():
    j = get(f"/api/team-transfers/{tid}")
    if not j or not j.get("ok"):
        print(f"team {label}: unavailable", flush=True)
        continue
    t = j.get("transfers") or {}
    items = t.get("items") or []
    for it in items:
        name = (it.get("name") or "").strip()
        nfa = (it.get("nameFa") or "").strip()
        totals["team_items"] += 1
        if name and nfa == name:
            e = raw.setdefault(name, {"teams": [], "kinds": []})
            e["teams"].append(f"team:{label}")
            e["kinds"].append(it.get("kind", ""))
    print(f"team {label}: {len(items)} items", flush=True)

out = {
    "totals": totals,
    "raw_unique_count": len(raw),
    "raw_names": raw,
}
with open("scripts/cycle392-transfers-raw.json", "w", encoding="utf-8") as f:
    json.dump(out, f, ensure_ascii=False, indent=1)
print(f"\nTOTALS {totals}", flush=True)
print(f"RAW UNIQUE NAMES: {len(raw)}", flush=True)
for n in raw:
    print(n, flush=True)
