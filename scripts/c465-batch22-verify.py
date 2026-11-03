#!/usr/bin/env python3
# cycle-465 batch-22 pre/post verification (the 446/447/450/451/452/455/456/
# 457/460/461/462 gate). PRE mode: every intended TEAM_FA key must be
# byte-exact (the live feed literal, lowercased for the key — the non-ASCII
# á key rides the file's OWN südtirol/köln/budućnost/dečić/atlético/átvélez
# precedent) and single-country across the whole ±7 window (the 389 rule:
# identity first, no guessing). Also runs the COLLISION GATE: zero key
# duplicates and zero VALUE collisions against the whole teamFa file (the
# Logroñés rule) — byte-read from src/lib/leagues.ts.
# Batch 22 = the PANAMA tranche (ALL 9 count>=3 single-country PAN names of
# the 465 census — the live LPF Apertura wave). The 447 tie-break rule
# invoked for the PAN 9/27 = HON 9/27 tie (the 464-card pin): anchor quality
# (the 447 RUS=GUA precedent) — PAN carries FIVE direct fa.wiki club
# articles (عربه یونیدو 43804828 / پلازا آمادور 41460671 /
# اسپورتینگ سن میگلیتو 44052583 / تائورو 41367386 / سان فرانسیسکو
# 41367482, every one identity-verified from its own intro) vs HON's THREE
# (رئال اسپانیا / اولانچو + the خوتیکالپا CITY page which is not a club
# anchor per the 452/462 rule) → PAN harvested, HON waits for the next
# update. ZERO (W) sides — no 435 skip needed; no exclusions.
# POST mode (--post): after the patch, the same names must render PERSIAN
# in the live ±7 feed (zero raw literals left for this batch).
# PRE mode is ONE-SHOT — it only works BEFORE the batch ships (the 454
# lesson). No domproof depends on this script's /tmp output: the 465
# domproof embeds the expected pairs and reads the in-repo block.
import json, re, subprocess, sys, time

BASE = "http://localhost:3000"
PERSIAN = re.compile(r"[\u0600-\u06FF]")
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CANDIDATES = [
    "CD Árabe Unido", "CD Plaza Amador", "Sporting San Miguelito",
    "UMECIT FC", "Tauro FC", "CD Universitario", "Herrera FC",
    "Independiente de La Chorrera", "San Francisco FC",
]

post = "--post" in sys.argv

PROPOSED = {
    "cd árabe unido": "عربه یونیدو",
    "cd plaza amador": "پلازا آمادور",
    "sporting san miguelito": "اسپورتینگ سن میگلیتو",
    "umecit fc": "اومسیت",
    "tauro fc": "تائورو",
    "cd universitario": "یونیورسیتاریو",
    "herrera fc": "هررا",
    "independiente de la chorrera": "ایندپندینته دی لا چوررا",
    "san francisco fc": "سان فرانسیسکو",
}


def fetch(url):
    out = subprocess.run(["curl", "-s", "--max-time", "40", "-A", UA, url],
                         capture_output=True, text=True, timeout=60).stdout
    return json.loads(out)


# ---- the whole teamFa file, byte-read (collision gate, the Logroñés rule)
src = open("src/lib/leagues.ts", encoding="utf-8").read()
pairs = re.findall(r'"((?:[^"\\]|\\.)+)":\s*"([^"]+)"', src)
file_keys = {}
for k, v in pairs:
    file_keys.setdefault(k, []).append(v)

if not post:
    print("== PRE: byte-exact live-literal keys + single-country ±7 ==")
    bad = 0
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
        ok = seen_rows >= 3 and len(ccs) == 1 and "PAN" in ccs
        print(f"  {cand!r} key={key!r} rows={seen_rows} cc={sorted(ccs)} "
              f"sample={sample} -> {'OK' if ok else 'BAD'}")
        if not ok:
            bad += 1
        if key in file_keys:
            print(f"    !! key already in file: {key}")
            bad += 1
    print(f"PRE-VERIFY: {len(CANDIDATES)-bad}/{len(CANDIDATES)} verified, {bad} bad")

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
