#!/usr/bin/env python3
# cycle-499 fix sweep: EVERY league (id, name, ccode) live in the ±7 window
# vs the LEAGUES registry — the c469-league-sweep discipline, re-derived
# fresh (the 494 card: the previous sweep artifact was wiped in a container
# recycle). Reads OUR OWN /api/matches feed (same source the team route's
# hintLeagueId comes from), so the ids here are exactly the ids team pages
# receive as league context.
import json, re, subprocess, sys, time

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
    for attempt in range(3):
        try:
            d = fetch(f"{BASE}/api/matches?offset={o}")
            break
        except Exception as e:
            time.sleep(2.0)
    else:
        print(f"offset {o}: FETCH FAILED", file=sys.stderr)
        continue
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
    time.sleep(1.8)

missing = {lid: e for lid, e in leagues.items() if lid not in registered}
print(f"days=15 totalRows={total} distinctLeagueIds={len(leagues)} registered={len(registered)}")
print(f"--- MISSING from registry: {len(missing)} ---")
for lid in sorted(missing, key=lambda k: -missing[k]["rows"]):
    e = missing[lid]
    print(f"  id={lid} cc={e['cc']} rows={e['rows']} days={len(e['days'])} "
          f"name={e['name']!r} sample={e['sampleMatchId']}")
print("--- registered ids seen live (sanity) ---")
seen = sorted(l for l in leagues if l in registered)
print(f"  {len(seen)} registered ids live: {seen}")
