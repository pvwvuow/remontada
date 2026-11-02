#!/usr/bin/env python3
# cycle-432 batch-3 pre-patch verification: every intended TEAM_FA key must be
# byte-exact (lowercase of the live feed literal) and single-country across
# the whole ±7 window (the 389 rule: identity first, no guessing).
import json, re, subprocess, sys

BASE = "http://localhost:3000"
PERSIAN = re.compile(r"[\u0600-\u06FF]")
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CANDIDATES = [
    # --- the England National League System cluster (31) ---
    "Hereford", "Morecambe", "Torquay United", "Hemel Hempstead",
    "Walton and Hersham", "Banbury United", "Stratford Town",
    "Halesowen Town FC", "Leamington", "Rushall Olympic", "Needham Market",
    "Leiston", "Racing Club Warwick", "Stourbridge", "Chichester City FC",
    "Hanworth Villa", "Gloucester City", "Yate Town",
    "Havant and Waterlooville", "Enfield Town", "Chatham Town",
    "Welling United", "Leatherhead", "Whitehawk", "Dulwich Hamlet", "Quorn",
    "Lewes", "Bamber Bridge", "Bury Town", "Evesham United",
    "Chippenham Town",
    # --- the Spain Copa del Rey / federaciones cluster (17) ---
    "CF Calamocha", "CE Europa", "Sestao", "Castellonense",
    "Atlético Tordesillas", "Ciudad Lucena", "Rayo Majadahonda",
    "Gimnástica Segoviana", "Cultural Leonesa", "RSD Alcalá", "UD Llanera",
    "Ponferradina", "CE Manresa", "Sant Andreu", "Don Benito",
    "CD Extremadura", "Arosa SC",
]

def fetch(url):
    out = subprocess.run(["curl", "-s", "--max-time", "40", "-A", UA, url],
                         capture_output=True, text=True, timeout=60).stdout
    return json.loads(out)

seen = {}  # rawName -> {ccodes:set, rows:int, days:set}
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
    key = cand.lower()
    hit = seen.get(cand)
    if hit is None:
        bad.append((cand, "NOT-IN-WINDOW"))
        continue
    ccs = sorted(hit["cc"])
    if len(ccs) != 1:
        bad.append((cand, f"MULTI-COUNTRY {ccs}"))
        continue
    ok.append((key, ccs[0], hit["rows"], len(hit["days"])))

print(f"verified={len(ok)} bad={len(bad)}")
by_cc = {}
rows_total = 0
for key, cc, rows, days in ok:
    by_cc.setdefault(cc, []).append(key)
    rows_total += rows
for cc, keys in sorted(by_cc.items()):
    print(f"  {cc}: {len(keys)} names / rows-covered computed below")
print(f"total live leak rows covered by this batch: {rows_total}")
for name, why in bad:
    print(f"  !! BAD {name!r}: {why}")
print("KEYS-JSON", json.dumps([k for k, _, _, _ in ok], ensure_ascii=False))
sys.exit(1 if bad else 0)
