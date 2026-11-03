#!/usr/bin/env python3
# cycle-450 batch-13 pre-patch verification: every intended TEAM_FA key must be
# byte-exact (the live feed literal, lowercased for the key) and single-country
# across the whole ±7 window (the 389 rule: identity first, no guessing).
# Batch 13 = the GUATEMALA tranche (all 12 count-3 single-country GUA names of
# the 450 census — Liga Nacional Apertura; no (W) women's sides, no exclusions).
# Exactly the tranche the 447/448 rotation lines predicted ("GUA ۱۲ در نوبت
# است") and the live window confirms: GUA 12 > CYP 11 = THA 11.
import json, re, subprocess, sys

BASE = "http://localhost:3000"
PERSIAN = re.compile(r"[\u0600-\u06FF]")
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CANDIDATES = [
    "Antigua Guatemala", "Aurora FC", "CD Suchitepéquez", "Club Xelajú",
    "Coban Imperial", "Comunicaciones FC", "CSD Municipal",
    "Deportivo Malacateco", "Deportivo Marquense", "Deportivo Mixco",
    "Guastatoya", "San Pedro",
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
    if sorted(e["cc"])[0] != "GUA":
        bad.append((cand, f"NOT-GUA {sorted(e['cc'])}"))
        continue
    key = cand.lower().strip().replace("\u0307", "")
    ok.append((cand, key, e["rows"], sorted(e["cc"])[0], len(e["days"])))

print(f"candidates={len(CANDIDATES)} verified={len(ok)} bad={len(bad)}")
for name, why in bad:
    print(f"  BAD {name}: {why}")
out = [{"key": k, "literal": n, "rows": r, "cc": c, "days": d}
       for n, k, r, c, d in ok]
json.dump(out, open("/tmp/c450-verified.json", "w"), ensure_ascii=False)
total_rows = sum(x["rows"] for x in out)
print(f"total live leak rows covered = {total_rows}")
for x in out:
    print(f"  {x['key']}  rows={x['rows']} days={x['days']}")
sys.exit(1 if bad else 0)
