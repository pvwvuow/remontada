#!/usr/bin/env python3
# cycle-435 batch-4 pre-patch verification: every intended TEAM_FA key must be
# byte-exact (lowercase of the live feed literal) and single-country across
# the whole ±7 window (the 389 rule: identity first, no guessing).
# Batch 4 = the England non-league tranche (count-3 tier of the 435 census):
# National League + North/South + Isthmian + Northern/Southern Premier.
import json, re, subprocess, sys

BASE = "http://localhost:3000"
PERSIAN = re.compile(r"[\u0600-\u06FF]")
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CANDIDATES = [
    "AFC Telford United", "AFC Totton", "Alfreton Town", "Ashton United",
    "Aveley", "Avro", "Basingstoke", "Bath City", "Billericay",
    "Boston United", "Brackley Town", "Buxton", "Chesham United",
    "Cheshunt", "Chester FC", "Chorley", "Cleethorpes Town",
    "Dagenham & Redbridge", "Darlington", "Dartford", "Dorking Wanderers",
    "Emley", "FC United of Manchester", "Folkestone Invicta",
    "Gainsborough", "Gosport Borough", "Hartlepool United", "Hednesford",
    "Horsham", "Ilkeston Town", "King's Lynn Town", "Leighton Town",
    "Maidenhead United", "Maidstone United", "Maldon & Tiptree",
    "Malvern Town", "Merthyr Town", "Redcar Athletic",
    "Scarborough Athletic", "Slough Town", "South Shields", "Southport",
    "Spalding United", "Spennymoor Town FC", "Stockton Town",
    "Taunton Town", "Three Bridges", "Tonbridge Angels",
    "Warrington Rylands", "Warrington Town", "Weston Super Mare",
    "Wingate & Finchley", "Woking", "Workington", "Worthing",
]

def fetch(url):
    out = subprocess.run(["curl", "-s", "--max-time", "40", "-A", UA, url],
                         capture_output=True, text=True, timeout=60).stdout
    return json.loads(out)

seen = {}  # rawName -> {cc:set, rows:int, days:int}
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
    key = cand.lower().strip().replace("\u0307", "")
    ok.append((cand, key, e["rows"], sorted(e["cc"])[0], len(e["days"])))

print(f"candidates={len(CANDIDATES)} verified={len(ok)} bad={len(bad)}")
for name, why in bad:
    print(f"  BAD: {name} :: {why}")
for name, key, rows, cc, days in ok:
    print(f"  OK: {key} ({rows} rows, {cc}, {days} days)")
json.dump([{"raw": n, "key": k, "rows": r, "cc": c, "days": d} for n, k, r, c, d in ok],
          open("/tmp/c435-verified.json", "w"), ensure_ascii=False)
sys.exit(1 if bad else 0)
