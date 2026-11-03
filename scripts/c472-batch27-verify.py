#!/usr/bin/env python3
# cycle-472 batch-27 pre/post verification (the 446..471 gate). PRE mode:
# every intended TEAM_FA key must be byte-exact (the live feed literal,
# lowercased — the á/ě/č keys ride the file's OWN südtirol/köln/budućnost/
# dečić/atlético/árabe/logroñés/españa/montreal-é/ä precedent) and
# single-country across the whole ±7 window (the 389 rule). Also the
# COLLISION GATE: zero key duplicates and zero VALUE collisions against
# the whole file (the Logroñés rule). Batch 27 = the CZE tranche (ALL 8
# count>=3 single-country CZE names of the 472 census — the live Czech
# 2. Liga/ČFL wave), the WINNER of the CZE/ISR 8/24 TWO-WAY tie by the
# FRESH 447 re-read (scripts/c472-wiki-probe.py + c472-wiki-probe2.py +
# c472-wiki-probe3.py + c472-wiki-probe4.py): CZE carries FOUR direct
# identity-verified fa.wiki club articles (زبرویوفکا برنو 43783062 /
# هرادتس کرالووه 32598818 / یک. اسلواتسکو 43123547 / ملادا بولسلاف
# 44786128 — the last re-verified fresh, the 471 documented anchor) vs
# ISR 3 (بنی یهودا تل آویو 43798549 / هاپوئل تل‌آویو 44406164 / اشدود
# 43349375 — re-verified fresh; the bare اشدود page is the CITY, the club
# article is باشگاه فوتبال اشدود; کریات یام 42126668 the CITY too). The
# تپلیتسه 43208205 and ییهلاوا 41212923 pages are the CITY articles, NOT
# club anchors (the 466 خوتیکالپا lesson, re-confirmed). ZERO (W) sides
# in the tranche — no 435 skip needed.
# POST mode (--post): after the patch, the same names must render PERSIAN
# in the live ±7 feed (zero raw literals left for this batch).
import json, re, subprocess, sys, time

BASE = "http://localhost:3000"
PERSIAN = re.compile(r"[\u0600-\u06FF]")
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CANDIDATES = [
    "Artis Brno", "FC Zbrojovka Brno", "Hradec Králové", "Mladá Boleslav",
    "SK Prostějov", "Slovácko", "Teplice", "Vysočina Jihlava",
]

post = "--post" in sys.argv

PROPOSED = {
    "artis brno": "آرتیس برنو",
    "fc zbrojovka brno": "زبرویوفکا برنو",
    "hradec králové": "هرادتس کرالووه",
    "mladá boleslav": "ملادا بولسلاف",
    "sk prostějov": "پروستییوف",
    "slovácko": "یک. اسلواتسکو",
    "teplice": "تپلیتسه",
    "vysočina jihlava": "وی‌سوچینا ییهلاوا",
}


def fetch(url):
    out = subprocess.run(["curl", "-s", "--max-time", "40", "-A", UA, url],
                         capture_output=True, text=True, timeout=60).stdout
    return json.loads(out)


# ---- the whole file, byte-read (collision gate, the Logroñés rule)
src = open("src/lib/leagues.ts", encoding="utf-8").read()
pairs = re.findall(r'"((?:[^"\\]|\\.)+)":\s*"([^"]+)"', src)
file_keys = {}
for k, v in pairs:
    file_keys.setdefault(k, []).append(v)

if not post:
    print("== PRE: byte-exact live-literal keys + single-country ±7 ==")
    bad = 0
    samples = []
    for cand in CANDIDATES:
        key = cand.lower()
        seen_rows = 0
        ccs = set()
        sample = None
        for o in range(-7, 8):
            d = fetch(f"{BASE}/api/matches?offset={o}")
            for g in d.get("groups", []):
                for m in g.get("matches", []):
                    for side in ("home", "away"):
                        t = m.get(side) or {}
                        nm = t.get("fa") or t.get("name") or ""
                        if nm == cand:
                            seen_rows += 1
                            ccs.add(g.get("ccode") or "")
                            sample = sample or m.get("id")
        ok = seen_rows >= 3 and len(ccs) == 1 and "CZE" in ccs
        print(f"  {cand!r} key={key!r} rows={seen_rows} cc={sorted(ccs)} "
              f"sample={sample} -> {'OK' if ok else 'BAD'}")
        samples.append(sample)
        if not ok:
            bad += 1
        if key in file_keys:
            print(f"    !! key already in file: {key}")
            bad += 1
    print(f"PRE-VERIFY: {len(CANDIDATES)-bad}/{len(CANDIDATES)} verified, {bad} bad")
    print(f"sample ids: {sorted(s for s in samples if s)}")

# ---- collision gate (always) ----
print("== COLLISION GATE ==")
dup_keys = [k for k, v in file_keys.items() if len(v) > 1]
all_vals = {}
val_dups = []
for k, v in pairs:
    if v in all_vals and all_vals[v] != k:
        val_dups.append((v, all_vals[v], k))
    all_vals.setdefault(v, k)
for k in PROPOSED:
    hits = file_keys.get(k)
    if hits:
        print(f"  !! proposed key already present: {k} -> {hits}")
for k, v in PROPOSED.items():
    if v in all_vals:
        print(f"  !! proposed VALUE collision: {v!r} already = {all_vals[v]!r}")
print(f"  file pairs read: {len(pairs)}; dupKeys={dup_keys[:5]}; "
      f"valueCollisions={val_dups[:5]}")

# ---- POST: zero raw literals for the batch in the live ±7 feed ----
if post:
    print("== POST: zero raw literals in the live ±7 feed ==")
    leak = 0
    renders = {}
    for o in range(-7, 8):
        d = fetch(f"{BASE}/api/matches?offset={o}")
        for g in d.get("groups", []):
            for m in g.get("matches", []):
                for side in ("home", "away"):
                    t = m.get(side) or {}
                    nm = t.get("fa") or t.get("name") or ""
                    for cand in CANDIDATES:
                        if nm == cand:
                            leak += 1
                            print(f"  RAW LEAK {o:+d}: {cand} in {m.get('id')}")
                        key = cand.lower()
                        if nm == PROPOSED[key]:
                            renders[cand] = renders.get(cand, 0) + 1
    print(f"  raw leaks = {leak}")
    for cand in CANDIDATES:
        print(f"  {cand} -> {PROPOSED[cand.lower()]} renders {renders.get(cand, 0)}")
    sys.exit(0 if leak == 0 else 1)

print("saved nothing to /tmp (the domproof embeds the pairs in-repo)")
