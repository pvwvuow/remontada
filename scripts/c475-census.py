#!/usr/bin/env python3
# cycle-475 fresh census — the whole ±7 window, RAW (unmapped) team names
# only; the 447 tie-break inputs for the ISR 8/24 ALONE rest (the 472
# card's rotation line). Rules copied from the 466/467/470/471/472 cards:
# count>=3 single-country (ccode) names; zero (W) sides in the top; the
# loud-pool distinct/rows numbers for the B4 re-anchor (471 documented
# post-census distinct=1704, rows=3048).
import json, subprocess
from collections import defaultdict

BASE = "http://localhost:3000"
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")


def fetch(url):
    out = subprocess.run(["curl", "-s", "--max-time", "40", "-A", UA, url],
                         capture_output=True, text=True, timeout=60).stdout
    return json.loads(out)


names = defaultdict(lambda: {"rows": 0, "cc": defaultdict(int), "ids": []})
rows = 0
for o in range(-7, 8):
    d = fetch(f"{BASE}/api/matches?offset={o}")
    for g in d.get("groups", []):
        cc = g.get("ccode") or ""
        for m in g.get("matches", []):
            for side in ("home", "away"):
                t = m.get(side) or {}
                nm = t.get("name") or ""
                fa = t.get("fa") or ""
                if not nm:
                    continue
                if fa and fa != nm:
                    continue                      # mapped (fa differs from raw)
                # raw row: fa missing OR fa == the English literal
                rows += 1
                e = names[nm]
                e["rows"] += 1
                e["cc"][cc] += 1
                if len(e["ids"]) < 4:
                    e["ids"].append(m.get("id"))

distinct = len(names)
by_cc = defaultdict(list)
for nm, e in names.items():
    if e["rows"] >= 3 and len(e["cc"]) == 1:
        cc = next(iter(e["cc"]))
        by_cc[cc].append((nm, e["rows"], e["ids"]))

print(f"census distinct={distinct} raw_rows={rows}")
print("== count>=3 single-country segments (by country, size desc) ==")
for cc, lst in sorted(by_cc.items(), key=lambda kv: -len(kv[1])):
    print(f"  {cc}: {len(lst)} names")
    for nm, r, ids in sorted(lst, key=lambda x: (-x[1], x[0])):
        print(f"      {nm!r} x{r} ids={ids}")

print("== the 8/24 rest: CZE / ISR detail ==")
for cc in ("CZE", "ISR"):
    lst = by_cc.get(cc, [])
    print(f"  {cc}: {len(lst)} names -> {[n for n, _, _ in sorted(lst)]}")

w_sides = [nm for nm, e in names.items()
           if e["rows"] >= 3 and len(e["cc"]) == 1 and "(W)" in nm]
print(f"(W) sides in top: {len(w_sides)}")
json.dump({"distinct": distinct, "rows": rows,
           "segments": {cc: [[n, r] for n, r, _ in sorted(v)]
                        for cc, v in by_cc.items()}},
          open("/tmp/c475-census.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c475-census.json")
