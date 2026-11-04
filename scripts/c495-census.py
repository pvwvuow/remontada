#!/usr/bin/env python3
# cycle-495 fresh census — the whole ±7 window, RAW (unmapped) team names
# only; the 494 rotation line declared the waiting tie SVK 4 / SVN 4 /
# SLV 4 (the fresh-492 anchor scoreboard SVK 2 / SLV 2 / SVN 1) + the
# fresh MLS possibility (the LAFC/RSL/Minnesota United playoff wave
# re-entering the ±7 window — the 494 observation). Rules copied from the
# 466..492 cards: count>=3 single-country (ccode) names; the 435 skip rule
# flags any (W) side inside a tranche; the loud-pool distinct/rows numbers
# for the B4 anchor (expect 1626/2820 exactly, the 492 post-patch measure —
# the 492 update touched only TEAM_FA + the matches cache key; the 494 fix
# touched only the LEAGUES catalog + COMPOSITE_REGION_FA, zero pool
# change).
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
    wflag = " (W) PRESENT" if any("(W)" in n for n, _, _ in lst) else ""
    print(f"  {cc}: {len(lst)} names{wflag}")
    for nm, r, ids in sorted(lst, key=lambda x: (-x[1], x[0])):
        print(f"      {nm!r} x{r} ids={ids}")

print("== the full count>=3 field (every country) ==")
for cc, lst in sorted(by_cc.items(), key=lambda kv: -len(kv[1])):
    print(f"  {cc}: {len(lst)} -> {[n for n, _, _ in sorted(lst)]}")

w_sides = [nm for nm, e in names.items()
           if e["rows"] >= 3 and len(e["cc"]) == 1 and "(W)" in nm]
print(f"(W) sides in top: {len(w_sides)} {w_sides}")
json.dump({"distinct": distinct, "rows": rows,
           "segments": {cc: [[n, r] for n, r, _ in sorted(v)]
                        for cc, v in by_cc.items()}},
          open("/tmp/c492-census.json", "w"), ensure_ascii=False)
print("saved -> /tmp/c492-census.json")
