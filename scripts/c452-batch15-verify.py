#!/usr/bin/env python3
# cycle-452 batch-15 pre/post verification (the 446/447/450/451 gate).
# PRE mode: every intended TEAM_FA key must be byte-exact (the live feed
# literal, lowercased for the key) and single-country across the whole ±7
# window (the 389 rule: identity first, no guessing). Also runs the
# COLLISION GATE: zero key duplicates and zero VALUE collisions against the
# whole teamFa file (the Logroñés rule) — byte-read from src/lib/leagues.ts.
# Batch 15 = the THAILAND tranche (all 11 count-3 single-country THA names
# of the 452 census — League Cup Play-offs; the honest 451 runner-up; no
# (W) women's sides, no exclusions).
# POST mode (--post): after the patch, the same names must render PERSIAN
# in the live ±7 feed (zero raw literals left for this batch).
# cycle-454 note: PRE mode is ONE-SHOT — it matches the raw English literals
# in the live feed, so it only works BEFORE the batch ships (after the patch
# it reports ABSENT by design — that IS the patch's success). POST mode
# (--post) is the repeatable half. cycle452-domproof.sh A3 no longer depends
# on this script's /tmp output (the 453 finding): it reads the git truth of
# commit 886f6ff instead.
import json, re, subprocess, sys

BASE = "http://localhost:3000"
PERSIAN = re.compile(r"[\u0600-\u06FF]")
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CANDIDATES = [
    "Chainat FC", "Kanchanaburi Power", "Kasetsart",
    "Khonkaen United FC", "Mahasarakham Sam Bai Tao", "Muang Loei United",
    "Nakhon Pathom", "Nong Bua Pitchaya FC", "PT Satun FC",
    "Pattaya Dolphins United", "Songkhla United FC",
]


def fetch(url):
    out = subprocess.run(["curl", "-s", "--max-time", "40", "-A", UA, url],
                         capture_output=True, text=True, timeout=60).stdout
    return json.loads(out)


def window():
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
                        e = seen.setdefault(name, {"cc": set(), "rows": 0,
                                                   "days": set()})
                        e["cc"].add(cc)
                        e["rows"] += 1
                        e["days"].add(day)
    return seen


post = "--post" in sys.argv
seen = window()
ok, bad = [], []
for cand in CANDIDATES:
    e = seen.get(cand)
    if not e:
        bad.append((cand, "ABSENT from the live ±7 window"))
        continue
    if len(e["cc"]) != 1:
        bad.append((cand, f"MULTI-COUNTRY {sorted(e['cc'])}"))
        continue
    if sorted(e["cc"])[0] != "THA":
        bad.append((cand, f"NOT-THA {sorted(e['cc'])}"))
        continue
    key = cand.lower().strip().replace("\u0307", "")
    ok.append((cand, key, e["rows"], sorted(e["cc"])[0], len(e["days"])))

print(f"candidates={len(CANDIDATES)} verified={len(ok)} bad={len(bad)}")
for name, why in bad:
    print(f"  BAD {name}: {why}")
out = [{"key": k, "literal": n, "rows": r, "cc": c, "days": d}
       for n, k, r, c, d in ok]
json.dump(out, open("/tmp/c452-verified.json", "w"), ensure_ascii=False)
total_rows = sum(x["rows"] for x in out)
print(f"total live leak rows covered = {total_rows}")

if not post:
    # collision gate (the 449/451 rule): keys unique within the file block
    # AND each BATCH value appears EXACTLY ONCE as a value in the whole
    # teamFa block (the same-value key groups — barça atlètic+barca atletic
    # etc. — are the file's own defensive-variant convention, expected and
    # fine; the gate only forbids a batch value ALREADY OWNED by another key
    # — the Logroñés rule).
    src = open("src/lib/leagues.ts", encoding="utf-8").read()
    m = re.search(r"const TEAM_FA[^=]*= \{([\s\S]*?)\n\};", src)
    if not m:
        print("BAD could not locate TEAM_FA block")
        sys.exit(1)
    block = m.group(1)
    pairs = re.findall(r'"((?:[^"\\]|\\.)+)":\s*"((?:[^"\\]|\\.)+)"', block)
    keys = [p[0] for p in pairs]
    vals = [p[1] for p in pairs]
    dupk = sorted({k for k in keys if keys.count(k) > 1})
    batch_keys = [x["key"] for x in out]
    valmap = dict(pairs)
    batch_vals = {k: valmap[k] for k in batch_keys if k in valmap}
    print(f"teamFa pairs parsed={len(pairs)} dupKeys={dupk}")
    print("batch block entries found:", len(batch_vals))
    coll = []
    for bk in batch_keys:
        bv = batch_vals.get(bk)
        c = vals.count(bv) if bv else 0
        if c != 1:
            coll.append((bk, bv, c))
        print(f"  {bk} -> {bv}  value-occurrences={c}")
    if dupk or coll or len(batch_vals) != len(CANDIDATES):
        print("BAD collision/parse gate")
        sys.exit(1)
    for x in out:
        print(f"  rows={x['rows']} days={x['days']} key={x['key']}")
else:
    # POST mode: a name ABSENT from the raw pool means it now renders
    # Persian (the map works) — that is SUCCESS; a name present in the raw
    # pool is a leak. The evidence names below are the ones the ±7 window
    # still carries raw-free.
    print(f"post candidates still raw: {len(ok)}  (0 = no leaks)")
    for x in ok:
        print(f"  STILL-RAW {x[0]}")
    if ok:
        print("BAD post gate: raw literals remain")
        sys.exit(1)
    print("POST gate PASS: zero batch raw literals in the live ±7 window")
    sys.exit(0)
