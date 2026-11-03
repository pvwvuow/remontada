#!/usr/bin/env python3
# cycle-450 batch-13 pool sweep: one full ±7 walk saved to /tmp/c450-pool.json
# so the tranche pick + the post-patch census re-read both answer from the
# SAME live window (the 435/436 pattern: rows drift, distinct is decisive).
# Groups the honest-raw pool by country identity (the 389 rule) for the
# count>=3 tranche pick; (W) women's sides excluded per the 435 skip line.
import json, re, subprocess, sys

BASE = "http://localhost:3000"
PERSIAN = re.compile(r"[\u0600-\u06FF]")
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

def fetch(url):
    out = subprocess.run(["curl", "-s", "--max-time", "40", "-A", UA, url],
                         capture_output=True, text=True, timeout=60).stdout
    return json.loads(out)

seen = {}  # rawName -> {cc:set, rows:int, days:set, leagues:set, sampleId}
total = 0
for o in range(-7, 8):
    d = fetch(f"{BASE}/api/matches?offset={o}")
    day = d.get("date") or str(o)
    for g in d.get("groups", []):
        cc = g.get("ccode") or ""
        lg = g.get("leagueName") or ""
        for m in g.get("matches", []):
            for side in ("home", "away"):
                t = m.get(side) or {}
                name = t.get("fa") or t.get("name") or ""
                if name and not PERSIAN.search(name):
                    e = seen.setdefault(name, {"cc": set(), "rows": 0,
                                               "days": set(), "leagues": set(),
                                               "sampleId": m.get("id"),
                                               "sampleDate": day})
                    e["cc"].add(cc); e["rows"] += 1
                    e["days"].add(day); e["leagues"].add(lg)
                    total += 1

by_count = {}
for n, e in seen.items():
    by_count.setdefault(e["rows"], []).append(n)

print(f"totalRows={total} distinct={len(seen)}")
for c in sorted(by_count, reverse=True)[:6]:
    print(f"  count-{c}: {len(by_count[c])} names")

# count>=3 single-country tranche, grouped by country (the 446-pick rule)
tranche = {}
for n, e in seen.items():
    if e["rows"] < 3 or len(e["cc"]) != 1:
        continue
    cc = sorted(e["cc"])[0]
    tranche.setdefault(cc, []).append(n)
print("count>=3 single-country pools by country:")
for cc in sorted(tranche, key=lambda k: -len(tranche[k])):
    names = tranche[cc]
    rows = sum(seen[n]["rows"] for n in names)
    print(f"  {cc}: {len(names)} names / {rows} rows")

json.dump({"total": total, "seen": {n: {"cc": sorted(e["cc"]), "rows": e["rows"],
                                        "days": sorted(e["days"]),
                                        "leagues": sorted(e["leagues"]),
                                        "sampleId": e["sampleId"],
                                        "sampleDate": e["sampleDate"]}
                                   for n, e in seen.items()}},
          open("/tmp/c450-pool.json", "w"), ensure_ascii=False)
print("pool saved -> /tmp/c450-pool.json")
sys.exit(0)
