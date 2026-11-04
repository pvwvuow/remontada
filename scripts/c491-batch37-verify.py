#!/usr/bin/env python3
# cycle-491 batch-37 pre/post verification (the 446..490 gate). PRE mode:
# every intended TEAM_FA key must be byte-exact (the live feed literal,
# lowercased) and single-country across the whole ±7 window (the 389 rule).
# COLLISION GATE: zero key duplicates and zero VALUE collisions against the
# whole file (the Logroñés rule). Batch 37 = the GRE tranche (ALL 4
# count>=3 single-country GRE names of the FRESH 491 census) — the WINNER
# of the THREE-WAY 2-tie GRE/SVK/SLV by the 447 QUALITY tie-break (the 487
# CHI-vs-BLR precedent): GRE 2 / SVK 2 / SLV 2 / SVN 1 / FIN 1 fresh, all
# six anchors top-flight per their own extracts, GRE's BOTH Super League
# Greece — the strongest+most visible league of the three.
# TWO direct anchors, byte-derived from the anchors' OWN titles (the FC
# rule minus the باشگاه-فوتبال prefix, the اشدود/آمازولو precedent):
# AE Larissa → لاریسا (باشگاه فوتبال لاریسا 3892127, «در سوپر لیگ فوتبال
# یونان بازی می‌کند… ۱۷ مه ۱۹۶۴ تأسیس») / Atromitos → آترومیتوس (باشگاه
# فوتبال آترومیتوس 3438822, «در پریستری، آتن… سوپر لیگ فوتبال یونان…
# ۱۹۲۳»). TWO zero-anchor honest reads (the 466 rule): GS Marko → جی‌اس
# مارکو (Q15309584 P17=Q41 + sitelink absence; «باشگاه فوتبال مارکو»
# re-proven the PORTUGUESE club 487+490; pure phonetic, the letter-cluster
# class) / Nestos Chrisoupolis → نستوس کریسوپولی (zero entity; «نستوس» fa
# = the river/municipality geography article, NOT the club; pure phonetic).
# POST mode (--post): after the patch, the same names must render PERSIAN
# in the live ±7 feed (zero raw literals).
import json, re, subprocess, sys

BASE = "http://localhost:3000"
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CANDIDATES = [
    "AE Larissa", "Atromitos", "GS Marko", "Nestos Chrisoupolis",
]

post = "--post" in sys.argv

PROPOSED = {
    "ae larissa": "لاریسا",
    "atromitos": "آترومیتوس",
    "gs marko": "جی‌اس مارکو",
    "nestos chrisoupolis": "نستوس کریسوپولی",
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
        ok = seen_rows >= 3 and len(ccs) == 1 and "GRE" in ccs
        print(f"  {cand!r} key={key!r} rows={seen_rows} cc={sorted(ccs)} "
              f"sample={sample} -> {'OK' if ok else 'BAD'}")
        samples.append(sample)
        if not ok:
            bad += 1
        if key in file_keys:
            print(f"    !! key already in file: {key}")
            bad += 1
    print(f"PRE-VERIFY: {len(CANDIDATES)-bad}/{len(CANDIDATES)} verified, "
          f"{bad} bad")
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
        print(f"  !! proposed VALUE collision: {v!r} already = "
              f"{all_vals[v]!r}")
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
                            print(f"  RAW LEAK {o:+d}: {cand} in "
                                  f"{m.get('id')}")
                        key = cand.lower()
                        if nm == PROPOSED[key]:
                            renders[cand] = renders.get(cand, 0) + 1
    print(f"  raw leaks = {leak}")
    for cand in CANDIDATES:
        print(f"  {cand} -> {PROPOSED[cand.lower()]} renders "
              f"{renders.get(cand, 0)}")
    sys.exit(0 if leak == 0 else 1)

print("saved nothing to /tmp (the domproof embeds the pairs in-repo)")
