#!/usr/bin/env python3
# cycle-492 batch-38 pre/post verification (the 446..491 gate). PRE mode:
# every intended TEAM_FA key must be byte-exact (the live feed literal,
# lowercased) and single-country across the whole ±7 window (the 389 rule).
# COLLISION GATE: zero key duplicates and zero VALUE collisions against the
# whole file (the Logroñés rule). Batch 38 = the FIN tranche (ALL 4
# count>=3 single-country FIN names of the FRESH 492 census) — the WINNER
# of the THREE-WAY 2-tie SVK/FIN/SLV by the 447 QUALITY tie-break (the 491
# form): FIN 2 (اینتر تورکو 5972064 + هلسینکی 3318721 via the football
# entity Q208584 — the ice-hockey Q5477766 trap rejected) vs SVK 2
# (کوشیتسه + دوکلا) and SLV 2 (پلاتینزه + ایسیدرو متاپان), SVN 1 — BOTH
# FIN anchors state «لیگ برتر فوتبال فنلاند» (a UEFA-member top flight)
# + HJK's «۲۷ قهرمانی» record marker.
# TWO direct anchors, byte-derived from the anchors' OWN titles (the FC
# rule minus the باشگاه-فوتبال prefix, the اشدود/آمازولو precedent):
# FC Inter Turku → اینتر تورکو (باشگاه فوتبال اینتر تورکو 5972064) / HJK →
# هلسینکی (باشگاه فوتبال هلسینکی 3318721, «به انگلیسی: HJK Helsinki»).
# TWO zero-anchor honest reads (the 466 rule): IF Gnistan → گنیستان
# (Q5970899 P17=Q33 + sitelink absence; fa hit player-noise only; pure
# phonetic) / VPS → وی‌پی‌اس (zero entity; the letter-cluster class).
# POST mode (--post): after the patch, the same names must render PERSIAN
# in the live ±7 feed (zero raw literals).
import json, re, subprocess, sys

BASE = "http://localhost:3000"
UA = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

CANDIDATES = [
    "FC Inter Turku", "HJK", "IF Gnistan", "VPS",
]

post = "--post" in sys.argv

PROPOSED = {
    "fc inter turku": "اینتر تورکو",
    "hjk": "هلسینکی",
    "if gnistan": "گنیستان",
    "vps": "وی\u200cپی\u200cاس",
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
        ok = seen_rows >= 3 and len(ccs) == 1 and "FIN" in ccs
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
