#!/usr/bin/env python3
# cycle-440 batch-7 pre-patch verification: every intended TEAM_FA key must be
# byte-exact (the live feed literal, lowercased for the key) and single-country
# across the whole ±7 window (the 389 rule: identity first, no guessing).
# Batch 7 = the SCOTLAND tranche (all 30 count-3 single-country SCO names of
# the 440 census — Challenge Cup + FA Cup + Lowland League East/West; no (W)
# women's sides in this pool, nothing excluded).
import json, re, subprocess, sys

BASE = "http://localhost:3000"
PERSIAN = re.compile(r"[\u0600-\u06FF]")
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CANDIDATES = [
    "Formartine United", "Airdrieonians", "Cove Rangers",
    "Queen of the South", "East Kilbride", "Peterhead",
    "Edinburgh City", "Kelty Hearts", "Elgin City",
    "Annan Athletic", "Stirling Albion", "Inverness Caledonian Thistle",
    "Greenock Morton", "Clyde", "Linlithgow Rose",
    "Brechin City", "East Stirlingshire", "Bo'ness United",
    "Stirling University FC", "Civil Service Strollers",
    "Gala Fairydean Rovers", "Broxburn Athletic", "Newton Stewart",
    "Gretna FC 2008", "Caledonian Braves", "Albion Rovers",
    "Renfrew FC", "Troon Juniors", "Largs Thistle", "Cumnock Juniors",
]

def fetch(url):
    out = subprocess.run(["curl", "-s", "--max-time", "40", "-A", UA, url],
                         capture_output=True, text=True, timeout=60).stdout
    return json.loads(out)

seen = {}  # rawName -> {cc:set, rows:int, days:set}
for o in range(-7, 8):
    d = fetch(f"{BASE}/api/matches?offset={o}")
    day = d.get("date") or str(o)
    for g in d.get("groups", []):
        cc = g.get("ccode") or ""
        for m in g.get("matches", []):
            for side in ("home", "away"):
                t = m.get(side) or {}
                name = t.get("fa") or t.get("name") or ""
                if name and not PERSIAN.search(name):
                    e = seen.setdefault(name, {"cc": set(), "rows": 0, "days": set()})
                    e["cc"].add(cc); e["rows"] += 1; e["days"].add(day)

ok, bad = [], []
for cand in CANDIDATES:
    e = seen.get(cand)
    if not e:
        bad.append((cand, "ABSENT from the live ±7 window"))
        continue
    if len(e["cc"]) != 1:
        bad.append((cand, f"MULTI-COUNTRY {sorted(e['cc'])}"))
        continue
    if sorted(e["cc"])[0] != "SCO":
        bad.append((cand, f"NOT-SCO {sorted(e['cc'])}"))
        continue
    key = cand.lower().strip().replace("\u0307", "")
    ok.append((cand, key, e["rows"], sorted(e["cc"])[0], len(e["days"])))

print(f"candidates={len(CANDIDATES)} verified={len(ok)} bad={len(bad)}")
for name, why in bad:
    print(f"  BAD: {name} :: {why}")
for name, key, rows, cc, days in ok:
    print(f"  OK: {key} ({rows} rows, {cc}, {days} days)")
json.dump([{"raw": n, "key": k, "rows": r, "cc": c, "days": d} for n, k, r, c, d in ok],
          open("/tmp/c440-verified.json", "w"), ensure_ascii=False)
sys.exit(1 if bad else 0)
