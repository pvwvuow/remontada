#!/usr/bin/env python3
# cycle-446 batch-11 pre-patch verification: every intended TEAM_FA key must be
# byte-exact (the live feed literal, lowercased for the key) and single-country
# across the whole ±7 window (the 389 rule: identity first, no guessing).
# Batch 11 = the COLOMBIA tranche (all 13 single-country COL names with
# count>=3 of the 446 census — 11 count-3 + Envigado/Unión Magdalena at
# count-4; Primera A + Primera B; no (W) women's sides, no exclusions).
# Byte-exactness matters here: the feed carries ñ=U+00F1, ó=U+00F3 and
# Á=U+00C1, and the TEAM_FA key is the lowercased literal.
import json, re, subprocess, sys

BASE = "http://localhost:3000"
PERSIAN = re.compile(r"[\u0600-\u06FF]")
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CANDIDATES = [
    "Envigado", "Unión Magdalena", "América de Cali", "Boca Juniors de Cali",
    "Chicó FC", "Deportes Quindío", "Deportivo Pereira", "Fortaleza FC",
    "Independiente Valle del Cauca", "Real Cartagena", "Real Cundinamarca",
    "Tigres FC", "Águilas Doradas",
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
    if sorted(e["cc"])[0] != "COL":
        bad.append((cand, f"NOT-COL {sorted(e['cc'])}"))
        continue
    key = cand.lower().strip().replace("\u0307", "")
    ok.append((cand, key, e["rows"], sorted(e["cc"])[0], len(e["days"])))

print(f"candidates={len(CANDIDATES)} verified={len(ok)} bad={len(bad)}")
for name, why in bad:
    print(f"  BAD {name}: {why}")
out = [{"key": k, "literal": n, "rows": r, "cc": c, "days": d}
       for n, k, r, c, d in ok]
json.dump(out, open("/tmp/c446-verified.json", "w"), ensure_ascii=False)
total_rows = sum(x["rows"] for x in out)
print(f"total live leak rows covered = {total_rows}")
for x in out:
    print(f"  {x['key']}  rows={x['rows']} days={x['days']}")
sys.exit(1 if bad else 0)
