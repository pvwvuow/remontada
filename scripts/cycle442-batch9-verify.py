#!/usr/bin/env python3
# cycle-442 batch-9 pre-patch verification: every intended TEAM_FA key must be
# byte-exact (the live feed literal, lowercased for the key) and single-country
# across the whole ±7 window (the 389 rule: identity first, no guessing).
# Batch 9 = the ROMANIA tranche (all 16 count-3 single-country ROU names of
# the 442 census — Cup Grp. A-D + Liga II + Superliga; no (W) women's sides,
# no exclusions). Byte-exactness matters twice here: the feed carries the
# Romanian comma-below letters (ș=U+0219, ț=U+021B — NOT the cedilla forms)
# plus â=U+00E2 and ă=U+0103, and the TEAM_FA key is the lowercased literal.
import json, re, subprocess, sys

BASE = "http://localhost:3000"
PERSIAN = re.compile(r"[\u0600-\u06FF]")
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CANDIDATES = [
    "ASU Politehnica Timișoara", "Chindia Târgoviște", "Concordia Chiajna",
    "Corvinul Hunedoara", "Csikszereda Miercurea Ciuc", "Dinamo București",
    "FC Argeș Pitesti", "FC Bacău", "FC Bihor Oradea", "FC Voluntari",
    "FCSB", "Gloria Bistrița", "Petrolul Ploiești", "Rapid București",
    "UTA Arad", "Universitatea Cluj",
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
    if sorted(e["cc"])[0] != "ROU":
        bad.append((cand, f"NOT-ROU {sorted(e['cc'])}"))
        continue
    key = cand.lower().strip().replace("\u0307", "")
    ok.append((cand, key, e["rows"], sorted(e["cc"])[0], len(e["days"])))

print(f"candidates={len(CANDIDATES)} verified={len(ok)} bad={len(bad)}")
for name, why in bad:
    print(f"  BAD: {name} :: {why}")
for name, key, rows, cc, days in ok:
    print(f"  OK: {key} ({rows} rows, {cc}, {days} days)")
json.dump([{"raw": n, "key": k, "rows": r, "cc": c, "days": d} for n, k, r, c, d in ok],
          open("/tmp/c442-verified.json", "w"), ensure_ascii=False)
sys.exit(1 if bad else 0)
