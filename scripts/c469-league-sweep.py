#!/usr/bin/env python3
# cycle-469 fix sweep: EVERY league (id, name, ccode) live in the ±7 window
# vs the LEAGUES registry — the authoritative missing-ids list behind the
# 468 finding (EST 1000001181 / HON 941508 / PAN + the harvested waves).
# The sweep reads OUR OWN /api/matches feed (same source the team route's
# hintLeagueId comes from), so the ids here are exactly the ids team pages
# receive as league context.
import json, re, subprocess, sys

BASE = "http://localhost:3000"
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

def fetch(url):
    out = subprocess.run(["curl", "-s", "--max-time", "40", "-A", UA, url],
                         capture_output=True, text=True, timeout=60).stdout
    return json.loads(out)

# registered fotmobIds straight from the source of truth
src = open("src/lib/leagues.ts", encoding="utf-8").read()
registered = set(int(m) for m in re.findall(r"fotmobId:\s*(\d+)", src))

leagues = {}  # leagueId -> {name, cc, rows, days, sampleMatchId}
total = 0
for o in range(-7, 8):
    d = fetch(f"{BASE}/api/matches?offset={o}")
    day = d.get("date") or str(o)
    for g in d.get("groups", []):
        lid = g.get("leagueId")
        if lid is None:
            continue
        e = leagues.setdefault(lid, {"name": g.get("leagueName") or "",
                                     "cc": g.get("ccode") or "",
                                     "rows": 0, "days": set(),
                                     "sampleMatchId": None})
        e["rows"] += len(g.get("matches", []))
        e["days"].add(day)
        ms = g.get("matches", [])
        if ms and e["sampleMatchId"] is None:
            e["sampleMatchId"] = ms[0].get("id")
        total += len(ms)

missing = {lid: e for lid, e in leagues.items() if lid not in registered}
print(f"days=15 totalRows={total} distinctLeagueIds={len(leagues)} registered={len(registered)}")
print(f"--- MISSING from registry: {len(missing)} ---")
for lid in sorted(missing, key=lambda k: -missing[k]["rows"]):
    e = missing[lid]
    print(f"  id={lid} cc={e['cc']} rows={e['rows']} days={len(e['days'])} "
          f"name={e['name']!r} sample={e['sampleMatchId']}")
print("--- registered ids seen live (sanity) ---")
seen_reg = {lid: e for lid, e in leagues.items() if lid in registered}
for lid in sorted(seen_reg, key=lambda k: -seen_reg[k]["rows"])[:10]:
    e = seen_reg[lid]
    print(f"  id={lid} cc={e['cc']} rows={e['rows']} name={e['name']!r}")

json.dump({"total": total,
           "leagues": {str(k): {"name": e["name"], "cc": e["cc"], "rows": e["rows"],
                                "days": sorted(e["days"]), "sampleMatchId": e["sampleMatchId"]}
                       for k, e in leagues.items()},
           "missing": {str(k): {"name": e["name"], "cc": e["cc"], "rows": e["rows"],
                                "sampleMatchId": e["sampleMatchId"]}
                       for k, e in missing.items()}},
          open("/tmp/c469-sweep.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c469-sweep.json")
sys.exit(0)
